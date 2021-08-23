class Zalo::IncomingMessageService
  pattr_initialize [:params!]

  def perform
    set_contact
    set_conversation
    @message = @conversation.messages.create(
      content: params[:Body],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:SmsSid]
    )
    attach_files
  end

  private

  def set_contact
    contact_inbox = ::ContactBuilder.new(
      source_id: params[:sender][:id],
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def zalo_inbox
    @zalo_inbox ||= ::Channel::Zalo.find_by!(
      oa_id: params[:oa_id].nil? ? params[:recipient][:id] : params[:oa_id],

      )
  end
end
