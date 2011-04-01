class WelcomesController < ApplicationController
  def show
    render :text => "Welcome to my awesome site. Be nice!"
  end
end
