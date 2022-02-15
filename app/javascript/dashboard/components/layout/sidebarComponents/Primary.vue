<template>
  <div class="primary--sidebar">
    <logo
      :source="logoSource"
      :name="installationName"
      :account-id="accountId"
    />
    <nav class="menu vertical">
      <primary-nav-item
        v-for="menuItem in gobyAdminMenu"
        :key="menuItem.toState"
        :icon="menuItem.icon"
        :name="menuItem.label"
        :to="menuItem.toState"
        :is-child-menu-active="menuItem.key === activeMenuItem"
        :href="menuItem.href"
        :children="menuItem.children"
      />

      <!-- <primary-nav-item
        v-for="menuItem in menuItems"
        :key="menuItem.toState"
        :icon="menuItem.icon"
        :name="menuItem.label"
        :to="menuItem.toState"
        :is-child-menu-active="menuItem.key === activeMenuItem"
      /> -->
    </nav>
    <div class="menu vertical user-menu">
      <notification-bell />
      <agent-details @toggle-menu="toggleOptions" />
      <options-menu
        :show="showOptionsMenu"
        @toggle-accounts="toggleAccountModal"
        @show-support-chat-window="toggleSupportChatWindow"
        @key-shortcut-modal="$emit('key-shortcut-modal')"
        @close="toggleOptions"
      />
    </div>
  </div>
</template>
<script>
import Logo from './Logo';
import PrimaryNavItem from './PrimaryNavItem';
import OptionsMenu from './OptionsMenu';
import AgentDetails from './AgentDetails';
import NotificationBell from './NotificationBell';

import { frontendURL } from 'dashboard/helper/URLHelper';

export default {
  components: {
    Logo,
    PrimaryNavItem,
    OptionsMenu,
    AgentDetails,
    NotificationBell,
  },
  props: {
    logoSource: {
      type: String,
      default: '',
    },
    installationName: {
      type: String,
      default: '',
    },
    accountId: {
      type: Number,
      default: 0,
    },
    menuItems: {
      type: Array,
      default: () => [],
    },
    activeMenuItem: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      showOptionsMenu: false,
    };
  },
  computed: {
    gobyAdminMenu() {
      const host_url = window.chatwootConfig.admin_frontend_url;

      return [
        {
          icon: 'chat',
          label: 'Khách hàng',
          href: 'https://admin.gobysend.com/customers/list',
          children: [
            {
              icon: 'chat',
              label: 'Danh sách khách hàng',
              href: `${host_url}/customers/list`,
            },
          ],
        },
        {
          icon: 'chat',
          label: 'Chat đa kênh',
          toState: frontendURL(`accounts/${this.accountId}/dashboard`),
          children: this.menuItems,
        },
        {
          icon: 'chat',
          label: 'Chiến dịch',
          href: 'https://admin.gobysend.com/customers/list',
        },
        {
          icon: 'chat',
          label: 'Tự động hóa',
          href: 'https://admin.gobysend.com/customers/list',
        },
        {
          icon: 'chat',
          label: 'Lịch sử gửi',
          href: 'https://admin.gobysend.com/customers/list',
        },
        {
          icon: 'chat',
          label: 'Đơn hàng & Sản phẩm',
          href: 'https://admin.gobysend.com/customers/list',
        },
        {
          icon: 'chat',
          label: 'Tích hợp',
          href: 'https://admin.gobysend.com/customers/list',
        },
      ];
    },
  },
  methods: {
    frontendURL,
    toggleOptions() {
      this.showOptionsMenu = !this.showOptionsMenu;
    },
    toggleAccountModal() {
      this.$emit('toggle-accounts');
    },
    toggleSupportChatWindow() {
      window.$chatwoot.toggle();
    },
  },
};
</script>
<style lang="scss" scoped>
.primary--sidebar {
  display: flex;
  flex-direction: column;
  width: 300px;
  border-right: 1px solid var(--s-50);
  box-sizing: content-box;
  height: 100vh;
  flex-shrink: 0;
}

.menu {
  //align-items: center;
  margin-top: var(--space-medium);
  background: #5629b6;
}

.user-menu {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  justify-content: flex-end;
  margin-bottom: var(--space-normal);
}
</style>
