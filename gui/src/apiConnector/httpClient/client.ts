import axios, {
  AxiosError,
  AxiosRequestConfig,
  AxiosResponse,
  Method,
} from 'axios';
import { set } from 'lodash';
import { singleton } from 'tsyringe';
import Settings from '../../api/settings';
import { MapType } from '../interfaces/common';
import ApiError from '../../errors/ApiError';
import { ValidationErrorType } from './interfaces/httpResponse';
import ApiValidationError from '../../errors/ApiValidationError';

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

/**
 * Process an api error response and returns the corresponding application error.
 * If the response is a 504 error, the connection to the server might be unavailable.
 *
 * @param response - The response object inside an axios error
 * @throws {ApiError} - A generic error caused by the API
 * @throws {ApiValidationError} - A validation error caused by a 422 status code
 */
function parseErrorResponse(response: AxiosResponse) {
  const status = response.status ?? 0;
  if (status === 504) return null;
  if (status === 422) {
    throw new ApiValidationError(
      'Error occurred during validation of input data',
      validationErrorParser(response.data.errors, ['^parameters'])
    );
  }
  if (response.data && response.data.message) {
    throw new ApiError(response.data.message);
  }
  throw new ApiError('Unknown error');
}

/**
 * Apply a delay to an async function
 *
 * @param {number} ms - the delay in milliseconds
 */
function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

type PartialAxiosConfig = Omit<
  AxiosRequestConfig,
  'url' | 'method' | 'baseURL' | 'headers' | 'responseType'
>;

@singleton()
export default class Client {
  constructor(private settings: Settings) {}

  /**
   * Call an API endpoint and returns the parsed results
   * @param url - the API endpoint
   * @param method - the HTTP method
   * @param config - a config object for the axios object
   * @param retry - the number of times the call will be retried on a 504 error
   * @private
   */
  private async call<T>(
    url: string,
    method: Method,
    config: PartialAxiosConfig,
    retry = 10
  ): Promise<T> {
    if (retry < 0) throw new ApiError('Too many retries');
    try {
      const { data } = await axios.request({
        method,
        url,
        ...config,
        ...this.settings.getAxiosHeaders(),
      });
      return data;
    } catch (e) {
      if ((e as AxiosError<T>).response) {
        const { response } = e as AxiosError<T>;
        if (response && parseErrorResponse(response) === null) {
          await delay(10000);
          return this.call(url, method, config, retry - 1);
        }
      }
      throw e;
    }
  }

  /**
   * Get the absolute URL of an endpoint
   * @param endpoint - the endpoint
   */
  public getEndpointUrl(endpoint: string): string {
    return `${this.settings.getApiUrl()}${endpoint.replace(/^\//gm, '')}`;
  }

  /**
   * Performs a GET request to an API endpoint
   * @param endpoint - the api endpoint
   * @param params - an optional map of GET parameters
   * @param config - an optional config object for the axios object
   */
  public async get<T>(
    endpoint: string,
    params: MapType = {},
    config: PartialAxiosConfig = {}
  ): Promise<T> {
    return this.call<T>(this.getEndpointUrl(endpoint), 'get', {
      ...config,
      params,
    });
  }

  /**
   * Performs a POST request to an API endpoint
   * @param endpoint - the api endpoint
   * @param params - an optional map of POST parameters
   * @param config - an optional config object for the axios object
   */
  public async post<T>(
    endpoint: string,
    params: MapType = {},
    config: PartialAxiosConfig = {}
  ): Promise<T> {
    return this.call<T>(this.getEndpointUrl(endpoint), 'post', {
      ...config,
      data: params,
    });
  }

  /**
   * Performs a PATCH request to an API endpoint
   * @param endpoint - the api endpoint
   * @param params - an optional map of PATCH parameters
   * @param config - an optional config object for the axios object
   */
  public async patch<T>(
    endpoint: string,
    params: MapType = {},
    config: PartialAxiosConfig = {}
  ): Promise<T> {
    return this.call<T>(this.getEndpointUrl(endpoint), 'patch', {
      ...config,
      data: params,
    });
  }

  /**
   * Performs a DELETE request to an API endpoint
   * @param endpoint - the api endpoint
   * @param params - an optional map of DELETE parameters
   * @param config - an optional config object for the axios object
   */
  public async delete(
    endpoint: string,
    params: MapType = {},
    config: PartialAxiosConfig = {}
  ): Promise<void> {
    return this.call(this.getEndpointUrl(endpoint), 'delete', {
      ...config,
      params,
    });
  }
}
