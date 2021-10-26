import React from 'react';
import { HashRouter as Router, Switch, Route } from 'react-router-dom';
import {
  createStyles,
  ImageList,
  ImageListItem,
  Typography,
  makeStyles,
} from '@material-ui/core';
import injector from './injector';
import InjectorContext from './reactInjector/context';
import Routes from './constants/routes.json';
import Constants from './constants/system.json';
import Layout from './app/layout';
import * as Pages from './app/components/pages';
import UNICT_LOGO from './resources/unict.png';
import ThemeContext from './app/themeContext';
import { useContainer, useService } from './reactInjector';
import { DiseaseRepository, PatientRepository } from './api';
import { runAsync } from './app/components/utils';

const useStyles = makeStyles(() =>
  createStyles({
    footerLight: {
      textAlign: 'center',
      position: 'fixed',
      bottom: 0,
      marginBottom: '20px',
      width: '100% !important',
    },
    footerDark: {
      textAlign: 'center',
      position: 'fixed',
      bottom: 0,
      marginBottom: '20px',
      width: '100% !important',
      '& img': {
        filter: 'invert(1)',
      },
    },
  })
);

const Home = () => {
  const classes = useStyles();
  return (
    <div>
      <Typography variant="overline">WELCOME</Typography>
      <Typography variant="h4" gutterBottom style={{ fontWeight: 'bold' }}>
        OncoReport
      </Typography>
      <Typography gutterBottom>
        <b>{`Version ${Constants.GUI_VERSION}`}</b>
      </Typography>
      <Typography>TODO text goes here</Typography>
      <ThemeContext.Consumer>
        {(dark) => (
          <div className={dark ? classes.footerDark : classes.footerLight}>
            <ImageList rowHeight={55} cols={3}>
              <ImageListItem cols={1}>
                <img
                  src={UNICT_LOGO}
                  alt="UNICT"
                  style={{ height: '50px', width: 'auto' }}
                />
              </ImageListItem>
            </ImageList>
          </div>
        )}
      </ThemeContext.Consumer>
    </div>
  );
};

function Test() {
  const container = useContainer();
  runAsync(async () => {
    const repository = container.resolve(PatientRepository);
    const query = repository.query();
    console.log(await repository.query().get());
    console.log(await (await repository.fetch(3)).refresh());
  });
  return <h1>Test!!</h1>;
}

export default function App() {
  return (
    <InjectorContext.Provider value={injector}>
      <Test />
      {/* <Router> */}
      {/*  <Layout> */}
      {/*    <Switch> */}
      {/*      <Route path={Routes.JOBS} component={Pages.JobsPage} /> */}
      {/*      <Route */}
      {/*        path={Routes.NEW_ANALYSIS} */}
      {/*        component={Pages.Forms.NewAnalysisForm} */}
      {/*      /> */}
      {/*      <Route */}
      {/*        path={Routes.JOBS_BY_PATIENT} */}
      {/*        component={Pages.JobsByPatientPage} */}
      {/*      /> */}
      {/*      <Route */}
      {/*        path={Routes.PATIENTS_CREATE} */}
      {/*        component={Pages.Forms.PatientForm} */}
      {/*      /> */}
      {/*      <Route */}
      {/*        path={Routes.PATIENTS_EDIT} */}
      {/*        component={Pages.Forms.PatientForm} */}
      {/*      /> */}
      {/*      /!* <Route *!/ */}
      {/*      /!*  path={Routes.PATIENTS_TUMORS} *!/ */}
      {/*      /!*  component={Pages.Forms.TumorForm} *!/ */}
      {/*      /!* /> *!/ */}
      {/*      <Route path={Routes.PATIENT} component={Pages.PatientPage} /> */}
      {/*      <Route */}
      {/*        path={Routes.PATIENTS} */}
      {/*        exact */}
      {/*        component={Pages.PatientsPage} */}
      {/*      /> */}
      {/*      <Route */}
      {/*        path={Routes.SETTINGS} */}
      {/*        exact */}
      {/*        component={Pages.SettingsPage} */}
      {/*      /> */}
      {/*      <Route path={Routes.HOME} exact component={Home} /> */}
      {/*    </Switch> */}
      {/*  </Layout> */}
      {/* </Router> */}
    </InjectorContext.Provider>
  );
}
