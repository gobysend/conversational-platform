class Zalo::CallbackController < ApplicationController
  before_action :check_signature, only: [:create]

  def create
    allowed_events = %w[user_send_text user_send_image user_send_link user_send_audio user_send_video user_send_sticker
                        user_send_location user_send_business_card user_send_file user_submit_info user_received_message
                        user_seen_message follow unfollow user_asking_product oa_send_text oa_send_image oa_send_gif
                        oa_send_list oa_send_file]

    # Accept only event in the allowed_events list
    head :ok unless allowed_events.include?(params[:event_name])

    # Build message
    message = JSON.parse(request.raw_post, {symbolize_names: true})

    Rails.logger.info "MESSAGE_RECEIVED #{message}"
    response = ::Integrations::Zalo::MessageParser.new(message)
    ::Integrations::Zalo::MessageCreator.new(response).perform

    head :no_content
  end

  private

  def check_signature
    zalo_signature = request.headers['X-ZEvent-Signature']
    head :ok if zalo_signature.nil?

    signature = "mac=#{Digest::SHA2.new(256).hexdigest((params[:app_id] + request.raw_post + params[:timestamp] + ENV['ZALO_OA_SECRET_KEY']).to_s)}"
    head :ok if signature != zalo_signature
  end

  def permitted_params
    params.permit(
      :oa_id,
      :app_id,
      :follower,
      :user_id_by_app,
      :event_name,
      :source,
      :timestamp,
      :sender,
      :recipient,
      :message,
      :product,
      :info
    )
  end
end
