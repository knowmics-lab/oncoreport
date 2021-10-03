import fs from 'fs-extra';
import { is } from 'electron-util';
import Client from 'dockerode';
import { debounce } from 'ts-debounce';
import * as NodeStream from 'stream';
import { inject, injectable } from 'tsyringe';
import Utils from '../utils';
import SystemConstants from '../../constants/system.json';
import type { ConfigObjectType } from '../../interfaces';
import TimeoutError from '../../errors/TimeoutError';
import { Nullable } from '../../interfaces';
import PullStatus from './pullStatus';
import { AuthTokenResult, PullEvent } from './types';
import { Stream } from 'stream';

@injectable()
export default class Manager {
  #config?: ConfigObjectType;

  #client: Client;

  #container?: Client.Container;

  constructor(@inject('config') config: ConfigObjectType) {
    this.#client = new Client();
    this.config = config;
  }

  public get config() {
    if (!this.#config)
      throw new Error('Config is null! This should never happen!');
    return this.#config;
  }

  public set config(config: ConfigObjectType) {
    this.#config = config;
    let socketPath;
    if (this.#config.socketPath) {
      socketPath = this.#config.socketPath;
    } else if (is.windows) {
      socketPath = '//./pipe/docker_engine';
    } else {
      socketPath = '/var/run/docker.sock';
    }
    this.#client = new Client({ socketPath });
    this.#container = undefined;
  }

  public static liveDemuxStream(
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

  public static async demuxStream(
    stream: NodeStream.Duplex,
    checkRunning: Nullable<() => Promise<boolean>>,
    timeoutRunning = 30000
  ): Promise<[string, string]> {
    return new Promise((resolve) => {
      let stdout = Buffer.from('');
      let stderr = Buffer.from('');
      Manager.liveDemuxStream(
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

  public getBootedFile(): string {
    return `${this.config.dataPath}/booted`;
  }

  public getDbDirectory(): string {
    return `${this.config.dataPath}/database/`;
  }

  public getDbReadyFile(): string {
    return `${this.getDbDirectory()}/ready`;
  }

  public async waitContainerBooted(timeout = 0) {
    await Utils.waitExists(this.getDbDirectory(), timeout);
    await Utils.waitExists(this.getDbReadyFile(), timeout);
    await Utils.waitExists(this.getBootedFile(), timeout);
  }

  public async cleanupBootedFile() {
    await fs.remove(this.getBootedFile());
  }

  public async checkContainerStatus(): Promise<string> {
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
          // eslint-disable-next-line @typescript-eslint/ban-ts-comment
          // @ts-ignore
          if (e.statusCode && e.statusCode === 404) {
            return 'not found';
          }
          throw e;
        }
      }
    }
    return inspect.State.Status;
  }

  public async isRunning(): Promise<boolean> {
    const status = await this.checkContainerStatus();
    return status === 'running';
  }

  public getContainer(): Client.Container {
    if (!this.#container) {
      this.#container = this.#client.getContainer(this.config.containerName);
    }
    return this.#container;
  }

  public async createContainer(): Promise<void> {
    const status = await this.checkContainerStatus();
    if (status === 'not found') {
      await this.cleanupBootedFile();
      this.#container = undefined;
      // noinspection ES6MissingAwait
      this.#client.createContainer({
        Image: SystemConstants.DOCKER_IMAGE_NAME,
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

  public async checkForUpdates(
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
            ? debounce((s: PullStatus) => {
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

  public async startupSequence(
    showMessage: (a: string, b: boolean) => void,
    displayLog: Nullable<(a: string) => void>,
    timeout = 120000,
    maxTries = 3
  ) {
    if (displayLog) displayLog('');
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

  public async startContainer(): Promise<void> {
    const status = await this.checkContainerStatus();
    if (status === 'not found') {
      await this.createContainer();
    } else if (status === 'exited' || status === 'created') {
      await this.cleanupBootedFile();
      const container = this.getContainer();
      container.start();
      await new Promise<void>((resolve, reject) => {
        let timer: ReturnType<typeof setInterval>;
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

  public async stopContainer(): Promise<void> {
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

  public async removeContainer(): Promise<void> {
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

  public async execDockerCommand(
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
      const [stdout] = await Manager.demuxStream(
        stream,
        () => {
          return new Promise((resolve) => {
            exec.inspect((_e, d) => {
              resolve(!!(d && d.Running));
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

  public async generateAuthToken(): Promise<string> {
    const result = (await this.execDockerCommand([
      '/genkey.sh',
      '--json',
    ])) as AuthTokenResult;
    if (!result.error) {
      return result.data;
    }
    throw new Error(result.data);
  }

  public async execDockerCommandLive(
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
      return Manager.liveDemuxStream(
        stream,
        (buf) => outputCallback(buf.toString()),
        onStderr,
        onExit,
        () => {
          return new Promise((resolve) => {
            exec.inspect((_e, d) => {
              resolve(!!(d && d.Running));
            });
          });
        },
        timeoutRunning
      );
    }
    throw new Error('Unable to exec command. Container is not running');
  }

  public async runSetupScript(
    cosmicUsername: string,
    cosmicPassword: string,
    outputCallback: (a: string) => void,
    debounceTime = 500
  ) {
    let debouncedCallback = outputCallback;
    let timer: ReturnType<typeof setInterval> | undefined;
    if (debounceTime > 0) {
      let accumulator = '';
      debouncedCallback = (s: string) => {
        accumulator += s;
      };
      const fnDebouncer = () => {
        if (accumulator !== '') {
          outputCallback(accumulator);
          accumulator = '';
        }
      };
      timer = setInterval(fnDebouncer, debounceTime);
    }
    return new Promise<void>((resolve, reject) => {
      this.execDockerCommandLive(
        [
          'bash',
          '/oncoreport/scripts/setup.bash',
          '-u',
          cosmicUsername,
          '-p',
          cosmicPassword,
        ],
        debouncedCallback,
        debouncedCallback,
        (c) => {
          if (timer) clearInterval(timer);
          if (c === 0) resolve();
          else reject(new Error(`Unknown error (Code: ${c})`));
        }
      ).catch((e) => {
        if (timer) clearInterval(timer);
        reject(e);
      });
    });
  }

  public async clearQueue(): Promise<unknown> {
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

  public async pullImage(
    outputCallback: Nullable<(s: PullStatus) => void>
  ): Promise<PullStatus> {
    return new Promise((resolve, reject) => {
      this.#client.pull(
        SystemConstants.DOCKER_IMAGE_NAME,
        (e: unknown, stream: Stream) => {
          if (e) {
            reject(e);
          } else {
            const status = new PullStatus();
            const onFinished = (err: unknown) => {
              if (err) reject(err);
              else resolve(status);
            };
            const onProgress = (event: PullEvent) => {
              status.pushEvent(event);
              if (outputCallback) {
                outputCallback(status);
              }
            };
            this.#client.modem.followProgress(stream, onFinished, onProgress);
          }
        }
      );
    });
  }

  public async hasImage() {
    const images = await this.#client.listImages();
    return (
      images.filter(
        (r) =>
          r.RepoTags && r.RepoTags.includes(SystemConstants.DOCKER_IMAGE_NAME)
      ).length > 0
    );
  }
}
