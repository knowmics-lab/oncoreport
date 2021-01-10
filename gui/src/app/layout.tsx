import React, { useEffect } from 'react';
import styled from 'styled-components';
import {
  CssBaseline,
  createMuiTheme,
  Button,
  Toolbar,
} from '@material-ui/core';
import MUILayout, {
  getCollapseBtn,
  getContent,
  getDrawerSidebar,
  getFooter,
  getHeader,
  getSidebarContent,
  getSidebarTrigger,
  Root,
} from '@mui-treasury/layout';
import { darkMode } from 'electron-util';
import {
  LayoutHeader,
  NavContent,
  Notifications,
  ContentWrapper,
  BlockingMessageHandler,
  StartHandler,
} from './components/layout';
import SetupWizardContainer from './components/setup/setupWizardContainer';

const Header = getHeader(styled);
const DrawerSidebar = getDrawerSidebar(styled);
const SidebarTrigger = getSidebarTrigger(styled);
const SidebarContent = getSidebarContent(styled);
const CollapseBtn = getCollapseBtn(styled);
const Content = getContent(styled);
const Footer = getFooter(styled);

const layout = MUILayout();

layout.configureHeader((builder) => {
  builder
    .registerConfig('xs', {
      position: 'sticky',
      clipped: false,
      initialHeight: 56,
    })
    .registerConfig('md', {
      position: 'fixed',
      initialHeight: 64,
      clipped: false,
    });
});

layout.configureEdgeSidebar((builder) => {
  builder
    .create('primarySidebar', { anchor: 'left' })
    .registerTemporaryConfig('xs', {
      width: 256,
    })
    .registerPermanentConfig('lg', {
      width: 256,
      collapsible: false,
    });
});

type Props = {
  children: React.ReactNode;
  footer?: React.ReactNode;
};

const Layout = ({ children, footer }: Props) => {
  // @TODO enable and remove button for production
  // const [dark, setDark] = React.useState(darkMode.isEnabled);
  const [dark, setDark] = React.useState(true);

  useEffect(() => {
    darkMode.onChange(() => {
      setDark(darkMode.isEnabled);
    });
  }, []);

  const theme = React.useMemo(
    () =>
      createMuiTheme({
        palette: {
          type: dark ? 'dark' : 'light',
        },
      }),
    [dark]
  );

  return (
    <Root theme={theme} scheme={layout}>
      <CssBaseline />
      <SetupWizardContainer
        header={
          <Header color={dark ? 'default' : 'primary'}>
            <Toolbar>
              <LayoutHeader />
              <Button
                style={{ marginRight: 16 }}
                variant="contained"
                color="primary"
                onClick={() => setDark((v) => !v)}
              >
                Switch to {dark ? 'Light' : 'Dark'} mode
              </Button>
            </Toolbar>
          </Header>
        }
      >
        <Header color={dark ? 'default' : 'primary'}>
          <Toolbar>
            <SidebarTrigger sidebarId="primarySidebar" />
            <LayoutHeader />
            <Button
              style={{ marginRight: 16 }}
              variant="contained"
              color="primary"
              onClick={() => setDark((v) => !v)}
            >
              Switch to {dark ? 'Light' : 'Dark'} mode
            </Button>
          </Toolbar>
        </Header>
        <DrawerSidebar sidebarId="primarySidebar">
          <SidebarContent style={{ overflow: 'hidden' }}>
            <NavContent />
          </SidebarContent>
          <CollapseBtn style={{ overflow: 'hidden' }} />
        </DrawerSidebar>
        <Content>
          <ContentWrapper>
            <StartHandler />
            {children}
            <Notifications />
            <BlockingMessageHandler />
          </ContentWrapper>
        </Content>
        {footer && <Footer>{footer}</Footer>}
      </SetupWizardContainer>
    </Root>
  );
};

Layout.defaultProps = {
  footer: null,
};

export default Layout;
