namespace :db do
  desc "Clear the database and re-seed with dev data"
  task reseed: :environment do
    puts "Clearing database..."

    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF;")
    tables = ActiveRecord::Base.connection.tables - [ "schema_migrations", "ar_internal_metadata" ]
    tables.each do |table_name|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}")
    end
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON;")

    puts "Seeding data..."

    # 1. Global Admin Account
    admin = User.create!(
      name: "Global Admin",
      email_address: "admin@example.com",
      password: "ThisIsAVeryLongAndSecurePassword123!",
      admin: true
    )
    puts "Created Global Admin: admin@example.com / ThisIsAVeryLongAndSecurePassword123!"

    # 2. Main Account (Account One)
    account_one = Account.create!(
      name: "Vraic Farms",
      address: "123 Farm Road, Jersey",
      owner_id: admin.id,
      is_b2c: true,
      is_b2b: true
    )

    LoyaltyProgram.create!(
      account: account_one,
      active: true,
      currency_to_points_ratio: 1,
      points_to_currency_ratio: 0.1
    )

    account_one_admin = User.create!(
      name: "Vraic Farms Admin",
      email_address: "account-one@example.com",
      password: "ThisIsAVeryLongAndSecurePassword123!"
    )
    AccountUser.create!(account: account_one, user: account_one_admin, user_role: :store_manager)

    account_one_staff = User.create!(
      name: "John Doe at Vraic Farms",
      email_address: "account-one-staff@example.com",
      password: "ThisIsAVeryLongAndSecurePassword123!"
    )
    AccountUser.create!(account: account_one, user: account_one_staff, user_role: :store_staff)

    account_one_customer = User.create!(
      name: "Jane Customer",
      email_address: "account-one-customer@example.com",
      password: "ThisIsAVeryLongAndSecurePassword123!"
    )
    AccountUser.create!(account: account_one, user: account_one_customer, user_role: :customer)
    puts "Created Vraic Farms with store manager (account-one@example.com), staff (account-one-staff@example.com) and customer (account-one-customer@example.com)"

    # 3. Suppliers
    supplier_names = [ "Paradise Veg", "Jolly Hoggs", "Dark Shrooms", "Coastal Fish" ]
    suppliers = []
    supplier_names.each_with_index do |name, i|
      num = i + 1
      email = "supplier-#{num}@example.com"
      s_acc = Account.create!(
        name: name,
        address: "#{num} Supplier Street, St Helier, Jersey",
        owner_id: admin.id
      )
      s_user = User.create!(
        name: "#{name} Staff",
        email_address: email,
        password: "ThisIsAVeryLongAndSecurePassword123!"
      )
      AccountUser.create!(account: s_acc, user: s_user, user_role: :store_manager)
      suppliers << s_acc
      puts "Created #{name}: #{email}"
    end


    # 5. Establish Relationships via SupplierRequests

    # All 4 named suppliers supply Vraic Farms (Account One)
    # This makes Vraic Farms a customer of these suppliers.
    suppliers.each do |s_acc|
      req = SupplierRequest.create!(sender_account: s_acc, receiver_account: account_one)
      req.approved!
    end

    # Inter-supplier relationships
    # Paradise Veg (suppliers[0]) supplies Jolly Hoggs (suppliers[1])
    # This makes Jolly Hoggs a customer of Paradise Veg
    SupplierRequest.create!(sender_account: suppliers[0], receiver_account: suppliers[1]).approved!

    # Coastal Fish (suppliers[3]) supplies Paradise Veg (suppliers[0])
    # This makes Paradise Veg a customer of Coastal Fish
    SupplierRequest.create!(sender_account: suppliers[3], receiver_account: suppliers[0]).approved!

    puts "Established relationships via Supplier Requests"

    # 6. Inventory and Content for Account One
    ActsAsTenant.with_tenant(account_one) do
      # ... content ...


      group_data = {
        "Meat" => [ "Ribeye Steak", "Chicken Breast", "Pork Chops", "Lamb Leg", "Bacon", "Sirloin", "Duck Breast", "Venison", "Sausages", "Burgers" ],
        "Dairy" => [ "Whole Milk", "Cheddar Cheese", "Butter", "Yogurt", "Cream", "Skimmed Milk", "Brie", "Goats Cheese", "Eggs", "Cottage Cheese" ],
        "Fruit" => [ "Braeburn Apple", "Banana", "Strawberries", "Blueberries", "Pear", "Raspberries", "Oranges", "Plums", "Cherries", "Grapes" ],
        "Vegetables" => [ "Carrots", "Potatoes", "Broccoli", "Spinach", "Onions", "Peas", "Corn", "Peppers", "Cucumber", "Lettuce" ],
        "Bakery" => [ "Sourdough Loaf", "Croissant", "Baguette", "Muffin", "Brownie", "White Loaf", "Bagel", "Scone", "Danish", "Pita" ]
      }

      locations = [
        Location.create!(name: "Farm Shop", collection_point: true),
        Location.create!(name: "Cold Store"),
        Location.create!(name: "Roadside Stall")
      ]
      puts "Created 3 locations in Account 1"

      # Regular individual customers

      regular_customers = [
        Customer.create!(name: FFaker::Name.name, email_address: FFaker::Internet.email),
        Customer.create!(name: FFaker::Name.name, email_address: FFaker::Internet.email),
        Customer.create!(name: "Jane Customer", email_address: "account-one-customer@example.com", user: account_one_customer)
      ]

      # Add more variety of customers
      15.times do
        Customer.create!(
          name: FFaker::Name.name,
          email_address: FFaker::Internet.email,
          phone: FFaker::PhoneNumber.phone_number,
          subscribed_to_newsletter: [ true, false ].sample
        )
      end
      puts "Created #{Customer.count} customers in Account 1"

      group_data.each do |group_name, item_names|
        ig = InventoryGroup.create!(name: group_name)
        item_names.each do |name|
          item = InventoryItem.create!(
            name: name,
            inventory_group: ig,
            price: Money.new(rand(500..3500))
          )

          locations.each do |loc|
            InventoryLevel.create!(
              inventory_item: item,
              location: loc,
              quantity: rand(100..500)
            )
          end
        end
      end
      puts "Created 5 inventory groups with 10 products each, stocked in all 3 locations"

      # Newsletters
      Newsletter.create!(
        subject: "Welcome to Vraic Farms!",
        content: "<h1>Welcome</h1><p>Thanks for joining our newsletter list. We have fresh veg every week!</p>",
        target: :everyone,
        sent_at: 2.days.ago
      )

      Newsletter.create!(
        subject: "Special Offer on Meat",
        content: "<h1>Meat Special</h1><p>Get 20% off all ribeye steaks this weekend.</p>",
        target: :customers,
        sent_at: 1.day.ago
      )

      Newsletter.create!(
        subject: "New Harvest Coming Soon",
        content: "<h1>Upcoming Harvest</h1><p>We are expecting a bumper crop of potatoes next week.</p>",
        target: :everyone,
        # Draft
      )
      puts "Created sample newsletters"

      # Tasks
      Task.create!(
        title: "Check Cold Store temperature",
        description: "Ensure it stays below 4 degrees",
        responsible_user: account_one_admin,
        assigned_by: account_one_admin
      )

      Task.create!(
        title: "Restock Roadside Stall",
        description: "Potatoes and Apples are running low",
        responsible_user: account_one_staff,
        assigned_by: account_one_admin
      )

      Task.create!(
        title: "Order more packaging",
        description: "We are running low on paper bags",
        responsible_user: account_one_staff,
        assigned_by: account_one_admin,
        due_date: 1.day.from_now
      )

      Task.create!(
        title: "Review supplier prices",
        description: "Paradise Veg has updated their wholesale price list",
        responsible_user: account_one_admin,
        assigned_by: account_one_admin,
        due_date: 2.days.from_now
      )

      Task.create!(
        title: "Clean the cold store",
        description: "Deep clean scheduled for Monday morning",
        responsible_user: account_one_staff,
        assigned_by: account_one_admin,
        completed_at: 1.hour.ago
      )
      puts "Created sample tasks"

      # Orders
      Customer.all.each do |customer|
        # 1-3 orders per customer
        rand(1..3).times do
          status = [ :ordered, :awaiting_collection, :complete ].sample
          order = Order.new(
            customer: customer,
            user: account_one_staff,
            status: status,
            notes: "Sample seed order - #{status}",
            location: locations.sample
          )

          InventoryItem.all.sample(rand(1..5)).each do |item|
            order.order_items.build(
              inventory_item: item,
              location: order.location,
              quantity: rand(1..5),
              price: item.price
            )
          end
          order.save!
        end
      end
      puts "Created sample orders for all customers"

      # Custom pricing for suppliers
      Supplier.all.each do |supplier_rec|
        InventoryItem.limit(5).each do |item|
          SupplierPrice.create!(
            supplier: supplier_rec,
            inventory_item: item,
            price: item.price * 0.8
          )
        end
      end
      puts "Added custom supplier pricing for all suppliers"
    end

    # 7. Suppliers' own inventory
    suppliers.each do |s_acc|
      ActsAsTenant.with_tenant(s_acc) do
        s_group = InventoryGroup.create!(name: "#{s_acc.name} Wholesale")
        loc = Location.create!(name: "Main Warehouse", collection_point: true)
        [ "Bulk Item A", "Bulk Item B", "Bulk Item C", "Special Resource" ].each do |name|
          item = InventoryItem.create!(
            name: "#{s_acc.name} #{name}",
            inventory_group: s_group,
            price: Money.new(rand(1000..5000))
          )
          InventoryLevel.create!(inventory_item: item, location: loc, quantity: 500)
        end

        # Grant visibility to all customers (including other accounts/suppliers)
        Customer.all.each do |customer_rec|
          InventoryGroupCustomer.create!(inventory_group: s_group, customer: customer_rec)
        end
        puts "Created #{s_acc.name}'s inventory and shared it with #{Customer.count} customers"
      end
    end

    # 8. Pending Request for realism
    pending_name = "#{FFaker::Company.name} (Pending)"
    pending_acc = Account.create!(name: pending_name, owner_id: admin.id)
    ActsAsTenant.with_tenant(pending_acc) do
      Location.create!(name: "Collection Point", collection_point: true)
    end
    SupplierRequest.create!(sender_account: pending_acc, receiver_account: account_one)
    puts "Added a pending Supplier Request from #{pending_name}"

    puts "Done! Seeded dev environment."
  end
end
