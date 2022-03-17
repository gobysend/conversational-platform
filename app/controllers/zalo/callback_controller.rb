class Zalo::CallbackController < ApplicationController
  include Zalo::Profile

  before_action :check_signature, only: [:create]

  def create
    allowed_events = %w[user_send_text user_send_image user_send_link user_send_audio user_send_video user_send_sticker
                        user_send_location user_send_business_card user_send_file user_submit_info user_received_message
                        user_seen_message user_asking_product oa_send_text oa_send_image oa_send_gif
                        oa_send_list oa_send_file follow]

    # Special process for following event
    if params[:event_name].to_s == 'follow'
      update_follower_info(params)
      head :ok and return
    end

    # Accept only event in the allowed_events list
    (head :ok and return) unless allowed_events.include?(params[:event_name].to_s)

    # Build message
    message = JSON.parse(request.raw_post, { symbolize_names: true })

    puts "MESSAGE_RECEIVED #{message}"
    response = ::Integrations::Zalo::MessageParser.new(message)

    # If this message was sent from our application, ignore it to prevent duplication of messages
    if response.message_id.present?
      cache_key = "#{Zalo::SendOnZaloService::KEY_PREFIX}_#{response.message_id}"
      cache_value = $alfred.get(cache_key)
      if cache_value.present?
        Rails.logger.debug { "Message #{response.message_id} was sent from our app. Ignore it." }
        $alfred.expire(cache_key, 0)
        head :ok and return
      end
    end

    ::Integrations::Zalo::MessageCreator.new(response).perform

    head :no_content
  end

  private

  def check_signature
    zalo_signature = request.headers['X-ZEvent-Signature']
    (head :ok and return) if zalo_signature.nil?

    signature = "mac=#{Digest::SHA2.new(256).hexdigest((params[:app_id] + request.raw_post + params[:timestamp] + ENV['ZALO_OA_SECRET_KEY']).to_s)}"
    head :ok if signature != zalo_signature
  end

  def update_follower_info(params)
    channel_ids = Channel::Zalo.where(oa_id: params[:oa_id]).pluck(:id)
    return if channel_ids.blank?

    inbox_ids = Inbox.where(channel_api: channel_ids).where(channel_type: 'Channel::Zalo').pluck(:id)
    return if inbox_ids.blank?

    source_id = params[:follower][:id]
    contact_ids = ContactInbox.where(inbox_id: inbox_ids).where(source_id: source_id).pluck(:contact_id).uniq
    return if contact_ids.blank?

    contacts = Contact.where(id: contact_ids)
    return if contacts.blank?

    # Fetch profile
    channel = Channel::Zalo.where(oa_id: params[:oa_id]).order(expires_at: :desc).first
    return if channel.nil?

    profile = zalo_profile(source_id, channel.access_token)
    return if profile.blank?

    ActiveRecord::Base.transaction do
      contacts.each do |contact|
        contact.name = profile[:display_name] || nil
        contact.remote_avatar_url = (profile[:avatars].present? ? profile[:avatars][:'240'] : nil)

        contact.custom_attributes = {} if contact.custom_attributes.nil?
        contact.custom_attributes.gender = (profile[:user_gender].present? && profile[:user_gender].zero?) ? 'Nữ' : 'Nam'

        contact.save
      end
    end
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
