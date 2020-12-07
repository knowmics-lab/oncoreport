/* eslint-disable class-methods-use-this */
import { injectable } from 'tsyringe';
import { Disease as DiseaseObject } from '../../interfaces/entities/disease';
import DiseaseAdapter from '../adapters/disease';
import Entity from './timedEntity';
import EntityError from '../../errors/EntityError';

@injectable()
export default class Disease extends Entity<DiseaseObject>
  implements DiseaseObject {
  name = '';

  public constructor(adapter: DiseaseAdapter) {
    super(adapter);
  }

  public async delete() {
    throw new EntityError('Diseases are read only entities');
  }

  async save() {
    throw new EntityError('Diseases are read only entities');
  }
}
