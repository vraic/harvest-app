require "test_helper"

class GuidesControllerTest < ActionDispatch::IntegrationTest
  test "index is publicly accessible" do
    get guides_path

    assert_response :success
    assert_select "h1", "Guides"
    assert_select "a[href=?]", guide_page_path("getting-started/overview"), minimum: 1
  end

  test "show is publicly accessible" do
    get guide_page_path("getting-started/overview")

    assert_response :success
    assert_select "h1", "Getting started"
    assert_select "article", /Choose your path/
    assert_select "article script", count: 0
  end

  test "show on this page links target section anchors in article" do
    get guide_page_path("getting-started/overview")

    assert_response :success

    guide = Guides::Repository.new.find("getting-started/overview")
    assert guide.present?
    assert guide.headings.any?

    guide.headings.each do |_heading, anchor|
      assert_select "a[href='##{anchor}']", minimum: 1
      assert_select "h1[id='#{anchor}'], h2[id='#{anchor}'], h3[id='#{anchor}']", minimum: 1
      assert_select "h1[id='#{anchor}'] > a[href='##{anchor}'], h2[id='#{anchor}'] > a[href='##{anchor}'], h3[id='#{anchor}'] > a[href='##{anchor}']", count: 0
    end
  end

  test "show opens external article links in a new tab" do
    get guide_page_path("getting-started/local-development")

    assert_response :success
    assert_select "article a[href='https://github.com/vraic/harvest-je'][target='_blank'][rel='noopener noreferrer']", minimum: 1
    assert_select "a[href^='#']:not([target])", minimum: 1
  end

  test "search returns matching docs" do
    get guides_path(q: "retention")

    assert_response :success
    assert_select "h2", "Search results"
    assert_select "a[href=?]", guide_page_path("data-protection-and-retention/overview", q: "retention"), minimum: 1
  end

  test "show renders section breadcrumb and related articles" do
    get guide_page_path("getting-started/self-hosted-with-kamal")

    assert_response :success
    assert_select "nav[aria-label='Breadcrumb']", /Guides/
    assert_select "nav[aria-label='Breadcrumb']", /Getting started/
    assert_select "h2", "Related guides"
    assert_select "a[href=?]", guide_page_path("integrations-and-deployment/deploy-with-kamal"), minimum: 1
  end

  test "legacy docs index redirects to guides" do
    get "/docs"

    assert_redirected_to "/guides"
  end

  test "legacy docs page redirects to guides slug" do
    get "/docs/getting-started/overview"

    assert_redirected_to "/guides/getting-started/overview"
  end

  test "missing doc slug returns not found" do
    get guide_page_path("does-not-exist")

    assert_response :not_found
  end
end
