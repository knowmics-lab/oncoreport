declare module 'check-internet-connected' {
  export type CheckInternetConnectedConfig = {
    timeout?: number;
    retries?: number;
    domain?: string;
  };

  export default function checkInternetConnected(
    config?: CheckInternetConnectedConfig,
  ): Promise<boolean>;
}
