require "uri"
require "net/http"
require "json"
require "securerandom"
require "base64"
require "digest"
require "oauth/pkce_helper"

class Oauth::EtsyController < ApplicationController
  before_action :authenticate_user!, except: [:connect]

  # Step 1: Redirect user to Etsy OAuth
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

  # Step 2: Handle Etsy OAuth callback
  def callback
    if params[:state] != session[:etsy_oauth_state]
      flash[:alert] = "Possible CSRF attack detected — state mismatch."
      redirect_to root_path and return
    end

    code = params[:code]
    code_verifier = session[:etsy_code_verifier]

    token_response = exchange_code_for_token(code, code_verifier)

    if token_response["access_token"]
      session.delete(:etsy_code_verifier)
      session.delete(:etsy_oauth_state)

      user_id = token_response["access_token"].split(".").first

      external_account = current_user.external_accounts.find_or_initialize_by(provider: "etsy")
      ExternalAccount.transaction do
        external_account.update!(
          access_token: token_response["access_token"],
          refresh_token: token_response["refresh_token"],
          token_expires_at: Time.current + token_response["expires_in"].to_i.seconds,
          external_user_id: user_id
        )

        # Fetch shop info and save
        shop_info = EtsyService.new(external_account).fetch_shop_info
        if shop_info
          flash[:notice] = "Etsy connected to shop #{external_account.external_shop_name}!"
        else
          flash[:notice] = "Etsy connected, but shop info could not be retrieved."
        end
      end

      Rails.logger.info "[Etsy OAuth] User #{current_user.id} connected shop #{external_account.external_shop_name} (#{external_account.external_shop_id})"
    else
      flash[:alert] = "Etsy OAuth failed: #{token_response}"
    end

    redirect_to root_path
  end

  # Step 3: Disconnect Etsy account
  def disconnect
    external_account = current_user.external_accounts.find_by(provider: "etsy")
    if external_account
      external_account.destroy
      flash[:notice] = "Disconnected Etsy."
    else
      flash[:alert] = "No Etsy account connected."
    end

    redirect_to user_integrations_path
  end

  private

  # Exchange authorization code for access token
  def exchange_code_for_token(code, code_verifier)
    uri = URI("https://api.etsy.com/v3/public/oauth/token")
    res = Net::HTTP.post_form(uri, {
      grant_type: "authorization_code",
      client_id: ENV["ETSY_API_KEYSTRING"],
      redirect_uri: oauth_etsy_callback_url,
      code: code,
      code_verifier: code_verifier
    })
    JSON.parse(res.body)
  rescue => e
    Rails.logger.error "[Etsy OAuth] Token exchange failed: #{e.class} - #{e.message}"
    {}
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to user_integrations_path, alert: "You need to sign in before continuing."
    end
  end
end
