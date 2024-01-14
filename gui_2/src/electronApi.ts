/* eslint-disable global-require */
import * as electron from 'electron';
import type * as ElectronRemote from '@electron/remote';

const renderer = process.type === 'renderer';

const macos = process.platform === 'darwin';

const api = renderer
  ? (require('@electron/remote') as unknown as typeof ElectronRemote)
  : electron;

export const getPath = (name: Parameters<typeof api.app.getPath>[0]) =>
  api.app.getPath(name);

export const activeWindow = () => api.BrowserWindow.getFocusedWindow();

export const darkMode = {
  get isEnabled() {
    if (!macos) {
      return false;
    }
    return api.nativeTheme.shouldUseDarkColors;
  },

  onChange(callback: Function) {
    if (!macos) {
      return () => {};
    }

    const handler = () => {
      callback();
    };

    api.nativeTheme.on('updated', handler);

    return () => {
      api.nativeTheme.off('updated', handler);
    };
  },
};

export default api;
