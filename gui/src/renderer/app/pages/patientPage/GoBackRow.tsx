import React, { useMemo } from 'react';
import { useNavigate, generatePath } from 'react-router-dom';
import { Grid, Icon } from '@mui/material';
import Routes from '../../../../constants/routes.json';
import Button from '../../components/ui/Button';
import styles from '../styles';

type Props = {
  id: number;
};

function GoBackRow({ id }: Props) {
  const navigate = useNavigate();
  const backUrl = useMemo(() => generatePath(Routes.PATIENTS), []);
  const editUrl = useMemo(
    () => generatePath(Routes.PATIENTS_EDIT, { id }),
    [id],
  );
  return (
    <Grid container justifyContent="space-between" sx={styles.topSeparation}>
      <Grid item xs="auto">
        <Button
          variant="contained"
          // color="default"
          onClick={() => navigate(backUrl)}
        >
          <Icon className="fas fa-arrow-left" /> Go Back
        </Button>
      </Grid>
      <Grid item xs="auto">
        <Button
          color="primary"
          variant="contained"
          onClick={() => navigate(editUrl)}
        >
          Edit
        </Button>
      </Grid>
    </Grid>
  );
}

export default GoBackRow;
