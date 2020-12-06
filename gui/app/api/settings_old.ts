import Store, { Schema } from 'electron-store';
import { api } from 'electron-util';
import findFreePort from 'find-free-port';
import configSchema from '../constants/config-schema.json';
import { ConfigObjectType } from '../interfaces/settings';
import { AxiosHeaders, SimpleMapType } from '../interfaces/common';

export default {
  configStore: new Store({ schema: configSchema as Schema<ConfigObjectType> }),
  getConfig(): ConfigObjectType {
    return {
      configured: this.configStore.get('configured'),
      local: this.configStore.get('local'),
      apiProtocol: this.configStore.get('apiProtocol'),
      apiHostname: this.configStore.get('apiHostname'),
      apiPort: this.configStore.get('apiPort'),
      apiPath: this.configStore.get('apiPath'),
      publicPath: this.configStore.get('publicPath'),
      dataPath: this.configStore.get(
        'dataPath',
        `${api.app.getPath('home')}/.Oncoreport`
      ),
      socketPath: this.configStore.get('socketPath'),
      containerName: this.configStore.get('containerName'),
      apiKey: this.configStore.get('apiKey'),
      autoStopDockerOnClose: this.configStore.get('autoStopDockerOnClose'),
    };
  },
  autoStopDockerOnClose(): boolean {
    return this.configStore.get('autoStopDockerOnClose') || false;
  },
  setAutoStopDockerOnClose(): void {
    const newConfig = {
      ...this.getConfig(),
      autoStopDockerOnClose: true,
    };
    this.configStore.set(newConfig);
  },
  isConfigured(): boolean {
    return this.configStore.get('configured') || false;
  },
  isLocal(): boolean {
    return this.configStore.get('local');
  },
  getApiUrl(): string {
    const config = this.getConfig();
    const path = config.apiPath.replace(/^\/|\/$/gm, '');
    return `${config.apiProtocol}://${config.apiHostname}:${config.apiPort}/${path}/`;
  },
  getPublicUrl(p = ''): string {
    const config = this.getConfig();
    const path = config.publicPath.replace(/^\/|\/$/gm, '');
    return `${config.apiProtocol}://${config.apiHostname}:${
      config.apiPort
    }/${path}/${p ? p.replace(/^\//, '') : ''}`;
  },
  getLocalPath(p = ''): string {
    const config = this.getConfig();
    return `${config.dataPath}/${p ? p.replace(/^\//, '') : ''}`;
  },
  getAuthHeaders(): SimpleMapType<string> {
    return {
      Authorization: `Bearer ${this.getConfig().apiKey}`,
    };
  },
  getAxiosHeaders(): AxiosHeaders {
    return {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...this.getAuthHeaders(),
      },
    };
  },
  saveConfig(config: ConfigObjectType) {
    return this.configStore.set(config);
  },
  async findFreePort(start: number): Promise<number> {
    const [port] = await findFreePort(start);
    return port;
  },
};
