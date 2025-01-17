import { frontendURL } from '../../../../helper/URLHelper';

const primaryMenuItems = accountId => [
  {
    icon: 'chat',
    key: 'conversations',
    label: 'CONVERSATIONS',
    toState: frontendURL(`accounts/${accountId}/dashboard`),
    toStateName: 'home',
    roles: ['administrator', 'agent'],
  },
  // {
  //   icon: 'book-contacts',
  //   key: 'contacts',
  //   label: 'CONTACTS',
  //   toState: frontendURL(`accounts/${accountId}/contacts`),
  //   toStateName: 'contacts_dashboard',
  //   roles: ['administrator', 'agent'],
  // },
  {
    icon: 'arrow-trending-lines',
    key: 'reports',
    label: 'REPORTS',
    toState: frontendURL(`accounts/${accountId}/reports`),
    toStateName: 'settings_account_reports',
    roles: ['administrator'],
  },
  {
    icon: 'megaphone',
    key: 'campaigns',
    label: 'AUTOMATED',
    toState: frontendURL(`accounts/${accountId}/campaigns`),
    toStateName: 'settings_account_campaigns',
    roles: ['administrator'],
  },
  {
    icon: 'settings',
    key: 'settings',
    label: 'SETTINGS',
    toState: frontendURL(`accounts/${accountId}/settings`),
    toStateName: 'settings_home',
    roles: ['administrator', 'agent'],
  },
  {
    icon: 'alert',
    key: 'notifications',
    label: 'NOTIFICATIONS',
    toState: frontendURL(`accounts/${accountId}/notifications`),
    toStateName: 'notifications',
    roles: ['administrator', 'agent'],
  },
];

export default primaryMenuItems;
