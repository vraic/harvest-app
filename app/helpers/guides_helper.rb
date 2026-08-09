module GuidesHelper
  def guides_sidebar_sections(sections)
    sections.to_a
  end

  def guide_page_path_with_query(slug, query)
    return guide_page_path(slug) if query.blank?

    guide_page_path(slug, q: query)
  end

  def guides_breadcrumb_items(guide, sections)
    items = [ [ "Guides", guides_path ] ]

    section = sections.to_a.find { |entry| entry.slug == guide.section_slug }
    if section.present?
      section_landing_guide = section.documents.first

      if section_landing_guide.present? && section_landing_guide.slug != guide.slug
        items << [ section.title, guide_page_path(section_landing_guide.slug) ]
      else
        items << [ section.title, nil ]
      end
    end

    items << [ guide.title, nil ]
    items
  end

  def previous_guide(guides, guide)
    index = guides.index(guide)
    return if index.nil? || index.zero?

    guides[index - 1]
  end

  def next_guide(guides, guide)
    index = guides.index(guide)
    return if index.nil? || index >= guides.length - 1

    guides[index + 1]
  end

  def guides_last_updated_label(timestamp)
    return if timestamp.blank?

    timestamp.to_date.strftime("%b %-d, %Y")
  end

  def guides_search_highlight(text, query)
    terms = query.to_s.scan(/[[:alnum:]]+/).uniq
    return text if terms.blank?

    highlight(
      text,
      terms,
      highlighter: '<mark class="rounded bg-amber-200 px-0.5 text-amber-900">\1</mark>'
    )
  end
end
