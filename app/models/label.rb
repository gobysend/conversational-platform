# == Schema Information
#
# Table name: labels
#
#  id              :bigint           not null, primary key
#  color           :string           default("#1f93ff"), not null
#  description     :text
#  show_on_sidebar :boolean
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint
#
# Indexes
#
#  index_labels_on_account_id            (account_id)
#  index_labels_on_title_and_account_id  (title,account_id) UNIQUE
#
class Label < ApplicationRecord
  include RegexHelper
  belongs_to :account

  validates :title,
            presence: { message: 'must not be blank' },
            format: { with: UNICODE_CHARACTER_NUMBER_HYPHEN_UNDERSCORE },
            uniqueness: { scope: :account_id }

  attr_accessor :skip_changes_callbacks

  after_update_commit :update_associated_models

  after_commit :notify_changes

  before_validation do
    self.title = title.downcase if attribute_present?('title')
  end

  def conversations
    account.conversations.tagged_with(title)
  end

  def messages
    account.messages.where(conversation_id: conversations.pluck(:id))
  end

  def events
    account.events.where(conversation_id: conversations.pluck(:id))
  end

  private

  def update_associated_models
    return unless title_previously_changed?

    Labels::UpdateJob.perform_later(title, title_previously_was, account_id)
  end

  def notify_changes
    return if @skip_changes_callbacks

    queue = ENV.fetch('RABBITMQ_MESSAGE_CONTROL_QUEUE')

    if transaction_include_any_action?([:create])
      Publishers::RabbitPublisher.publish_control_message(queue_name: queue, event_type: 'label_created', payload: self)
    elsif transaction_include_any_action?([:update])
      Publishers::RabbitPublisher.publish_control_message(queue_name: queue, event_type: 'label_updated', payload: self, extras: { old_title: title_previously_was })
    else
      Publishers::RabbitPublisher.publish_control_message(queue_name: queue, event_type: 'label_destroyed', payload: self)
    end
  end
end
