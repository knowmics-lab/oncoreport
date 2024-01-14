import React, { ForwardedRef, useState } from 'react';
import { get, set } from 'lodash';
import {
  List,
  ListItemText,
  ListItemIcon,
  Icon,
  Divider,
  Collapse,
  ListItemButton,
  styled,
  ClassNameMap,
} from '@mui/material';
import { NavLink as RouterLink, NavLinkProps } from 'react-router-dom';
import ExpandLess from '@mui/icons-material/ExpandLess';
import ExpandMore from '@mui/icons-material/ExpandMore';
import { produce } from 'immer';
import menu from '../../../../constants/menu.json';
import { Nullable, SimpleMapType } from '../../../../interfaces';
import { useService } from '../../../../reactInjector';
import { Settings } from '../../../../api';

type ListItemLinkProps = {
  icon?: Nullable<React.ReactNode>;
  primary: string;
  to: string;
  classes?: Partial<ClassNameMap>;
  className?: string;
  exact?: boolean;
};

type LinkComponentProps = Pick<
  React.PropsWithoutRef<NavLinkProps>,
  Exclude<keyof React.PropsWithoutRef<NavLinkProps>, 'to' | 'className'>
> & { className: string | undefined };

const LinkComponentGenerator = (to: string, exact?: boolean) =>
  React.forwardRef(
    (
      { className, ...itemProps }: LinkComponentProps,
      ref: ForwardedRef<HTMLAnchorElement>,
    ) => {
      return (
        <RouterLink
          to={to}
          caseSensitive={!!exact}
          {...itemProps}
          ref={ref}
          className={({ isActive }) =>
            isActive ? `${className} Mui-selected` : className
          }
        />
      );
    },
  );

function ListItemLink({
  icon,
  primary,
  to,
  classes,
  className,
  exact,
}: ListItemLinkProps) {
  const renderLink = React.useMemo(
    () => LinkComponentGenerator(to, exact),
    [to, exact],
  );

  return (
    <ListItemButton component={renderLink} className={className}>
      {icon ? <ListItemIcon>{icon}</ListItemIcon> : null}
      <ListItemText
        classes={classes}
        primary={primary}
        primaryTypographyProps={{ noWrap: true }}
      />
    </ListItemButton>
  );
}

ListItemLink.defaultProps = {
  icon: null,
  classes: null,
  className: null,
  exact: false,
};

const NestedListItemLink = styled(ListItemLink)(({ theme }) => ({
  paddingLeft: theme.spacing(4),
  fontSize: 1,
}));

type ListItemExpandableProps = {
  icon?: Nullable<React.ReactNode>;
  primary: string;
  isOpen: boolean;
  handleClick: () => void;
  classes?: Partial<ClassNameMap>;
  className?: string;
};

function ListItemExpandable({
  icon,
  primary,
  isOpen,
  handleClick,
  classes,
  className,
}: ListItemExpandableProps) {
  return (
    <div>
      <ListItemButton onClick={handleClick} className={className}>
        {icon ? <ListItemIcon>{icon}</ListItemIcon> : null}
        <ListItemText
          classes={classes}
          primary={primary}
          primaryTypographyProps={{ noWrap: true }}
        />
        {isOpen ? <ExpandLess /> : <ExpandMore />}
      </ListItemButton>
    </div>
  );
}

ListItemExpandable.defaultProps = {
  icon: null,
  classes: null,
  className: null,
};

export type MenuItem = {
  icon: string;
  text: string;
  collapsible: boolean;
  configured: boolean;
  key: string;
  items?: MenuItem[];
  to?: string;
  divider?: boolean;
  exact?: boolean;
};

const useCollapsibleState = () => {
  const [collapsibleState, setCollapsibleState] = useState(
    {} as SimpleMapType<boolean>,
  );
  const getState = (key: string): boolean => {
    return get(collapsibleState, key, false);
  };
  const setState = (key: string) => {
    setCollapsibleState((prevState) => {
      return produce(prevState, (draft) => {
        set(draft, key, !get(draft, key, false));
      });
    });
  };
  return [{ getState, setState }];
};

const NestedListItemExpandable = styled(ListItemExpandable)(({ theme }) => ({
  paddingLeft: theme.spacing(4),
  fontSize: 1,
}));

const NestedCollapse = styled(Collapse)(({ theme }) => ({
  paddingLeft: theme.spacing(4),
  fontSize: 1,
}));

function NavContent() {
  const [{ getState, setState }] = useCollapsibleState();
  const settings = useService(Settings);

  const renderMenuItems = (
    items: Nullable<MenuItem[]>,
    renderMenuItem: (item: MenuItem, nested: boolean) => React.ReactNode,
    nested = false,
  ): React.ReactNode => {
    if (!items) return null;
    const itemElements = items.map((item) => renderMenuItem(item, nested));
    if (nested) {
      return (
        <List component="div" disablePadding>
          {itemElements}
        </List>
      );
    }

    return <List>{itemElements}</List>;
  };

  const renderMenuItem = (
    {
      icon,
      text,
      collapsible,
      configured,
      key,
      items,
      to,
      divider,
      exact,
    }: MenuItem,
    nested = false,
  ): React.ReactNode => {
    if (configured && !settings.isConfigured()) return null;
    if (divider) return <Divider key={key} sx={{ margin: '12px 0' }} />;
    if (collapsible) {
      const ExpandableComponent = nested
        ? NestedListItemExpandable
        : ListItemExpandable;
      const CollapseComponent = nested ? NestedCollapse : Collapse;
      return (
        <React.Fragment key={key}>
          <ExpandableComponent
            icon={<Icon className={icon} />}
            primary={text}
            isOpen={getState(key)}
            handleClick={() => setState(key)}
            // className={nested ? classes.nested : undefined}
          />
          <CollapseComponent
            in={getState(key)}
            timeout="auto"
            unmountOnExit
            // className={nested ? classes.nested : undefined}
          >
            {renderMenuItems(items, renderMenuItem, true)}
          </CollapseComponent>
        </React.Fragment>
      );
    }
    if (to) {
      const Link = nested ? NestedListItemLink : ListItemLink;
      return (
        <Link
          icon={<Icon className={icon} />}
          primary={text}
          to={to}
          exact={exact}
          key={key}
        />
      );
    }
    return null;
  };

  return (
    <>{renderMenuItems(menu.items as MenuItem[], renderMenuItem, false)}</>
  );
}

export default NavContent;
