import { ModifiableStateType, Nullable } from './common';

export interface ConfigObjectType {
  readonly configured?: boolean;
  readonly local: boolean;
  readonly apiProtocol: 'http' | 'https';
  readonly apiHostname: string;
  readonly apiPort: number;
  readonly apiPath: string;
  readonly publicPath: string;
  readonly dataPath: string;
  readonly containerName: string;
  readonly apiKey: string;
  readonly socketPath?: Nullable<string>;
  readonly autoStopDockerOnClose?: boolean;
}

export interface ConfigObjectWithState extends ConfigObjectType {
  readonly state: ModifiableStateType;
}

export type SettingsStateType = {
  readonly settings: ConfigObjectWithState;
};
