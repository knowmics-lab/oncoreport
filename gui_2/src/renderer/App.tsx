import { MemoryRouter as Router, Routes, Route } from 'react-router-dom';
import icon from '../../assets/icon.svg';
import '@fortawesome/fontawesome-free/css/all.css';
import './App.css';
import injector from '../injector';
import InjectorContext from '../reactInjector/context';
import AppStartedContext from './app/components/layout/appStartedContext';

function Hello() {
  return (
    <div>
      <div className="Hello">
        <img width="200" alt="icon" src={icon} />
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
            <span role="img" aria-label="folded hands">
              🙏
            </span>
            Donate
          </button>
        </a>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <InjectorContext.Provider value={injector}>
      <AppStartedContext>
        <Router>
          <Routes>
            <Route path="/" element={<Hello />} />
          </Routes>
        </Router>
      </AppStartedContext>
    </InjectorContext.Provider>
  );
}
