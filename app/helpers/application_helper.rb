module ApplicationHelper
  def icon(name)
    render plain: Rails.root.join("app", "assets", "icons", "#{name}.svg").read.html_safe rescue nil
  end
end
