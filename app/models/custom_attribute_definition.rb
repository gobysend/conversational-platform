# == Schema Information
#
# Table name: custom_attribute_definitions
#
#  id                     :bigint           not null, primary key
#  attribute_description  :text
#  attribute_display_name :string
#  attribute_display_type :integer          default("text")
#  attribute_key          :string
#  attribute_model        :integer          default("conversation_attribute")
#  attribute_values       :jsonb
#  default_value          :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint
#
# Indexes
#
#  attribute_key_model_index                         (attribute_key,attribute_model,account_id) UNIQUE
#  index_custom_attribute_definitions_on_account_id  (account_id)
#
class CustomAttributeDefinition < ApplicationRecord
  scope :with_attribute_model, ->(attribute_model) { attribute_model.presence && where(attribute_model: attribute_model) }
  validates :attribute_display_name, presence: true

  validates :attribute_key,
            presence: true,
            uniqueness: { scope: [:account_id, :attribute_model] }

  validates :attribute_display_type, presence: true
  validates :attribute_model, presence: true

  enum attribute_model: { conversation_attribute: 0, contact_attribute: 1 }
  enum attribute_display_type: { text: 0, number: 1, currency: 2, percent: 3, link: 4, date: 5, list: 6, checkbox: 7 }

  belongs_to :account

  attr_accessor :skip_commit_callbacks

  after_commit :notify_changes

  def notify_changes
    return if self.attribute_model == 'conversation_attribute' || @skip_commit_callbacks

    event_type = 'custom_attribute_destroyed'
    if transaction_include_any_action?([:create])
      event_type = 'custom_attribute_created'
    elsif transaction_include_any_action?([:update])
      event_type = 'custom_attribute_updated'
    end

    Publishers::RabbitPublisher.publish_control_message(queue_name: ENV.fetch('RABBITMQ_MESSAGE_CONTROL_QUEUE'), event_type: event_type, payload: self)
  end
end
