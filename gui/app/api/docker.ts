// eslint-disable-next-line max-classes-per-file
import fs from 'fs-extra';
import { is } from 'electron-util';
import Client from 'dockerode';
import { debounce } from 'ts-debounce';
import * as NodeStream from 'stream';
import Utils from './utils';
import Settings from './settings';
import { DOCKER_IMAGE_NAME } from '../constants/system.json';
import type { ConfigObjectType } from '../interfaces/settings';
import TimeoutError from '../errors/TimeoutError';
import { Nullable } from '../interfaces/common';

type DockerPullEvent = {
  status: string;
  id?: string;
  progress?: string;
};

type AuthTokenResult = {
  error: number;
  data: string;
};

export class DockerPullStatus {
  idMap: Map<string, number> = new Map<string, number>();

  outputArray: string[] = [];

  pushEvent(event: DockerPullEvent) {
    if (event.id) {
      const { id, status } = event;
      let mappedId;
      if (this.idMap.has(id)) {
        mappedId = this.idMap.get(id);
      } else {
        mappedId = this.outputArray.length;
        this.idMap.set(id, mappedId);
        this.outputArray.push('');
      }
      if (mappedId) {
        const progress = event.progress ? ` ${event.progress}` : '';
        this.outputArray[mappedId] = `${id}: ${status}${progress}`;
      }
    } else {
      this.outputArray.push(event.status);
    }
  }

  isUpToDate() {
    return (
      this.outputArray.filter((s) => s.includes('Image is up to date')).length >
      0
    );
  }

  toString() {
    return this.outputArray.join('\n');
  }
}

export class DockerManager {
  public config: ConfigObjectType;

  private client: Client;

  private container: Client.Container | undefined;

  constructor(config: ConfigObjectType) {
    this.config = config;
    let socketPath;
    if (this.config.socketPath) {
      socketPath = this.config.socketPath;
    } else if (is.windows) {
      socketPath = '//./pipe/docker_engine';
    } else {
      socketPath = '/var/run/docker.sock';
    }
    this.client = new Client({ socketPath });
    this.container = undefined;
  }

  static liveDemuxStream(
    stream: NodeStream.Duplex,
    onStdout: Nullable<(b: Buffer) => void>,
    onStderr: Nullable<(b: Buffer) => void>,
    onEnd: Nullable<() => void>,
    checkRunning: Nullable<() => Promise<boolean>>,
    timeoutRunning = 30000
  ): void {
    let nextDataType: number | null = null;
    let nextDataLength = -1;
    let buffer = Buffer.from('');
    let ended = false;

    const bufferSlice = (end: number) => {
      const out = buffer.slice(0, end);
      buffer = Buffer.from(buffer.slice(end, buffer.length));
      return out;
    };
    const processData = (data?: Uint8Array) => {
      if (data) {
        buffer = Buffer.concat([buffer, data]);
      }
      if (nextDataType) {
        if (buffer.length >= nextDataLength) {
          const content = bufferSlice(nextDataLength);
          if (onStdout && nextDataType === 1) {
            onStdout(Buffer.from(content));
          } else if (onStderr && nextDataType !== 1) {
            onStderr(Buffer.from(content));
          }
          nextDataType = null;
          processData();
        }
      } else if (buffer.length >= 8) {
        const header = bufferSlice(8);
        nextDataType = header.readUInt8(0);
        nextDataLength = header.readUInt32BE(4);
        processData();
      }
    };

    stream.on('data', processData).on('end', () => {
      if (!ended && onEnd) {
        onEnd();
        ended = true;
      }
    });
    if (checkRunning) {
      const fnRunning = async () => {
        if (ended) return;
        if (await checkRunning()) {
          setTimeout(fnRunning, timeoutRunning);
        } else if (!ended && onEnd) {
          onEnd();
          ended = true;
        }
      };
      setTimeout(fnRunning, timeoutRunning);
    }
  }

  static async demuxStream(
    stream: NodeStream.Duplex,
    checkRunning: Nullable<() => Promise<boolean>>,
    timeoutRunning = 30000
  ): Promise<[string, string]> {
    return new Promise((resolve) => {
      let stdout = Buffer.from('');
      let stderr = Buffer.from('');
      DockerManager.liveDemuxStream(
        stream,
        (content) => {
          stdout = Buffer.concat([stdout, content]);
        },
        (content) => {
          stderr = Buffer.concat([stderr, content]);
        },
        () => resolve([stdout.toString(), stderr.toString()]),
        checkRunning,
        timeoutRunning
      );
    });
  }

  getBootedFile(): string {
    return `${this.config.dataPath}/booted`;
  }

  getDbDirectory(): string {
    return `${this.config.dataPath}/database/`;
  }

  getDbReadyFile(): string {
    return `${this.getDbDirectory()}/ready`;
  }

