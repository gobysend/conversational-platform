<template>
  <router-link
    :to="menuItem.toState"
    tag="li"
    active-class="active"
    :class="computedClass"
  >
    <a
      v-tooltip="{
        content: currentRoute == 'home' ? '' : $t(`SIDEBAR.${menuItem.label}`),
        placement: 'right',
        classes: ['custom-left'],
      }"
      class="sub-menu-title"
      :class="getMenuItemClass"
      data-tooltip
      aria-haspopup="true"
      :title="menuItem.toolTip"
    >
      <div class="wrap">
        <i :class="menuItem.icon" />

        <span class="nav-text">{{ $t(`SIDEBAR.${menuItem.label}`) }}</span>
      </div>

      <span
        v-if="showItem(menuItem)"
        class="child-icon ion-android-add-circle"
        @click.prevent="$emit('add-label')"
      />
    </a>

    <ul v-if="menuItem.hasSubMenu" class="nested vertical menu">
      <div class="header-title">
        {{ $t(`SIDEBAR.${menuItem.label}`) }}
      </div>

      <router-link
        v-for="child in menuItem.children"
        :key="child.toState"
        active-class="active"
        tag="li"
        :to="child.toState"
      >
        <a href="#" :class="computedChildClass(child)">
          <i
            v-if="computedInboxClass(child)"
            class="inbox-icon"
            :class="computedInboxClass(child)"
          />
          <span
            v-if="child.color"
            class="label-color--display"
            :style="{ backgroundColor: child.color }"
          />

          {{ $t(`SIDEBAR.${child.label}`) }}
        </a>
      </router-link>

      <template v-if="menuItem.toStateName == 'contacts_dashboard'">
        <li>
          <div class="sub-title">
            <div>
              <i class="ion-pound"></i>
              {{ $t('SIDEBAR.TAGGED_WITH') }}
            </div>

            <span
              v-if="showItem(contactLabelSection)"
              class="child-icon ion-android-add-circle"
              @click.prevent="newLinkClick(contactLabelSection)"
            />
          </div>
        </li>

        <router-link
          v-for="child in contactLabelSection.children"
          :key="child.toState"
          active-class="active flex-container"
          tag="li"
          :to="child.toState"
        >
          <a href="#" :class="computedChildClass(child)">
            <span
              v-if="child.color"
              class="label-color--display"
              :style="{ backgroundColor: child.color }"
            />

            {{ child.label }}
          </a>
        </router-link>
      </template>

      <template v-if="menuItem.toStateName == 'conversations'">
        <!-- team section -->
        <template v-if="teams.length">
          <li>
            <div class="sub-title">
              <div>
                <i class="ion-ios-people"></i>
                {{ $t('SIDEBAR.TEAMS') }}
              </div>

              <span
                v-if="showItem(teamSection)"
                class="child-icon ion-android-add-circle"
                @click.prevent="newLinkClick(teamSection)"
              />
            </div>
          </li>

          <router-link
            v-for="child in teamSection.children"
            :key="child.toState"
            active-class="active flex-container"
            tag="li"
            :to="child.toState"
          >
            <a href="#" :class="computedChildClass(child)">
              {{ child.label }}
            </a>
          </router-link>
        </template>

        <!-- inbox section -->
        <template>
          <li>
            <div class="sub-title">
              <div>
                <i class="ion-folder"></i>
                {{ $t('SIDEBAR.INBOXES') }}
              </div>

              <span
                v-if="showItem(inboxSection)"
                class="child-icon ion-android-add-circle"
                @click.prevent="newLinkClick(inboxSection)"
              />
            </div>
          </li>

          <router-link
            v-for="child in inboxSection.children"
            :key="child.toState"
            active-class="active flex-container"
            tag="li"
            :to="child.toState"
          >
            <a href="#" :class="computedChildClass(child)">
              {{ child.label }}
            </a>
          </router-link>
        </template>

        <!-- label section -->
        <template>
          <li>
            <div class="sub-title">
              <div>
                <i class="ion-pound"></i>
                {{ $t('SIDEBAR.LABELS') }}
              </div>

              <span
                v-if="showItem(labelSection)"
                class="child-icon ion-android-add-circle"
                @click.prevent="newLinkClick(labelSection)"
              />
            </div>
          </li>

          <router-link
            v-for="child in labelSection.children"
            :key="child.toState"
            active-class="active flex-container"
            tag="li"
            :to="child.toState"
          >
            <a href="#" :class="computedChildClass(child)">
              <span
                v-if="child.color"
                class="label-color--display"
                :style="{ backgroundColor: child.color }"
              />

              {{ child.label }}
            </a>
          </router-link>
        </template>
      </template>
    </ul>
  </router-link>
</template>

<script>
import { mapGetters } from 'vuex';

