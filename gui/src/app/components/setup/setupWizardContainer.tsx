import React from 'react';
import { makeStyles, Theme } from '@material-ui/core/styles';
import { useService } from '../../../reactInjector';
import { Settings } from '../../../api';
import { Notifications } from '../layout';
import SetupWizard from './setupWizard';

const useStyles = makeStyles((theme: Theme) => ({
  root: {
    display: 'flex',
  },
  content: {
    flexGrow: 1,
    padding: theme.spacing(3),
  },
}));

type Props = {
  children: React.ReactNode | React.ReactNodeArray;
  header?: React.ReactNode;
};

export default function SetupWizardContainer({ children, header }: Props) {
  const classes = useStyles();
  const settings = useService(Settings);
  return (
    <>
      {settings.isConfigured() ? (
        children
      ) : (
        <>
          {header}
          <div className={classes.root}>
            <main className={classes.content}>
              <SetupWizard />
              <Notifications />
            </main>
          </div>
        </>
      )}
    </>
  );
}

SetupWizardContainer.defaultProps = {
  header: undefined,
};
