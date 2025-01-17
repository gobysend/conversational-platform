/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */

import Cookies from 'js-cookie';
import endPoints from './endPoints';
import { setAuthCredentials, clearCookiesOnLogout } from '../store/utils/api';

export default {
  login(creds) {
    return new Promise((resolve, reject) => {
      axios
        .post('auth/sign_in', creds)
        .then(response => {
          setAuthCredentials(response);
          resolve(response.data.data);
        })
        .catch(error => {
          reject(error.response);
        });
    });
  },

  register(creds) {
    const urlData = endPoints('register');
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, {
          account_name: creds.accountName.trim(),
          user_full_name: creds.fullName.trim(),
          email: creds.email,
          password: creds.password,
          h_captcha_client_response: creds.hCaptchaClientResponse,
        })
        .then(response => {
          setAuthCredentials(response);
          resolve(response);
        })
        .catch(error => {
          reject(error);
        });
    });
    return fetchPromise;
  },
  validityCheck() {
    const urlData = endPoints('validityCheck');
    return axios.get(urlData.url);
  },
  logout() {
    const urlData = endPoints('logout');
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .delete(urlData.url)
        .then(response => {
          clearCookiesOnLogout();
          resolve(response);
        })
        .catch(error => {
          reject(error);
        });
    });
    return fetchPromise;
  },

  isLoggedIn() {
    const hasAuthCookie = !!Cookies.getJSON('auth_data');
    //const hasUserCookie = !!Cookies.getJSON('user');
    const hasUserCookie = !!localStorage.getItem('user');
    return hasAuthCookie && hasUserCookie;
  },

  isAdmin() {
    if (this.isLoggedIn()) {
      //return Cookies.getJSON('user').role === 'administrator';
      return JSON.parse(localStorage.getItem('user')).role === 'administrator';
    }
    return false;
  },

  getAuthData() {
    if (this.isLoggedIn()) {
      return Cookies.getJSON('auth_data');
    }
    return false;
  },
  getPubSubToken() {
    if (this.isLoggedIn()) {
      //const user = Cookies.getJSON('user') || {};
      const user = JSON.parse(localStorage.getItem('user')) || {};
      const { pubsub_token: pubsubToken } = user;
      return pubsubToken;
    }
    return null;
  },
  getCurrentUser() {
    if (this.isLoggedIn()) {
      //return Cookies.getJSON('user');
      return JSON.parse(localStorage.getItem('user'));
    }
    return null;
  },

  verifyPasswordToken({ confirmationToken }) {
    return new Promise((resolve, reject) => {
      axios
        .post('auth/confirmation', {
          confirmation_token: confirmationToken,
        })
        .then(response => {
          setAuthCredentials(response);
          resolve(response);
        })
        .catch(error => {
          reject(error.response);
        });
    });
  },

  setNewPassword({ resetPasswordToken, password, confirmPassword }) {
    return new Promise((resolve, reject) => {
      axios
        .put('auth/password', {
          reset_password_token: resetPasswordToken,
          password_confirmation: confirmPassword,
          password,
        })
        .then(response => {
          setAuthCredentials(response);
          resolve(response);
        })
        .catch(error => {
          reject(error.response);
        });
    });
  },

  resetPassword({ email }) {
    const urlData = endPoints('resetPassword');
    return axios.post(urlData.url, { email });
  },

  profileUpdate({
    password,
    password_confirmation,
    displayName,
    avatar,
    ...profileAttributes
  }) {
    const formData = new FormData();
    Object.keys(profileAttributes).forEach(key => {
      const hasValue = profileAttributes[key] === undefined;
      if (!hasValue) {
        formData.append(`profile[${key}]`, profileAttributes[key]);
      }
    });
    formData.append('profile[display_name]', displayName || '');
    if (password && password_confirmation) {
      formData.append('profile[password]', password);
      formData.append('profile[password_confirmation]', password_confirmation);
    }
    if (avatar) {
      formData.append('profile[avatar]', avatar);
    }
    return axios.put(endPoints('profileUpdate').url, formData);
  },

  updateUISettings({ uiSettings }) {
    return axios.put(endPoints('profileUpdate').url, {
      profile: { ui_settings: uiSettings },
    });
  },

  updateAvailability(availabilityData) {
    return axios.post(endPoints('availabilityUpdate').url, {
      profile: { ...availabilityData },
    });
  },

  deleteAvatar() {
    return axios.delete(endPoints('deleteAvatar').url);
  },
};
