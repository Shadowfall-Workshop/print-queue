require "uri"
require "net/http"
require "json"
require "securerandom"
require "base64"
require "digest"
require "oauth/pkce_helper"

class Oauth::EtsyController < ApplicationController
  before_action :authenticate_user!, except: [:connect]

  def connect
    code_verifier, code_challenge = Oauth::PkceHelper.generate_code_verifier_and_challenge

    session[:etsy_code_verifier] = code_verifier

    state = SecureRandom.hex(24)
    session[:etsy_oauth_state] = state

    Rails.logger.debug "[Etsy OAuth] connect - code_verifier: #{code_verifier}"
    Rails.logger.debug "[Etsy OAuth] connect - code_challenge: #{code_challenge}"
    Rails.logger.debug "[Etsy OAuth] connect - state: #{state}"
    Rails.logger.debug "[Etsy OAuth] connect - redirect_uri: #{oauth_etsy_callback_url}"

    query = {
      response_type: "code",
      client_id: ENV["ETSY_API_KEYSTRING"],
      redirect_uri: oauth_etsy_callback_url,
      scope: "transactions_r transactions_w",
      state: state,
      code_challenge: code_challenge,
      code_challenge_method: "S256"
    }

    redirect_to "https://www.etsy.com/oauth/connect?#{query.to_query}", allow_other_host: true
  end

  def callback
    Rails.logger.debug "[Etsy OAuth] callback - received params: #{params.to_unsafe_h}"

    if params[:state] != session[:etsy_oauth_state]
      flash[:alert] = "Possible CSRF attack detected — state mismatch."
      Rails.logger.warn "[Etsy OAuth] callback - State mismatch! Expected #{session[:etsy_oauth_state]}, got #{params[:state]}"
      redirect_to root_path and return
    end

    code = params[:code]
    code_verifier = session[:etsy_code_verifier]

    uri = URI("https://api.etsy.com/v3/public/oauth/token")

    res = Net::HTTP.post_form(uri, {
      grant_type: "authorization_code",
      client_id: ENV["ETSY_API_KEYSTRING"],
      redirect_uri: oauth_etsy_callback_url,
      code: code,
      code_verifier: code_verifier
    })

    token_response = JSON.parse(res.body)
    Rails.logger.debug "[Etsy OAuth] callback - token response: #{token_response}"

    if token_response["access_token"]
      session.delete(:etsy_code_verifier)
      session.delete(:etsy_oauth_state)

      access_token = token_response["access_token"]
      user_id = access_token.split(".").first

      external_account = current_user.external_accounts.find_or_initialize_by(provider: "etsy")
      external_account.access_token = access_token
      external_account.refresh_token = token_response["refresh_token"]
      external_account.token_expires_at = Time.current + token_response["expires_in"].to_i.seconds
      external_account.external_user_id = user_id
      external_account.save!

      shop_info = fetch_shop_info(access_token, user_id)

      if shop_info
        external_account.external_shop_id = shop_info["shop_id"].to_s
        external_account.metadata ||= {}
        external_account.metadata["shop_name"] = shop_info["shop_name"]
        external_account.save!
      end
      flash[:notice] = "Etsy connected!"
    else
      flash[:alert] = "Etsy OAuth failed: #{token_response}"
    end

    redirect_to root_path
  end

  def disconnect
    external_account = current_user.external_accounts.find_by(provider: "etsy")
    if external_account
      external_account.destroy
      flash[:notice] = "Disconnected Etsy."
    else
      flash[:alert] = "No Etsy account connected."
    end

    redirect_to edit_user_registration_path
  end

  private

  def authenticate_user!
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "You need to sign in before continuing."
    end
  end

  def fetch_shop_info(access_token, user_id)
    uri = URI("https://openapi.etsy.com/v3/application/users/#{user_id}/shops")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{access_token}"
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
end
