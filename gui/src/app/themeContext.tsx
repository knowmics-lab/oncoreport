import React from 'react';

const ThemeContext = React.createContext<boolean>(false);
ThemeContext.displayName = 'ThemeContext';

export default ThemeContext;
