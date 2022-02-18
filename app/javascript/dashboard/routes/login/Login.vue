<template>
  <div class="medium-12 column login">
    <div class="row align-center">
      <div v-if="!email" class="small-12 medium-6 large-3 column">
        <form class="login-box column align-self-top" @submit.prevent="login()">
          <div class="text-center medium-12 login__hero align-self-top">
            <img
              src="https://cdn-dev.gobysend.com/brand/logo/1622268746Gobysend logo_logo dài 56PX (1).svg"
              :alt="globalConfig.installationName"
              class="hero__logo"
              width="210"
            />

            <h5 class="hero__title">
              {{
                useInstallationName(
                  $t('LOGIN.TITLE'),
                  globalConfig.installationName
                )
              }}
            </h5>
          </div>

          <div class="column log-in-form">
            <label :class="{ error: $v.credentials.email.$error }">
              {{ $t('LOGIN.EMAIL.LABEL') }}
              <input
                v-model.trim="credentials.email"
                type="text"
                data-testid="email_input"
                :placeholder="$t('LOGIN.EMAIL.PLACEHOLDER')"
                @input="$v.credentials.email.$touch"
              />
            </label>
            <label :class="{ error: $v.credentials.password.$error }">
              {{ $t('LOGIN.PASSWORD.LABEL') }}
              <input
                v-model.trim="credentials.password"
                type="password"
                data-testid="password_input"
                :placeholder="$t('LOGIN.PASSWORD.PLACEHOLDER')"
                @input="$v.credentials.password.$touch"
              />
            </label>
            <woot-submit-button
              :disabled="
                $v.credentials.email.$invalid ||
                  $v.credentials.password.$invalid ||
                  loginApi.showLoading
              "
              :button-text="$t('LOGIN.SUBMIT')"
              :loading="loginApi.showLoading"
              button-class="expanded"
            >
            </woot-submit-button>
          </div>
        </form>
        <div class="column text-center sigin__footer">
          <p>
            <router-link to="auth/reset/password">
              {{ $t('LOGIN.FORGOT_PASSWORD') }}
            </router-link>
          </p>
          <p v-if="showSignupLink()">
            <router-link to="auth/signup">
              {{ $t('LOGIN.CREATE_NEW_ACCOUNT') }}
            </router-link>
          </p>
        </div>
      </div>
      <woot-spinner v-else size="" />
    </div>
  </div>
</template>

<script>
import { required, email } from 'vuelidate/lib/validators';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import WootSubmitButton from '../../components/buttons/FormSubmitButton';
import { mapGetters } from 'vuex';

export default {
  components: {
    WootSubmitButton,
  },
  mixins: [globalConfigMixin],
  props: {
    ssoAuthToken: { type: String, default: '' },
    redirectUrl: { type: String, default: '' },
    config: { type: String, default: '' },
    email: { type: String, default: '' },
    accountId: { type: String, default: '' },
  },
  data() {
    return {
      // We need to initialize the component with any
      // properties that will be used in it
      credentials: {
        email: '',
        password: '',
      },
      loginApi: {
        message: '',
        showLoading: false,
      },
      error: '',
    };
  },
  validations: {
    credentials: {
      password: {
        required,
      },
      email: {
        required,
        email,
      },
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
  created() {
    if (this.ssoAuthToken) {
      this.login();
    }
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.loginApi.showLoading = false;
      this.loginApi.message = message;
      bus.$emit('newToastMessage', this.loginApi.message);
    },
    showSignupLink() {
      return window.chatwootConfig.signupEnabled === 'true';
    },
    login() {
      this.loginApi.showLoading = true;
      const credentials = {
        email: this.email ? this.email : this.credentials.email,
        password: this.credentials.password,
        sso_auth_token: this.ssoAuthToken,
        account_id: this.accountId,
      };
      this.$store
        .dispatch('login', credentials)
        .then(() => {
          this.showAlert(this.$t('LOGIN.API.SUCCESS_MESSAGE'));

          this.$router.push(this.redirectUrl);
        })
        .catch(response => {
          // Reset URL Params if the authentication is invalid
          if (this.email) {
            window.location = window.ssoUrl;
          }

          if (response && response.status === 401) {
            const { errors } = response.data;
            const hasAuthErrorMsg =
              errors &&
              errors.length &&
              errors[0] &&
              typeof errors[0] === 'string';
            if (hasAuthErrorMsg) {
              this.showAlert(errors[0]);
            } else {
              this.showAlert(this.$t('LOGIN.API.UNAUTH'));
            }
            return;
          }
          this.showAlert(this.$t('LOGIN.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>
