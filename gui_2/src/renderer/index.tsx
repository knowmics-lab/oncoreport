import { createRoot } from 'react-dom/client';
import { ipcRenderer } from 'electron';
import App from './App';

const container = document.getElementById('root') as HTMLElement;
const root = createRoot(container);
root.render(<App />);

// calling IPC exposed from preload script
ipcRenderer.once('ipc-example', (arg) => {
  // eslint-disable-next-line no-console
  console.log(arg);
});
ipcRenderer.send('ipc-example', ['ping']);
