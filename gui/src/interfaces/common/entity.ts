import { Dayjs } from 'dayjs';

/**
 * This object represents contains the type definition of the basic
 * entity. It is compatible with laravel models. All entity objects
 * must have an id, a created_at, and an updated_at field.
 */
export default interface Entity {
  /**
   * The numeric identifier of this entity. The value is always
   * a positive non-zero number. In any other case, the entity
   * is considered new.
   */
  id: number;

  /**
   * The creation date of this entity
   */
  created_at: Dayjs;

  /**
   * The human readable version of the creation date represented as the difference
   * between today and the creation date
   */
  created_at_diff: string;

  /**
   * The last update date of this entity
   */
  updated_at: Dayjs;

  /**
   * The human readable version of the last update date represented as the difference
   * between today and the date
   */
  updated_at_diff: string;
}
