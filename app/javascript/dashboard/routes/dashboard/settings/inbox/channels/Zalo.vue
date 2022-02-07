<template>
  <div class="wizard-body small-9 columns">
    <div v-if="!accessToken" class="login-init">
      <woot-button @click="openSignInWindow()">
        {{ $t('INBOX_MGMT.ADD.ZALO.CONNECT') }}
      </woot-button>

      <p>{{ $t('INBOX_MGMT.ADD.ZALO.DESC') }}</p>
    </div>

    <div v-else>
      <woot-loading-state
        v-if="uiFlags.isCreating"
        :message="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.LOADING_MESSAGE')"
      />
      <form
        v-if="!uiFlags.isCreating"
        class="row"
        @submit.prevent="createChannel"
      >
        <div v-if="avatar" class="medium-12 columns">
          <img
            src="https://s160-ava-talk.zadn.vn/b/b/4/d/5/160/02ba538f685872e4bceb7bbc96346926.jpg"
            style="width: 65px; margin-bottom: 15px;"
          />
        </div>

        <div class="medium-12 columns">
          <label>
            {{ $t('INBOX_MGMT.ADD.WEBSITE_NAME.LABEL') }}
            <input
              v-model.trim="inboxName"
              type="text"
              :placeholder="$t('INBOX_MGMT.ADD.WEBSITE_NAME.PLACEHOLDER')"
            />
          </label>
        </div>

        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :loading="uiFlags.isCreating"
              :disabled="!inboxName"
              :button-text="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.SUBMIT_BUTTON')"
            />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import router from '../../../../index';

export default {
  data() {
    return {
      inboxName: '',
      accessToken: '',
      avatar: '',

      windowObjectReference: null,
      previousUrl: null,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  methods: {
    async createChannel() {
      const website = await this.$store.dispatch('inboxes/createZaloChannel', {
        inbox_name: this.inboxName,
        access_token: this.accessToken,
      });

      router.replace({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: website.id,
        },
      });
    },

    openSignInWindow() {
      const url = this.getZaloOauthUrl();
      const window_name = 'zaloOauth';

      // remove any existing event listeners
      window.removeEventListener('message', this.receiveMessage);

      if (!this.windowObjectReference) {
        /* if the pointer to the window object in memory does not exist
      or if such pointer exists but the window was closed */
        this.windowObjectReference = this.popupCenter(
          url,
          window_name,
          600,
          700
        );
      } else if (this.previousUrl !== url) {
        /* if the resource to load is different,
      then we load it in the already opened secondary window and then
      we bring such window back on top/in front of its parent window. */
        this.windowObjectReference = this.popupCenter(
          url,
          window_name,
          600,
          700
        );
        this.windowObjectReference.focus();
      } else {
        /* else the window reference must exist and the window
      is not closed; therefore, we can bring it back on top of any other
      window with the focus() method. There would be no need to re-create
      the window or to reload the referenced resource. */
        this.windowObjectReference.focus();
      }

      // add the listener for receiving a message from the popup
      window.addEventListener('message', this.receiveMessage, false);
      // assign the previous URL
      this.previousUrl = url;
    },

    popupCenter(url, name, w, h) {
      const y = window.top.outerHeight / 2 + window.top.screenY - h / 2;
      const x = window.top.outerWidth / 2 + window.top.screenX - w / 2;

      const newWindow = window.open(
        url,
        name,
        `toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=no, resizable=no, copyhistory=no, width=${w}, height=${h}, top=${y}, left=${x}`
      );

      if (window.focus) newWindow.focus();
    },

    getZaloOauthUrl() {
      let param_obj = {
        app_id: window.chatwootConfig.zalo_app_id,
        redirect_uri: window.chatwootConfig.hostURL + '/app/oauth-redirect',
        // redirect_uri: 'https://chat.dev.gobysend.com',
        state: btoa(
          JSON.stringify({
            service: 'zalo',
          })
        ),
      };

      let param_str = '';
      for (let index = 0; index < Object.keys(param_obj).length; index += 1) {
        let key = Object.keys(param_obj)[index];

        if (param_str !== '') {
          param_str += '&';
        }
        param_str += key + '=' + param_obj[key];
      }

      return 'https://oauth.zaloapp.com/v3/oa/permission?' + param_str;
    },

    receiveMessage(event) {
      if (!event.data) return;

      const data = event.data;

      if (data.type === 'integration' && data.service === 'zalo') {
        // handle connect
        this.accessToken = event.data.access_token;

        window.axios
          .get(
            `${window.chatwootConfig.zalo_oa_api_base_url}/getoa?access_token=${this.accessToken}`
          )
          .then(response => {
            this.inboxName = response.data.data.name;
            this.avatar = response.data.data.avatar;
          });

        window.removeEventListener('message', this.receiveMessage);
      }
    },
  },
};
</script>
