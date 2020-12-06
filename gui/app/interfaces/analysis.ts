import { MapType, Nullable } from './common';

export type JobConfig = MapType;

export interface FileContainingConfig extends MapType {
  fastq1?: Nullable<string>;
  fastq2?: Nullable<string>;
  ubam?: Nullable<string>;
  bam?: Nullable<string>;
}

export interface FilterType extends MapType {
  comparison?: 'lt' | 'lte' | 'gt' | 'gte';
  value?: number;
}

export interface TumorOnlyAnalysisConfig
  extends FileContainingConfig,
    JobConfig {
  paired: boolean;
  vcf?: Nullable<string>;
  genome?: 'hg19' | 'hg38';
  threads?: number;
  depthFilter: FilterType;
  alleleFractionFilter: FilterType;
}

export interface TumorNormalAnalysisConfig extends JobConfig {
  paired: boolean;
  tumor: FileContainingConfig;
  normal: FileContainingConfig;
  vcf?: Nullable<string>;
  genome?: 'hg19' | 'hg38';
  threads?: number;
}
