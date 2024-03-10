import { singleton } from 'tsyringe';
import { ipcRenderer } from 'electron';
import uniqid from 'uniqid';
import fs from 'fs-extra';
import { is } from './utils';
import Settings from './settings';

type OncoKbConfigType = {
  oncoKbApiKey: string;
  ncbiApiKey: string;
};

type OncoKbListener = (config: OncoKbConfigType | undefined) => void;

function unquoteString(s: string): string {
  if (s.match(/^".+"$/)) {
    return s.replace(/^"(.+)"$/, '$1');
  }
  return s;
}

@singleton()
export default class OncoKb {
  private config: OncoKbConfigType | undefined = undefined;

  private listeners = new Map<string, OncoKbListener>();

  constructor(private settings: Settings) {}

  public reset(): this {
    this.config = undefined;
    this.notify();
    return this;
  }

  public getEnvFilePath(): string {
    return this.settings.getLocalPath('.env_oncokb');
  }

  public getConfig(): OncoKbConfigType | undefined {
    return this.config;
  }

  public async readConfig(): Promise<OncoKbConfigType | undefined> {
    if (!this.settings.isLocal()) {
      return undefined;
    }
    if (!this.config) {
      const envFilePath = this.getEnvFilePath();
      const config: OncoKbConfigType = {
        oncoKbApiKey: '',
        ncbiApiKey: '',
      };
      if (await fs.pathExists(envFilePath)) {
        const content = await fs.readFile(envFilePath, 'utf8');
        const lines = content.split('\n');
        lines.forEach((line) => {
          const [key, value] = line.split('=');
          if (key === 'ONCOKB_BEARER_TOKEN') {
            config.oncoKbApiKey = unquoteString(value);
          } else if (key === 'NCBI_API_KEY') {
            config.ncbiApiKey = unquoteString(value);
          }
        });
      }
      this.config = config;
      this.notify();
    }
    return this.config;
  }

  public async saveConfig(config: Partial<OncoKbConfigType>): Promise<void> {
    if (!this.settings.isLocal()) {
      return;
    }
    const envFilePath = this.getEnvFilePath();
    let content = '';
    if (config.oncoKbApiKey) {
      content += `ONCOKB_BEARER_TOKEN="${config.oncoKbApiKey}"\n`;
    }
    if (config.ncbiApiKey) {
      content += `NCBI_API_KEY="${config.ncbiApiKey}"\n`;
    }
    await fs.writeFile(envFilePath, content);
    this.config = {
      oncoKbApiKey: config.oncoKbApiKey ?? '',
      ncbiApiKey: config.ncbiApiKey ?? '',
    };
    this.notify();
  }

  public subscribe(l: OncoKbListener): string {
    const id = uniqid();
    this.listeners.set(id, l);
    return id;
  }

  public unsubscribe(id: string): this {
    if (this.listeners.has(id)) this.listeners.delete(id);
    return this;
  }

  private notify(): void {
    if (this.listeners.size > 0) {
      this.listeners.forEach((l) => l(this.config));
    }
    if (is.renderer) {
      ipcRenderer.send('oncokb-config-change');
    }
  }
}
