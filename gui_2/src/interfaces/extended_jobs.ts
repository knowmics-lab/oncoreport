// import { Nullable } from './common';
// import {
//   Job,
//   JobBase,
//   JobCollectionItem,
//   JobOutput,
//   JobPathType,
//   JobTypes,
//   OutputTypes,
// } from './jobs';
// import { TumorNormalAnalysisConfig, TumorOnlyAnalysisConfig } from './analysis';
// import { PatientCollectionItem } from './patients';
//
// export interface ConfirmationOutputType extends JobOutput {
//   type: OutputTypes.confirmation;
//   done: boolean;
//   message?: Nullable<string>;
// }
//
// export interface TumorOnlyOutputType extends JobOutput {
//   type: OutputTypes.tumorOnly;
//   bamOutputFile: JobPathType;
//   vcfOutputFile: JobPathType;
//   vcfPASSOutputFile: JobPathType;
//   textOutputFiles: JobPathType;
//   reportOutputFile: JobPathType;
// }
//
// export interface TumorOnlyJobBase extends JobBase {
//   type: JobTypes.tumorOnly;
//   output?: TumorOnlyOutputType;
//   patient: PatientCollectionItem;
// }
//
// export interface TumorOnlyJob extends Job, TumorOnlyJobBase {
//   type: JobTypes.tumorOnly;
//   parameters: TumorOnlyAnalysisConfig;
//   output?: TumorOnlyOutputType;
//   patient: PatientCollectionItem;
// }
//
// export interface TumorOnlyJobCollectionItem
//   extends JobCollectionItem,
//     TumorOnlyJobBase {
//   type: JobTypes.tumorOnly;
//   output?: TumorOnlyOutputType;
//   patient: PatientCollectionItem;
// }
//
// export interface TumorNormalOutputType extends JobOutput {
//   type: OutputTypes.tumorNormal;
//   tumorBamOutputFile: JobPathType;
//   normalBamOutputFile: JobPathType;
//   vcfOutputFile: JobPathType;
//   vcfPASSOutputFile: JobPathType;
//   textOutputFiles: JobPathType;
//   reportOutputFile: JobPathType;
// }
//
// export interface TumorNormalJobBase extends JobBase {
//   type: JobTypes.tumorNormal;
//   output?: TumorNormalOutputType;
//   patient: PatientCollectionItem;
// }
//
// export interface TumorNormalJob extends Job, TumorNormalJobBase {
//   type: JobTypes.tumorNormal;
//   parameters: TumorNormalAnalysisConfig;
//   output?: TumorNormalOutputType;
//   patient: PatientCollectionItem;
// }
//
// export interface TumorNormalJobCollectionItem
//   extends JobCollectionItem,
//     TumorNormalJobBase {
//   type: JobTypes.tumorNormal;
//   output?: TumorNormalOutputType;
//   patient: PatientCollectionItem;
// }
//
// export function isTumorOnlyJob(job: Job): job is TumorOnlyJob {
//   return job.type === JobTypes.tumorOnly;
// }
//
// export function isTumorNormalJob(job: Job): job is TumorNormalJob {
//   return job.type === JobTypes.tumorNormal;
// }
//
// export function isTumorOnlyJobCollectionItem(
//   job: JobCollectionItem
// ): job is TumorOnlyJobCollectionItem {
//   return job.type === JobTypes.tumorOnly;
// }
//
// export function isTumorNormalJobCollectionItem(
//   job: JobCollectionItem
// ): job is TumorNormalJobCollectionItem {
//   return job.type === JobTypes.tumorNormal;
// }
