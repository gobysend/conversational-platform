module WootMessageSeeder
  def self.create_sample_email_collect_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content_type: :input_email,
      content: 'Get notified by email'
    )
  end

  def self.create_sample_csat_collect_message(conversation)
    Message.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      message_type: :template,
      content_type: :input_csat,
      content: 'Please rate the support'
    )
  end

  def self.sample_form
    {
      items: [
        { name: 'email', placeholder: 'Please enter your email', type: 'email', label: 'Email', required: 'required',
          pattern_error: 'Please fill this field', pattern: '^[^\s@]+@[^\s@]+\.[^\s@]+$' },
        { name: 'text_area', placeholder: 'Please enter text', type: 'text_area', label: 'Large Text', required: 'required',
          pattern_error: 'Please fill this field' },
        { name: 'text', placeholder: 'Please enter text', type: 'text', label: 'text', default: 'defaut value', required: 'required',
          pattern: '^[a-zA-Z ]*$', pattern_error: 'Only alphabets are allowed' },
        { name: 'select', label: 'Select Option', type: 'select', options: [{ label: '🌯 Burito', value: 'Burito' },
                                                                            { label: '🍝 Pasta', value: 'Pasta' }] }
      ]
    }
  end

end
