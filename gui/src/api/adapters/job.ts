import { singleton } from 'tsyringe';
import { sprintf } from 'sprintf-js';
import { Adapter, HttpClient, PartialObject } from '../../apiConnector';
import { JobEntity } from '../entities';

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
      | (JobEntity & { id: number })
  ): Promise<void> {
    const entityId = typeof id === 'number' ? id : id.id;
    const endpoint = sprintf(
      `${this.getEndpointForResource(entityId)}/submit`,
      this.getParameters(undefined, typeof id === 'object' ? id : undefined)
    );
    await this.client.patch(endpoint);
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
