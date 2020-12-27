import React from 'react';
import { HashRouter as Router, Switch, Route } from 'react-router-dom';
import icon from '../assets/icon.svg';
import injector from './injector';
import InjectorContext from './reactInjector/context';
import Routes from './constants/routes.json';
import Layout from './app/layout';
import * as Pages from './app/components/pages';

const Hello = () => {
  return (
    <div>
      <div className="Hello">
        <img width="200px" alt="icon" src={icon} />
      </div>
      <h1>electron-react-boilerplate</h1>
      <div className="Hello">
        <a
          href="https://electron-react-boilerplate.js.org/"
          target="_blank"
          rel="noreferrer"
        >
          <button type="button">
            <span role="img" aria-label="books">
              📚
            </span>
            Read our docs
          </button>
        </a>
        <a
          href="https://github.com/sponsors/electron-react-boilerplate"
          target="_blank"
          rel="noreferrer"
        >
          <button type="button">
            <span role="img" aria-label="books">
              🙏
            </span>
            Donate
          </button>
        </a>
      </div>
    </div>
  );
};

export default function App() {
  return (
    <InjectorContext.Provider value={injector}>
      <Router>
        <Layout>
          <Switch>
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
            <Route path={Routes.HOME} exact component={Hello} />
          </Switch>
        </Layout>
      </Router>
    </InjectorContext.Provider>
  );
}
