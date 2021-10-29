import { injectable } from 'tsyringe';
import { DiseaseAdapter } from '../adapters';
import Entity, { field } from '../../apiConnector/entity/entity';

@injectable()
export default class Disease extends Entity {
  @field({
    fillable: true,
    readonly: true,
  })
  public icd_code = '';

  @field({
    fillable: true,
    readonly: true,
  })
  public name = '';

  @field({
    fillable: true,
    readonly: true,
  })
  public tumor = false;

  public constructor(adapter: DiseaseAdapter) {
    super(adapter);
  }
}
