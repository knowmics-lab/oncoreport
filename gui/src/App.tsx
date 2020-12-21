import React from 'react';
import { BrowserRouter as Router, Switch, Route } from 'react-router-dom';
import icon from '../assets/icon.svg';
import injector from './injector';
import { JobRepository, PatientRepository, Settings } from './api';

injector.resolve(Settings).setConfig({
  apiKey: '5|J1i9JMjO4wltBRi83eEknCgV4YnjX8GWaPW7qCUI',
});

const repo = injector.resolve(JobRepository);
const repo1 = injector.resolve(PatientRepository);

console.log(repo);

repo1
  .fetch(1)
  .then((p) => {
    // eslint-disable-next-line promise/no-nesting
    repo
      .fetchPageByPatient(p)
      .then((j) => {
        console.log(j);
        repo.refreshAllPagesByPatient(p);
      })
      .catch(console.error);
  })
  .catch(console.error);

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
    <Router>
      <Switch>
        <Route path="/" component={Hello} />
      </Switch>
    </Router>
  );
}
