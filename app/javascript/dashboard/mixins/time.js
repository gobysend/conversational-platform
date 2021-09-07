import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import formatDistanceToNow from 'date-fns/formatDistanceToNow';
import { vi } from 'date-fns/locale';

export default {
  methods: {
    messageStamp(time, dateFormat = 'HH:mm') {
      const unixTime = fromUnixTime(time);

      if (window.chatwootConfig.selectedLocale === 'vi') {
        return format(unixTime, dateFormat, { locale: vi });
      }

      return format(unixTime, dateFormat);
    },

    dynamicTime(time) {
      const unixTime = fromUnixTime(time);

      if (window.chatwootConfig.selectedLocale === 'vi') {
        return formatDistanceToNow(unixTime, { addSuffix: true, locale: vi });
      }

      return formatDistanceToNow(unixTime, { addSuffix: true });
    },
  },
};
