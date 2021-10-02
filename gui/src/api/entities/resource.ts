/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import { ResourceObject } from '../../interfaces';
import Entity from './timedEntity';
import EntityError from '../../errors/EntityError';
import { ResourceAdapter } from '../adapters';
import { field } from './entity';

@injectable()
export default class Resource
  extends Entity<ResourceObject>
  implements ResourceObject
{
  @field({
    fillable: true,
  })
  name = '';

  @field({
    fillable: true,
  })
  id = 0;

  public constructor(adapter: ResourceAdapter) {
    super(adapter);
  }

  public async delete(): Promise<this> {
    throw new EntityError('Diseases are read only entities');
  }

  async save(): Promise<this> {
    throw new EntityError('Diseases are read only entities');
  }
}
