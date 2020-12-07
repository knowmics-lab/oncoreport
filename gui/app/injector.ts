import { container } from 'tsyringe';
import Store, { Schema } from 'electron-store';
import configSchema from './constants/config-schema.json';
import { ConfigObjectType } from './interfaces/settings';
import Settings from './api/settings';

container.register<Store<ConfigObjectType>>(Store, {
  useFactory: () =>
    new Store({
      schema: configSchema as Schema<ConfigObjectType>,
    }),
});
container.register<ConfigObjectType>('config', {
  useFactory: () => container.resolve(Settings).getConfig(),
});

// container.register<Settings>(Settings, { useClass: Settings });

export default container;
