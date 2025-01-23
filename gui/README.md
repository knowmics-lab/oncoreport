## Oncoreport GUI v. 1.0.1

This GUI uses the Electron React Boilerplate that still does not support Node 23.

To avoid issue in development run using Node 22.

In macOS, you can install Node 22 using Homebrew:

```bash
brew install node@22
```

Then, you can run the GUI using Node 22:

```bash
    export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
    npm install
    npm start
```