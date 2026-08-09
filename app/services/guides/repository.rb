require "yaml"

module Guides
  class Repository
    Document = Data.define(
      :slug,
      :title,
      :description,
      :body_markdown,
      :body_html,
      :search_text,
      :headings,
      :position,
      :updated_at,
      :section_slug,
      :section_title,
      :section_position,
      :summary,
      :keywords,
      :related_slugs
    )
    Section = Data.define(:slug, :title, :position, :summary, :documents)
    SearchResult = Data.define(:document, :excerpt, :score)

    class << self
      attr_writer :docs_root

      def docs_root
        @docs_root ||= Rails.root.join("doc/guides")
      end
    end

    def initialize(root: self.class.docs_root)
      @root = Pathname(root)
    end

    def all
      @all ||= load_documents
    end

    def sections
      @sections ||= all
        .group_by(&:section_slug)
        .map do |section_slug, documents|
          sorted_documents = documents.sort_by { |document| [ document.position, document.title ] }
          section_reference = sorted_documents.first

          Section.new(
            slug: section_slug,
            title: section_reference.section_title,
            position: section_reference.section_position,
            summary: section_reference.summary,
            documents: sorted_documents
          )
        end
        .sort_by { |section| [ section.position, section.title ] }
    end

    def find(slug)
      normalized_slug = normalize_slug(slug)
      all.find { |document| document.slug == normalized_slug }
    end

    def related_documents(document)
      return [] if document.blank?

      document.related_slugs.filter_map { |slug| find(slug) }
        .reject { |related_document| related_document.slug == document.slug }
        .uniq
    end

    def search(query)
      terms = normalize_terms(query)
      return [] if terms.empty?

      all.filter_map do |document|
        search_scope = [
          document.title,
          document.description,
          document.section_title,
          document.summary,
          document.keywords.join(" "),
          document.search_text
        ].join(" ").downcase
        next unless terms.all? { |term| search_scope.include?(term) }

        SearchResult.new(
          document:,
          excerpt: excerpt_for(document.search_text, terms),
          score: score_for(document, terms)
        )
      end.sort_by { |result| [ -result.score, result.document.position, result.document.title ] }
    end

    private

      attr_reader :root

      def load_documents
        return [] unless root.directory?

        root.glob("**/*.md").sort
          .filter_map { |path| build_document(path) }
          .sort_by { |document| [ document.section_position, document.position, document.title ] }
      end

      def build_document(path)
        relative_path = path.relative_path_from(root).to_s
        content = path.read
        metadata, markdown = split_front_matter(content)
        slug = slug_from_path(relative_path)
        body_html = Guides::MarkdownRenderer.render(markdown)
        search_text = ActionView::Base.full_sanitizer.sanitize(body_html).squish

        title = metadata["title"].presence || first_markdown_heading(markdown) || default_title_from_path(relative_path)
        description = metadata["description"].presence
        summary = metadata["summary"].to_s.squish.presence

        position = metadata.fetch("position", inferred_position(relative_path)).to_i
        section_slug, section_title, section_position = section_metadata(relative_path, metadata)
        keywords = normalize_keywords(metadata["keywords"])
        related_slugs = normalize_related_slugs(metadata["related"])

        Document.new(
          slug:,
          title:,
          description:,
          body_markdown: markdown,
          body_html:,
          search_text:,
          headings: headings_from_html(body_html),
          position:,
          updated_at: path.mtime,
          section_slug:,
          section_title:,
          section_position:,
          summary:,
          keywords:,
          related_slugs:
        )
      rescue StandardError
        nil
      end

      def section_metadata(relative_path, metadata)
        path_segments = Pathname(relative_path).each_filename.to_a
        section_segment = path_segments.first.to_s
        section_position = section_segment[/\A(\d+)/, 1].presence&.to_i || 9_999

        metadata_section_title = metadata["section"].to_s.squish.presence
        inferred_section_title = default_title_from_segment(section_segment)
        section_title = metadata_section_title || inferred_section_title
        section_slug = section_title.parameterize

        [ section_slug, section_title, section_position ]
      end

      def default_title_from_segment(segment)
        segment.to_s
          .delete_suffix(".md")
          .sub(/\A\d+[\-_\s]+/, "")
          .tr("-_", " ")
          .squish
          .titleize
      end

      def normalize_keywords(raw_keywords)
        Array(raw_keywords)
          .flat_map { |value| value.to_s.split(",") }
          .map { |keyword| keyword.to_s.strip.downcase }
          .reject(&:blank?)
          .uniq
      end

      def normalize_related_slugs(raw_related)
        Array(raw_related)
          .flat_map { |value| value.to_s.split(",") }
          .map { |value| normalize_slug(value.to_s.sub(%r{\A/?(?:docs|guides)/}, "")) }
          .reject(&:blank?)
          .uniq
      end

      def split_front_matter(content)
        match = content.match(/\A---\s*\n(?<front_matter>.*?)\n---\s*\n(?<body>.*)\z/m)
        return [ {}, content ] if match.blank?

        metadata = YAML.safe_load(match[:front_matter], aliases: false) || {}
        [ metadata.is_a?(Hash) ? metadata : {}, match[:body].to_s ]
      end

      def slug_from_path(relative_path)
        pathname = Pathname(relative_path)
        segments = pathname.each_filename.map do |segment|
          basename = segment.delete_suffix(".md")
          basename.sub(/\A\d+[\-_\s]+/, "").parameterize
        end

        segments.reject(&:blank?).join("/")
      end

      def inferred_position(relative_path)
        basename = File.basename(relative_path, ".md")
        prefix = basename[/\A(\d+)/, 1]
        prefix.present? ? prefix.to_i : 9_999
      end

      def default_title_from_path(relative_path)
        basename = File.basename(relative_path, ".md").sub(/\A\d+[\-_\s]+/, "")
        basename.tr("-_", " ").squish.titleize
      end

      def first_markdown_heading(markdown)
        heading_line = markdown.lines.find { |line| line.match?(/^\s*#\s+\S+/) }
        return if heading_line.blank?

        heading_line.sub(/^\s*#\s+/, "").strip
      end

      def headings_from_html(body_html)
        body_html.to_s.scan(/<(h2|h3)\b[^>]*id=["']([^"']+)["'][^>]*>(.*?)<\/\1>/mi).filter_map do |_tag, id, inner_html|
          title = ActionView::Base.full_sanitizer.sanitize(inner_html).delete("¶↑").squish
          next if title.blank? || id.blank?

          [ title, id ]
        end.uniq.first(12)
      end

      def normalize_slug(slug)
        slug.to_s.split("/").map { |segment| segment.parameterize }.join("/")
      end

      def normalize_terms(query)
        query.to_s.downcase.scan(/[[:alnum:]]+/).uniq
      end

      def excerpt_for(search_text, terms)
        plain_text = search_text.to_s.squish
        return "" if plain_text.blank?

        text_for_match = plain_text.downcase
        first_match_index = terms.filter_map { |term| text_for_match.index(term) }.min
        return plain_text.first(180) if first_match_index.nil?

        start = [ first_match_index - 80, 0 ].max
        chunk = plain_text[start, 200].to_s
        prefix = start.positive? ? "…" : ""
        suffix = start + chunk.length < plain_text.length ? "…" : ""
        "#{prefix}#{chunk.strip}#{suffix}"
      end

      def score_for(document, terms)
        title_scope = document.title.to_s.downcase
        section_scope = document.section_title.to_s.downcase
        keywords_scope = document.keywords.join(" ").downcase
        body_scope = document.search_text.to_s.downcase

        terms.sum do |term|
          score = 0
          score += 8 if title_scope.include?(term)
          score += 5 if section_scope.include?(term)
          score += 4 if keywords_scope.include?(term)
          score += 3 if body_scope.include?(term)
          score
        end
      end
  end
end
