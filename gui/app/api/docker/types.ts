export type DockerPullEvent = {
  status: string;
  id?: string;
  progress?: string;
};

export type AuthTokenResult = {
  error: number;
  data: string;
};
