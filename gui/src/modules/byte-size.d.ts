declare module 'byte-size' {
  export class ByteSize {
    public value: string;

    public unit: string;

    public long: string;

    public toString(): string;
  }

  export default function byteSize(
    bytes: number,
    options?: {
      precision?: number;
      units?: 'metric' | 'iec' | 'metric_octet' | 'iec_octet';
      toStringFn?: () => string & ThisType<ByteSize>;
    },
  ): ByteSize;
}
