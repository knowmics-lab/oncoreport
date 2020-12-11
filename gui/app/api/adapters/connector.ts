import axios, { AxiosResponse, Method } from 'axios';
import { set } from 'lodash';
import { singleton } from 'tsyringe';
import Settings from '../settings';
import {
  MapType,
  Nullable,
  RecursiveMapType,
  ResponseType,
} from '../../interfaces';
import ApiError from '../../errors/ApiError';

@singleton()
export default class Connector {
  constructor(private settings: Settings) {}

  private static dotParser(
    obj: RecursiveMapType<string>,
    suppress: string[] = []
  ): RecursiveMapType<string> {
    const rxp = new RegExp(suppress.join('|'));
    const res = {};
    // eslint-disable-next-line no-restricted-syntax
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
      throw new ApiError(response.data.message);
    }
    throw new ApiError('Unknown error');
  }

  private static delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  private async call<T>(
    url: string,
    method: Method,
    config: MapType,
    retry = 10
  ): Promise<ResponseType<T>> {
    if (retry < 0) throw new ApiError('Too many retries');
    try {
      const { data } = await axios.request({
        method,
        url,
        ...config,
        ...this.settings.getAxiosHeaders(),
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
          return this.call(url, method, config, retry - 1);
        }
        return parsedResponse;
      }
      throw e;
    }
  }

  // eslint-disable-next-line class-methods-use-this
  public getEndpointUrl(endpoint: string): string {
    return `${this.settings.getApiUrl()}${endpoint.replace(/^\//gm, '')}`;
  }

  public async callGet<T>(
    endpoint: string,
    params: MapType = {}
  ): Promise<ResponseType<T>> {
    return this.call(this.getEndpointUrl(endpoint), 'get', {
      params,
    });
  }

  public async callPost<T>(
    endpoint: string,
    params: MapType = {}
  ): Promise<ResponseType<T>> {
    return this.call(this.getEndpointUrl(endpoint), 'post', {
      data: params,
    });
  }

  public async callPatch<T>(
    endpoint: string,
    params: MapType = {}
  ): Promise<ResponseType<T>> {
    return this.call(this.getEndpointUrl(endpoint), 'patch', {
      data: params,
    });
  }

  public async callDelete<T>(
    endpoint: string,
    params: MapType = {}
  ): Promise<ResponseType<T>> {
    return this.call(this.getEndpointUrl(endpoint), 'delete', {
      params,
    });
  }
}
