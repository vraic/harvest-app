class UserMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.two_factor_code.subject
  #
  def two_factor_code(user)
    @user = user
    @token = user.email_otp_token
    mail to: user.email_address, subject: "Your 2FA Verification Code"
  end

  def account_invitation(user, account)
    @user = user
    @account = account
    mail to: user.email_address, subject: "You've been invited to #{@account.name} on Harvest"
  end
end
