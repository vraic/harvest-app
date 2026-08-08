namespace :users do
  desc "Create or update the initial super user and require password reset on first login"
  task seed_super_user: :environment do
    interactive = $stdin.tty?

    email_address = ENV["SEED_EMAIL_ADDRESS"].to_s.strip.downcase
    if email_address.blank? && interactive
      print "Email address: "
      email_address = $stdin.gets.to_s.strip.downcase
    end

    name = ENV["SEED_NAME"].to_s.strip
    if name.blank? && interactive
      print "Name [Super User]: "
      name_input = $stdin.gets.to_s.strip
      name = name_input if name_input.present?
    end

    password = ENV["SEED_PASSWORD"].to_s
    if password.blank? && interactive
      print "Password: "
      password = if $stdin.respond_to?(:noecho)
        $stdin.noecho(&:gets).to_s.chomp
      else
        $stdin.gets.to_s.chomp
      end
      puts

      print "Confirm password: "
      password_confirmation = if $stdin.respond_to?(:noecho)
        $stdin.noecho(&:gets).to_s.chomp
      else
        $stdin.gets.to_s.chomp
      end
      puts

      abort "Password confirmation does not match." if password != password_confirmation
    end

    abort(interactive ? "Email address is required." : "EMAIL_ADDRESS is required in non-interactive mode.") if email_address.blank?
    abort(interactive ? "Password is required." : "PASSWORD is required in non-interactive mode.") if password.blank?

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
