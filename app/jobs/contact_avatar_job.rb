class ContactAvatarJob < ApplicationJob
  queue_as :default

  def perform(contact, avatar_url)
    avatar_file = Down.download(
      avatar_url,
      max_size: 15 * 1024 * 1024
    )
    contact.avatar.attach(
      key: "pages/avatars/account_#{contact.account_id}/contact_#{contact.id}_#{Time.now.to_i}_#{avatar_file.original_filename}",
      io: avatar_file,
      filename: avatar_file.original_filename,
      content_type: avatar_file.content_type
    )
  rescue Down::Error => e
    Rails.logger.info "Exception: invalid avatar url #{avatar_url} : #{e.message}"
  end
end
