<template>
  <div class="primary--sidebar">
    <logo
      :source="logoSource"
      :name="installationName"
      :account-id="accountId"
    />
    <nav class="menu vertical main-menu">
      <primary-nav-item
        v-for="menuItem in gobyAdminMenu"
        :key="menuItem.toState"
        :icon="menuItem.icon"
        :iconViewBox="menuItem.iconViewBox"
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
      <!-- <notification-bell /> -->
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
          icon: 'customers',
          iconViewBox: '0 -3 511.99981 511',
          label: 'Khách hàng',
          href: 'https://admin.gobysend.com/customers/list',
          children: [
            {
              label: 'Danh sách khách hàng',
              href: `${host_url}/customers/list`,
            },
            {
              label: 'Phản hồi',
              href: `${host_url}/customers/feedbacks`,
            },
            {
              label: 'Phân khúc',
              href: `${host_url}/customers/segments`,
            },
            {
              label: 'Thẻ',
              href: `${host_url}/customers/tags`,
            },
            {
              label: 'Mẫu đăng ký',
              href: `${host_url}/customers/signup-forms`,
            },
            {
              label: 'Điểm tiềm năng',
              href: `${host_url}/customers/lead-scoring`,
            },
            {
              label: 'Trường dữ liệu',
              href: `${host_url}/customers/fields`,
            },
            {
              label: 'Cài đặt',
              href: `${host_url}/customers/settings`,
            },
            {
              label: 'Lưu trữ',
              href: `${host_url}/customers/archives`,
            },
            {
              label: 'Xuất dữ liệu',
              href: `${host_url}/customers/exports`,
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
          icon: 'campaign',
          iconViewBox: '0 0 512 512',
          label: 'Chiến dịch',
          href: 'https://admin.gobysend.com/customers/list',
          children: [
            {
              label: 'Danh sách chiến dịch',
              href: `${host_url}/campaigns`,
            },
            {
              label: 'Mẫu email',
              href: `${host_url}/template/email`,
            },
          ],
        },
        {
          icon: 'automations',
          iconViewBox: '0 0 512 512',
          label: 'Tự động hóa',
          href: 'https://admin.gobysend.com/customers/list',
        },
        {
          icon: 'delivery',
          label: 'Lịch sử gửi',
          href: 'https://admin.gobysend.com/customers/list',
        },
        {
          icon: 'order',
          iconViewBox: '0 0 511.997 511.997',
          label: 'Đơn hàng & Sản phẩm',
          href: 'https://admin.gobysend.com/customers/list',
          children: [
            {
              label: 'Danh sách đơn hàng',
              href: `${host_url}/customers/orders`,
            },
            {
              label: 'Danh sách sản phẩm',
              href: `${host_url}/customers/products`,
            },
          ],
        },
        {
          icon: 'integrations',
          iconViewBox: '0 0 30 30',
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
  width: 250px;
  border-right: 1px solid var(--s-50);
  box-sizing: content-box;
  height: 100vh;
  flex-shrink: 0;

  background: #064095;
}

.main-menu {
  flex: 1;
}

.user-menu {
  padding: 16px;
}
</style>
