import fs from 'fs-extra';
import axios from 'axios';
import { inject, injectable } from 'tsyringe';
import type { ConfigObjectType } from '../interfaces';
import DockerManager from './docker/manager';

@injectable()
export default class ValidateConfig {
  readonly #manager: DockerManager;

  readonly #oldConfig?: ConfigObjectType;

  #newConfig?: ConfigObjectType;

  constructor(
    manager: DockerManager,
    @inject('config') oldConfig: ConfigObjectType,
  ) {
    this.#manager = manager;
    this.#oldConfig = oldConfig.configured ? oldConfig : undefined;
  }

  public get newConfig(): ConfigObjectType {
    if (!this.#newConfig) throw new Error('Invalid configuration object!');
    return this.#newConfig;
  }

  public set newConfig(config: ConfigObjectType) {
    this.#newConfig = config;
  }

  private getApiUrl(): string {
    const path = this.newConfig.apiPath.replace(/^\/|\/$/gm, '');
    return `${this.newConfig.apiProtocol}://${this.newConfig.apiHostname}:${this.newConfig.apiPort}/${path}/`;
  }

  private async checkUrl() {
    const {
      data: { data },
    } = await axios.get(`${this.getApiUrl()}ping`);
    if (data !== 'pong') throw new Error('Invalid webservice URL');
  }

  private async checkToken() {
    let data = null;
    try {
      const response = await axios.get(`${this.getApiUrl()}auth-ping`, {
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.newConfig.apiKey}`,
        },
      });
      data = response.data.data;
    } catch (e) {
      if (e instanceof Error) {
        throw new Error(`Invalid authentication token - ${e.message}`);
      }
      throw new Error(`Unknown error: ${e}`);
    }
    if (data !== 'pong') throw new Error('Invalid authentication token');
  }

  private getManager(config: ConfigObjectType): DockerManager {
    this.#manager.config = config;
    return this.#manager;
  }

  private async tryRemovePreviousContainer(
    reportStatus?: (message: string) => void,
  ) {
    if (this.#oldConfig && this.#oldConfig.configured) {
      if (
        this.#oldConfig.containerName !== this.newConfig.containerName ||
        this.#oldConfig.dataPath !== this.newConfig.dataPath ||
        this.#oldConfig.apiPort !== this.newConfig.apiPort
      ) {
        if (reportStatus) reportStatus('Removing old container...');
        await this.getManager(this.#oldConfig).removeContainer();
        if (reportStatus) reportStatus('Ok!\n');
      }
    }
  }

  public async validate(
    reportStatus?: (message: string) => void,
  ): Promise<ConfigObjectType> {
    if (this.newConfig.local) {
      await this.tryRemovePreviousContainer(reportStatus);
      const newManager = this.getManager(this.newConfig);

      if (reportStatus) reportStatus(' - Creating directories...');
      if (!(await fs.pathExists(this.newConfig.dataPath))) {
        await fs.ensureDir(this.newConfig.dataPath, 0o755);
      }
      if (!(await fs.pathExists(`${this.newConfig.dataPath}/database`))) {
        await fs.ensureDir(this.newConfig.dataPath, 0o777);
      }
      if (reportStatus) reportStatus('Ok!\n');
      const status = await newManager.checkContainerStatus();
      if (status !== 'running') {
        if (reportStatus) reportStatus(' - Starting container...');
        await newManager.startContainer();
        if (reportStatus) reportStatus('Ok!\n');
      }
      if (!this.newConfig.apiKey) {
        if (reportStatus) reportStatus(' - Generating Auth Token...');
        this.newConfig = {
          ...this.newConfig,
          apiKey: await newManager.generateAuthToken(),
        };
        newManager.config = this.newConfig;
        if (reportStatus) reportStatus('Ok!\n');
      }
    }
    if (reportStatus) reportStatus(' - Checking connection to container...');
    await this.checkUrl();
    await this.checkToken();
    if (reportStatus) reportStatus('Ok!\n');
    return this.newConfig;
  }
}
