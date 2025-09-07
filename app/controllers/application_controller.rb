require "ostruct"

class ApplicationController < ActionController::Base
  include Authentication
  helper_method :model_class, :current_exchange_rate

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_admin_user, :set_record

  def authenticate_admin_user
    redirect_to "/", alert: I18n.t("pundit.not_authorized") unless authenticated? && Current.user.admin?
  end

  def set_record
    return unless model_class
    @record = if [ :edit, :update ].include?(action_name.to_sym)
      model_class.find(params[:id])
    else
      model_class.new
    end
  end

  def model_class
    controller_name.singularize.classify.constantize rescue nil
  end

  def current_exchange_rate
    OpenStruct.new(source: "CLP", target: "VES")
  end
end
