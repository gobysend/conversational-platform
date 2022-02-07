# loading installation configs
GlobalConfig.clear_cache
ConfigLoader.new.process

## Seeds productions
if Rails.env.production?
  # Setup Onboarding flow
  ::Redis::Alfred.set(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
end

## Seeds for Local Development
unless Rails.env.production?
  SuperAdmin.create!(email: 'dat@gobysend.com', password: 'Password1!')

  account = Account.create!(
    name: 'Gobysend'
  )

  secondary_account = Account.create!(
    name: 'Gobysend'
  )

  user = User.new(name: 'Dat', email: 'dat@gobysend.com', password: 'Password1!')
  user.skip_confirmation!
  user.save!

  AccountUser.create!(
    account_id: account.id,
    user_id: user.id,
    role: :administrator
  )

  AccountUser.create!(
    account_id: secondary_account.id,
    user_id: user.id,
    role: :administrator
  )

  # Enables creating additional accounts from dashboard
  installation_config = InstallationConfig.find_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
  installation_config.value = true
  installation_config.save!
  GlobalConfig.clear_cache

  web_widget = Channel::WebWidget.create!(account: account, website_url: 'https://goby.vn')

  inbox = Inbox.create!(channel: web_widget, account: account, name: 'Gobysend Support')
  InboxMember.create!(user: user, inbox: inbox)

  contact = Contact.create!(name: 'Support', email: 'support@gobysend.com', phone_number: '+84918612568', account: account)
  contact_inbox = ContactInbox.create!(inbox: inbox, contact: contact, source_id: user.id, hmac_verified: true)
  conversation = Conversation.create!(
    account: account,
    inbox: inbox,
    status: :open,
    assignee: user,
    contact: contact,
    contact_inbox: contact_inbox,
    additional_attributes: {}
  )

  # sample email collect
  Seeders::MessageSeeder.create_sample_email_collect_message conversation

  Message.create!(content: 'Hi', account: account, inbox: inbox, conversation: conversation, message_type: :incoming)

  # sample card
  Seeders::MessageSeeder.create_sample_cards_message conversation
  # input select
  Seeders::MessageSeeder.create_sample_input_select_message conversation
  # form
  Seeders::MessageSeeder.create_sample_form_message conversation
  # articles
  Seeders::MessageSeeder.create_sample_articles_message conversation
  # csat
  Seeders::MessageSeeder.create_sample_csat_collect_message conversation

  CannedResponse.create!(account: account, short_code: 'start', content: 'Welcome to Goby Messaging.')
end
