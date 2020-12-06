import { Nullable, SimpleMapType } from './common';

export type TypeOfNotification = 'success' | 'warning' | 'error' | 'info';

export interface Notification {
  message: string;
  variant: TypeOfNotification;
  duration: Nullable<number>;
}

export interface PushedNotification extends Notification {
  id: string;
  shown: boolean;
}

export type Notifications = SimpleMapType<PushedNotification>;

export interface NotificationsState {
  readonly notifications: Notifications;
}

export type PushNotificationFunction = (
  message: string,
  type?: TypeOfNotification
) => void;
