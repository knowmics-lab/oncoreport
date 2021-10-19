import { IdentifiableEntity } from './index';

export default interface EntityArray<T extends IdentifiableEntity>
  extends Array<T> {
  create(data: Partial<T>): T;
  delete(id: number): void;
}
