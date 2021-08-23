import { frontendURL } from '../helper/URLHelper';

export const getSidebarItems = accountId => ({
  common: {
    routes: [
      'home',
      'inbox_dashboard',
      'inbox_conversation',
      'conversation_through_inbox',
      'notifications_dashboard',
      'profile_settings',
      'profile_settings_index',
      'label_conversations',
      'conversations_through_label',
      'team_conversations',
      'conversations_through_team',
      'notifications_index',
    ],
    menuItems: {
      conversations: {
        icon: 'ion-chatbox-working',
        label: 'CONVERSATIONS',
        hasSubMenu: true,
        key: '',
        toState: frontendURL(`accounts/${accountId}/conversations`),
        toolTip: 'Conversation from all subscribed inboxes',
        toStateName: 'conversations',
        children: [
          {
            label: 'ALL_CONVERSATIONS',
            toState: frontendURL(`accounts/${accountId}/conversations`),
            toStateName: 'conversations',
          },
        ],
      },
      contacts: {
        icon: 'ion-person',
        label: 'CONTACTS',
        hasSubMenu: true,
        toState: frontendURL(`accounts/${accountId}/contacts`),
        toStateName: 'contacts_dashboard',
        children: [
          {
            label: 'ALL_CONTACTS',
            toState: frontendURL(`accounts/${accountId}/contacts`),
            toStateName: 'contacts_dashboard',
          },
        ],
      },
      notifications: {
        icon: 'ion-ios-bell',
        label: 'NOTIFICATIONS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/notifications`),
        toStateName: 'notifications_index',
      },
      report: {
        icon: 'ion-arrow-graph-up-right',
        label: 'REPORTS',
        hasSubMenu: true,
        toState: frontendURL(`accounts/${accountId}/reports`),
        toStateName: 'settings_account_reports',
        children: [
          {
            label: 'REPORTS_OVERVIEW',
            toState: frontendURL(`accounts/${accountId}/reports/overview`),
            toStateName: 'settings_account_reports',
          },
          {
            label: 'CSAT',
            toState: frontendURL(`accounts/${accountId}/reports/csat`),
            toStateName: 'csat_reports',
          },
        ],
      },
      campaigns: {
        icon: 'ion-speakerphone',
        label: 'CAMPAIGNS',
        hasSubMenu: true,
        toState: frontendURL(`accounts/${accountId}/campaigns`),
        toStateName: 'settings_account_campaigns',
        children: [
          {
            icon: 'ion-arrow-swap',
            label: 'ONGOING',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/campaigns/ongoing`),
            toStateName: 'settings_account_campaigns',
          },
          {
            icon: 'ion-radio-waves',
            label: 'ONE_OFF',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/campaigns/one_off`),
            toStateName: 'one_off',
          },
        ],
      },
      settings: {
        icon: 'ion-settings',
        label: 'SETTINGS',
        hasSubMenu: true,
        toState: frontendURL(`accounts/${accountId}/settings`),
        toStateName: 'settings_home',
        children: [
          {
            icon: 'ion-person-stalker',
            label: 'AGENTS',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/settings/agents`),
            toStateName: 'agent_list',
          },
          {
            icon: 'ion-ios-people',
            label: 'TEAMS',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/settings/teams`),
            toStateName: 'settings_teams_list',
          },
          {
            icon: 'ion-archive',
            label: 'INBOXES',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/settings/inboxes`),
            toStateName: 'settings_inbox_list',
          },
          {
            icon: 'ion-pricetags',
            label: 'LABELS',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/settings/labels`),
            toStateName: 'labels_list',
          },
          {
            icon: 'ion-chatbox-working',
            label: 'CANNED_RESPONSES',
            hasSubMenu: false,
            toState: frontendURL(
              `accounts/${accountId}/settings/canned-response`
            ),
            toStateName: 'canned_list',
          },
          {
            icon: 'ion-flash',
            label: 'INTEGRATIONS',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/settings/integrations`),
            toStateName: 'settings_integrations',
          },
          {
            icon: 'ion-asterisk',
            label: 'APPLICATIONS',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/settings/applications`),
            toStateName: 'settings_applications',
          },
          {
            icon: 'ion-gear-a',
            label: 'ACCOUNT_SETTINGS',
            hasSubMenu: false,
            toState: frontendURL(`accounts/${accountId}/settings/general`),
            toStateName: 'general_settings_index',
          },
        ],
      },
    },
  },
  conversations: {
    routes: [
      'conversations',
      'inbox_dashboard',
      'inbox_conversation',
      'conversation_through_inbox',
      'label_conversations',
      'conversations_through_label',
      'team_conversations',
      'conversations_through_team',
    ],
  },
  contacts: {
    routes: [
      'contacts_dashboard',
      'contacts_dashboard_manage',
      'contacts_labels_dashboard',
    ],
    menuItems: {
      back: {
        icon: 'ion-ios-arrow-back',
        label: 'HOME',
        hasSubMenu: false,
        toStateName: 'home',
        toState: frontendURL(`accounts/${accountId}/dashboard`),
      },
      contacts: {
        icon: 'ion-person',
        label: 'ALL_CONTACTS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/contacts`),
        toStateName: 'contacts_dashboard',
      },
    },
  },
  reports: {
    routes: ['settings_account_reports', 'csat_reports'],
    menuItems: {
      back: {
        icon: 'ion-ios-arrow-back',
        label: 'HOME',
        hasSubMenu: false,
        toStateName: 'home',
        toState: frontendURL(`accounts/${accountId}/dashboard`),
      },
      reportOverview: {
        icon: 'ion-arrow-graph-up-right',
        label: 'REPORTS_OVERVIEW',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/reports/overview`),
        toStateName: 'settings_account_reports',
      },
      csatReports: {
        icon: 'ion-happy',
        label: 'CSAT',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/reports/csat`),
        toStateName: 'csat_reports',
      },
    },
  },
  campaigns: {
    routes: ['settings_account_campaigns', 'one_off'],
    menuItems: {
      back: {
        icon: 'ion-ios-arrow-back',
        label: 'HOME',
        hasSubMenu: false,
        toStateName: 'home',
        toState: frontendURL(`accounts/${accountId}/dashboard`),
      },
      ongoingCampaigns: {
        icon: 'ion-arrow-swap',
        label: 'ONGOING',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/campaigns/ongoing`),
        toStateName: 'settings_account_campaigns',
      },
      onOffCampaigns: {
        icon: 'ion-radio-waves',
        label: 'ONE_OFF',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/campaigns/one_off`),
        toStateName: 'one_off',
      },
    },
  },
  settings: {
    routes: [
      'agent_list',
      'canned_list',
      'labels_list',
      'settings_inbox',
      'settings_inbox_new',
      'settings_inbox_list',
      'settings_inbox_show',
      'settings_inboxes_page_channel',
      'settings_inboxes_add_agents',
      'settings_inbox_finish',
      'settings_integrations',
      'settings_integrations_webhook',
      'settings_integrations_integration',
      'settings_applications',
      'settings_applications_webhook',
      'settings_applications_integration',
      'general_settings',
      'general_settings_index',
      'settings_teams_list',
      'settings_teams_new',
      'settings_teams_add_agents',
      'settings_teams_finish',
      'settings_teams_edit',
      'settings_teams_edit_members',
      'settings_teams_edit_finish',
    ],
    menuItems: {
      back: {
        icon: 'ion-ios-arrow-back',
        label: 'HOME',
        hasSubMenu: false,
        toStateName: 'home',
        toState: frontendURL(`accounts/${accountId}/dashboard`),
      },
      agents: {
        icon: 'ion-person-stalker',
        label: 'AGENTS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/agents/list`),
        toStateName: 'agent_list',
      },
      teams: {
        icon: 'ion-ios-people',
        label: 'TEAMS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/teams/list`),
        toStateName: 'settings_teams_list',
      },
      inboxes: {
        icon: 'ion-archive',
        label: 'INBOXES',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/inboxes/list`),
        toStateName: 'settings_inbox_list',
      },
      labels: {
        icon: 'ion-pricetags',
        label: 'LABELS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/labels/list`),
        toStateName: 'labels_list',
      },
      cannedResponses: {
        icon: 'ion-chatbox-working',
        label: 'CANNED_RESPONSES',
        hasSubMenu: false,
        toState: frontendURL(
          `accounts/${accountId}/settings/canned-response/list`
        ),
        toStateName: 'canned_list',
      },
      settings_integrations: {
        icon: 'ion-flash',
        label: 'INTEGRATIONS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/integrations`),
        toStateName: 'settings_integrations',
      },
      settings_applications: {
        icon: 'ion-asterisk',
        label: 'APPLICATIONS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/applications`),
        toStateName: 'settings_applications',
      },
      general_settings_index: {
        icon: 'ion-gear-a',
        label: 'ACCOUNT_SETTINGS',
        hasSubMenu: false,
        toState: frontendURL(`accounts/${accountId}/settings/general`),
        toStateName: 'general_settings_index',
      },
    },
  },
});
