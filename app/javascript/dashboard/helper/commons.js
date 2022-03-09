/* eslint no-param-reassign: 0 */

import getUuid from 'widget/helpers/uuid';
import { MESSAGE_STATUS, MESSAGE_TYPE } from 'shared/constants/messages';

export default () => {
  if (!Array.prototype.last) {
    Object.assign(Array.prototype, {
      last() {
        return this[this.length - 1];
      },
    });
  }
};

export const isEmptyObject = obj =>
  Object.keys(obj).length === 0 && obj.constructor === Object;

export const isJSONValid = value => {
  try {
    JSON.parse(value);
  } catch (e) {
    return false;
  }
  return true;
};

export const getTypingUsersText = (users = []) => {
  const count = users.length;
  if (count === 1) {
    const [user] = users;
    return `${user.name} is typing`;
  }

  if (count === 2) {
    const [first, second] = users;
    return `${first.name} and ${second.name} are typing`;
  }

  const [user] = users;
  const rest = users.length - 1;
  return `${user.name} and ${rest} others are typing`;
};

export const createPendingMessage = data => {
  const timestamp = Math.floor(new Date().getTime() / 1000);
  const tempMessageId = getUuid();
  const { message, file } = data;
  const tempAttachments = [{ id: tempMessageId }];
  const pendingMessage = {
    ...data,
    content: message || null,
    id: tempMessageId,
    echo_id: tempMessageId,
    status: MESSAGE_STATUS.PROGRESS,
    created_at: timestamp,
    message_type: MESSAGE_TYPE.OUTGOING,
    conversation_id: data.conversationId,
    attachments: file ? tempAttachments : null,
  };

  return pendingMessage;
};

export const convertToSlug = (str, separator = '_') => {
  str = str.trim();
  str = str.toLowerCase();

  // remove accents, swap ñ for n, etc
  const from =
    'åàáãảạäăặâậấầẩẫắằèéẽëẹẻêệềếểễìíĩịïîỉĩýỳỵỷỹòóọöôộỗốồổơợớờỡụùúũủưửứừựữüûñçđ·/_,:;';
  const to =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeeiiiiiiiiyyyyyooooooooooooooouuuuuuuuuuuuuncd------';

  for (let i = 0, l = from.length; i < l; i++) {
    str = str.replace(new RegExp(from.charAt(i), 'g'), to.charAt(i));
  }

  return str
    .replace(/[^a-z0-9 -]/g, '') // remove invalid chars
    .replace(/\s+/g, '-') // collapse whitespace and replace by -
    .replace(/-+/g, '-') // collapse dashes
    .replace(/^-+/, '') // trim - from start of text
    .replace(/-+$/, '') // trim - from end of text
    .replace(/-/g, separator);
};
