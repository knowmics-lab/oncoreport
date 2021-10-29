import React, { useEffect, useState } from 'react';
import {
  createStyles,
  ImageList,
  ImageListItem,
  makeStyles,
  Typography,
} from '@material-ui/core';
import injector from './injector';
import InjectorContext from './reactInjector/context';
import Constants from './constants/system.json';
import UNICT_LOGO from './resources/unict.png';
import ThemeContext from './app/themeContext';
import { DiseaseRepository } from './api';
import useDebugInformation from './app/hooks/useDebug';
import useRepositorySearch from './app/hooks/useRepositorySearch';
import useDebounce from './app/hooks/useDebounce';

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
  const [query, setQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState<string>();
  useDebounce(
    () => {
      if (query.length > 3) {
        setDebouncedQuery(query);
      } else {
        setDebouncedQuery(undefined);
      }
    },
    500,
    [query]
  );
  const [loading, resultSet] = useRepositorySearch(
    DiseaseRepository,
    debouncedQuery,
    { tumor: true }
  );

  useEffect(() => {
    if (resultSet) {
      console.log(resultSet?.map((e) => e.toDataObject()));
    }
  }, [resultSet]);
  useDebugInformation('Test', { loading, resultSet, debouncedQuery, query });
  return (
    <>
      <h1>Test!!</h1>
      <div>
        <input
          type="text"
          placeholder="Enter test query"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>
      <div>
        <b>Loading: </b>
        <code>{loading ? 'Yes' : 'No'}</code>
      </div>
      {resultSet && (
        <>
          <div>
            <b>Size: </b>
            <code>{resultSet.length}</code>
          </div>
          <div>
            <button onClick={() => resultSet?.refresh()} type="button">
              Refresh
            </button>
          </div>
        </>
      )}
    </>
  );
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
