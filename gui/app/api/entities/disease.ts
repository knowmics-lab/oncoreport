/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import { DiseaseObject } from '../../interfaces';
import Entity from './timedEntity';
import EntityError from '../../errors/EntityError';
import { fillable } from './entity';
import { DiseaseAdapter } from '../adapters';

@injectable()
export default class Disease extends Entity<DiseaseObject>
  implements DiseaseObject {
  @fillable()
  name = '';

  public constructor(adapter: DiseaseAdapter) {
    super(adapter);
  }

  public async delete(): Promise<this> {
    throw new EntityError('Diseases are read only entities');
  }

  async save(): Promise<this> {
    throw new EntityError('Diseases are read only entities');
  }
}
