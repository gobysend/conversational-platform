class Platform::Api::V1::UsersController < PlatformController
  # ref: https://stackoverflow.com/a/45190318/939299
  # set resource is called for other actions already in platform controller
  # we want to add login to that chain as well
  before_action(only: [:login]) { set_resource }
  before_action(only: [:login]) { validate_platform_app_permissible }

  def create
    @resource = (User.find_by(email: user_params[:email]) || User.new(user_params))
    # Disable confirmation email
    @resource.skip_confirmation_notification!
    @resource.save!
    @resource.confirm
    @platform_app.platform_app_permissibles.find_or_create_by(permissible: @resource)
  end

  def login
    url = "#{ENV['FRONTEND_URL']}/app/login?email=#{@resource.email}&sso_auth_token=#{@resource.generate_sso_auth_token}"
    url += "&account_id=#{params[:account_id]}" if params[:account_id].present?

    render json: { url: url }
  end

  def show; end

  def update
    @resource.assign_attributes(user_update_params)
    @resource.save!
  end

  def destroy
    DeleteObjectJob.perform_later(@resource)
    head :ok
  end

  private

  def user_custom_attributes
    return @resource.custom_attributes.merge(user_params[:custom_attributes]) if user_params[:custom_attributes]

    @resource.custom_attributes
  end

  def user_update_params
    # we want the merged custom attributes not the original one
    user_params.except(:custom_attributes).merge({ custom_attributes: user_custom_attributes })
  end

  def set_resource
    @resource = User.find(params[:id])
  end

  def user_params
    params.permit(:name, :email, :password, :allowed_log_in, custom_attributes: {})
  end
end
