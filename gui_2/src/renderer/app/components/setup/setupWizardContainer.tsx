import React, { useEffect, useState, ReactNode } from 'react';
import { styled, Toolbar } from '@mui/material';
import { useService } from '../../../../reactInjector';
import { Settings } from '../../../../api';
import { BlockingMessageHandler, ContentWrapper, Notifications, StartHandler } from '../layout';
import SetupWizard from './setupWizard';
import ConfigUploader from './configUploader';
import { Footer } from '@mui-treasury/layout';

const Main = styled('main')(({ theme }) => ({
  flexGrow: 1,
  padding: theme.spacing(3),
}));

type Props = {
  children: ReactNode | ReactNode[] | Iterable<ReactNode>;
  header?: ReactNode;
};

export default function SetupWizardContainer({ children, header }: Props) {
  const settings = useService(Settings);
  const [configured, setConfigured] = useState(true); // settings.isConfigured());

  useEffect(() => {
    const id = settings.subscribe((c) => {
      setConfigured(c.configured || false);
    });
    return () => {
      settings.unsubscribe(id);
    };
  }, [settings]);

  return (
    // eslint-disable-next-line react/jsx-no-useless-fragment
    <>
      {configured ? (
        children
      ) : (
        <ConfigUploader>
          {header}
          <ContentWrapper>
            <SetupWizard />
            <Notifications />
          </ContentWrapper>
        </ConfigUploader>
      )}
    </>
  );
}

SetupWizardContainer.defaultProps = {
  header: undefined,
};
