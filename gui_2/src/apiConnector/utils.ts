/* eslint-disable import/prefer-default-export */
export function ignorePromise<T>(p: Promise<T>): void {
  p.catch((e) => {
    throw e;
  });
}
