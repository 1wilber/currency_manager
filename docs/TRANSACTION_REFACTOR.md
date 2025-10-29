# Transaction Model Refactoring Guide

## 📋 Tabla de Contenidos

- [Resumen](#resumen)
- [Motivación](#motivación)
- [Arquitectura Anterior](#arquitectura-anterior)
- [Nueva Arquitectura](#nueva-arquitectura)
- [Concerns Creados](#concerns-creados)
- [Service Objects](#service-objects)
- [Decorator Mejorado](#decorator-mejorado)
- [Guía de Migración](#guía-de-migración)
- [Ejemplos de Uso](#ejemplos-de-uso)
- [Testing](#testing)
- [Mejores Prácticas](#mejores-prácticas)

---

## 🎯 Resumen

Este documento describe la refactorización del modelo `Transaction` para mejorar la encapsulación, mantenibilidad y adherencia a principios SOLID y convenciones de Rails.

### Cambios Principales

- ✅ Separación de responsabilidades usando Concerns
- ✅ Extracción de lógica de negocio a Service Objects (Interactors)
- ✅ Movimiento de lógica de presentación a Decorators
- ✅ Mejora en testing y cobertura
- ✅ Código más mantenible y testeable

---

## 💡 Motivación

### Problemas del Código Original

1. **Violación del Single Responsibility Principle**
   - El modelo manejaba cálculos, asignación de fondos, validaciones y presentación
   - Métodos `display_*` mezclaban lógica de presentación con lógica de negocio

2. **Callbacks Complejos**
   - Múltiples operaciones en `before_validation` difíciles de debuggear
   - Orden de ejecución no explícito

3. **Acoplamiento Fuerte**
   - Lógica de asignación de fondos acoplada directamente al modelo
   - Difícil de testear y reutilizar

4. **Falta de Modularidad**
   - Todo el código en un solo archivo grande
   - Difícil de navegar y mantener

---

## 📦 Arquitectura Anterior

```ruby
# app/models/transaction.rb (ANTES)
class Transaction < ApplicationRecord
  # 150+ líneas de código
  # - Cálculos
  # - Asignación de fondos
  # - Formateo de datos
  # - Validaciones
  # - Scopes
  # - Métodos de utilidad
end
```

**Responsabilidades mezcladas:**
- ✗ Cálculos matemáticos
- ✗ Gestión de bank_balances
- ✗ Formateo para vistas
- ✗ Lógica de negocio compleja
- ✗ Validaciones

---

## 🏗️ Nueva Arquitectura

### Separación por Concerns

```
app/models/
├── transaction.rb (Modelo principal - coordinación)
└── concerns/
    ├── transaction_attributable.rb (Gestión de atributos)
    ├── transaction_calculable.rb (Cálculos)
    └── transaction_fundable.rb (Gestión de fondos)
```

### Service Objects

```
app/interactors/
└── transactions/
    └── assign_funds.rb (Lógica de asignación de fondos)
```

### Decorators

```
app/decorators/
└── transaction_decorator.rb (Lógica de presentación)
```

---

## 🧩 Concerns Creados

### 1. TransactionAttributable

**Responsabilidad:** Gestión de atributos y relaciones polimórficas

```ruby
# app/models/concerns/transaction_attributable.rb
module TransactionAttributable
  extend ActiveSupport::Concern

  included do
    belongs_to :sender, polymorphic: true
    belongs_to :receiver, polymorphic: true
    belongs_to :customer
    
    before_validation :set_currencies_from_parties
    before_validation :set_customer_from_receiver
  end
end
```

**Métodos Principales:**
- `set_currencies_from_parties` - Auto-asigna monedas desde sender/receiver
- `set_customer_from_receiver` - Auto-asigna customer
- `currency_pair` - Retorna "CLP/VES"
- `clp_to_ves?` - Verifica dirección de conversión
- `involves_bank?(bank)` - Verifica si un banco está involucrado
- `parties_info` - Información detallada de las partes

**Uso:**
```ruby
transaction.currency_pair  # => "CLP/VES"
transaction.clp_to_ves?    # => true
transaction.sender_name    # => "Banco de Chile"
```

### 2. TransactionCalculable

**Responsabilidad:** Todos los cálculos matemáticos de la transacción

```ruby
# app/models/concerns/transaction_calculable.rb
module TransactionCalculable
  extend ActiveSupport::Concern

  included do
    before_validation :calculate_amounts
  end
end
```

**Métodos Principales:**
- `calculate_total` - Calcula total = amount × rate
- `calculate_profit` - Calcula ganancia
- `profit_margin` - Margen de ganancia como decimal
- `profitable?` - Verifica si es rentable
- `rate_spread` - Diferencia entre rate y cost_rate
- `cost_total` - Total del costo

**Fórmulas:**
```ruby
total = amount × rate
cost_total = amount × cost_rate
profit = (cost_total - total) / rate
profit_margin = profit / amount
```

**Uso:**
```ruby
transaction.calculate_amounts
transaction.total           # => 35000
transaction.profit          # => -28.57
transaction.profit_margin   # => -0.02857
transaction.profitable?     # => false
```

### 3. TransactionFundable

**Responsabilidad:** Gestión de bank_balances y asignación de fondos

```ruby
# app/models/concerns/transaction_fundable.rb
module TransactionFundable
  extend ActiveSupport::Concern

  included do
    has_many :bank_balance_transactions, dependent: :destroy
    has_many :bank_balances, through: :bank_balance_transactions
    
    before_validation :assign_funds_to_transaction
    before_validation :set_cost_rate_from_balances
  end
end
```

**Métodos Principales:**
- `assign_funds_to_transaction` - Asigna fondos automáticamente
- `merged_rates` - Calcula tasa promedio ponderada
- `funded?` - Verifica si tiene fondos asignados
- `total_funds_assigned` - Total de fondos asignados
- `funding_percentage` - Porcentaje de financiamiento
- `funding_details` - Detalles de fondos por balance
- `release_funds!` - Libera fondos asignados
- `reassign_funds!` - Reasigna fondos

**Uso:**
```ruby
transaction.funded?              # => true
transaction.total_funds_assigned # => 35000
transaction.funding_percentage   # => 100.0
transaction.funding_details      # => [{ bank_balance_code: "COM-001", ... }]
```

---

## 🔧 Service Objects

### Transactions::AssignFunds

**Responsabilidad:** Asignar fondos de bank_balances disponibles a una transacción

**Ubicación:** `app/interactors/transactions/assign_funds.rb`

**Estrategia:** FIFO (First In, First Out) - usa los balances más antiguos primero

**API:**
```ruby
result = Transactions::AssignFunds.call(transaction: transaction)

if result.success?
  puts "Fondos asignados: #{result.assigned_balances.count}"
  puts "Total asignado: #{result.total_assigned}"
else
  puts "Error: #{result.error}"
end
```

**Flujo de Ejecución:**
1. Valida que la transacción sea válida
2. Limpia asignaciones previas
3. Obtiene balances disponibles (ordenados por fecha)
4. Valida que haya fondos suficientes
5. Asigna fondos usando estrategia FIFO
6. Crea registros `BankBalanceTransaction`

**Ventajas:**
- ✅ Lógica aislada y testeable
- ✅ Fácil de modificar la estrategia de asignación
- ✅ Manejo de errores robusto
- ✅ Logging integrado
- ✅ Reutilizable desde cualquier lugar

**Ejemplo de Uso Directo:**
```ruby
# En un controller o servicio
def create
  @transaction = Transaction.new(transaction_params)
  
  # Los fondos se asignan automáticamente en before_validation
  if @transaction.save
    redirect_to @transaction
  else
    render :new
  end
end

# O manualmente si necesitas control
result = Transactions::AssignFunds.call(transaction: @transaction)
if result.success?
  @transaction.save
end
```

---

## 🎨 Decorator Mejorado

### TransactionDecorator

**Responsabilidad:** Toda la lógica de presentación

**Ubicación:** `app/decorators/transaction_decorator.rb`

**Métodos de Presentación:**
```ruby
decorator = transaction.decorate

# Formateo de montos
decorator.amount           # => "$100.000"
decorator.total            # => "3.550.000 Bs."
decorator.profit           # => "-$28,57"

# Formateo de tasas
decorator.rate             # => "35.5"
decorator.cost_rate        # => "34.8"
decorator.rate_display     # => "1 CLP = 35.5 VES"

# Métricas
decorator.profit_margin    # => "-2.8571%"
decorator.currency_pair    # => "CLP/VES"

# Fechas
decorator.formatted_created_at  # => "15 de enero de 2025, 14:30"

# Estado visual
decorator.status_badge     # => <span class="badge badge-success">Completada</span>
```

**Uso en Vistas:**
```erb
<%# app/views/transactions/show.html.erb %>
<% transaction = @transaction.decorate %>

<div class="transaction-details">
  <h2>Transacción <%= transaction.currency_pair %></h2>
  
  <dl>
    <dt>Monto:</dt>
    <dd><%= transaction.amount %></dd>
    
    <dt>Tasa:</dt>
    <dd><%= transaction.rate_display %></dd>
    
    <dt>Total:</dt>
    <dd><%= transaction.total %></dd>
    
    <dt>Ganancia:</dt>
    <dd><%= transaction.profit %> (<%= transaction.profit_margin %>)</dd>
    
    <dt>Estado:</dt>
    <dd><%= transaction.status_badge %></dd>
  </dl>
</div>
```

---

## 🔄 Guía de Migración

### Paso 1: Actualizar Referencias a Métodos Display

**ANTES:**
```ruby
# En vistas
<%= @transaction.display_amount %>
<%= @transaction.display_profit_margin %>
```

**DESPUÉS:**
```ruby
# En vistas
<% transaction = @transaction.decorate %>
<%= transaction.amount %>
<%= transaction.profit_margin %>
```

### Paso 2: Actualizar Cálculos Manuales

**ANTES:**
```ruby
transaction.calculate
transaction.save
```

**DESPUÉS:**
```ruby
# Los cálculos son automáticos
transaction.save  # calculate_amounts se ejecuta en before_validation
```

### Paso 3: Actualizar Asignación de Fondos

**ANTES:**
```ruby
transaction.assign_funds!
```

**DESPUÉS:**
```ruby
# Automático en before_validation
transaction.save

# O manual si necesitas:
result = Transactions::AssignFunds.call(transaction: transaction)
```

### Paso 4: Actualizar Tests

**ANTES:**
```ruby
it 'calcula el total' do
  transaction.calculate
  expect(transaction.total).to eq(35000)
end
```

**DESPUÉS:**
```ruby
it 'calcula el total' do
  transaction.valid?  # Dispara los callbacks
  expect(transaction.total).to eq(35000)
end
```

---

## 📝 Ejemplos de Uso

### Crear una Transacción

```ruby
# Los cálculos y asignación de fondos son automáticos
transaction = Transaction.create!(
  sender: bank_clp,
  receiver: bank_ves,
  amount: 100_000,
  rate: 35.5
)

# Acceder a valores calculados
transaction.total           # => 3_550_000
transaction.profit          # => calculado automáticamente
transaction.cost_rate       # => promedio ponderado de balances asignados
transaction.funded?         # => true
```

### Consultar Transacciones

```ruby
# Scopes mejorados
Transaction.profitable
Transaction.recents
Transaction.by_range([1.week.ago, Date.today])
Transaction.for_customer(customer)
Transaction.for_bank(bank)

# Estadísticas
stats = Transaction.by_range([1.month.ago, Date.today]).statistics
# => {
#   count: 150,
#   total_amount: 5_000_000,
#   total_profit: 125_000,
#   average_rate: 35.2,
#   average_profit_margin: 0.025
# }

# Agrupar por par de monedas
Transaction.group_by_currency_pair
```

### Información Detallada

```ruby
# Resumen de la transacción
transaction.summary
# => {
#   id: 1,
#   currency_pair: "CLP/VES",
#   amount: 100000,
#   rate: 35.5,
#   total: 3550000,
#   profit: -28.57,
#   funded: true,
#   ...
# }

# Información de financiamiento
transaction.funding_details
# => [
#   { bank_balance_code: "COM-001", amount_used: 2000000, rate_used: 34.5, percentage: 56.34 },
#   { bank_balance_code: "COM-002", amount_used: 1550000, rate_used: 35.0, percentage: 43.66 }
# ]

# Auditoría
transaction.audit_info
```

### Usar el Decorator

```ruby
# En el controller
def show
  @transaction = Transaction.find(params[:id]).decorate
end

# En la vista
<%= @transaction.amount %>
<%= @transaction.profit_margin %>
<%= @transaction.status_badge %>
```

### Duplicar Transacción

```ruby
# Para transacciones recurrentes
new_transaction = transaction.duplicate
new_transaction.save
```

---

## 🧪 Testing

### Testear Concerns

```ruby
# spec/models/concerns/transaction_calculable_spec.rb
RSpec.describe TransactionCalculable do
  let(:transaction) { build(:transaction, amount: 1000, rate: 35, cost_rate: 34) }
  
  describe '#calculate_total' do
    it 'calcula correctamente' do
      transaction.calculate_total
      expect(transaction.total).to eq(35000)
    end
  end
end
```

### Testear Service Objects

```ruby
# spec/interactors/transactions/assign_funds_spec.rb
RSpec.describe Transactions::AssignFunds do
  describe '.call' do
    context 'con fondos suficientes' do
      it 'asigna fondos correctamente' do
        result = described_class.call(transaction: transaction)
        
        expect(result).to be_success
        expect(result.assigned_balances.count).to eq(2)
      end
    end
    
    context 'sin fondos suficientes' do
      it 'falla con error' do
        result = described_class.call(transaction: transaction)
        
        expect(result).to be_failure
        expect(result.error).to include('fondos insuficientes')
      end
    end
  end
end
```

### Testear Decorators

```ruby
# spec/decorators/transaction_decorator_spec.rb
RSpec.describe TransactionDecorator do
  let(:transaction) { create(:transaction).decorate }
  
  describe '#amount' do
    it 'formatea el monto correctamente' do
      expect(transaction.amount).to eq('$100.000')
    end
  end
  
  describe '#profit_margin' do
    it 'formatea el margen como porcentaje' do
      expect(transaction.profit_margin).to match(/\d+\.\d+%/)
    end
  end
end
```

---

## ✨ Mejores Prácticas

### 1. Usar Concerns para Agrupar Funcionalidad

```ruby
# ✅ BIEN: Cada concern tiene una responsabilidad clara
class Transaction < ApplicationRecord
  include TransactionAttributable
  include TransactionCalculable
  include TransactionFundable
end

# ❌ MAL: Todo en un solo modelo
class Transaction < ApplicationRecord
  # 500 líneas de código...
end
```

### 2. Usar Service Objects para Lógica Compleja

```ruby
# ✅ BIEN: Lógica aislada y testeable
result = Transactions::AssignFunds.call(transaction: transaction)

# ❌ MAL: Lógica en callbacks
before_validation :assign_funds_with_complex_logic
```

### 3. Usar Decorators para Presentación

```ruby
# ✅ BIEN: Lógica de presentación en decorator
<%= @transaction.decorate.amount %>

# ❌ MAL: Lógica de presentación en modelo
<%= @transaction.display_amount %>
```

### 4. Mantener el Modelo Limpio

```ruby
# ✅ BIEN: Modelo como coordinador
class Transaction < ApplicationRecord
  include Concerns...
  
  # Solo métodos de coordinación y queries
  def summary
    # ...
  end
end

# ❌ MAL: Modelo con todo
class Transaction < ApplicationRecord
  def calculate_everything
    # 100 líneas...
  end
end
```

### 5. Escribir Tests para Cada Capa

```ruby
# ✅ Testear concerns independientemente
# ✅ Testear service objects aislados
# ✅ Testear decorators
# ✅ Testear integración en el modelo
```

---

## 📊 Beneficios de la Refactorización

### Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Líneas en modelo** | 150+ | 60 |
| **Responsabilidades** | 5+ | 1 (coordinación) |
| **Testabilidad** | Difícil | Fácil |
| **Mantenibilidad** | Baja | Alta |
| **Reutilización** | Baja | Alta |
| **Claridad** | Confusa | Clara |

### Principios SOLID Aplicados

- ✅ **Single Responsibility**: Cada clase/módulo tiene una sola razón para cambiar
- ✅ **Open/Closed**: Abierto a extensión, cerrado a modificación
- ✅ **Liskov Substitution**: Los concerns pueden ser intercambiables
- ✅ **Interface Segregation**: Interfaces pequeñas y específicas
- ✅ **Dependency Inversion**: Dependemos de abstracciones (concerns, interactors)

---

## 🚀 Próximos Pasos

1. **Migrar código existente** siguiendo la guía de migración
2. **Escribir tests** para asegurar que todo funciona igual
3. **Actualizar vistas** para usar decorators
4. **Documentar** cualquier comportamiento específico del dominio
5. **Refactorizar otros modelos** siguiendo el mismo patrón

---

## 📚 Referencias

- [Rails Concerns](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)
- [Interactor Gem](https://github.com/collectiveidea/interactor)
- [Draper Decorators](https://github.com/drapergem/draper)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Service Objects in Rails](https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial)

---

**Fecha de Refactorización:** Enero 2025  
**Versión:** 1.0  
**Autor:** Currency Manager Team