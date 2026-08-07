class User < ApplicationRecord
  has_referrals
  include Anony::Anonymisable
  acts_as_paranoid

  has_prefix_id :user
  has_secure_password

  encrypts :name, :email_address, deterministic: true
  encrypts :otp_secret
  encrypts :email_otp_token

  has_many :sessions, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users
  has_many :customers, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :tasks, foreign_key: :responsible_user_id, dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assigned_by_id, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :notes, dependent: :destroy
  has_many :support_requests, foreign_key: "requester_id", dependent: :destroy

  anonymise do
    overwrite do
      ignore :admin
      email :email_address
      hex :name
      with_strategy("ANONYMISED", :password_digest)
      ignore :otp_secret, :email_otp_token, :email_otp_sent_at, :otp_required_for_login, :prefers_email_login, :security_choice_made, :onboarded
    end
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }
  validates :name, presence: true
  validate :password_strength, if: -> { password.present? }

  before_destroy :check_admin_flag

  after_save :sync_email_to_customers, if: :saved_change_to_email_address?
  after_create :link_existing_customers

  def otp_enabled?
    otp_secret.present? && otp_required_for_login?
  end

  def generate_otp_secret!
    self.otp_secret = ROTP::Base32.random_base32
    save!(validate: false)
  end

  def otp_qr_code
    return if otp_secret.blank?
    issuer = "Vraic OS"
    label = "#{issuer}:#{email_address}"
    totp = ROTP::TOTP.new(otp_secret, issuer: issuer)
    url = totp.provisioning_uri(label)
    RQRCode::QRCode.new(url)
  end

  def validate_otp(code)
    return false if otp_secret.blank?
    totp = ROTP::TOTP.new(otp_secret.strip)
    totp.verify(code.to_s.strip, drift_behind: 60, drift_ahead: 60)
  end

  def generate_email_otp!
    numbers = Array.new(3) { rand(0..9) }.join
    letters = Array.new(3) { ("A".."Z").to_a.sample }.join
    token = "#{numbers}#{letters}"
    self.email_otp_token = token
    self.email_otp_sent_at = Time.current
    save!(validate: false)
    UserMailer.two_factor_code(self, token).deliver_later
  end

  def validate_email_otp(code)
    return false if email_otp_token.blank? || email_otp_sent_at < 15.minutes.ago
    email_otp_token == code.to_s.strip.upcase
  end

  def clear_email_otp!
    self.email_otp_token = nil
    self.email_otp_sent_at = nil
    save!(validate: false)
  end

  def email_login_only?
    prefers_email_login?
  end

  private

  def password_strength
    score = Zxcvbn.test(password, [ email_address, name ].compact).score
    return if score >= 3

    errors.add(:password, "is too weak. Please use a longer password with mixed characters.")
  end

  def sync_email_to_customers
    Customer.unscoped.where(user_id: id).each { |c| c.update(email_address: email_address) }
    Supplier.unscoped.where(user_id: id).each { |s| s.update(email_address: email_address) }
  end

  def link_existing_customers
    ActsAsTenant.without_tenant do
      Customer.unscoped.where(email_address: email_address, user_id: nil).each do |customer|
        customer.update(user: self)
      end
      Supplier.unscoped.where(email_address: email_address, user_id: nil).each do |supplier|
        supplier.update(user: self)
      end
    end
  end

  def check_admin_flag
    throw :abort if admin?
    errors.add(:base, "Cannot delete admin users.")
  end
end
