/* eslint-disable @typescript-eslint/no-explicit-any */
export type ValidationErrorType = {
  [name: string]: string | ValidationErrorType;
};

export interface HttpResponse<T = any> {
  readonly validationErrors?: ValidationErrorType;
  readonly data?: T;
}
