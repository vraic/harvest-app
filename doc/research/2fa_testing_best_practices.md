### 2FA/TOTP Testing Best Practices in Ruby on Rails

Researching high-quality implementations (Basecamp, 37signals, Rails 8) reveals several first principles for building robust, non-flaky 2FA tests.

#### 1. Deterministic Time
TOTP (Time-based One-Time Password) relies on 30-second windows. Flakiness in CI often appears when browser/system timing and server timing are coupled inside end-to-end Selenium flows.

- **Best Practice:** Keep TOTP validity assertions in integration/controller tests where request timing is deterministic.
- **System Test Scope:** In Selenium system tests, verify user navigation and form behavior, not strict TOTP acceptance.
- **When Needed:** If you must freeze time, use `travel_to` in model/integration/controllers where both generation and verification happen in the same request flow.

#### 2. Realistic Integration (Avoid Mocks)
Following the Basecamp philosophy, avoid mocking the TOTP verification logic itself. Mocks can hide bugs where the secret is stored incorrectly (e.g., missing padding or leading/trailing whitespace).

- **Best Practice:** Use the real `ROTP` library in tests to generate codes from the user's actual `otp_secret`.
- **Verification:** Ensure `otp_secret` is correctly stripped of whitespace, as `ROTP` is sensitive to it.
- **Alphanumeric Tokens:** For email-based OTP, verify that the test handles mixed-case or alphanumeric tokens correctly, mirroring the real user experience.

#### 3. System Test Synchronization
System tests fail when they interact with elements before the page is fully interactive.

- **Best Practices:**
  - **Wait for Elements:** Use `assert_selector` or `assert_field` with explicit `wait` times to ensure the page has transitioned.
  - **Actionable Elements:** Prefer `fill_in` and `click_button` over generic `find().set()` or `find().click` to benefit from Capybara's built-in waiting and visibility checks.
  - **Robust Input Verification:** Assert field presence/value immediately after `fill_in` for important auth inputs.
  - **Assertion Choice:** Prefer durable UI state (e.g., being on the verification screen, presence of expected form controls) over ephemeral flash timing when testing phase transitions.

#### 4. Clean State & Flow Control
2FA is often part of a multi-step onboarding or security setup flow. Tests should explicitly control these flags to avoid "interruption redirects."

- **Best Practice:** In the `setup` block, explicitly set flags like `onboarded: true` and `security_choice_made: true` unless the test specifically targets those flows.

#### 5. Turbo-Aware Redirections
Modern Rails apps using Turbo expect `303 See Other` for redirects after POST requests.

- **Best Practice:** Ensure all authentication controllers use `status: :see_other` for redirects to prevent Turbo from misinterpreting the response.

#### 6. Failure Isolation
Large, monolithic "happy path" tests are hard to debug when they fail in CI.

- **Best Practice:** Split the authentication flow into discrete units:
  1. Phase 1: Valid credentials -> Redirected to 2FA prompt.
  2. Phase 2 UI: Verification form accepts expected code format.
  3. Phase 2 validity: Controller/integration test posts valid OTP and asserts signed-in redirect/session.
  4. Phase 2 invalid: Controller/integration test posts invalid OTP and asserts rejection.
