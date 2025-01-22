import { container } from 'tsyringe';
import { Theme } from '@mui/material';
import Convert from 'ansi-to-html';
import { Notifications } from '../../../api';
import { TypeOfNotification } from '../../../interfaces';

const convert = new Convert({ newline: true });

export function formControlStyle(theme: Theme) {
  return {
    margin: theme.spacing(1),
    minWidth: 120,
  };
}

export function runAsync(
  asyncFn: (manager: Notifications) => Promise<void>,
  catchFn?: (reason: unknown) => void,
  notifyError = true,
  finallyFn?: () => void,
) {
  const manager = container.resolve(Notifications);
  asyncFn(manager)
    .finally(() => finallyFn && finallyFn())
    .catch((e) => {
      if (notifyError) {
        manager.pushSimple(
          `An error occurred: ${e.message}`,
          TypeOfNotification.error,
        );
        // eslint-disable-next-line no-console
        console.error(e); // TODO: remove...only for debug
      }
      if (catchFn) catchFn(e);
    });
}

export function logToHtml(log: string): string {
  return convert.toHtml(
    log
      .split('\n')
      .map((s) => s.split('\r').pop())
      .map((s) =>
        (s || '')
          .replaceAll(' ', '&nbsp;')
          .replaceAll('\t', '&nbsp;&nbsp;&nbsp;&nbsp;'),
      )
      .join('\n'),
  );
}

export default {};
