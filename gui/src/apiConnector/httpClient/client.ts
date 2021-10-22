import axios, { AxiosError, AxiosResponse, Method } from 'axios';
import { set } from 'lodash';
import { singleton } from 'tsyringe';
import Settings from '../../api/settings';
import { MapType, Nullable } from '../interfaces/common';
import ApiError from '../../errors/ApiError';
import { HttpResponse, ValidationErrorType } from './interfaces/httpResponse';

function validationErrorParser(
  obj: ValidationErrorType,
  suppress: string[] = []
): ValidationErrorType {
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

function parseErrorResponse<T>(
  response: AxiosResponse
): Nullable<HttpResponse<T>> {
  if (response.status && response.status === 422) {
    const validationErrors = validationErrorParser(response.data.errors, [
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

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

@singleton()
export default class Client {
  constructor(private settings: Settings) {}

  private async call<T>(
    url: string,
    method: Method,
    config: MapType,
    retry = 10
  ): Promise<HttpResponse<T>> {
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
      if ((e as AxiosError<T>).response) {
        const { response } = e as AxiosError<T>;
        if (response) {
          const parsedResponse = parseErrorResponse<T>(response);
          if (!parsedResponse) {
            await delay(10000);
            return this.call(url, method, config, retry - 1);
          }
          return parsedResponse;
        }
      }
      throw e;
    }
  }

  public getEndpointUrl(endpoint: string): string {
    return `${this.settings.getApiUrl()}${endpoint.replace(/^\//gm, '')}`;
  }

  public async get<T>(
    endpoint: string,
    params: MapType = {},
    config: MapType = {}
  ): Promise<HttpResponse<T>> {
    return this.call<T>(this.getEndpointUrl(endpoint), 'get', {
      ...config,
      params,
    });
  }

  public async post<T>(
    endpoint: string,
    params: MapType = {},
    config: MapType = {}
  ): Promise<HttpResponse<T>> {
    return this.call<T>(this.getEndpointUrl(endpoint), 'post', {
      ...config,
      data: params,
    });
  }

  public async patch<T>(
    endpoint: string,
    params: MapType = {},
    config: MapType = {}
  ): Promise<HttpResponse<T>> {
    return this.call<T>(this.getEndpointUrl(endpoint), 'patch', {
      ...config,
      data: params,
    });
  }

  public async delete(
    endpoint: string,
    params: MapType = {},
    config: MapType = {}
  ): Promise<HttpResponse<void>> {
    return this.call(this.getEndpointUrl(endpoint), 'delete', {
      ...config,
      params,
    });
  }
}
