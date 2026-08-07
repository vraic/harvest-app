require "ostruct"

class Cart
  def initialize(session)
    @session = session
    @session[:cart] ||= {}
  end

  def add_item(product_id, quantity = 1)
    @session[:cart][product_id.to_s] ||= 0
    @session[:cart][product_id.to_s] += quantity
  end

  def remove_item(product_id)
    @session[:cart].delete(product_id.to_s)
  end

  def set_quantity(product_id, quantity)
    if quantity.to_i > 0
      @session[:cart][product_id.to_s] = quantity.to_i
    else
      remove_item(product_id)
    end
  end

  def items
    return [] if @session[:cart].empty?

    products = InventoryItem.unscoped.includes(:account).where(id: @session[:cart].keys).index_by(&:id)
    @session[:cart].map do |product_id, quantity|
      product = products[product_id.to_i]
      next if product.nil?

      OpenStruct.new(
        product: product,
        account: product.account,
        quantity: quantity,
        total_price: product.price * quantity
      )
    end.compact
  end

  def grouped_items
    items.group_by(&:account)
  end

  def total_price
    items.sum(&:total_price)
  end

  def empty?
    @session[:cart].empty?
  end

  def count
    @session[:cart].values.sum
  end
end
