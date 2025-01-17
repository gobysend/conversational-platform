/* eslint no-param-reassign: 0 */
import fromUnixTime from 'date-fns/fromUnixTime';
import differenceInDays from 'date-fns/differenceInDays';
import Cookies from 'js-cookie';
import { frontendURL } from '../../helper/URLHelper';
import {
  ANALYTICS_IDENTITY,
  ANALYTICS_RESET,
  CHATWOOT_RESET,
  CHATWOOT_SET_USER,
} from '../../helper/scriptHelpers';

Cookies.defaults = { sameSite: 'Lax' };

export const getLoadingStatus = state => state.fetchAPIloadingStatus;
export const setLoadingStatus = (state, status) => {
  state.fetchAPIloadingStatus = status;
};

export const setUser = (user, expiryDate, options = {}) => {
  if (options && options.setUserInSDK) {
    window.bus.$emit(CHATWOOT_SET_USER, { user });
    window.bus.$emit(ANALYTICS_IDENTITY, { user });
  }
  // Cookies.set('user', user, {
  //   expires: differenceInDays(expiryDate, new Date()),
  // });
  localStorage.setItem('user', JSON.stringify(user));
};

export const getHeaderExpiry = response =>
  fromUnixTime(response.headers.expiry);

export const setAuthCredentials = response => {
  const expiryDate = getHeaderExpiry(response);
  Cookies.set('auth_data', response.headers, {
    expires: differenceInDays(expiryDate, new Date()),
  });

  setUser(response.data.data, expiryDate);

  //Share cookie
  let host, domainParts, domain;
  host = location.host;
  if (host.split('.').length > 1) {
    domainParts = host.split('.');
    domainParts.shift();
    domain = '.' + domainParts.join('.');
  }
  Cookies.set('chat_auth_data', response.headers, { domain });
};

export const clearBrowserSessionCookies = () => {
  Cookies.remove('auth_data');
  Cookies.remove('user');
};

export const clearCookiesOnLogout = () => {
  window.bus.$emit(CHATWOOT_RESET);
  window.bus.$emit(ANALYTICS_RESET);

  clearBrowserSessionCookies();
  window.location.href =
    window.chatwootConfig.admin_frontend_url + '/login?auto_logout=true';
};
