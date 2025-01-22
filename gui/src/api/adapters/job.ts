import { singleton } from 'tsyringe';
import { sprintf } from 'sprintf-js';
import { get, has } from 'lodash';
import { Adapter, HttpClient } from '../../apiConnector';
import { JobEntity } from '../entities';
import type { PartialObject } from '../../apiConnector/interfaces/common';
import { MapType, SimpleMapType } from '../../apiConnector/interfaces/common';
import { QueryRequest } from '../../apiConnector/interfaces/queryRequest';

@singleton()
export default class Job extends Adapter<JobEntity> {
  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'jobs';
  }

  public async submit(
    id:
      | number
      | (PartialObject<JobEntity> & { id: number })
      | (JobEntity & { id: number }),
  ): Promise<void> {
    const entityId = typeof id === 'number' ? id : id.id;
    const endpoint = sprintf(
      `${this.getEndpointForResource(entityId)}/submit`,
      this.getParameters(undefined, typeof id === 'object' ? id : undefined),
    );
    await this.client.patch(endpoint);
  }

  protected postProcessQueryParams(
    queryParams: MapType,
    _queryRequest?: QueryRequest,
    parameters?: SimpleMapType,
  ): MapType {
    if (has(parameters, 'completed') && get(parameters, 'completed')) {
      queryParams.completed = true;
    }
    if (has(parameters, 'type')) {
      queryParams.type = get(parameters, 'type');
    }
    if (has(parameters, 'patient')) {
      queryParams.patient = +get(parameters, 'patient');
    }
    return queryParams;
  }

  // public async processDeletedList(deleted: number[]): Promise<number[]> {
  //   if (deleted.length === 0) return deleted;
  //   const deletedPromises = deleted.map(
  //     (id) =>
  //       new Promise<boolean>((resolve) => {
  //         this.connector
  //           .callGet(`jobs/${id}`)
  //           .then(() => resolve(true))
  //           .catch(() => resolve(false));
  //       })
  //   );
  //   const res = await Promise.all(deletedPromises);
  //   return deleted.filter((_v, idx) => res[idx]);
  // }
}
