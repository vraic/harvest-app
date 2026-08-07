require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  setup do
    Capybara.default_max_wait_time = 10
    resize_to_desktop
  end

  def login_as(user)
    Capybara.reset_sessions!
    # Use the fast-path login for system tests to avoid flaky 2FA UI interactions
    visit test_login_path(user_id: user.id)

    # Wait for the page to load - customers are redirected to shop, staff to dashboard
    assert_selector "nav", visible: :any, wait: 10
  end

  def login_via_ui(user)
    Capybara.reset_sessions!
    visit new_session_url
    fill_in "Email", with: user.email_address

    if page.has_button?("Sign in with password")
      click_button "Sign in with password"
    end

    # We use a broader search and wait for the field to become interactable
    find("input[name='password']", visible: :all).set("password")
    click_button "Continue"

    # We expect 2FA after signing in if enabled
    if page.has_css?("h2", text: "Two-Factor Verification", wait: 10)
      code = if user.otp_enabled?
        ROTP::TOTP.new(user.otp_secret).now
      else
        # For email OTP, we need to fetch it from the database
        token = nil
        50.times do
          token = User.uncached { User.find(user.id).email_otp_token }
          break if token.present?
          sleep 0.2
        end
        token
      end
      fill_in "Verification Code", with: code
      click_on "Verify"
    end

    assert_selector "nav", wait: 10
  end

  def select_account(name)
    # Use the Accounts page for admins to Join
    if page.has_link?("Administration")
      visit accounts_path
      row = find("tr", text: name)
      if row.has_button?("Join Account")
        within row do
          click_on "Join Account"
        end
        # Joining redirects to dashboard
      elsif row.has_button?("Leave Account")
        # Already joined
        visit dashboard_path
      end
    else
      visit dashboard_path
      # Find the account section and click Select
      # Use a more specific selector to avoid ambiguous matches
      # Search in stores-grid and business-stores (if it still exists)
      selected = false
      [ "#stores-grid", "#business-stores" ].each do |section|
        next unless page.has_css?(section)
        within section do
          if page.has_text?(name)
            # Find the card containing the name
            # We look for h3 with the name
            card = find("h3", text: name).find(:xpath, "ancestor::div[contains(@class, 'flex-col')]")
            within card do
              if page.has_text?("Active")
                selected = true
                break
              elsif page.has_button?("Select")
                click_on "Select"
                selected = true
                break
              elsif page.has_button?("Visit Shop")
                click_on "Visit Shop"
                selected = true
                break
              elsif page.has_button?("Manage Store")
                click_on "Manage Store"
                selected = true
                break
              end
            end
          end
        end
        break if selected
      end
    end

    assert_text name
    # Verify banner if it's an admin
    if page.has_link?("Administration")
      assert_selector "div", text: "Managing Account: #{name}"
    end
  end

  def logout
    # The Logout button is now inside a Stimulus dropdown at the bottom of the sidebar
    # We need to open it first.
    # Try desktop first
    if page.has_css?("#user-menu-button-desktop", visible: true, wait: 2)
      button = find("#user-menu-button-desktop")
      button.click
      assert_selector "[data-dropdown-target='menu']", visible: true, wait: 5
    elsif page.has_css?("#user-menu-button-mobile", visible: true, wait: 2)
      button = find("#user-menu-button-mobile")
      button.click
      assert_selector "[data-dropdown-target='menu']", visible: true, wait: 5
    elsif page.has_button?("Open sidebar")
      click_on "Open sidebar"
      if page.has_css?("#user-menu-button-mobile", visible: true, wait: 5)
        button = find("#user-menu-button-mobile")
        button.click
        assert_selector "[data-dropdown-target='menu']", visible: true, wait: 5
      end
    end

    # There are multiple Logout buttons (mobile and desktop dropdowns)
    # They should be visible now.
    # We use match: :first because there might be one for mobile and one for desktop in the DOM
    begin
      click_retries ||= 0
      find("button, input[type='submit']", text: "Logout", visible: true, wait: 10, match: :first).click
    rescue Selenium::WebDriver::Error::StaleElementReferenceError, Selenium::WebDriver::Error::UnknownError
      retry if (click_retries += 1) < 3
    end

    # Verify we are logged out
    begin
      logout_retries ||= 0
      assert_text "Sign in", wait: 10
    rescue Selenium::WebDriver::Error::StaleElementReferenceError, Selenium::WebDriver::Error::UnknownError
      retry if (logout_retries += 1) < 3
    end
  end

  def grant_support_access(account, user = nil)
    user ||= users(:administrator)
    SupportRequest.create!(
      account: account,
      requester: user,
      status: :accepted,
      expires_at: 72.hours.from_now,
      message: "Test authorization"
    )
  end

  def resize_to_mobile
    page.current_window.resize_to(375, 812)
  end

  def resize_to_desktop
    page.current_window.resize_to(1400, 1400)
  end
end
