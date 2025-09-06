module ButtonHelper
  def icon_link(text, path, icon:, **options)
    link_to path, options do
      concat icon("plus")
      concat tag.span { text }
    end
  end

  def turbo_submit(form)
    form.submit t(:save), data: { turbo_submits_with: t(:saving) }
  end
end
