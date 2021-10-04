import { container } from 'tsyringe';
import { Notifications } from '../../api';
import { TypeOfNotification } from '../../interfaces';

export function runAsync(
  asyncFn: (manager: Notifications) => Promise<void>,
  catchFn?: (reason: unknown) => void
) {
  const manager = container.resolve(Notifications);
  asyncFn(manager).catch((e) => {
    manager.pushSimple(
      `An error occurred: ${e.message}`,
      TypeOfNotification.error
    );
    // eslint-disable-next-line no-console
    console.error(e); // TODO: remove...only for debug
    if (catchFn) catchFn(e);
  });
}

export default {};