  async waitContainerBooted(timeout = 0) {
    await Utils.waitExists(this.getDbDirectory(), timeout);
    await Utils.waitExists(this.getDbReadyFile(), timeout);
    await Utils.waitExists(this.getBootedFile(), timeout);
  }

  async cleanupBootedFile() {
    await fs.remove(this.getBootedFile());
  }

  async checkContainerStatus(): Promise<string> {
    let inspect = null;
    while (inspect === null) {
      try {
        // eslint-disable-next-line no-await-in-loop
        inspect = await Utils.promiseTimeout(
          this.getContainer().inspect(),
          500
        );
      } catch (e) {
        if (!(e instanceof TimeoutError)) {
          if (e.statusCode && e.statusCode === 404) {
            return 'not found';
          }
          throw e;
        }
      }
    }
    return inspect.State.Status;
  }

  async isRunning(): Promise<boolean> {
    const status = await this.checkContainerStatus();
    return status === 'running';
  }

  getContainer(): Client.Container {
    if (!this.container) {
      this.container = this.client.getContainer(this.config.containerName);
    }
    return this.container;
  }

  async createContainer(): Promise<void> {
    const status = await this.checkContainerStatus();
    if (status === 'not found') {
      await this.cleanupBootedFile();
      this.container = undefined;
      // noinspection ES6MissingAwait
      this.client.createContainer({
        Image: DOCKER_IMAGE_NAME,
        name: this.config.containerName,
        ExposedPorts: {
          '80/tcp': {},
        },
        Volumes: {
          '/oncoreport/ws/storage/app/': {},
        },
        HostConfig: {
          PortBindings: {
            '80/tcp': [
              {
                HostPort: `${this.config.apiPort}`,
              },
            ],
          },
          Binds: [`${this.config.dataPath}:/oncoreport/ws/storage/app/`],
        },
      });
      return new Promise((resolve, reject) => {
        const timer = setInterval(async () => {
          const currentStatus = await this.checkContainerStatus();
          if (currentStatus !== 'not found') {
            clearInterval(timer);
            if (currentStatus !== 'created') {
              reject(
                new Error(
                  `Unable to create the container ${this.config.containerName}. Create it manually`
                )
              );
            }
            try {
              await this.startContainer();
              resolve();
            } catch (e) {
              reject(e);
            }
          }
        }, 500);
      });
    }
    return undefined;
  }

  async checkForUpdates(
    showMessage: (a: string, b: boolean) => void,
    displayLog: Nullable<(a: string) => void>,
    timeout = 120000,
    maxTries = 3
  ) {
    if (this.config.local) {
      showMessage('Checking internet connection...', false);
      if (!(await this.isRunning()) && (await Utils.isOnline())) {
        showMessage('Checking for container updates...', false);
        try {
          const displayStatus = displayLog
            ? debounce((s: DockerPullStatus) => {
                if (s) displayLog(s.toString());
              }, 500)
            : undefined;
          const res = await this.pullImage(displayStatus);
          if (displayStatus) {
            displayStatus.cancel();
          }
          if (!res.isUpToDate()) {
            await Utils.retryFunction(
              async (t: number) => {
                const first = t === 0;
                showMessage(
                  `Update found...removing old container...${
                    first ? '' : `Attempt ${t + 1} of ${maxTries}...`
                  }`,
                  !first
                );
                await this.removeContainer();
              },
              timeout,
              maxTries
            );
          }
        } catch (e) {
          if (e instanceof TimeoutError) {
            throw new Error(
              `Unable to update the container ${this.config.containerName}. Update it manually`
            );
          } else {
            throw e;
          }
        }
      }
    }
  }

  async startupSequence(
    showMessage: (a: string, b: boolean) => void,
    displayLog: Nullable<(a: string) => void>,
    timeout = 120000,
    maxTries = 3
  ) {
    await this.checkForUpdates(showMessage, displayLog, timeout, maxTries);
    try {
      await Utils.retryFunction(
        async (t: number) => {
          const first = t === 0;
          const odd = t % 2 > 0;
          showMessage(
            first
              ? 'Starting docker container...'
              : `Container is not starting...Attempt ${
                  t + 1
                } of ${maxTries}...`,
            !first
          );
          if (odd) {
            await this.removeContainer();
          }
          return this.startContainer();
        },
        timeout,
        maxTries
      );
    } catch (e) {
      if (e instanceof TimeoutError) {
        throw new Error(
          `Unable to start the container ${this.config.containerName}. Start it manually`
        );
      } else {
        throw e;
      }
    }
  }

