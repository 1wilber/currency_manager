module ApplicationHelper
  def icon(name)
    render plain: Rails.root.join("app", "assets", "icons", "#{name}.svg").read.html_safe rescue nil
  end

  def dollar_sign
    "$"
  end

  def render_currency_flag(currency)
    render plain: Rails.root.join("app", "assets", "flags", "#{currency}.svg").read.html_safe rescue "No existe #{currency}"
  end
end
