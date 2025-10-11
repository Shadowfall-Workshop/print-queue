class PagesController < ApplicationController
  before_action :authenticate_user!

  def integrations
  end
end
