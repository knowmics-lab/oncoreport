import React from 'react';
import { withStyles } from '@material-ui/core/styles';
import Typography from '@material-ui/core/Typography';
import { ClassNameMap } from '@material-ui/styles/withStyles/withStyles';

type Props = {
  classes: Partial<ClassNameMap>;
};

const Header = ({ classes }: Props) => (
  <>
    <Typography noWrap color="textSecondary" className={classes.header}>
      Oncoreport
    </Typography>
    <div className={classes.grow} />
  </>
);

export default withStyles({
  header: {
    fontWeight: 900,
    minWidth: 0,
    fontSize: 18,
  },
  grow: {
    flexGrow: 1,
  },
})(Header);
