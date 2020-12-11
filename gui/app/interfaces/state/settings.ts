import { ConfigObjectType } from '../settings';

export type ModifiableStateType = {
  readonly saving: boolean;
};

export interface ConfigObjectWithState extends ConfigObjectType {
  readonly state: ModifiableStateType;
}

export default interface SettingsState {
  readonly settings: ConfigObjectWithState;
}
