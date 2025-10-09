class LoginToken < ApplicationRecord
  belongs_to :user

  before_validation :generate_token, :set_expiration

  validates :token, presence: true, uniqueness: true
  validates :user_id, uniqueness: { message: "already has an active login token" }, if: :active_token_exists?

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  def consume!
    destroy!
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end

  def set_expiration
    self.expires_at ||= 10.minutes.from_now
  end

  def active_token_exists?
    LoginToken.where(user_id: user_id).where("expires_at > ?", Time.current).exists?
  end
end
