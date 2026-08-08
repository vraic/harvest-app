namespace :users do
  desc "Create or update the initial super user and require password reset on first login"
  task seed_super_user: :environment do
    email_address = ENV["EMAIL_ADDRESS"].to_s.strip.downcase
    password = ENV["PASSWORD"].to_s
    name = ENV["NAME"].to_s.strip

    abort "EMAIL_ADDRESS is required." if email_address.blank?
    abort "PASSWORD is required." if password.blank?

    name = "Super User" if name.blank?

    user = User.find_or_initialize_by(email_address: email_address)
    action = user.new_record? ? "Created" : "Updated"

    user.name = name
    user.password = password
    user.password_confirmation = password
    user.admin = true
    user.force_password_reset = true

    user.save!

    puts "#{action} super user #{user.email_address}. Password reset is required at first login."
  rescue ActiveRecord::RecordInvalid => e
    abort "Unable to seed super user: #{e.record.errors.full_messages.to_sentence}"
  end
end
