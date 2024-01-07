/* eslint-disable class-methods-use-this */
import path from 'path';
import fs from 'fs-extra';
import { api as electron } from 'electron-util';
import { injectable } from 'tsyringe';
import type { JobConfig, JobOutput, Nullable } from '../../interfaces';
import { JobStatus, JobTypes } from '../../interfaces';
import Patient from './patient';
import Settings from '../settings';
import { PatientRepository } from '../repositories';
import { Utils } from '../index';
import EntityError from '../../errors/EntityError';
import TransferManager from '../transferManager';
import { JobAdapter } from '../adapters';
import Entity, { field } from '../../apiConnector/entity/entity';
import { RelationsType } from '../../apiConnector';

@injectable()
export default class Job extends Entity {
  @field<string>({
    fillable: true,
  })
  public sample_code = '';

  @field<string>({
    fillable: true,
  })
  public name = '';

  @field<JobTypes>({
    fillable: true,
  })
  public type: JobTypes = JobTypes.empty;

  @field<string>({
    readonly: true,
  })
  public readable_type = '';

  @field<JobStatus>({
    readonly: true,
  })
  public status: JobStatus = JobStatus.ready;

  @field<JobConfig>({
    fillable: true,
    serialize: {
      leaveAsIs: true,
    },
  })
  public parameters?: JobConfig;

  @field<JobOutput>({
    readonly: true,
  })
  public output?: JobOutput;

  @field<string>({
    readonly: true,
  })
  public log?: string;

  @field<Patient>({
    fillable: true,
    relation: {
      type: RelationsType.ONE,
      repositoryToken: PatientRepository,
      noRecursionSave: true,
    },
    serialize: {
      serializedKey: 'patient_id',
    },
  })
  public patient!: Nullable<Patient>;

  public constructor(
    adapter: JobAdapter,
    private settings: Settings,
    private transferManager: TransferManager,
  ) {
    super(adapter);
  }

  public getUploadUrl(): string {
    if (this.isNew)
      throw new Error('No upload can be performed until the object is saved');
    return this.adapter.client.getEndpointUrl(`jobs/${this.id}/upload`);
  }

  public getLocalDirectory(): string {
    return this.settings.getLocalPath(`/public/jobs/${this.id}`);
  }

  public hasOutputFile(outputVariable: string) {
    return this.output && Utils.hasPathProperty(this.output, outputVariable);
  }

  public async download(
    outputVariable: string,
    onStart?: (s: string) => void,
    onCompleted?: (s: string) => void,
  ): Promise<void> {
    if (this.output && Utils.hasPathProperty(this.output, outputVariable)) {
      const { path: outputPath } = this.output[outputVariable];
      const outputUrl = this.settings.getPublicUrl(outputPath);
      const outputFilename = path.basename(outputPath);
      this.transferManager.download(
        outputUrl,
        outputFilename,
        onStart ? () => onStart(outputVariable) : undefined,
        onCompleted ? () => onCompleted(outputVariable) : undefined,
      );
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
          this.settings.getLocalPath(`/public/${outputPath}`),
        );
        if (!(await fs.pathExists(jobFolder)))
          throw new EntityError('Unable to find output path');
        if (!electron.shell.openPath(jobFolder)) {
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
    if (this.isDeleted)
      throw new EntityError('Attempting to submit deleted entity');
    if (this.isNew || this.isDirty) {
      await this.save();
    }
    await (this.adapter as unknown as JobAdapter).submit(this.id);
    return this.refresh();
  }
}
