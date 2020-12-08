/* eslint-disable class-methods-use-this */
import { container, injectable } from 'tsyringe';
import path from 'path';
import fs from 'fs-extra';
import { api as electron } from 'electron-util';
import {
  Job as JobObject,
  JobConfig,
  JobOutput,
  JobStatus,
  JobTypes,
} from '../../interfaces/entities/job';
import JobAdapter from '../adapters/job';
import Entity from './timedEntity';
import { fillable, fillableWithEntity, userReadonly } from './entity';
import { Nullable } from '../../interfaces/common';
import Patient from './patient';
import Settings from '../settings';
import { Utils } from '../index';
import Downloader from '../downloader';
import EntityError from '../../errors/EntityError';

@injectable()
export default class Job extends Entity<JobObject> implements JobObject {
  @fillable()
  log?: string;

  @fillable()
  name = '';

  @fillable()
  @userReadonly()
  output?: JobOutput;

  @fillable()
  @userReadonly()
  owner: unknown = {};

  @fillable()
  parameters?: JobConfig;

  @fillable()
  @fillableWithEntity(Patient)
  patient!: Nullable<Patient>;

  @fillable()
  @userReadonly()
  readable_type = '';

  @fillable()
  sample_code = '';

  @fillable()
  @userReadonly()
  status: JobStatus = JobStatus.ready;

  @fillable()
  type: JobTypes = JobTypes.empty;

  public constructor(adapter: JobAdapter, private settings: Settings) {
    super(adapter);
  }

  public getUploadUrl(): string {
    return this.adapter.connector.getEndpointUrl(`jobs/${this.id}/upload`);
  }

  public getLocalDirectory(): string {
    return this.settings.getLocalPath(`/public/jobs/${this.id}`);
  }

  public async download(
    outputVariable: string,
    onStart?: (s: string) => void,
    onCompleted?: (s: string) => void
  ): Promise<void> {
    if (this.output && Utils.hasPathProperty(this.output, outputVariable)) {
      const { path: outputPath } = this.output[outputVariable];
      const outputUrl = this.settings.getPublicUrl(outputPath);
      const outputFilename = path.basename(outputPath);
      Downloader.downloadUrl(
        outputUrl,
        outputFilename,
        () => onStart && onStart(outputVariable),
        () => onCompleted && onCompleted(outputVariable)
      ); // @todo modify with IOC
    } else {
      throw new EntityError('Unable to find output path');
    }
  }

  public async openLocalFolder(): Promise<void> {
    if (!this.settings.isLocal())
      throw new EntityError('Unable to open folder when in remote mode');
    if (this.output && Utils.hasPathProperty(this.output, 'reportOutputFile')) {
      const outputPath = this.output.reportOutputFile.path;
      if (outputPath) {
        const jobFolder = path.dirname(
          this.settings.getLocalPath(`/public/${outputPath}`)
        );
        if (!(await fs.pathExists(jobFolder)))
          throw new EntityError('Unable to find output path');
        if (!electron.shell.openItem(jobFolder)) {
          throw new EntityError('Unable to open output folder');
        }
        return;
      }
    }
    throw new EntityError('Unable to find output path');
  }

  public async openReport(): Promise<Window> {
    if (this.output && Utils.hasPathProperty(this.output, 'reportOutputFile')) {
      const reportPath = this.output.reportOutputFile.path;
      if (!reportPath) throw new EntityError('Unable to get report url');
      const reportUrl = this.settings.getPublicUrl(reportPath);
      const win = window.open(reportUrl, '_blank', 'nodeIntegration=no');
      if (!win) throw new EntityError('Unable to open browser window');
      win.focus();
      return win;
    }
    throw new EntityError('This job does not contain any report file');
  }

  public async submit(): Promise<this> {
    if (this.deleted) throw new Error('Attempting to submit deleted entity');
    return this.doFill(await (this.adapter as JobAdapter).submit(this), true);
  }

  public static async processDeletedList(deleted: number[]): Promise<number[]> {
    return container.resolve(JobAdapter).processDeletedList(deleted);
  }
}
