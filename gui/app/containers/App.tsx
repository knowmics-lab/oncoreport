import React, { ReactNode } from 'react';
import injector from '../injector';
import Settings from '../api/settings';
import Job from '../api/entities/job';

type Props = {
  children: ReactNode;
};

console.log(injector.resolve('config'));

console.log(
  injector.resolve(Settings).setConfig({
    apiKey: '4|nQFrAucFZv9GG5D30u8s1yZ9nWvHU52mZZItXYR5',
  })
);

const job = injector.resolve(Job);
console.log(job);
job.setId(2).then(() => {
  console.log(job);
});

export default function App(props: Props) {
  const { children } = props;
  return <>{children}</>;
}
