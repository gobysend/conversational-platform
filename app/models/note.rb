# == Schema Information
#
# Table name: notes
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  contact_id :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_notes_on_account_id  (account_id)
#  index_notes_on_contact_id  (contact_id)
#  index_notes_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class Note < ApplicationRecord
  before_validation :ensure_account_id
  validates :content, presence: true

  belongs_to :account
  belongs_to :contact
  belongs_to :user

  scope :latest, -> { order(created_at: :desc) }

  private

  def ensure_account_id
    self.account_id = contact&.account_id
  end
end
