// noinspection SuspiciousTypeOfGuard

import React from 'react';
import { useParams } from 'react-router-dom';
import { generatePath } from 'react-router';
import Routes from '../../../constants/routes.json';
import JobsTableByPatient from './tables/jobsTableByPatient';

// const useStyles = makeStyles((theme) =>
//   createStyles({
//     backdrop: {
//       zIndex: theme.zIndex.drawer + 1,
//       color: '#fff',
//     },
//   })
// );

export default function JobsByPatient() {
  const patient: number = +useParams<{ id: string }>().id;

  return (
    <>
      <JobsTableByPatient
        patient={patient}
        title="Patient Analysis"
        backRoute={generatePath(Routes.PATIENTS)}
      />
    </>
  );
}

/*
          <Backdrop className={classes.backdrop} open={!patient}>
            <CircularProgress color="inherit" />
          </Backdrop>
 */
