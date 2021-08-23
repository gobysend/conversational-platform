/* global axios */
import ApiClient from '../ApiClient';

class WebChannel extends ApiClient {
  constructor() {
    super('zalo_callbacks', { accountScoped: true });
  }

  create(params) {
    return axios.post(
      `${this.url.replace(this.resource, '')}zalo_callbacks/register_zalo_oa`,
      params
    );
  }
}

export default new WebChannel();
