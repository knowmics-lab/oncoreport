/* eslint-disable camelcase */
// @flow
import Connector from './connector';
import { Disease, DiseasesCollection } from '../interfaces/diseases';
import { MetaResponseType } from '../interfaces/common';
import ApiError from '../errors/ApiError';

interface ApiResponseSingle {
  data: Omit<Disease, 'links'>;
  links: Disease['links'];
}

type ApiResponseCollection = DiseasesCollection & {
  meta: MetaResponseType;
};

export default {
  async fetchById(id: number): Promise<Disease> {
    const result = await Connector.callGet<ApiResponseSingle>(`diseases/${id}`);
    if (!result.data) throw new ApiError('Unable to fetch the disease');
    const { data, links } = result.data;
    return {
      ...data,
      links,
    };
  },
  async fetch(): Promise<Disease[]> {
    const result = await Connector.callGet<ApiResponseCollection>(`diseases`);
    if (!result.data) throw new ApiError('Unable to fetch diseases');
    return result.data.data.map((d) => ({
      ...d,
      links: {
        self: d.self_link,
      },
    }));
  },
};
