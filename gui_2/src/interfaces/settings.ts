import { ApiProtocol } from './enums';

export interface ConfigObjectType {
  readonly configured?: boolean;
  readonly local: boolean;
  readonly apiProtocol: ApiProtocol;
  readonly apiHostname: string;
  readonly apiPort: number;
  readonly apiPath: string;
  readonly publicPath: string;
  readonly dataPath: string;
  readonly containerName: string;
  readonly apiKey: string;
  readonly socketPath?: string;
  readonly autoStopDockerOnClose?: boolean;
}
