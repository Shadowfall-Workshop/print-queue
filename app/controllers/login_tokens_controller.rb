class LoginTokensController < ApplicationController
  before_action :authenticate_user!, only: [:new, :check_status]
  skip_before_action :authenticate_user!, only: [:consume]

  def new
    # Delete old tokens
    current_user.login_tokens.delete_all

    # Create a new token
    @login_token = current_user.login_tokens.create!(purpose: "login")
    @login_url = consume_login_token_url(@login_token.token)

    require 'rqrcode'
    @qr_code = RQRCode::QRCode.new(@login_url)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def consume
    token = LoginToken.active.find_by(token: params[:token])

    if token
      user = token.user
      token.destroy!
      sign_in(user)
      redirect_to root_path, notice: "Logged in successfully!"
    else
      redirect_to new_user_session_path, alert: "Invalid or expired login link."
    end
  end

  # GET /login_token/check_status/:id
  def check_status
    token = current_user.login_tokens.find_by(id: params[:id])

    if token.nil?
      render json: { consumed: true }
    else
      render json: { consumed: false }
    end
  end
end
