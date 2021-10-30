import React, { useMemo } from 'react';
import { useHistory } from 'react-router-dom';
import { generatePath } from 'react-router';
import { Grid, Icon } from '@material-ui/core';
import Routes from '../../../../constants/routes.json';
import Button from '../../ui/Button';
import useStyles from './useStyles';

type Props = {
  id: number;
};

const GoBackRow = ({ id }: Props) => {
  const classes = useStyles();
  const history = useHistory();
  const backUrl = useMemo(() => generatePath(Routes.PATIENTS), []);
  const editUrl = useMemo(
    () => generatePath(Routes.PATIENTS_EDIT, { id }),
    [id]
  );
  return (
    <Grid
      container
      justifyContent="space-between"
      className={classes.topSeparation}
    >
      <Grid item xs="auto">
        <Button
          variant="contained"
          color="default"
          onClick={() => history.push(backUrl)}
        >
          <Icon className="fas fa-arrow-left" /> Go Back
        </Button>
      </Grid>
      <Grid item xs="auto">
        <Button
          color="primary"
          variant="contained"
          onClick={() => history.push(editUrl)}
        >
          Edit
        </Button>
      </Grid>
    </Grid>
  );
};

export default GoBackRow;
