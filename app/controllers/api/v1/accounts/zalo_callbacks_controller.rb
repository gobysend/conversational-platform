class Api::V1::Accounts::ZaloCallbacksController < Api::V1::Accounts::BaseController
  before_action :oa_access_token
  before_action :oa_detail, only: [:register_zalo_oa]

  def request_auth_url
    pkce_challenge = ::PkceChallenge.challenge(char_length: 43)

    redirect_uri = "#{ENV['FRONTEND_URL']}/app/oauth-redirect?goby_integration=zalo"
    auth_url = 'https://oauth.zaloapp.com/v4/oa/permission'
    auth_url += "?app_id=#{ENV['ZALO_APP_ID']}&code_challenge=#{pkce_challenge.code_challenge}&redirect_uri=#{redirect_uri}"

    # Store verifier and challenge to redis
    ::Redis::Alfred.setex(pkce_challenge.code_challenge, pkce_challenge.code_verifier, 5.minutes)

    render json: {
      code_challenge: pkce_challenge.code_challenge,
      login_url: auth_url
    }
  end

  def oa_access_token
    auth_code = params[:code]
    code_challenge = params[:code_challenge]
    verifier_code = ::Redis::Alfred.get(code_challenge)

    return if verifier_code.blank?

    payload = {
      code: auth_code,
      app_id: ENV['ZALO_APP_ID'],
      grant_type: 'authorization_code',
      code_verifier: verifier_code
    }

    begin
      response = HTTParty.post(
        'https://oauth.zaloapp.com/v4/oa/access_token',
        query: payload,
        headers: {
          'secret_key' => ENV['ZALO_APP_SECRET']
        }
      )
    rescue RestClient::ExceptionWithResponse
      return
    end

    response = JSON.parse(response.body, { symbolize_names: true })
    @oa_access_token = response[:access_token] if response[:access_token].present?
    @oa_refresh_token = response[:refresh_token] if response[:refresh_token].present?
  end

  ##
  # Get Zalo OA account details from access token
  #
  def oa_detail
    @oa = nil

    return if @oa_access_token.nil?

    url = "#{ENV['ZALO_OA_API_BASE_URL']}/getoa"

    begin
      response = RestClient.get(url, { content_type: 'application/json', access_token: @oa_access_token })
    rescue RestClient::ExceptionWithResponse
      response = nil
    end

    response = JSON.parse(response.body, { symbolize_names: true })
    @oa = response[:data]
  end

  ##
  # Register a new inbox with a Zalo OA account
  #
  def register_zalo_oa
    return if @oa.nil?

    # Check if Zalo OA has been authorized
    zalo_channel = Current.account.zalo_channels.find_by(oa_id: @oa[:oa_id])
    @zalo_inbox = Current.account.inboxes.find_by(channel_type: 'Channel::Zalo', channel_id: zalo_channel.id) if zalo_channel

    inbox_name = params[:inbox_name] || @oa[:name]
    ActiveRecord::Base.transaction do
      if zalo_channel
        # Update Zalo OA information if it is already existing
        zalo_channel.update!(
          oa_id: @oa[:oa_id],
          oa_name: @oa[:name],
          oa_description: @oa[:description],
          oa_avatar: @oa[:avatar],
          oa_cover: @oa[:cover],
          access_token: @oa_access_token,
          expires_at: (DateTime.now + 1.hour),
          refresh_token: @oa_refresh_token
        )
      else
        # Otherwise, create new Zalo channel
        zalo_channel = Current.account.zalo_channels.create!(
          oa_id: @oa[:oa_id],
          oa_name: @oa[:name],
          oa_description: @oa[:description],
          oa_avatar: @oa[:avatar],
          oa_cover: @oa[:cover],
          access_token: @oa_access_token,
          expires_at: (DateTime.now + 1.hour),
          is_synced: true,
          refresh_token: @oa_refresh_token
        )
      end

      if @zalo_inbox
        # Update inbox with new name
        @zalo_inbox&.update!(name: inbox_name)
      else
        # Create a new inbox
        @zalo_inbox = Current.account.inboxes.create!(name: inbox_name, channel: zalo_channel)
      end
      update_avatar(@zalo_inbox)

      # Download conversation history

    rescue StandardError => e
      Rails.logger.info e
    end

    render json: @zalo_inbox
  end

  private

  def update_avatar(zalo_inbox)
    avatar_file = Down.download(@oa[:avatar])
    zalo_inbox.avatar.attach(io: avatar_file, filename: avatar_file.original_filename, content_type: avatar_file.content_type)
  end
end
