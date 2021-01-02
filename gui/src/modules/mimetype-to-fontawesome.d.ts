declare module 'mimetype-to-fontawesome' {
  export default function mimetype2fa(options?: {
    prefix?: string;
    version?: number;
  }): (mimetype: string) => string;
}
