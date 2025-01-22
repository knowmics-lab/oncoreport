import ApiError from './ApiError';
import { RecursiveMapType } from '../interfaces';

export default class ApiValidationError extends ApiError {
  constructor(
    message: string,
    public validationErrors?: RecursiveMapType<string>,
  ) {
    super(message);
    this.name = 'ApiValidationError';
  }
}
