class ExternalAccount < ApplicationRecord
  belongs_to :user
  has_many :sync_logs, dependent: :nullify
  attribute :ignored_skus, :jsonb, default: []
  attribute :due_date_adjustment, :integer, default: 0

  validates :provider, presence: true

  def refresh_if_needed!
    return if provider != "etsy"
    return if token_expires_at.nil? || token_expires_at > 5.minutes.from_now

    uri = URI("https://api.etsy.com/v3/public/oauth/token")
    res = Net::HTTP.post_form(uri, {
      grant_type: "refresh_token",
      client_id: ENV["ETSY_API_KEYSTRING"],
      refresh_token: refresh_token
    })

    response = JSON.parse(res.body)
    if response["access_token"]
      update!(
        access_token: response["access_token"],
        refresh_token: response["refresh_token"],
        token_expires_at: Time.current + response["expires_in"].to_i.seconds
      )
    else
      Rails.logger.error("[Etsy OAuth] Token refresh failed: #{response}")
      raise "Failed to refresh Etsy token: #{response["error_description"] || 'unknown error'}"
    end
  end

  def ignored_skus_text
    (ignored_skus || []).join("\n")
  end

  def ignored_skus_text=(value)
    self.ignored_skus = value.to_s.split(/\r?\n/).map(&:strip).reject(&:blank?)
  end
end
