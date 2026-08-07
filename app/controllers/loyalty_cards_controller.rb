class LoyaltyCardsController < ApplicationController
  before_action :set_loyalty_card, only: %i[ show wallet offline ]
  skip_before_action :set_loyalty_card, only: %i[ index create ]

  def index
    authorize LoyaltyCard
    if staff?
      @loyalty_program = Current.account&.loyalty_program
      @loyalty_cards = policy_scope(LoyaltyCard).includes(:customer).order("customers.name")
      render :staff_index
    else
      @customer = Customer.find_by(user_id: Current.user.id)
      @loyalty_card = @customer&.loyalty_card

      if @loyalty_card
        redirect_to loyalty_card_path(@loyalty_card)
      else
        @loyalty_program = Current.account&.loyalty_program
        render :index
      end
    end
  end

  def show
    authorize @loyalty_card
    @transactions = @loyalty_card.loyalty_transactions.includes(order: { order_items: :inventory_item }).order(created_at: :desc)
  end

  def create
    @loyalty_program = Current.account.loyalty_program
    @customer = Customer.find_by!(user_id: Current.user.id)

    @loyalty_card = LoyaltyCard.new(customer: @customer, loyalty_program: @loyalty_program)
    authorize @loyalty_card

    if @loyalty_card.save
      redirect_to dashboard_path, notice: "You've successfully enrolled in the loyalty program!"
    else
      redirect_to dashboard_path, alert: "Failed to enroll in the loyalty program."
    end
  end

  def wallet
    authorize @loyalty_card

    # Generate a simple Apple Wallet pass (.pkpass)
    # Note: A real production pass would require a certificate and signature.
    # Here we generate the unsigned bundle structure.

    pass_json = {
      formatVersion: 1,
      passTypeIdentifier: "pass.vraic.os.loyalty",
      serialNumber: @loyalty_card.identifier,
      teamIdentifier: "VRAICOS",
      organizationName: Current.account.name,
      description: "#{Current.account.name} Loyalty Card",
      logoText: Current.account.name,
      foregroundColor: "rgb(255, 255, 255)",
      backgroundColor: "rgb(79, 70, 229)",
      storeCard: {
        primaryFields: [
          {
            key: "balance",
            label: "POINTS",
            value: @loyalty_card.points_balance
          }
        ],
        secondaryFields: [
          {
            key: "holder",
            label: "CARD HOLDER",
            value: @loyalty_card.customer.name
          }
        ],
        backFields: [
          {
            key: "terms",
            label: "Terms & Conditions",
            value: "Points can be redeemed against future orders. 1 point = #{view_context.number_to_currency(@loyalty_card.loyalty_program.points_to_currency_ratio)} discount."
          }
        ]
      },
      barcode: {
        message: @loyalty_card.identifier,
        format: "PKBarcodeFormatQR",
        messageEncoding: "iso-8859-1"
      }
    }

    require "zip"

    string_io = Zip::OutputStream.write_buffer do |zio|
      zio.put_next_entry("pass.json")
      zio.write(pass_json.to_json)
      # In a real app, we would add icon.png, logo.png, manifest.json and signature
    end

    send_data string_io.string, filename: "loyalty_card_#{@loyalty_card.identifier}.pkpass", type: "application/vnd.apple.pkpass", disposition: "attachment"
  end

  def offline
    authorize @loyalty_card
    pdf = Prawn::Document.new(page_size: "A6", margin: 20)

    # Card Background
    pdf.fill_color "4F46E5" # Indigo 600
    pdf.fill_rounded_rectangle [ 0, pdf.cursor ], pdf.bounds.width, 150, 20

    pdf.fill_color "FFFFFF"
    pdf.move_down 20
    pdf.text Current.account.name, size: 24, style: :bold, align: :center
    pdf.text "LOYALTY CARD", size: 10, align: :center, character_spacing: 2

    pdf.move_down 30
    pdf.text "Balance: #{@loyalty_card.points_balance} points", size: 18, style: :bold, align: :center
    pdf.text @loyalty_card.customer.name, size: 12, align: :center

    pdf.move_down 40
    pdf.fill_color "000000"
    pdf.text "ID: #{@loyalty_card.identifier}", font: "Courier", align: :center, size: 14

    # Draw QR code manually using rectangles
    pdf.move_down 20
    qrcode = RQRCode::QRCode.new(@loyalty_card.identifier)
    size = 120
    module_size = size.to_f / qrcode.modules.length
    offset_x = (pdf.bounds.width - size) / 2

    qrcode.modules.each_with_index do |row, i|
      row.each_with_index do |col, j|
        if col
          pdf.fill_rectangle [ offset_x + (j * module_size), pdf.cursor - (i * module_size) ], module_size, module_size
        end
      end
    end

    send_data pdf.render, filename: "loyalty_card_#{@loyalty_card.identifier}.pdf", type: "application/pdf", disposition: "inline"
  end

  private

  def set_loyalty_card
    @loyalty_card = LoyaltyCard.find(params[:id])
  end
end
