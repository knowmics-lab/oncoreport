declare module 'find-free-port' {
  type Callback = (err: Error | null, ...freePorts: number[]) => void;

  type ReturnType<T extends Callback | undefined> = T extends undefined
    ? void
    : Promise<number[]>;

  export default function findFreePort<T extends Callback>(
    portBeg: number,
    portEnd?: number,
    host?: string,
    homany?: number,
    cb?: T
  ): ReturnType<T>;
}
