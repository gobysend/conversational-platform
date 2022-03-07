class Zalo::RefreshZaloAccessTokenJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    next_15_minutes = DateTime.now + 15.minutes

    loop do
      # Load list of Zalo OAs that have access_token expired in next 15 minutes
      oa_list = Channel::Zalo.where(expires_at: DateTime.now..next_15_minutes)
      return if oa_list.blank?

      oa_list.each do |zalo_channel|
        Rails.logger.info "Refreshing access token for OA #{zalo_channel.oa_name}"
        refresh_access_token(zalo_channel)
      end
    end
  end

  private

  #
  # Refresh access token for a Zalo OA
  #
  def refresh_access_token(zalo_channel)
    zalo_channel ||= Channel::Zalo.new

    url = 'https://oauth.zaloapp.com/v4/oa/access_token'
    params = {
      refresh_token: zalo_channel.refresh_token,
      app_id: ENV['ZALO_APP_ID'],
      grant_type: 'refresh_token'
    }

    response = RestClient.post(url, params.to_json, { secret_key: ENV['ZALO_APP_SECRET'] })
    response = JSON.parse(response, { symbolize_names: true })
    return if response[:access_token].blank?

    zalo_channel.access_token = response[:access_token]
    zalo_channel.refresh_token = response[:refresh_token]
    zalo_channel.expires_at = DateTime.now + response[:expires_in].seconds
    zalo_channel.save
  end
end