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
    # Refresh token if expired
    token = access_token

    uri = URI("#{API_BASE_URL}/users/#{@user_id}/shops")

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@access_token}"
    req["x-api-key"] = ENV["ETSY_API_KEYSTRING"]

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    json = JSON.parse(res.body)
    Rails.logger.debug "[Etsy OAuth] full shop info response: #{json.inspect}"

    if json["shop_id"]
      json
    else
      Rails.logger.warn "[Etsy OAuth] Unexpected shop info format: #{json.inspect}"
      nil
    end
  rescue => e
    Rails.logger.error "[Etsy OAuth] Failed to fetch shop info: #{e.class} - #{e.message}"
    nil
  end

  # Fetch receipts (orders) from Etsy
  def fetch_receipts
    return unless @external_account&.access_token && @external_account&.external_shop_id

    # Refresh token if expired
    token = access_token

  # Create the API URL
  min_created = (Time.now - 48.hours).to_i
  max_created = (Time.now - 5.minutes).to_i

  uri = URI("#{API_BASE_URL}/shops/#{@external_account.external_shop_id}/receipts?min_created=#{min_created}&max_created=#{max_created}")

    # Make the request
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@external_account.access_token}"
    req["x-api-key"] = ENV["ETSY_API_KEYSTRING"]

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    json = JSON.parse(res.body)
    Rails.logger.debug "[EtsyService] Receipts response: #{json.inspect}"

    json
  rescue => e
    Rails.logger.error "[EtsyService] fetch_receipts error: #{e.class} - #{e.message}"
    nil
  end

  def sync_orders_to_queue_items(user_id)
    receipts = fetch_receipts["results"]
    return unless receipts

    receipts.each do |receipt|
      receipt["transactions"].each do |txn|
        next if txn["is_digital"] == true  # Skip digital items
        create_or_update_queue_item(user_id, receipt, txn)
      end
    end
  end

  private

  def create_or_update_queue_item(user_id, receipt, txn)
    reference_id = "Etsy Order: #{receipt['receipt_id']}"

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
      queue_item.due_date = Time.at(txn["expected_ship_date"])
      queue_item.user_id = user_id
      queue_item.order_id = receipt["receipt_id"]
      queue_item.order_item_id = txn["transaction_id"]
      queue_item.quantity = txn["quantity"] || 1
      queue_item.variations = variations

      buyer_note = receipt["message_from_buyer"].to_s.strip
      seller_note = receipt["message_from_seller"].to_s.strip
      notes_parts = []
      notes_parts << "**Buyer Note:**\n#{buyer_note}" unless buyer_note.empty?
      # notes_parts << "**Seller Note:**\n#{seller_note}" unless seller_note.empty?
      queue_item.notes = notes_parts.join("\n\n")

      queue_item.save!
    end
  end
end
