# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionCalculable do
  let(:sender) { create(:bank, currency: 'CLP') }
  let(:receiver) { create(:bank, currency: 'VES') }
  let(:transaction) do
    build(:transaction,
          sender: sender,
          receiver: receiver,
          amount: 1000,
          rate: 35,
          cost_rate: 34)
  end

  describe '#calculate_total' do
    it 'calcula el total correctamente' do
      transaction.calculate_total
      expect(transaction.total).to eq(35000)
    end

    it 'actualiza el total cuando cambia el amount' do
      transaction.amount = 2000
      transaction.calculate_total
      expect(transaction.total).to eq(70000)
    end

    it 'actualiza el total cuando cambia el rate' do
      transaction.rate = 40
      transaction.calculate_total
      expect(transaction.total).to eq(40000)
    end
  end

  describe '#calculate_profit' do
    before do
      transaction.calculate_total
    end

    it 'calcula la ganancia correctamente' do
      transaction.calculate_profit
      # cost_total = 1000 * 34 = 34000
      # total = 35000
      # profit = (34000 - 35000) / 35 = -28.57
      expect(transaction.profit).to eq(-28.57)
    end

    it 'maneja rate = 0 sin errores' do
      transaction.rate = 0
      transaction.calculate_profit
      expect(transaction.profit).to eq(0)
    end

    it 'maneja NaN correctamente' do
      transaction.rate = 0
      transaction.amount = 0
      expect { transaction.calculate_profit }.not_to raise_error
      expect(transaction.profit).to eq(0)
    end
  end

  describe '#calculate_amounts' do
    it 'calcula total y profit juntos' do
      transaction.calculate_amounts
      expect(transaction.total).to eq(35000)
      expect(transaction.profit).to eq(-28.57)
    end

    it 'no calcula si falta amount' do
      transaction.amount = nil
      transaction.calculate_amounts
      expect(transaction.total).to be_nil
    end

    it 'no calcula si falta rate' do
      transaction.rate = nil
      transaction.calculate_amounts
      expect(transaction.total).to be_nil
    end

    it 'no calcula si falta cost_rate' do
      transaction.cost_rate = nil
      transaction.calculate_amounts
      expect(transaction.total).to eq(35000) # total se calcula
      # pero profit necesita cost_rate
    end
  end

  describe '#profit_margin' do
    before do
      transaction.calculate_amounts
    end

    it 'calcula el margen de ganancia como decimal' do
      # profit = -28.57, amount = 1000
      # margin = -28.57 / 1000 = -0.02857
      expect(transaction.profit_margin).to be_within(0.00001).of(-0.02857)
    end

    it 'retorna 0 cuando rate es 0' do
      transaction.rate = 0
      expect(transaction.profit_margin).to eq(0.0)
    end

    it 'retorna 0 cuando amount es 0' do
      transaction.amount = 0
      expect(transaction.profit_margin).to eq(0.0)
    end

    context 'cuando hay ganancia positiva' do
      let(:transaction) do
        build(:transaction,
              sender: sender,
              receiver: receiver,
              amount: 1000,
              rate: 34,
              cost_rate: 35)
      end

      it 'retorna un margen positivo' do
        transaction.calculate_amounts
        expect(transaction.profit_margin).to be > 0
      end
    end
  end

  describe '#profit_percentage_on_total' do
    before do
      transaction.calculate_amounts
    end

    it 'calcula el porcentaje de ganancia sobre el total' do
      # profit = -28.57, total = 35000
      # percentage = (-28.57 / 35000) * 100
      expect(transaction.profit_percentage_on_total).to be_within(0.01).of(-0.0816)
    end

    it 'retorna 0 cuando total es 0' do
      transaction.total = 0
      expect(transaction.profit_percentage_on_total).to eq(0.0)
    end
  end

  describe '#rate_spread' do
    it 'calcula la diferencia entre rate y cost_rate' do
      expect(transaction.rate_spread).to eq(1)
    end

    it 'puede ser negativo' do
      transaction.rate = 30
      transaction.cost_rate = 35
      expect(transaction.rate_spread).to eq(-5)
    end
  end

  describe '#profitable?' do
    context 'cuando hay ganancia' do
      before do
        transaction.cost_rate = 40
        transaction.calculate_amounts
      end

      it 'retorna true' do
        expect(transaction).to be_profitable
      end
    end

    context 'cuando hay pérdida' do
      before do
        transaction.cost_rate = 30
        transaction.calculate_amounts
      end

      it 'retorna false' do
        expect(transaction).not_to be_profitable
      end
    end

    context 'cuando profit es 0' do
      before do
        transaction.cost_rate = 35
        transaction.calculate_amounts
      end

      it 'retorna false' do
        expect(transaction).not_to be_profitable
      end
    end
  end

  describe '#cost_total' do
    it 'calcula el total del costo' do
      expect(transaction.cost_total).to eq(34000)
    end

    it 'actualiza cuando cambian los valores' do
      transaction.amount = 2000
      transaction.cost_rate = 36
      expect(transaction.cost_total).to eq(72000)
    end
  end

  describe 'callbacks' do
    it 'ejecuta calculate_amounts en before_validation' do
      expect(transaction).to receive(:calculate_amounts)
      transaction.valid?
    end
  end

  describe 'integración completa' do
    context 'escenario de compra de VES' do
      let(:transaction) do
        build(:transaction,
              sender: sender,
              receiver: receiver,
              amount: 100000,    # 100,000 CLP
              rate: 35.5,        # 1 CLP = 35.5 VES
              cost_rate: 34.8)   # Tasa de costo
      end

      it 'calcula todos los valores correctamente' do
        transaction.calculate_amounts

        expect(transaction.total).to eq(3550000)      # 100,000 * 35.5
        expect(transaction.cost_total).to eq(3480000) # 100,000 * 34.8
        expect(transaction.profit).to be_within(0.01).of(-1971.83) # (3,480,000 - 3,550,000) / 35.5
        expect(transaction.profit_margin).to be_within(0.00001).of(-0.0197183)
        expect(transaction).not_to be_profitable
      end
    end

    context 'escenario de venta de VES' do
      let(:ves_bank) { create(:bank, currency: 'VES') }
      let(:clp_bank) { create(:bank, currency: 'CLP') }
      let(:transaction) do
        build(:transaction,
              sender: ves_bank,
              receiver: clp_bank,
              amount: 3500000,   # 3,500,000 VES
              rate: 0.028,       # 1 VES = 0.028 CLP
              cost_rate: 0.027)  # Tasa de costo
      end

      it 'calcula todos los valores correctamente' do
        transaction.calculate_amounts

        expect(transaction.total).to eq(98000)        # 3,500,000 * 0.028
        expect(transaction.cost_total).to eq(94500)   # 3,500,000 * 0.027
        expect(transaction.profit).to be_within(0.01).of(125000) # (94,500 - 98,000) / 0.028
        expect(transaction.profit_margin).to be_within(0.00001).of(0.0357142857)
        expect(transaction).to be_profitable
      end
    end
  end
end
