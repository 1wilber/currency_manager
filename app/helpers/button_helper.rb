module ButtonHelper
  def icon_link(text, path, icon:, **options)
    link_to path, options do
      concat icon("plus")
      concat tag.span { text }
    end
  end
end
