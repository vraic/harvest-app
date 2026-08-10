# Below are the routes for madmin
namespace :madmin do
  namespace :noticed do
    resources :events
  end
  namespace :ahoy do
    resources :events
  end
  namespace :ahoy do
    resources :messages
  end
  namespace :ahoy do
    resources :visits
  end
  resources :support_request_comments
  resources :tasks
  resources :supplier_requests
  resources :support_requests
  resources :supplier_prices
  resources :suppliers
  resources :order_items
  resources :payments
  resources :orders
  resources :newsletters
  resources :notes
  resources :sessions
  resources :users
  namespace :audits1984 do
    resources :audits
  end
  resources :loyalty_transactions
  namespace :console1984 do
    resources :commands
  end
  namespace :console1984 do
    resources :sensitive_accesses
  end
  resources :loyalty_cards
  namespace :console1984 do
    resources :sessions
  end
  resources :loyalty_programs
  resources :inventory_levels
  namespace :console1984 do
    resources :users
  end
  resources :locations
  resources :inventory_group_customers
  resources :inventory_group_suppliers
  resources :inventory_items
  resources :inventory_groups
  namespace :active_storage do
    resources :attachments
  end
  resources :application_notifiers
  resources :data_subject_requests
  namespace :application_notifier do
    resources :notifications
  end
  resources :customer_order_notifiers
  namespace :customer_order_notifier do
    resources :notifications
  end
  resources :task_assigned_notifiers
  namespace :task_assigned_notifier do
    resources :notifications
  end
  namespace :active_storage do
    resources :blobs
  end
  namespace :refer do
    resources :referrals
  end
  namespace :refer do
    resources :referral_codes
  end
  namespace :refer do
    resources :visits
  end
  namespace :active_storage do
    resources :variant_records
  end
  namespace :audited do
    resources :audits
  end
  namespace :action_text do
    resources :rich_texts
  end
  namespace :noticed do
    resources :notifications
  end
  namespace :action_text do
    resources :encrypted_rich_texts
  end
  resources :accounts
  resources :customers
  resources :account_users
  resources :data_retention_events
  root to: "dashboard#show"
end
