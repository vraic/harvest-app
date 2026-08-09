require "rdoc"
require "rdoc/markdown"
require "rdoc/markup/to_html"
require "nokogiri"
require "uri"

module Guides
  class MarkdownRenderer
    ALLOWED_TAGS = %w[
      a blockquote br code em h1 h2 h3 h4 h5 h6 hr li ol p pre strong table tbody td th thead tr ul
    ].freeze
    ALLOWED_ATTRIBUTES = %w[href title id].freeze

    class << self
      def render(markdown)
        html = RDoc::Markup::ToHtml.new.convert(RDoc::Markdown.new.parse(markdown.to_s))

        sanitized_html = ApplicationController.helpers.sanitize(
          html,
          tags: ALLOWED_TAGS,
          attributes: ALLOWED_ATTRIBUTES
        )

        add_external_link_targets(sanitized_html)
      rescue StandardError
        ApplicationController.helpers.simple_format(ERB::Util.html_escape(markdown.to_s))
      end

      private

      def add_external_link_targets(html)
        fragment = Nokogiri::HTML::DocumentFragment.parse(html)

        remove_self_referential_heading_links(fragment)

        fragment.css("a[href]").each do |link|
          href = link["href"].to_s
          next unless external_link?(href)

          link["target"] = "_blank"
          link["rel"] = "noopener noreferrer"
        end

        fragment.to_html
      end

      def remove_self_referential_heading_links(fragment)
        fragment.css("h1[id], h2[id], h3[id], h4[id], h5[id], h6[id]").each do |heading|
          heading_id = heading["id"].to_s
          next if heading_id.blank?

          heading.css("a[href]").each do |link|
            next unless link["href"].to_s == "##{heading_id}"

            link.replace(link.text)
          end
        end
      end

      def external_link?(href)
        uri = URI.parse(href)
        uri.is_a?(URI::HTTP) && uri.host.present?
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
