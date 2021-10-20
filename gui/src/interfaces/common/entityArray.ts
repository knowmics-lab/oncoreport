import { Entity, Arrayable } from './index';

/**
 * An array of entities with custom methods used to represent
 * one-to-many relationships.
 */
export default interface EntityArray<T extends Entity> extends Array<T> {
  /**
   * Create a new entity linked to the parent object
   * @param data
   */
  create(data: Partial<T>): T;

  /**
   * Delete an entity linked to the parent object
   * @param id
   */
  delete(id: number): void;

  /**
   * Find an entity with the specified id or create a new object with the provided values
   * @param id
   * @param values
   */
  findOrCreate(id: number, values: Partial<T>): T;

  /**
   * Find an entity using the specified attributes or create a new object
   * if the entity was not found
   * @param attributes
   * @param values
   */
  firstOrCreate(attributes: Partial<T>, values: Partial<T>): T;

  /**
   * Find an entity using the specified attributes or create a new object
   * if the entity was not found. The entity always filled with the values
   * provided in the <code>values</code> parameter
   * @param attributes
   * @param values
   */
  updateOrCreate(attributes: Partial<T>, values: Partial<T>): T;

  /**
   * Connect one or more entities to the parent object
   * @param entities
   */
  save(entities: Arrayable<T>): void;
}
