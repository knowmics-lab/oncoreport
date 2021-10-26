export enum Gender {
  m = 'm',
  f = 'f',
}

export enum OutputTypes {
  confirmation = 'confirmation',
  tumorOnly = 'tumor-only',
  tumorNormal = 'tumor-vs-normal',
}

export enum JobStatus {
  ready = 'ready',
  queued = 'queued',
  processing = 'processing',
  completed = 'completed',
  failed = 'failed',
}

export enum JobTypes {
  empty = '',
  tumorOnly = 'tumor_only_analysis_job_type',
  tumorNormal = 'tumor_vs_normal_analysis_job_type',
}

export enum Comparison {
  lt = 'lt',
  lte = 'lte',
  gt = 'gt',
  gte = 'gte',
}

export enum Genome {
  hg19 = 'hg19',
  hg38 = 'hg38',
}

export enum SortingDirection {
  asc = 'asc',
  desc = 'desc',
}

export enum TypeOfNotification {
  success = 'success',
  warning = 'warning',
  error = 'error',
  info = 'info',
}

export enum ApiProtocol {
  http = 'http',
  https = 'https',
}

export enum TumorTypes {
  primary = 'primary',
  secondary = 'secondary',
}
