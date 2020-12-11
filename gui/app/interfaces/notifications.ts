import { SimpleMapType } from './common';
import { TypeOfNotification } from './enums';

export interface Notification {
  message: string;
  variant: TypeOfNotification;
  duration?: number;
}

export interface PushedNotification extends Notification {
  id: string;
  shown: boolean;
}

export interface NotificationsState {
  readonly notifications: SimpleMapType<PushedNotification>;
}

export type PushNotificationFunction = (
  message: string,
  type?: TypeOfNotification
) => void;
