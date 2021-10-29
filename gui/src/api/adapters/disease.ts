import { singleton } from 'tsyringe';
import { get, has } from 'lodash';
import { Adapter, HttpClient } from '../../apiConnector';
import { DiseaseEntity } from '../entities';
import { MapType, SimpleMapType } from '../../apiConnector/interfaces/common';
import { QueryRequest } from '../../apiConnector/interfaces/queryRequest';

@singleton()
export default class Disease extends Adapter<DiseaseEntity> {
  protected isReadOnly = true;

  public constructor(client: HttpClient) {
    super(client);
  }

  get endpoint(): string {
    return 'diseases';
  }

  protected postProcessQueryParams(
    queryParams: MapType,
    _queryRequest?: QueryRequest,
    parameters?: SimpleMapType
  ): MapType {
    if (has(parameters, 'tumor') && get(parameters, 'tumor')) {
      queryParams.tumor = true;
    }
    return queryParams;
  }
}
