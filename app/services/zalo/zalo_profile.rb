module Zalo::Profile
  private

  def zalo_profile(user_id, access_token)
    begin
      response = RestClient::Request.execute(
        method: :get,
        url: "#{ENV['ZALO_OA_API_BASE_URL']}/getprofile?data={\"user_id\":\"#{user_id}\"}",
        headers: { content_type: 'application/json', access_token: access_token }
      )

      response = JSON.parse(response.body, { symbolize_names: true })

      result = response[:data] || {}
    rescue RestClient::ExceptionWithResponse => e
      result = {}
      Rails.logger.error(e)
      puts "Error getting Zalo profile #{e.message}"
    end

    result
  end
end
