export const INBOX_TYPES = {
  WEB: 'Channel::WebWidget',
  FB: 'Channel::FacebookPage',
  TWITTER: 'Channel::TwitterProfile',
  TWILIO: 'Channel::TwilioSms',
  API: 'Channel::Api',
  EMAIL: 'Channel::Email',
  ZALO: 'Channel::Zalo',
};

export default {
  computed: {
    channelType() {
      return this.inbox.channel_type;
    },
    isAPIInbox() {
      return this.channelType === INBOX_TYPES.API;
    },
    isATwitterInbox() {
      return this.channelType === INBOX_TYPES.TWITTER;
    },
    isAFacebookInbox() {
      return this.channelType === INBOX_TYPES.FB;
    },
    isAZaloInbox() {
      return this.channelType === INBOX_TYPES.ZALO;
    },
    isAWebWidgetInbox() {
      return this.channelType === INBOX_TYPES.WEB;
    },
    isATwilioChannel() {
      return this.channelType === INBOX_TYPES.TWILIO;
    },
    isAnEmailChannel() {
      return this.channelType === INBOX_TYPES.EMAIL;
    },
    isATwilioSMSChannel() {
      const { phone_number: phoneNumber = '' } = this.inbox;
      return this.isATwilioChannel && !phoneNumber.startsWith('whatsapp');
    },
    isATwilioWhatsappChannel() {
      const { phone_number: phoneNumber = '' } = this.inbox;
      return this.isATwilioChannel && phoneNumber.startsWith('whatsapp');
    },
    isAZaloChannel() {
      return this.channelType === INBOX_TYPES.ZALO;
    },
  },
};
