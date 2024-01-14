import React, { useEffect } from 'react';
import { CssBaseline, createTheme, ThemeProvider } from '@mui/material';
import Box from '@mui/material/Box';
import useMediaQuery from '@mui/material/useMediaQuery';
import { Footer } from '@mui-treasury/layout';
import {
  LayoutHeader,
  Notifications,
  ContentWrapper,
  BlockingMessageHandler,
  StartHandler,
} from './components/layout';
import SetupWizardContainer from './components/setup/setupWizardContainer';
import ThemeContext from './themeContext';
import useDarkMode from './hooks/useDarkMode';
import useToggle from './hooks/useToggle';
import LeftDrawer from './components/layout/leftDrawer';
import usePrevious from './hooks/usePrevious';

type Props = {
  children: React.ReactNode;
  footer?: React.ReactNode;
};

function Layout({ children, footer }: Props) {
  const [dark, setDark] = useDarkMode();
  const isMedium = useMediaQuery('(min-width:900px)');
  const prevMedium = usePrevious(isMedium);
  const [open, toggleOpen] = useToggle(false);

  useEffect(() => {
    if (isMedium && prevMedium !== isMedium) {
      toggleOpen(true);
    } else if (!isMedium && prevMedium !== isMedium) {
      toggleOpen(false);
    }
  }, [isMedium, prevMedium, toggleOpen]);

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
        <Box sx={{ display: 'flex' }}>
          <CssBaseline />
          <SetupWizardContainer
            header={
              <LayoutHeader
                themeSwitcher={{ label: switcherLabel, setDark, dark }}
              />
            }
          >
            <LayoutHeader
              hasDrawer
              toggleDrawer={toggleOpen}
              open={open}
              themeSwitcher={{
                label: switcherLabel,
                setDark,
                dark,
              }}
            />
            <LeftDrawer open={open} />
            <ContentWrapper>
              <StartHandler />
              {children}
              <Notifications />
              <BlockingMessageHandler />
              {footer && <Footer>{footer}</Footer>}
            </ContentWrapper>
          </SetupWizardContainer>
        </Box>
      </ThemeProvider>
    </ThemeContext.Provider>
  );
}

Layout.defaultProps = {
  footer: null,
};

export default Layout;
