class Workers::SyncToChatJob
  include Singleton

  TAG_CREATED = 'tag_created'.freeze
  TAG_UPDATED = 'tag_updated'.freeze
  TAG_DELETED = 'tag_deleted'.freeze

  CONTACT_UPDATED = 'contact_updated'.freeze

  CUSTOM_ATTRIBUTE_CHANGED = 'custom_attribute_changed'.freeze

  def work(msg)
    message = JSON.parse(msg, symbolize_names: true)
    return if message.nil? || message[:eventType].blank? || message[:chatwootAccountId].blank?

    case message[:eventType]
    when TAG_CREATED
      create_tag(message)
    when TAG_UPDATED
      update_tag(message)
    when TAG_DELETED
      delete_tag(message)

    when CONTACT_UPDATED
      update_contact(message[:payload])

    when CUSTOM_ATTRIBUTE_CHANGED
      update_custom_attributes(message)

    else
      Rails.logger.info "Received unknown message: #{msg}"
    end
  end

  private

  #
  # Create a new tag
  #
  # Format: { eventType: 'tag_created', chatwootAccountId: 1, data: { name: 'New Tag Name', color: '#FFFFFF' } }
  #
  def create_tag(message)
    account_id = message[:chatwootAccountId]
    payload = message[:data]

    label = Label.new account_id: account_id,
                      title: payload[:name].parameterize,
                      description: payload[:name],
                      color: payload[:color],
                      show_on_sidebar: true
    label.skip_changes_callbacks = true
    label.save
  end

  #
  # Update an existing tag
  #
  # Format: { eventType: 'tag_updated', chatwootAccountId: 1, old_tag: 'Tag Name', data: { name: 'New Tag Name', color: '#FFFFFF' } }
  #
  def update_tag(message)
    account_id = message[:chatwootAccountId]
    old_tag = message[:old_tag]
    payload = message[:data]

    return if old_tag.blank?

    old_label = Label.where(account_id: account_id, title: old_tag.parameterize).first
    return if old_label.blank?

    old_label.title = payload[:name].parameterize
    old_label.description = payload[:name]
    old_label.color = payload[:color]
    old_label.skip_changes_callbacks = true
    old_label.save!
  end

  #
  # Delete a tag
  #
  # Format: { eventType: 'tag_deleted', chatwootAccountId: 1, names: ['Tag Name'] }
  #
  def delete_tag(message)
    return if message[:names].blank?

    account_id = message[:chatwootAccountId]

    message[:names].each do |title|
      title = title.parameterize
      label = Label.where(account_id: account_id, title: title).first
      next if label.blank?

      label.skip_changes_callbacks = true
      label.destroy!
    end
  end

  #
  # Update an existing contact
  #
  # Format: { eventType: 'contact_updated', data: { ..., chatwoot_contact_id: 1 } }
  #
  def update_contact(payload)
    return if payload[:chatwoot_contact_id].blank?

    payload = message[:data]

    contact = Contact.find(payload[:chatwoot_contact_id]).first
    return if contact.nil?

    contact.email = payload[:email]
    contact.phone_number = payload[:phone_number]

    hash_attributes = {}
    custom_attributes = CustomAttributeDefinition.where(account_id: contact.account.id).all

    custom_attributes.each do |attribute|
      next unless payload.key?(attribute.attribute_key)

      hash_attributes[attribute.attribute_key] = payload[attribute.attribute_key]
    end

    contact.skip_update_callbacks = true
    contact.update(hash_attributes)
  end

  #
  # Update list of custom attributes
  #
  # Format: { eventType: 'custom_attribute_changed', 'chatwootAccountId': 1, data: [ { id: 1, name: 'Attribute', content_tag: 'attribute', ... } ] }
  #
  def update_custom_attributes(message)
    return if message[:chatwootAccountId].blank? || message[:data].blank?

    account_id = message[:chatwootAccountId]
    fields = message[:data]

    existing_attributes = CustomAttributeDefinition.where(account_id: account_id).all.index_by(&:attribute_key)
    display_type_map = { email: 0, phone: 0, number: 1, dropdown: 6, radio: 7, date: 5, datetime: 5 }
    processed_content_tags = []

    ActiveRecord::Base.transaction do
      # Insert or update fields
      fields.each do |field|
        content_tag = field[:content_tag]
        processed_content_tags.push(content_tag)

        if existing_attributes.key?(content_tag)
          # Update existing field, we need to update only the name
          existing_attributes[content_tag].skip_commit_callbacks = true
          existing_attributes[content_tag].update({ attribute_display_name: field[:name] })
        else
          # Insert new field
          attribute = CustomAttributeDefinition.new account_id: account_id,
                                                    attribute_display_name: field[:name],
                                                    attribute_key: content_tag,
                                                    attribute_display_type: display_type_map[field[:type]] || 0,
                                                    default_value: field[:default_value],
                                                    attribute_model: 1,
                                                    attribute_description: field[:name]
          attribute.skip_commit_callbacks = true
          attribute.save
        end
      end

      # Delete unused fields
      existing_attributes.each do |content_tag, field|
        next if processed_content_tags.include?(content_tag)

        field.skip_commit_callbacks = true
        field.destroy
      end
    end
  end
end
