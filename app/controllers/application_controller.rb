class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_admin_user

  def authenticate_admin_user
    redirect_to "/", alert: I18n.t("pundit.not_authorized") unless authenticated? && Current.user.admin?
  end
end
