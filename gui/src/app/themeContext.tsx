import React from 'react';

const ThemeContext = React.createContext<boolean>(true);
ThemeContext.displayName = 'ThemeContext';

export default ThemeContext;