import router from '../../routes';
import {
  hasPressedAltAndCKey,
  hasPressedAltAndVKey,
  hasPressedAltAndRKey,
  hasPressedAltAndSKey,
} from 'shared/helpers/KeyboardHelpers';
import adminMixin from '../../mixins/isAdmin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import { getInboxClassByType } from 'dashboard/helper/inbox';
import { frontendURL } from '../../helper/URLHelper';
import { getSidebarItems } from '../../i18n/default-sidebar';
export default {
  mixins: [adminMixin, eventListenerMixins],
  props: {
    menuItem: {
      type: Object,
      default() {
        return {};
      },
    },
  },
  computed: {
    ...mapGetters({
      inboxes: 'inboxes/getInboxes',
      activeInbox: 'getSelectedInbox',
      accountId: 'getCurrentAccountId',
      accountLabels: 'labels/getLabelsOnSidebar',
      teams: 'teams/getMyTeams',
    }),
    getMenuItemClass() {
      return this.menuItem.cssClass
        ? `side-menu ${this.menuItem.cssClass}`
        : 'side-menu';
    },
    currentRoute() {
      return this.$store.state.route.name;
    },
    sidemenuItems() {
      return getSidebarItems(this.accountId);
    },
    computedClass() {
      // // If active Inbox is present
      // // donot highlight conversations
      // if (this.activeInbox) return ' ';

      // if (
      //   this.$store.state.route.name === 'inbox_conversation' &&
      //   this.menuItem.toStateName === 'home'
      // ) {
      //   return 'active';
      // }
      // return ' ';

      let currentMenu = this.menuItem.label.toLowerCase();

      if (
        this.sidemenuItems[currentMenu] &&
        this.sidemenuItems[currentMenu].routes.includes(this.currentRoute)
      ) {
        return 'active';
      }
      return '';
    },

    teamSection() {
      return {
        icon: 'ion-ios-people',
        label: 'TEAMS',
        hasSubMenu: true,
        newLink: true,
        key: 'team',
        cssClass: ' teams-sidebar-menu',
        toState: frontendURL(`accounts/${this.accountId}/settings/teams`),
        toStateName: 'teams_list',
        newLinkRouteName: 'settings_teams_new',
        children: this.teams.map(team => ({
          id: team.id,
          label: team.name,
          truncateLabel: true,
          toState: frontendURL(`accounts/${this.accountId}/team/${team.id}`),
        })),
      };
    },

    inboxSection() {
      return {
        icon: 'ion-folder',
        label: 'INBOXES',
        hasSubMenu: true,
        newLink: true,
        key: 'inbox',
        cssClass: '',
        toState: frontendURL(`accounts/${this.accountId}/settings/inboxes`),
        toStateName: 'settings_inbox_list',
        newLinkRouteName: 'settings_inbox_new',
        children: this.inboxes.map(inbox => ({
          id: inbox.id,
          label: inbox.name,
          toState: frontendURL(`accounts/${this.accountId}/inbox/${inbox.id}`),
          type: inbox.channel_type,
          phoneNumber: inbox.phone_number,
        })),
      };
    },

    labelSection() {
      return {
        icon: 'ion-pound',
        label: 'LABELS',
        hasSubMenu: true,
        newLink: true,
        key: 'label',
        cssClass: '',
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        showModalForNewItem: true,
        modalName: 'AddLabel',
        children: this.accountLabels.map(label => ({
          id: label.id,
          label: label.title,
          color: label.color,
          truncateLabel: true,
          toState: frontendURL(
            `accounts/${this.accountId}/label/${label.title}`
          ),
        })),
      };
    },

    contactLabelSection() {
      return {
        icon: 'ion-pound',
        label: 'TAGGED_WITH',
        hasSubMenu: true,
        key: 'label',
        newLink: false,
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        showModalForNewItem: true,
        modalName: 'AddLabel',
        children: this.accountLabels.map(label => ({
          id: label.id,
          label: label.title,
          color: label.color,
          truncateLabel: true,
          toState: frontendURL(
            `accounts/${this.accountId}/labels/${label.title}/contacts`
          ),
        })),
      };
    },
  },
  methods: {
    computedInboxClass(child) {
      const { type, phoneNumber } = child;
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
    },
    computedChildClass(child) {
      if (!child.truncateLabel) return '';
      return 'text-truncate';
    },
    computedChildTitle(child) {
      if (!child.truncateLabel) return false;
      return child.label;
    },
    newLinkClick(item) {
      if (item.newLinkRouteName) {
        router.push({ name: item.newLinkRouteName, params: { page: 'new' } });
      } else if (item.showModalForNewItem) {
        if (item.modalName === 'AddLabel') {
          this.$emit('add-label');
        }
      }
    },
    handleKeyEvents(e) {
      if (hasPressedAltAndCKey(e)) {
        router.push({ name: 'home' });
      }
      if (hasPressedAltAndVKey(e)) {
        router.push({ name: 'contacts_dashboard' });
      }
      if (hasPressedAltAndRKey(e)) {
        router.push({ name: 'settings_account_reports' });
      }
      if (hasPressedAltAndSKey(e)) {
        router.push({ name: 'settings_home' });
      }
    },
    showItem(item) {
      return this.isAdmin && item.newLink !== undefined;
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.sub-menu-title {
  display: flex;
  justify-content: space-between;
}

.wrap {
  display: flex;
  align-items: center;
}

.label-color--display {
  border-radius: $space-smaller;
  height: $space-normal;
  margin-right: $space-small;
  min-width: $space-normal;
  width: $space-normal;
}

.inbox-icon {
  position: relative;
  top: -1px;
  &.ion-ios-email {
    font-size: var(--font-size-medium);
  }
}
</style>
