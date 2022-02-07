<template>
  <div class="notifications-link">
    <primary-nav-item
      name="NOTIFICATIONS"
      icon="alert"
      :to="`/app/accounts/${accountId}/notifications`"
      :count="unreadCount"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import PrimaryNavItem from './PrimaryNavItem';

export default {
  components: { PrimaryNavItem },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      notificationMetadata: 'notifications/getMeta',
    }),
    unreadCount() {
      if (!this.notificationMetadata.unreadCount) {
        return '';
      }

      return this.notificationMetadata.unreadCount < 100
        ? `${this.notificationMetadata.unreadCount}`
        : '99+';
    },
  },
  methods: {},
};
</script>

<style scoped lang="scss">
.notifications {
  font-size: var(--font-size-big);
  margin-bottom: auto;
  margin-left: auto;
  margin-top: auto;
  position: relative;
  color: #fff;

  .unread-badge {
    background: var(--r-300);
    border-radius: var(--space-small);
    color: #007dfa;
    font-size: var(--font-size-micro);
    font-weight: var(--font-weight-black);
    left: var(--space-slab);
    padding: 0 var(--space-smaller);
    position: absolute;
    top: var(--space-smaller);
  }
}
.notifications-link {
  margin-bottom: var(--space-small);
}
</style>
