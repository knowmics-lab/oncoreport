import { useService } from '../../../reactInjector';
import { Notifications as NotificationsManager } from '../../../api';

export default function useNotifications() {
  const manager = useService(NotificationsManager);
  return {
    pushSimple: manager.pushSimple.bind(manager),
    push: manager.push.bind(manager),
    manager,
  };
}
