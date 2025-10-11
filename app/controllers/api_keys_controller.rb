class ApiKeysController < ApplicationController
    before_action :authenticate_user!
    before_action :set_api_key, only: [:create] # Initialize @api_key
  
  
    def new
      @api_key = ApiKey.new
    end
  
    def create
      @api_key = current_user.api_keys.new(api_key_params)
    
      if @api_key.save
        redirect_to user_integrations_path, notice: 'API Key successfully generated.'
      else
        puts @api_key.errors.full_messages # Debugging output
        redirect_to user_integrations_path, alert: 'Error generating API key.'
      end
    end
  
    def destroy
      @api_key = current_user.api_keys.find(params[:id])
      @api_key.destroy
      redirect_to user_integrations_path, notice: 'API key deleted successfully.'
    end
  
    private
  
    def api_key_params
      params.require(:api_key).permit(:description)
    end

    # Initialize the @api_key instance variable for use in the form
    def set_api_key
      @api_key = current_user.api_keys.new
    end
  end
  