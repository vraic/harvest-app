module DataRetention
  class Policy
    attr_reader :account

    def initialize(account)
      @account = account
    end

    def inactivity_retention_years
      account.effective_inactivity_retention_years
    end

    def soft_delete_retention_days
      account.effective_soft_delete_retention_days
    end

    def inactive_customer_action
      account.effective_inactive_customer_retention_action
    end

    def inactive_supplier_action
      account.effective_inactive_supplier_retention_action
    end

    def inactivity_cutoff_time(reference_time: Time.current)
      reference_time - inactivity_retention_years.years
    end

    def soft_delete_cutoff_time(reference_time: Time.current)
      reference_time - soft_delete_retention_days.days
    end
  end
end
