<template>
  <woot-button variant="link" class="current-user" @click="handleClick">
    <thumbnail
      :src="currentUser.avatar_url"
      :username="currentUser.name"
      :status="statusOfAgent"
      should-show-status-always
      size="32px"
    />

    <span class="user-name"> {{ currentUser.available_name }} </span>
  </woot-button>
</template>
<script>
import { mapGetters } from 'vuex';
import Thumbnail from '../../widgets/Thumbnail';

export default {
  components: {
    Thumbnail,
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserAvailability: 'getCurrentUserAvailability',
    }),
    statusOfAgent() {
      return this.currentUserAvailability || 'offline';
    },
  },
  methods: {
    handleClick() {
      this.$emit('toggle-menu');
    },
  },
};
</script>

<style scoped lang="scss">
.current-user {
  ::v-deep.button__content {
    display: flex;
    align-items: center;

    .user-name {
      color: #fff;
      margin-left: 16px;
    }
  }
}

.current-user--data {
  display: flex;
  flex-direction: column;

  .current-user--name {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    margin-bottom: var(--space-micro);
    margin-left: var(--space-one);
    max-width: 12rem;
    color: #fff;
  }

  .current-user--role {
    color: #fff;
    font-size: var(--font-size-mini);
    margin-bottom: var(--zero);
    margin-left: var(--space-one);
    text-transform: capitalize;
  }
  border-radius: 50%;
  border: 2px solid var(--white);
}
</style>
