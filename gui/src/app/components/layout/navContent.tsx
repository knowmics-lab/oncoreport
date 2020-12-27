import React, { ForwardedRef, useState } from 'react';
import { get, set } from 'lodash';
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';
import ListItemText from '@material-ui/core/ListItemText';
import ListItemIcon from '@material-ui/core/ListItemIcon';
import Icon from '@material-ui/core/Icon';
import Divider from '@material-ui/core/Divider';
import { NavLink as RouterLink, NavLinkProps } from 'react-router-dom';
import ExpandLess from '@material-ui/icons/ExpandLess';
import ExpandMore from '@material-ui/icons/ExpandMore';
import Collapse from '@material-ui/core/Collapse';
import { ClassNameMap } from '@material-ui/styles/withStyles/withStyles';
import { makeStyles, Theme } from '@material-ui/core';
import produce from 'immer';
import menu from '../../../constants/menu.json';
import { Nullable, SimpleMapType } from '../../../interfaces';
import { useService } from '../../../reactInjector';
import { Settings } from '../../../api';

type ListItemLinkProps = {
  icon?: Nullable<React.ReactNode>;
  primary: string;
  to: string;
  classes?: Partial<ClassNameMap>;
  className?: string;
  exact?: boolean;
};

const ListItemLink = ({
  icon,
  primary,
  to,
  classes,
  className,
  exact,
}: ListItemLinkProps) => {
  const renderLink = React.useMemo(
    () =>
      React.forwardRef(
        (
          itemProps: Pick<
            React.PropsWithoutRef<NavLinkProps>,
            Exclude<keyof React.PropsWithoutRef<NavLinkProps>, 'to'>
          >,
          ref: ForwardedRef<HTMLAnchorElement>
        ) => (
          <RouterLink
            to={to}
            exact={!!exact}
            {...itemProps}
            innerRef={ref}
            activeClassName="Mui-selected"
          />
        )
      ),
    [to, exact]
  );

  return (
    <ListItem button component={renderLink} className={className}>
      {icon ? <ListItemIcon>{icon}</ListItemIcon> : null}
      <ListItemText
        classes={classes}
        primary={primary}
        primaryTypographyProps={{ noWrap: true }}
      />
    </ListItem>
  );
};

ListItemLink.defaultProps = {
  icon: null,
  classes: null,
  className: null,
  exact: false,
};

type ListItemExpandableProps = {
  icon?: Nullable<React.ReactNode>;
  primary: string;
  isOpen: boolean;
  handleClick: () => void;
  classes?: Partial<ClassNameMap>;
  className?: string;
};

const ListItemExpandable = ({
  icon,
  primary,
  isOpen,
  handleClick,
  classes,
  className,
}: ListItemExpandableProps) => {
  return (
    <div>
      <ListItem button onClick={handleClick} className={className}>
        {icon ? <ListItemIcon>{icon}</ListItemIcon> : null}
        <ListItemText
          classes={classes}
          primary={primary}
          primaryTypographyProps={{ noWrap: true }}
        />
        {isOpen ? <ExpandLess /> : <ExpandMore />}
      </ListItem>
    </div>
  );
};

ListItemExpandable.defaultProps = {
  icon: null,
  classes: null,
  className: null,
};

const useStyles = makeStyles((theme: Theme) => ({
  nested: {
    paddingLeft: theme.spacing(4),
    fontSize: 1,
  },
}));

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
    {} as SimpleMapType<boolean>
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

const NavContent = () => {
  const [{ getState, setState }] = useCollapsibleState();
  const classes = useStyles();
  const settings = useService(Settings);

  const renderMenuItems = (
    items: Nullable<MenuItem[]>,
    nested = false,
    renderMenuItem: (item: MenuItem, nested: boolean) => React.ReactNode
  ): React.ReactNode => {
    if (!items) return null;
    const itemsElements = items.map((item) => renderMenuItem(item, nested));
    if (nested) {
      return (
        <List component="div" disablePadding>
          {itemsElements}
        </List>
      );
    }

    return <List>{itemsElements}</List>;
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
    nested = false
  ): React.ReactNode => {
    if (configured && !settings.isConfigured()) return null;
    if (divider) return <Divider key={key} style={{ margin: '12px 0' }} />;
    if (collapsible) {
      return (
        <React.Fragment key={key}>
          <ListItemExpandable
            icon={<Icon className={icon} />}
            primary={text}
            isOpen={getState(key)}
            handleClick={() => setState(key)}
            className={nested ? classes.nested : undefined}
          />
          <Collapse
            in={getState(key)}
            timeout="auto"
            unmountOnExit
            className={nested ? classes.nested : undefined}
          >
            {renderMenuItems(items, true, renderMenuItem)}
          </Collapse>
        </React.Fragment>
      );
    }
    if (to) {
      return (
        <ListItemLink
          icon={<Icon className={icon} />}
          primary={text}
          to={to}
          exact={exact}
          key={key}
          className={nested ? classes.nested : undefined}
        />
      );
    }
    return null;
  };

  return (
    <>{renderMenuItems(menu.items as MenuItem[], false, renderMenuItem)}</>
  );
};

export default NavContent;
