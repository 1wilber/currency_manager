class SessionsController < ApplicationController
  layout "authentication"
  skip_before_action :authenticate_admin_user, only: %i[ new create ]
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: t(:try_again_later) }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: t("sessions.invalid_email_or_password")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
