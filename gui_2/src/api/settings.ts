import Store from 'electron-store';
import { api, is } from 'electron-util';
import findFreePort from 'find-free-port';
import { singleton } from 'tsyringe';
import { ipcRenderer } from 'electron';
import uniqid from 'uniqid';
import type {
  AxiosHeaders,
  ConfigObjectType,
  SimpleMapType,
} from '../interfaces';
import { ApiProtocol } from '../interfaces';

type Listener = (config: ConfigObjectType) => void;

@singleton()
export default class Settings {
  private config: ConfigObjectType | undefined = undefined;

  private listeners = new Map<string, Listener>();

  constructor(private configStore: Store<ConfigObjectType>) {}

  public reset(): this {
    this.config = undefined;
    this.notify();
    return this;
  }

  // eslint-disable-next-line class-methods-use-this
  public getDefaultConfig(apiPort: number): ConfigObjectType {
    return {
      local: true,
      apiProtocol: ApiProtocol.http,
      apiHostname: 'localhost',
      apiPort,
      apiPath: '/api/',
      publicPath: '/storage/',
      dataPath: `${api.app.getPath('home')}/.Oncoreport`,
      socketPath: is.windows
        ? '//./pipe/docker_engine'
        : '/var/run/docker.sock',
      containerName: 'OncoReport',
      apiKey: '',
    };
  }

  public getConfig(): ConfigObjectType {
    if (!this.config) {
      this.config = {
        configured: this.configStore.get('configured'),
        local: this.configStore.get('local'),
        apiProtocol: this.configStore.get('apiProtocol'),
        apiHostname: this.configStore.get('apiHostname'),
        apiPort: this.configStore.get('apiPort'),
        apiPath: this.configStore.get('apiPath'),
        publicPath: this.configStore.get('publicPath'),
        dataPath: this.configStore.get(
          'dataPath',
          `${api.app.getPath('home')}/.Oncoreport`,
        ),
        socketPath: this.configStore.get('socketPath'),
        containerName: this.configStore.get('containerName'),
        apiKey: this.configStore.get('apiKey'),
        autoStopDockerOnClose: this.configStore.get('autoStopDockerOnClose'),
      };
    }
    return this.config;
  }

  public autoStopDockerOnClose(): boolean {
    return this.configStore.get('autoStopDockerOnClose') || false;
  }

  public setAutoStopDockerOnClose(): this {
    return this.saveConfig({
      autoStopDockerOnClose: true,
    });
  }

  public isConfigured(): boolean {
    return this.configStore.get('configured') || false;
  }

  public isLocal(): boolean {
    return this.configStore.get('local');
  }

  public getApiUrl(): string {
    const config = this.getConfig();
    const path = config.apiPath.replace(/^\/|\/$/gm, '');
    return `${config.apiProtocol}://${config.apiHostname}:${config.apiPort}/${path}/`;
  }

  public getPublicUrl(p = ''): string {
    const config = this.getConfig();
    const path = config.publicPath.replace(/^\/|\/$/gm, '');
    return `${config.apiProtocol}://${config.apiHostname}:${
      config.apiPort
    }/${path}/${p ? p.replace(/^\//, '') : ''}`;
  }

  public getLocalPath(p = ''): string {
    const config = this.getConfig();
    return `${config.dataPath}/${p ? p.replace(/^\//, '') : ''}`;
  }

  public getAuthHeaders(): SimpleMapType<string> {
    return {
      Authorization: `Bearer ${this.getConfig().apiKey}`,
    };
  }

  public getAxiosHeaders(): AxiosHeaders {
    return {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...this.getAuthHeaders(),
      },
    };
  }

  public setConfig(config: Partial<ConfigObjectType>): this {
    this.config = {
      ...this.getConfig(),
      ...config,
    };
    this.notify();
    return this;
  }

  public saveConfig(config: Partial<ConfigObjectType>): this {
    this.configStore.set({
      ...this.getConfig(),
      ...config,
    });
    this.reset();
    return this;
  }

  // eslint-disable-next-line class-methods-use-this
  public async findFreePort(start: number): Promise<number> {
    const [port] = await findFreePort(start);
    return port;
  }

  // eslint-disable-next-line @typescript-eslint/ban-types
  public subscribe(l: Listener): string {
    const id = uniqid();
    this.listeners.set(id, l);
    return id;
  }

  // eslint-disable-next-line @typescript-eslint/ban-types
  public unsubscribe(id: string): this {
    if (this.listeners.has(id)) this.listeners.delete(id);
    return this;
  }

  private notify(): void {
    if (this.listeners.size > 0) {
      const cfg = this.getConfig();
      this.listeners.forEach((l) => l(cfg));
    }
    if (is.renderer) {
      ipcRenderer.send('config-change');
    }
  }
}
