import { Notifications as NotificationsManager } from '../../../api';
import { useService } from '../../../reactInjector';

export function useNotifications() {
  const manager = useService(NotificationsManager);
  return {
    pushSimple: manager.pushSimple.bind(manager),
    push: manager.push.bind(manager),
    manager,
  };
}
