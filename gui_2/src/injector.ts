import { container } from 'tsyringe';
import Store, { Schema } from 'electron-store';
import configSchema from './constants/config-schema.json';
import { ConfigObjectType } from './interfaces';
import { Settings } from './api';

container.register<Store<ConfigObjectType>>(Store, {
  useFactory: () =>
    new Store({
      schema: configSchema as Schema<ConfigObjectType>,
      name: 'oncoreport',
    }),
});
container.register<ConfigObjectType>('config', {
  useFactory: () => container.resolve(Settings).getConfig(),
});

// container.register<Settings>(Settings, { useClass: Settings });

export default container;
