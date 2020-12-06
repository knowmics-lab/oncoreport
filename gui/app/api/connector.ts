/* eslint-disable no-restricted-syntax,no-plusplus */
import axios, { AxiosResponse, Method } from 'axios';
import { set } from 'lodash';
import Settings from './settings';
import {
  MapType,
  Nullable,
  RecursiveMapType,
  ResponseType,
} from '../interfaces/common';

class Connector {
  private static dotParser(
    obj: RecursiveMapType<string>,
    suppress: string[] = []
  ): RecursiveMapType<string> {
    const rxp = new RegExp(suppress.join('|'));
    const res = {};
    for (const [k, v] of Object.entries(obj)) {
      const sanitized = k.replace(rxp, '').replace(/^\./, '');
      const val = Array.isArray(v) && v.length ? v[0] : v;
      if (sanitized) {
        set(res, sanitized, val);
      }
    }
    return res;
  }

  private static parseErrorResponse<T>(
    response: AxiosResponse
  ): Nullable<ResponseType<T>> {
    if (response.status && response.status === 422) {
      const validationErrors = Connector.dotParser(response.data.errors, [
        '^parameters',
      ]);
      return {
        validationErrors,
      };
    }
    if (response.status && response.status === 504) {
      return null;
    }
    if (response.data && response.data.message) {
      throw new Error(response.data.message);
    }
    throw new Error('Unknown error');
  }

  private static delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  private static async call<T>(
    url: string,
    method: Method,
    config: MapType,
    retry = 10
  ): Promise<ResponseType<T>> {
    if (retry < 0) throw new Error('Too many retries');
    try {
      const { data } = await axios.request({
        method,
        url,
        ...config,
        ...Settings.getAxiosHeaders(),
      });
      return {
        data,
      };
    } catch (e) {
      if (e.response) {
        const { response } = e;
        const parsedResponse = Connector.parseErrorResponse(
          response
        ) as Nullable<ResponseType<T>>;
        if (!parsedResponse) {
          await Connector.delay(10000);
          return Connector.call(url, method, config, retry - 1);
        }
        return parsedResponse;
      }
      throw e;
    }
  }

  // eslint-disable-next-line class-methods-use-this
  public getEndpointUrl(endpoint: string): string {
    return `${Settings.getApiUrl()}${endpoint.replace(/^\//gm, '')}`;
  }

  public async callGet<T>(
    endpoint: string,
    params: MapType = {}
  ): Promise<ResponseType<T>> {
    return Connector.call(this.getEndpointUrl(endpoint), 'get', {
      params,
    });
  }

  public async callPost<T>(
    endpoint: string,
    params: MapType = {}
  ): Promise<ResponseType<T>> {
    return Connector.call(this.getEndpointUrl(endpoint), 'post', {
      data: params,
    });
  }

  public async callPatch<T>(
    endpoint: string,
    params: MapType = {}
  ): Promise<ResponseType<T>> {
    return Connector.call(this.getEndpointUrl(endpoint), 'patch', {
      data: params,
    });
  }

  public async callDelete<T>(
    endpoint: string,
    params: MapType = {}
  ): Promise<ResponseType<T>> {
    return Connector.call(this.getEndpointUrl(endpoint), 'delete', {
      params,
    });
  }
}

export default new Connector();
