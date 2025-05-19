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

    if params[:state] != session[:etsy_oauth_state]
      flash[:alert] = "Possible CSRF attack detected — state mismatch."
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

      service = EtsyService.new(external_account)
      shop_info = service.fetch_shop_info

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
end
