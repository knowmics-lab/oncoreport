/* eslint-disable no-underscore-dangle */
import { singleton } from 'tsyringe';
import { set, get, has, unset } from 'lodash';
import uniqid from 'uniqid';
import produce from 'immer';
import {
  Notification,
  PushedNotification,
  SimpleMapType,
  TypeOfNotification,
} from '../interfaces';

type Listener = (notifications: SimpleMapType<PushedNotification>) => void;

@singleton()
export default class Notifications {
  private _notifications: SimpleMapType<PushedNotification> = {};

  private _listeners: SimpleMapType<Listener> = {};

  public get notifications() {
    return this._notifications;
  }

  public push(n: Notification): this {
    const id = uniqid();
    this._notifications = produce(this._notifications, (d) => {
      set(d, id, {
        ...n,
        id,
        shown: true,
      });
    });
    this.notify();
    return this;
  }

  public pushSimple(message: string, variant: TypeOfNotification): this {
    return this.push({
      message,
      variant,
    });
  }

  public close(id: string): this {
    if (has(this._notifications, id)) {
      this._notifications = produce(this._notifications, (d) => {
        set(d, id, {
          ...get(d, id),
          shown: false,
        });
      });
      this.notify();
    }
    return this;
  }

  public destroy(id: string): this {
    if (has(this._notifications, id)) {
      this._notifications = produce(this._notifications, (d) => {
        unset(d, id);
      });
      this.notify();
    }
    return this;
  }

  public subscribe(listener: Listener): string {
    const id = uniqid();
    set(this._listeners, id, listener);
    return id;
  }

  public unsubscribe(id: string) {
    if (has(this._listeners, id)) {
      unset(this._listeners, id);
    }
  }

  private notify() {
    Object.values(this._listeners).forEach((l) => l(this._notifications));
  }
}
