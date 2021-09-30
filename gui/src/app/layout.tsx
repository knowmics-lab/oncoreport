import React, { useEffect } from 'react';
import styled from 'styled-components';
import {
  CssBaseline,
  createTheme,
  Toolbar,
  IconButton,
  Tooltip,
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
import Brightness4 from '@material-ui/icons/Brightness4';
import Brightness7 from '@material-ui/icons/Brightness7';
import {
  LayoutHeader,
  NavContent,
  Notifications,
  ContentWrapper,
  BlockingMessageHandler,
  StartHandler,
} from './components/layout';
import SetupWizardContainer from './components/setup/setupWizardContainer';
import ThemeContext from './themeContext';

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
  const [dark, setDark] = React.useState(darkMode.isEnabled);

  useEffect(() => {
    darkMode.onChange(() => {
      setDark(darkMode.isEnabled);
    });
  }, []);

  const theme = React.useMemo(
    () =>
      createTheme({
        palette: {
          type: dark ? 'dark' : 'light',
        },
      }),
    [dark]
  );

  const switcherLabel = dark ? 'Switch to light theme' : 'Switch to dark theme';

  return (
    <ThemeContext.Provider value={dark}>
      <Root theme={theme} scheme={layout}>
        <CssBaseline />
        <SetupWizardContainer
          header={
            <Header color={dark ? 'default' : 'primary'}>
              <Toolbar>
                <LayoutHeader />
                <Tooltip title={switcherLabel}>
                  <IconButton aria-label={switcherLabel}>
                    {dark ? <Brightness7 /> : <Brightness4 />}
                  </IconButton>
                </Tooltip>
              </Toolbar>
            </Header>
          }
        >
          <Header color={dark ? 'default' : 'primary'}>
            <Toolbar>
              <SidebarTrigger sidebarId="primarySidebar" />
              <LayoutHeader />
              <Tooltip title={switcherLabel}>
                <IconButton
                  aria-label={switcherLabel}
                  onClick={() => setDark((v) => !v)}
                >
                  {dark ? <Brightness7 /> : <Brightness4 />}
                </IconButton>
              </Tooltip>
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
    </ThemeContext.Provider>
  );
};

Layout.defaultProps = {
  footer: null,
};

export default Layout;
