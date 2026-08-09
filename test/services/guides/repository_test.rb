require "test_helper"
require "tmpdir"

module Guides
  class RepositoryTest < ActiveSupport::TestCase
    test "loads markdown documents with front matter" do
      repository = Repository.new

      documents = repository.all

      assert documents.any?

      getting_started = repository.find("getting-started/overview")
      refute_nil getting_started
      assert_equal "Getting started", getting_started.title
      assert_equal "Getting started", getting_started.section_title
      assert_includes getting_started.body_html, "Choose your path"
    end

    test "groups docs by section" do
      repository = Repository.new

      sections = repository.sections

      assert sections.any?
      assert_equal "Getting started", sections.first.title
      assert_includes sections.first.documents.map(&:slug), "getting-started/overview"
    end

    test "resolves related documents from front matter" do
      repository = Repository.new
      document = repository.find("getting-started/self-hosted-with-kamal")

      related_slugs = repository.related_documents(document).map(&:slug)

      assert_includes related_slugs, "getting-started/overview"
      assert_includes related_slugs, "integrations-and-deployment/deploy-with-kamal"
    end

    test "search matches title and content" do
      repository = Repository.new

      results = repository.search("retention")

      assert results.any?
      assert_equal "Data protection and retention", results.first.document.section_title
      assert_includes results.first.excerpt.downcase, "retention"
    end

    test "search matches section keywords" do
      repository = Repository.new

      results = repository.search("two-factor")

      assert results.any?
      assert_equal "Passwords, sessions, and 2FA", results.first.document.title
    end

    test "ignores invalid related slugs safely" do
      Dir.mktmpdir do |dir|
        docs_root = Pathname(dir)
        docs_root.join("01-sample").mkpath

        docs_root.join("01-sample/01-overview.md").write(<<~MARKDOWN)
          ---
          title: Sample Overview
          position: 1
          section: Sample
          related:
            - sample/second
            - missing/slug
          ---

          # Sample Overview
        MARKDOWN

        docs_root.join("01-sample/02-second.md").write(<<~MARKDOWN)
          ---
          title: Sample Second
          position: 2
          section: Sample
          ---

          # Sample Second
        MARKDOWN

        repository = Repository.new(root: docs_root)
        document = repository.find("sample/overview")
        related_slugs = repository.related_documents(document).map(&:slug)

        assert_equal [ "sample/second" ], related_slugs
      end
    end
  end
end
