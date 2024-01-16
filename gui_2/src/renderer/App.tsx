import { MemoryRouter as Router, Routes, Route } from 'react-router-dom';
import '@fortawesome/fontawesome-free/css/all.css';
import './App.css';
import 'reflect-metadata';
import injector from '../injector';
import InjectorContext from '../reactInjector/context';
import RoutesList from '../constants/routes.json';
import AppStartedContext from './app/components/layout/appStartedContext';
import Layout from './app/layout';
import * as Pages from './app/pages';

export default function App() {
  return (
    <InjectorContext.Provider value={injector}>
      <AppStartedContext>
        <Router>
          <Layout>
            <Routes>
              <Route path={RoutesList.JOBS} element={<Pages.JobsPage />} />
              <Route
                path={RoutesList.NEW_ANALYSIS}
                element={<Pages.Forms.NewAnalysisForm />}
              />
              <Route
                path={RoutesList.JOBS_BY_PATIENT}
                element={<Pages.JobsByPatientPage />}
              />
              <Route
                path={RoutesList.PATIENTS_CREATE}
                element={<Pages.Forms.PatientForm />}
              />
              <Route
                path={RoutesList.PATIENTS_EDIT}
                element={<Pages.Forms.PatientForm />}
              />
              <Route
                path={RoutesList.PATIENT}
                element={<Pages.PatientPage />}
              />
              <Route
                path={RoutesList.PATIENTS}
                element={<Pages.PatientsPage />}
              />
              <Route
                path={RoutesList.SETTINGS}
                element={<Pages.SettingsPage />}
              />
              <Route path="/" element={<Pages.Home />} />
            </Routes>
          </Layout>
        </Router>
      </AppStartedContext>
    </InjectorContext.Provider>
  );
}
