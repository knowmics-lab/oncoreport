import fs from 'fs-extra';
import axios from 'axios';
import { DockerManager } from './docker';
import { ConfigObjectType } from '../interfaces/settings';
import { Nullable } from '../interfaces/common';

export default class Check {
  private newConfig: ConfigObjectType;

  private oldConfig: Nullable<ConfigObjectType>;

  constructor(
    newConfig: ConfigObjectType,
    oldConfig: Nullable<ConfigObjectType>
  ) {
    this.newConfig = newConfig;
    this.oldConfig = oldConfig;
  }

  getApiUrl(): string {
    const path = this.newConfig.apiPath.replace(/^\/|\/$/gm, '');
    return `${this.newConfig.apiProtocol}://${this.newConfig.apiHostname}:${this.newConfig.apiPort}/${path}/`;
  }

  async checkUrl() {
    const {
      data: { data },
    } = await axios.get(`${this.getApiUrl()}ping`);
    if (data !== 'pong') throw new Error('Invalid webservice URL');
  }

  async checkToken() {
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
      throw new Error(`Invalid authentication token - ${e.message}`);
    }
    if (data !== 'pong') throw new Error('Invalid authentication token');
  }

  async check(
    reportStatus?: (message: string) => void
  ): Promise<ConfigObjectType> {
    let { newConfig: config } = this;
    const { oldConfig } = this;

    if (config.local) {
      if (oldConfig && oldConfig.configured) {
        if (
          oldConfig.containerName !== config.containerName ||
          oldConfig.dataPath !== config.dataPath ||
          oldConfig.apiPort !== config.apiPort
        ) {
          if (reportStatus) reportStatus('Removing old container...');
          const oldManager = new DockerManager(oldConfig);
          await oldManager.removeContainer();
          if (reportStatus) reportStatus('Ok!\n');
        }
      }
      const newManager = new DockerManager(config);

      if (reportStatus) reportStatus('Creating directories...');
      if (!(await fs.pathExists(config.dataPath))) {
        await fs.ensureDir(config.dataPath, 0o755);
      }
      if (!(await fs.pathExists(`${config.dataPath}/database`))) {
        await fs.ensureDir(config.dataPath, 0o777);
      }
      if (reportStatus) reportStatus('Ok!\n');
      const status = await newManager.checkContainerStatus();
      if (status !== 'running') {
        if (reportStatus) reportStatus('Starting container...');
        await newManager.startContainer();
        if (reportStatus) reportStatus('Ok!\n');
      }
      if (!config.apiKey) {
        if (reportStatus) reportStatus('Generating Auth Token...');
        config = {
          ...config,
          apiKey: await newManager.generateAuthToken(),
        };
        this.newConfig = config;
        newManager.config = config;
        if (reportStatus) reportStatus('Ok!\n');
      }
    }
    if (reportStatus) reportStatus('Checking connection to container...');
    await this.checkUrl();
    await this.checkToken();
    if (reportStatus) reportStatus('Ok!\n');
    return config;
  }
}
