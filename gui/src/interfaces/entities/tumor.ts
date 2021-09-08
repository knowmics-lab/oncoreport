import { Resource } from "../resource";
import { Drug } from "./drug";

export interface Tumor{
  id: number;
  name?: string;
  sede: (Resource)[];
  type?: string;
  stadio?: {T?: number, M?: number, N?: number};
  drugs: Drug[];
}
