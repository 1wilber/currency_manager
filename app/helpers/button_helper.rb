module ButtonHelper
  def icon_link(text, path, icon:, **options)
    css_class = options.delete(:class) || "btn"

    link_to path, { class: css_class, **options } do
      concat icon(icon)
      concat tag.span(text, class: "ml-2")
    end
  end

  def turbo_submit(form)
    form.submit t(:save),
                class: "btn btn-primary",
                data: { turbo_submits_with: t(:saving) }
  end
end