  async startContainer(): Promise<void> {
    const status = await this.checkContainerStatus();
    if (status === 'not found') {
      await this.createContainer();
    } else if (status === 'exited' || status === 'created') {
      await this.cleanupBootedFile();
      const container = this.getContainer();
      container.start();
      await new Promise((resolve, reject) => {
        let timer: number;
        const fnTimer = async () => {
          const currentStatus = await this.checkContainerStatus();
          if (currentStatus === 'running') {
            clearInterval(timer);
            try {
              await this.waitContainerBooted();
              return resolve();
            } catch (e) {
              return reject(e);
            }
          }
          return undefined;
        };
        timer = setInterval(fnTimer, 500);
      });
    }
  }

  async stopContainer(): Promise<void> {
    const status = await this.checkContainerStatus();
    if (status === 'running') {
      const container = this.getContainer();
      if (container) {
        await container.stop();
        await this.cleanupBootedFile();
      } else {
        throw new Error('Unable to find container');
      }
    }
  }

  async removeContainer(): Promise<void> {
    const status = await this.checkContainerStatus();
    if (status === 'running') {
      await this.stopContainer();
    }
    if (status !== 'not found') {
      const container = this.getContainer();
      if (container) {
        await container.remove();
      } else {
        throw new Error('Unable to find container');
      }
    }
  }

  async execDockerCommand(
    Cmd: string[],
    timeoutRunning = 30000,
    parse = true
  ): Promise<unknown> {
    const status = await this.checkContainerStatus();
    if (status === 'running') {
      const container = this.getContainer();
      if (!container) throw new Error('Unable to get container instance');
      const exec = await container.exec({
        Cmd,
        AttachStdout: true,
      });
      const stream = await exec.start({});
      const [stdout] = await DockerManager.demuxStream(
        stream,
        () => {
          return new Promise((resolve) => {
            exec.inspect((_e, d) => {
              resolve(d && d.Running);
            });
          });
        },
        timeoutRunning
      );
      if (parse) {
        return JSON.parse(stdout);
      }
      return stdout;
    }
    throw new Error('Unable to exec command. Container is not running');
  }

  async generateAuthToken(): Promise<string> {
    const result = (await this.execDockerCommand([
      '/genkey.sh',
      '--json',
    ])) as AuthTokenResult;
    if (!result.error) {
      return result.data;
    }
    throw new Error(result.data);
  }

  async execDockerCommandLive(
    Cmd: string[],
    outputCallback: (a: string) => void,
    errCallback: Nullable<(a: string) => void> = null,
    exitCallback: Nullable<(a: number) => void> = null,
    timeoutRunning = 30000
  ): Promise<void> {
    const status = await this.checkContainerStatus();
    if (status === 'running') {
      const container = this.getContainer();
      if (!container) throw new Error('Unable to get container instance');
      const exec = await container.exec({
        Cmd,
        AttachStdout: true,
        AttachStderr: !!errCallback,
      });
      const stream = await exec.start({});
      const onStderr = errCallback
        ? (buf: Buffer) => errCallback(buf.toString())
        : null;
      const onExit = exitCallback
        ? () => {
            exec.inspect((err, data) => {
              if (err) throw new Error(err);
              exitCallback(data?.ExitCode || 0);
            });
          }
        : null;
      return DockerManager.liveDemuxStream(
        stream,
        (buf) => outputCallback(buf.toString()),
        onStderr,
        onExit,
        () => {
          return new Promise((resolve) => {
            exec.inspect((_e, d) => {
              resolve(d && d.Running);
            });
          });
        },
        timeoutRunning
      );
    }
    throw new Error('Unable to exec command. Container is not running');
  }

  async clearQueue(): Promise<unknown> {
    const status = await this.checkContainerStatus();
    if (status === 'running') {
      return this.execDockerCommand(
        ['php', '/oncoreport/ws/artisan', 'queue:clear'],
        1000,
        false
      );
    }
    return undefined;
  }

  async pullImage(
    outputCallback: Nullable<(s: DockerPullStatus) => void>
  ): Promise<DockerPullStatus> {
    return new Promise((resolve, reject) => {
      this.client.pull(DOCKER_IMAGE_NAME, (e: unknown, stream: unknown) => {
        if (e) {
          reject(e);
        } else {
          const status = new DockerPullStatus();
          const onFinished = (err: unknown) => {
            if (err) reject(err);
            else resolve(status);
          };
          const onProgress = (event: DockerPullEvent) => {
            status.pushEvent(event);
            if (outputCallback) {
              outputCallback(status);
            }
          };
          this.client.modem.followProgress(stream, onFinished, onProgress);
        }
      });
    });
  }

  async hasImage() {
    const images = await this.client.listImages();
    return (
      images.filter((r) => r.RepoTags.includes(DOCKER_IMAGE_NAME)).length > 0
    );
  }
}

let instance: Nullable<DockerManager> = null;

export const getInstance = () => {
  if (!instance) {
    instance = new DockerManager(Settings.getConfig());
  }
  return instance;
};

export const resetInstance = () => {
  instance = null;
};

export default getInstance();
