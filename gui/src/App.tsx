import React from 'react';
import {
  createStyles,
  ImageList,
  ImageListItem,
  makeStyles,
  Typography,
} from '@material-ui/core';
import { Route, HashRouter as Router, Switch } from 'react-router-dom';
import injector from './injector';
import InjectorContext from './reactInjector/context';
import Constants from './constants/system.json';
import Routes from './constants/routes.json';
import UNICT_LOGO from './resources/unict.png';
import ThemeContext from './app/themeContext';
import * as Pages from './app/components/pages';
import Layout from './app/layout';

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

export default function App() {
  return (
    <InjectorContext.Provider value={injector}>
      <Router>
        <Layout>
          <Switch>
            <Route path={Routes.JOBS} component={Pages.JobsPage} />
            {/* <Route */}
            {/*  path={Routes.NEW_ANALYSIS} */}
            {/*  component={Pages.Forms.NewAnalysisForm} */}
            {/* /> */}
            <Route
              path={Routes.JOBS_BY_PATIENT}
              component={Pages.JobsByPatientPage}
            />
            <Route
              path={Routes.PATIENTS_CREATE}
              component={Pages.Forms.PatientForm}
            />
            <Route
              path={Routes.PATIENTS_EDIT}
              component={Pages.Forms.PatientForm}
            />
            {/* <Route */}
            {/*  path={Routes.PATIENTS_TUMORS} */}
            {/*  component={Pages.Forms.TumorForm} */}
            {/* /> */}
            <Route path={Routes.PATIENT} component={Pages.PatientPage} />
            <Route
              path={Routes.PATIENTS}
              exact
              component={Pages.PatientsPage}
            />
            <Route
              path={Routes.SETTINGS}
              exact
              component={Pages.SettingsPage}
            />
            <Route path={Routes.HOME} exact component={Home} />
          </Switch>
        </Layout>
      </Router>
    </InjectorContext.Provider>
  );
}
