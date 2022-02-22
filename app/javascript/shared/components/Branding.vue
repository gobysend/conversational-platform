<template>
  <div
    v-if="globalConfig.brandName"
    class="px-0 py-3 flex justify-center items-center"
  >
    <img
      class="branding--image"
      :alt="globalConfig.brandName"
      src="/favicon.png"
    />
    <div class="text-gray-100 text-xs">
      {{ useInstallationName($t('POWERED_BY'), globalConfig.brandName) }}
    </div>
  </div>

  <div v-else class="p-3" />
</template>

<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { mapGetters } from 'vuex';

const {
  LOGO_THUMBNAIL: logoThumbnail,
  BRAND_NAME: brandName,
  WIDGET_BRAND_URL: widgetBrandURL,
} = window.globalConfig || {};

export default {
  mixins: [globalConfigMixin],
  data() {
    return {
      globalConfig: {
        brandName,
        logoThumbnail,
        widgetBrandURL,
      },
    };
  },
  computed: {
    ...mapGetters({ referrerHost: 'appConfig/getReferrerHost' }),
    brandRedirectURL() {
      const baseURL = `${this.globalConfig.widgetBrandURL}?utm_source=widget_branding`;
      if (this.referrerHost) {
        return `${baseURL}&utm_referrer=${this.referrerHost}`;
      }
      return baseURL;
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.branding--image {
  margin-right: 8px;
  width: 20px;
}
</style>
