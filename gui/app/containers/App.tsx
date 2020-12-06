import React, { ReactNode } from 'react';
import injector from '../injector';

type Props = {
  children: ReactNode;
};

console.log(injector.resolve('config'));

export default function App(props: Props) {
  const { children } = props;
  return <>{children}</>;
}
