<template>
  <!-- Page to handle redirect from oauth with third party -->
  <div></div>
</template>

<script>
export default {
  name: 'OauthRedirect',

  created() {
    let query = this.$route.query;

    if (query.state) {
      // state is a base64 encoding of json
      let state = JSON.parse(atob(query.state));

      switch (state.service) {
        case 'zalo':
          // get the URL parameters which will include the auth token

          if (window.opener) {
            // send them to the opening window
            window.opener.postMessage({
              type: 'integration',
              service: 'zalo',
              ...query,
            });
            // close the popup
            window.close();
          }
          break;
        default:
          break;
      }
    }
  },
};
</script>
