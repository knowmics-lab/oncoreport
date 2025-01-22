import React, { useEffect, useState, ReactNode } from 'react';
import { useService } from '../../../../reactInjector';
import { Settings } from '../../../../api';
import { ContentWrapper, Notifications } from '../layout';
import SetupWizard from './setupWizard';
import ConfigUploader from './configUploader';

type Props = {
  children: ReactNode | ReactNode[] | Iterable<ReactNode>;
  header?: ReactNode;
};

export default function SetupWizardContainer({ children, header }: Props) {
  const settings = useService(Settings);
  const [configured, setConfigured] = useState(settings.isConfigured());

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
