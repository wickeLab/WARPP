class ApplicationController < ActionController::Base
  add_flash_types :info, :danger, :warning, :success, :notice, :error

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[user_name email])
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[login password])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[user_name email])
  end
end
