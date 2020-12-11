import { MapType } from './common';
import { JobConfig } from './entities';
import { Comparison, Genome } from './enums';

export interface FileContainingConfig extends MapType {
  fastq1?: string;
  fastq2?: string;
  ubam?: string;
  bam?: string;
}

export interface FilterType extends MapType {
  comparison?: Comparison;
  value?: number;
}

export interface TumorOnlyAnalysisConfig
  extends FileContainingConfig,
    JobConfig {
  paired: boolean;
  vcf?: string;
  genome?: Genome;
  threads?: number;
  depthFilter: FilterType;
  alleleFractionFilter: FilterType;
}

export interface TumorNormalAnalysisConfig extends JobConfig {
  paired: boolean;
  tumor: FileContainingConfig;
  normal: FileContainingConfig;
  vcf?: string;
  genome?: Genome;
  threads?: number;
}
