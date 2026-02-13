require "net/http"
require "uri"

class EtsyService
  API_BASE_URL = "https://openapi.etsy.com/v3/application"

  def initialize(external_account)
    @external_account = external_account
    @access_token = external_account.access_token
    @shop_id = external_account.external_shop_id
    @user_id = external_account.external_user_id
  end

  def access_token
    refresh_token_if_expired
    @external_account.access_token
  end

  def refresh_token_if_expired
    return if @external_account.token_expires_at && @external_account.token_expires_at > Time.current

    uri = URI("https://api.etsy.com/v3/public/oauth/token")
    res = Net::HTTP.post_form(uri, {
      grant_type: "refresh_token",
      client_id: ENV["ETSY_API_KEYSTRING"],
      refresh_token: @external_account.refresh_token
    })

    json = JSON.parse(res.body)
    Rails.logger.debug "[EtsyService] Refresh token response: #{json.inspect}"

    if json["access_token"]
      @external_account.update!(
        access_token: json["access_token"],
        refresh_token: json["refresh_token"],
        token_expires_at: Time.current + json["expires_in"].to_i.seconds
      )
      @access_token = json["access_token"]  # Update cached token in the service
    else
      raise "Failed to refresh Etsy token: #{json}"
    end
  end

  # Fetch shop info
  def fetch_shop_info
    token = access_token

    # If we already have a shop ID, fetch it directly
    if @external_account.external_shop_id.present?
      uri = URI("#{API_BASE_URL}/shops/#{@external_account.external_shop_id}")
    else
      # Otherwise, list the shops for the user (should only be 1 for standard accounts)
      uri = URI("#{API_BASE_URL}/users/#{@user_id}/shops")
    end

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@access_token}"
    req["x-api-key"] = "#{ENV["ETSY_API_KEYSTRING"]}:#{ENV["ETSY_API_SECRET"]}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    json = JSON.parse(res.body)
    Rails.logger.debug "[Etsy OAuth] full shop info response: #{json.inspect}"

    # If we queried by user, grab the first shop
    shop = json["results"]&.first || json
    if shop && shop["shop_id"]
      @external_account.update!(
        external_shop_id: shop["shop_id"].to_s,
        external_shop_name: shop["shop_name"]
      )
      Rails.logger.info "[Etsy OAuth] Synced shop: #{shop['shop_name']} (#{shop['shop_id']})"
      shop
    else
      Rails.logger.warn "[Etsy OAuth] Unexpected shop info format: #{json.inspect}"
      nil
    end
  rescue => e
    Rails.logger.error "[Etsy OAuth] Failed to fetch shop info: #{e.class} - #{e.message}"
    nil
  end

  # --------------------------------------------------------------------------------------
  # Fetch receipts (orders) from Etsy
  # https://openapi.etsy.com/v3/application/shops/{shop_id}/receipts
  # --------------------------------------------------------------------------------------
  def fetch_receipts
    return unless @external_account&.access_token && @external_account&.external_shop_id

    # Refresh token if expired
    token = access_token

    # Create the API URL
    min_created = (Time.now - 2.days).to_i
    max_created = (Time.now - 5.minutes).to_i

    uri = URI("#{API_BASE_URL}/shops/#{@external_account.external_shop_id}/receipts?min_created=#{min_created}&max_created=#{max_created}&limit=100")

    # Make the request
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@external_account.access_token}"
    req["x-api-key"] = "#{ENV["ETSY_API_KEYSTRING"]}:#{ENV["ETSY_API_SECRET"]}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    json = JSON.parse(res.body)
    # Log the number of receipts:
    Rails.logger.info "[EtsyService] Fetched #{json['count']} receipts"
    # Log the receipt IDs and their created dates for debugging:
    Rails.logger.info "[EtsyService] Receipt IDs and dates: #{json['results']&.map { |r| { id: r['receipt_id'], date: Time.at(r['created_timestamp']).to_s } }.inspect}"


    json
  rescue => e
    Rails.logger.error "[EtsyService] fetch_receipts error: #{e.class} - #{e.message}"
    nil
  end

  # --------------------------------------------------------------------------------------
  # Fetch Single Receipt (order) from Etsy  
  # https://openapi.etsy.com/v3/application/shops/{shop_id}/receipts/{receipt_id}
  # --------------------------------------------------------------------------------------
  def fetch_receipt(receipt_id)
    return unless @external_account&.access_token && @external_account&.external_shop_id

    # Refresh token if expired
    token = access_token

    # Create the API URL 
    uri = URI("#{API_BASE_URL}/shops/#{@external_account.external_shop_id}/receipts/#{receipt_id}")

    # Make the request
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@external_account.access_token}"
    req["x-api-key"] = "#{ENV["ETSY_API_KEYSTRING"]}:#{ENV["ETSY_API_SECRET"]}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    json = JSON.parse(res.body)
    # Log the receipt:
    Rails.logger.info "[EtsyService #fetch_receipt ID:#{receipt_id}] #{json.inspect}"

    json
  rescue => e
    Rails.logger.error "[EtsyService #fetch_receipt ID:#{receipt_id}] fetch_receipt error: #{e.class} - #{e.message}"
    nil
  end
  
  # --------------------------------------------------------------------------------------
  # Add single order to QueueItems
  # -------------------------------------------------------------------------------------- 
  def sync_order_to_queue_items(user_id, receipt_id)
    receipt = fetch_receipt(receipt_id)
    return unless receipt

    receipt["transactions"].each do |txn|
        next if txn["is_digital"] == true  # Skip digital items
        Rails.logger.debug "[EtsyService] Processing transaction #{txn['transaction_id']} for receipt #{receipt['receipt_id']}"
        create_or_update_queue_item(user_id, receipt, txn)
    end
  end

  # --------------------------------------------------------------------------------------
  # Sync orders to QueueItems
  # -------------------------------------------------------------------------------------- 
  def sync_orders_to_queue_items(user_id)
    receipts = fetch_receipts["results"]
    return unless receipts

    receipts.each do |receipt|
      receipt["transactions"].each do |txn|
        next if txn["is_digital"] == true  # Skip digital items
        Rails.logger.debug "[EtsyService] Processing transaction #{txn['transaction_id']} for receipt #{receipt['receipt_id']}"
        create_or_update_queue_item(user_id, receipt, txn)
      end
    end
  end

  private

  def create_or_update_queue_item(user_id, receipt, txn)
    reference_id = "Etsy Order: #{receipt['receipt_id']}"

    # Skip if this SKU is in the Etsy integration's ignored SKUs
    if txn["sku"].present? && @external_account.ignored_skus&.include?(txn["sku"])
      Rails.logger.info "[EtsyService] Ignoring SKU #{txn['sku']} for user #{user_id}"
      return
    end

    # Use updated_timestamp if it exists, default to current time as fallback
    etsy_updated_at = Time.at(txn["updated_timestamp"].to_i) rescue Time.current

    queue_item = QueueItem.find_or_initialize_by(order_item_id: txn["transaction_id"], user_id: user_id)

    # Only update if this is a new record, or the Etsy data is newer
    if queue_item.new_record? || queue_item.updated_at < etsy_updated_at
      variations = txn["variations"].map do |variation|
        {
          "title" => variation["formatted_name"],
          "value" => variation["formatted_value"]
        }
      end

      queue_item.name = txn["title"]
      queue_item.reference_id = reference_id
      queue_item.status = queue_item.new_record? ? 0 : queue_item.status
      queue_item.priority = nil
      queue_item.due_date = Time.at(txn["expected_ship_date"]) + @external_account.due_date_adjustment.days if txn["expected_ship_date"]
      queue_item.user_id = user_id
      queue_item.order_id = receipt["receipt_id"]
      queue_item.order_item_id = txn["transaction_id"]
      queue_item.quantity = txn["quantity"] || 1
      queue_item.variations = variations
      queue_item.sku = txn["sku"]

      buyer_note = receipt["message_from_buyer"].to_s.strip
      notes_parts = []
      notes_parts << "**Buyer Note:**\n#{buyer_note}" unless buyer_note.empty?
      queue_item.notes = notes_parts.join("\n\n")

      queue_item.save!
    end
  end
end
