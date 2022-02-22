<template>
  <!-- Page to handle redirect from oauth with third party -->
  <div></div>
</template>

<script>
export default {
  name: 'OauthRedirect',

  created() {
    let query = this.$route.query;

    if (window.opener) {
      // send them to the opening window
      window.opener.postMessage({
        type: 'integration',
        ...query,
      });
      // close the popup
      window.close();
    }
  },
};
</script>
