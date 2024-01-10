import React from 'react';
import {
  CssBaseline,
  createTheme,
  Toolbar,
  IconButton,
  Tooltip,
  ThemeProvider,
} from '@mui/material';
import {
  EdgeTrigger,
  EdgeSidebar,
  Root,
  Header,
  Footer,
  SidebarContent,
  Content,
} from '@mui-treasury/layout';
import Brightness4 from '@mui/icons-material/Brightness4';
import Brightness7 from '@mui/icons-material/Brightness7';
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
import useDarkMode from './hooks/useDarkMode';

type Props = {
  children: React.ReactNode;
  footer?: React.ReactNode;
};

function Layout({ children, footer }: Props) {
  const [dark, setDark] = useDarkMode();

  const theme = React.useMemo(
    () =>
      createTheme({
        palette: {
          mode: dark ? 'dark' : 'light',
        },
      }),
    [dark],
  );

  const switcherLabel = dark ? 'Switch to light theme' : 'Switch to dark theme';

  return (
    <ThemeContext.Provider value={dark}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Root
          scheme={{
            header: {
              config: {
                xs: {
                  position: 'sticky',
                  clipped: false,
                  height: 56,
                },
                md: {
                  position: 'fixed',
                  clipped: false,
                  height: 64,
                },
              },
            },
            leftEdgeSidebar: {
              config: {
                xs: {
                  width: 256,
                  variant: 'temporary',
                },
                lg: {
                  width: 256,
                  collapsible: false,
                  variant: 'permanent',
                },
              },
            },
          }}
        >
          <SetupWizardContainer
            header={
              <Header color={dark ? 'default' : 'primary'}>
                <Toolbar>
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
            }
          >
            <Header color={dark ? 'default' : 'primary'}>
              <Toolbar>
                <EdgeTrigger target={{ anchor: 'left', field: 'open' }}>
                  {
                    ((
                      state: boolean,
                      setState: (newState: boolean) => void,
                    ) => (
                      <IconButton onClick={() => setState(!state)}>
                        {state ? 'Close' : 'Open'}
                      </IconButton>
                    )) as any
                  }
                </EdgeTrigger>
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
            <EdgeSidebar anchor="left">
              <SidebarContent style={{ overflow: 'hidden' }}>
                <NavContent />
              </SidebarContent>
              {/* <CollapseBtn style={{ overflow: 'hidden' }} /> */}
            </EdgeSidebar>
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
      </ThemeProvider>
    </ThemeContext.Provider>
  );
}

Layout.defaultProps = {
  footer: null,
};

export default Layout;
