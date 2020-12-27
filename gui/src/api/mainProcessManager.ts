/* eslint-disable no-console */
import { injectable } from 'tsyringe';
import { app, BrowserWindow, dialog, ipcMain } from 'electron';
import TransferManager from './transferManager';
import { DockerManager } from './docker';
import Settings from './settings';

@injectable()
export default class MainProcessManager {
  #registered = false;

  #window?: BrowserWindow;

  #doQuit = false;

  public constructor(
    private dockerManager: DockerManager,
    private settings: Settings,
    private transferManager: TransferManager
  ) {}

  public setWindow(window: BrowserWindow): this {
    this.#window = window;
    return this;
  }

  private quitNow = () => {
    this.#doQuit = true;
    if (this.#window) this.#window.close();
    app.quit();
  };

  private stopDockerAndQuit = async () => {
    if (this.#window) {
      this.#window.webContents.send('on-display-blocking-message', {
        message: 'Waiting for container to stop',
        error: false,
      });
    }
    console.log('Waiting for docker container to stop');
    try {
      await this.dockerManager.clearQueue();
      await this.dockerManager.stopContainer();
      console.log('Docker container has been stopped!');
    } catch (ex) {
      console.log('Docker container cannot be stopped! Stop it manually!');
      console.log(ex);
    } finally {
      console.log('Quitting!');
      this.quitNow();
    }
  };

  private registerNewWindowHandler() {
    if (this.#window) {
      this.#window.webContents.on(
        'new-window',
        (event, _url, frameName, _disposition, options) => {
          event.preventDefault();
          const forcedOptions = {
            parent: this.#window,
            width: 1024,
            height: 728,
            webPreferences: {
              nodeIntegration: false,
              nativeWindowOpen: true,
              webviewTag: false,
              nodeIntegrationInSubFrames: false,
            },
          };
          const isModal = frameName === 'modal';
          const win = new BrowserWindow({
            ...options,
            ...forcedOptions,
            modal: isModal,
          });
          win.setMenuBarVisibility(false);
          // eslint-disable-next-line no-param-reassign
          event.newGuest = win;
        }
      );
    }
  }

  private registerBlockingMessagesHandler() {
    ipcMain.on('display-blocking-message', (_e, args) => {
      if (this.#window) {
        this.#window.webContents.send('on-display-blocking-message', args);
        this.#window.webContents.send('on-blocking-message-log', '');
      }
    });

    ipcMain.on('blocking-message-log', (_e, args) => {
      if (this.#window) {
        this.#window.webContents.send('on-blocking-message-log', args);
      }
    });

    ipcMain.on('hide-blocking-message', () => {
      if (this.#window) {
        this.#window.webContents.send('on-hide-blocking-message');
      }
    });
  }

  private registerQuitHandler() {
    if (this.#window) {
      this.#window.on('close', async (e) => {
        if (this.#doQuit) return;
        if (
          this.settings.isLocal() &&
          this.settings.isConfigured() &&
          !this.#doQuit
        ) {
          e.preventDefault();
          if (await this.dockerManager.isRunning()) {
            if (this.settings.autoStopDockerOnClose()) {
              await this.stopDockerAndQuit();
            } else if (this.#window) {
              const { response, checkboxChecked } = await dialog.showMessageBox(
                this.#window,
                {
                  // title: 'Close docker',
                  message: 'Do you wish to stop the docker container?',
                  buttons: ['&Yes', '&No', '&Cancel'],
                  cancelId: 2,
                  type: 'question',
                  checkboxLabel: 'Close without asking again?',
                  checkboxChecked: this.settings.autoStopDockerOnClose(),
                  normalizeAccessKeys: true,
                }
              );
              if (checkboxChecked) {
                this.settings.setAutoStopDockerOnClose();
              }
              if (response === 0) {
                await this.stopDockerAndQuit();
              } else if (response === 1) {
                this.quitNow();
              }
            }
          } else {
            this.quitNow();
          }
        }
      });
    }
  }

  private registerConfigChangeHandler() {
    ipcMain.on('config-change', () => {
      console.log('Reloading configuration');
      this.settings.reset();
    });
  }

  public registerHandlers() {
    if (!this.#registered) {
      this.registerQuitHandler();
      this.registerBlockingMessagesHandler();
      if (this.#window) this.transferManager.registerMainHandlers(this.#window);
      this.registerNewWindowHandler();
      this.registerConfigChangeHandler();
      this.#registered = true;
    }
  }
}
