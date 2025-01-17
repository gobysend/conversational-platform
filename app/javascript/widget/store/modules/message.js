import MessageAPI from '../../api/message';

const state = {
  uiFlags: {
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  update: async (
    { commit, dispatch },
    { email, messageId, submittedValues }
  ) => {
    commit('toggleUpdateStatus', true);
    try {
      await MessageAPI.update({
        email,
        messageId,
        values: submittedValues,
      });
      commit(
        'conversation/updateMessage',
        {
          id: messageId,
          content_attributes: {
            submitted_email: email,
            submitted_values: email ? null : submittedValues,
          },
        },
        { root: true }
      );
      dispatch('contacts/get', {}, { root: true });
    } catch (error) {
      // Ignore error
    }
    commit('toggleUpdateStatus', false);
  },

  updatePhone: async (
    { commit, dispatch },
    { phoneNumber, messageId, submittedValues }
  ) => {
    commit('toggleUpdateStatus', true);
    try {
      await MessageAPI.updatePhone({
        phoneNumber,
        messageId,
        values: submittedValues,
      });
      commit(
        'conversation/updateMessage',
        {
          id: messageId,
          content_attributes: {
            submitted_phone: phoneNumber,
            submitted_values: phoneNumber ? null : submittedValues,
          },
        },
        { root: true }
      );
      dispatch('contacts/get', {}, { root: true });
    } catch (error) {
      // Ignore error
    }
    commit('toggleUpdateStatus', false);
  },
};

export const mutations = {
  toggleUpdateStatus($state, status) {
    $state.uiFlags.isUpdating = status;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
