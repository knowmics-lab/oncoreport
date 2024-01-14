import React, { Dispatch, SetStateAction } from 'react';
import { Toolbar, Tooltip, AppBar } from '@mui/material';
import IconButton from '@mui/material/IconButton';
import MenuIcon from '@mui/icons-material/Menu';
import MenuOpen from '@mui/icons-material/MenuOpen';
import Typography from '@mui/material/Typography';
import Brightness7 from '@mui/icons-material/Brightness7';
import Brightness4 from '@mui/icons-material/Brightness4';
import APP_LOGO from '../../../../resources/logoOncoReport.png';

interface ThemeSwitcherProps {
  label: string;
  setDark: Dispatch<SetStateAction<boolean | undefined>>;
  dark: boolean;
}

interface HeaderProps {
  hasDrawer?: boolean;
  toggleDrawer?: () => void;
  open?: boolean;
  themeSwitcher: ThemeSwitcherProps;
}

function ThemeSwitcher({ label, setDark, dark }: ThemeSwitcherProps) {
  return (
    <Tooltip title={label}>
      <IconButton aria-label={label} onClick={() => setDark((v) => !v)}>
        {dark ? <Brightness7 /> : <Brightness4 />}
      </IconButton>
    </Tooltip>
  );
}

export default function Header({
  hasDrawer,
  toggleDrawer,
  open,
  themeSwitcher,
}: HeaderProps) {
  return (
    <AppBar
      position="fixed"
      sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}
    >
      <Toolbar
        sx={{
          pr: '24px', // keep right padding when drawer closed
        }}
      >
        {hasDrawer && (
          <IconButton
            edge="start"
            color="inherit"
            aria-label="open drawer"
            onClick={() => toggleDrawer!()}
            sx={{
              marginRight: '36px',
            }}
          >
            {open ? <MenuOpen /> : <MenuIcon />}
          </IconButton>
        )}
        <Typography
          component="h1"
          variant="h6"
          color="inherit"
          noWrap
          sx={{
            flexGrow: 1,
            display: 'flex',
            alignItems: 'center',
          }}
        >
          <img
            src={APP_LOGO}
            alt="OncoReport"
            style={{ height: '36px', width: 'auto' }}
          />
        </Typography>
        <ThemeSwitcher {...themeSwitcher} />
      </Toolbar>
    </AppBar>
  );
}

Header.defaultProps = {
  hasDrawer: false,
  toggleDrawer: () => undefined,
  open: false,
};
