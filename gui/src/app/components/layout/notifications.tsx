import * as React from 'react';
import { useEffect, useState } from 'react';
import Snackbar from '../UI/Snackbar';
import { Notifications } from '../../../api';
import { useService } from '../../../reactInjector';

export default function NotificationsList() {
  const manager = useService(Notifications);
  const [notifications, setNotifications] = useState(manager.notifications);
  useEffect(() => {
    const handlerId = manager.subscribe((newNotifications) => {
      setNotifications(newNotifications);
    });
    return function cleanup() {
      manager.unsubscribe(handlerId);
    };
  }, [notifications]);
  const makeCloseNotification = (k: string) => () => {
    manager.close(k);
    manager.destroy(k);
  };

  const notificationsArray = Object.values(notifications);
  const firstNotification =
    notificationsArray.length > 0 ? notificationsArray[0] : undefined;
  return (
    <>
      {firstNotification && (
        <Snackbar
          duration={firstNotification.duration || 3000}
          key={firstNotification.id}
          message={firstNotification.message}
          isOpen={firstNotification.shown}
          setClosed={makeCloseNotification(firstNotification.id)}
          variant={firstNotification.variant}
        />
      )}
      {/* {notificationsArray.map((v) => ( */}
      {/*  <Snackbar */}
      {/*    key={v.id} */}
      {/*    setClosed={makeCloseNotification(v.id)} */}
      {/*    message={v.message} */}
      {/*    variant={v.variant} */}
      {/*    isOpen={v.shown} */}
      {/*    duration={v.duration || 3000} */}
      {/*  /> */}
      {/* ))} */}
    </>
  );
}
