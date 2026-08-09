require "test_helper"

module Guides
  class MarkdownRendererTest < ActiveSupport::TestCase
    test "adds new-tab attributes only for external links" do
      html = MarkdownRenderer.render(
        "[External](https://example.com) [Internal](/guides) [Anchor](#intro)"
      )

      fragment = Nokogiri::HTML::DocumentFragment.parse(html)

      external_link = fragment.at_css("a[href='https://example.com']")
      assert_equal "_blank", external_link["target"]
      assert_equal "noopener noreferrer", external_link["rel"]

      internal_link = fragment.at_css("a[href='/guides']")
      assert_nil internal_link["target"]
      assert_nil internal_link["rel"]

      anchor_link = fragment.at_css("a[href='#intro']")
      assert_nil anchor_link["target"]
      assert_nil anchor_link["rel"]
    end
  end
end