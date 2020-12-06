// /* eslint-disable @typescript-eslint/naming-convention */
// import Connector from './connector';
// import {
//   SortingSpec,
//   ResponseType,
//   MetaResponseType,
// } from '../../interfaces/common';
// import {
//   Gender,
//   Patient,
//   PatientCollectionItem,
//   PatientsCollection,
// } from '../../interfaces/patients';
// import { Disease } from '../../interfaces/diseases';
// import ApiError from '../../errors/ApiError';
//
// interface ApiResponseSingle {
//   data: Omit<Patient, 'links'>;
//   links: Patient['links'];
// }
//
// interface ApiResponseCollection {
//   data: PatientCollectionItem[];
//   meta: MetaResponseType;
// }
//
// export default {
//   async create(
//     code: string,
//     first_name: string,
//     last_name: string,
//     age: number,
//     gender: Gender,
//     disease: Disease | number
//   ): Promise<ResponseType<Patient>> {
//     const disease_id = typeof disease === 'number' ? disease : disease.id;
//     const result = await Connector.callPost<ApiResponseSingle>('patients', {
//       code,
//       first_name,
//       last_name,
//       gender,
//       age,
//       disease_id,
//     });
//     if (!result.data) {
//       return {
//         validationErrors: result.validationErrors,
//       };
//     }
//     const { data, links } = result.data;
//     return {
//       data: {
//         ...data,
//         links,
//       },
//     };
//   },
//   async delete(id: number): Promise<void> {
//     await Connector.callDelete(`patients/${id}`);
//   },
//   async fetchById(id: number): Promise<Patient> {
//     const result = await Connector.callGet<ApiResponseSingle>(`patients/${id}`);
//     if (!result.data) throw new ApiError('Unable to fetch the patient');
//     const { data, links } = result.data;
//     return {
//       ...data,
//       links,
//     };
//   },
//   async fetch(
//     per_page = 15,
//     sorting: SortingSpec = { created_at: 'desc' },
//     page = 1
//   ): Promise<PatientsCollection> {
//     const order = Object.keys(sorting);
//     const order_direction = Object.values(sorting);
//     const result = await Connector.callGet<ApiResponseCollection>(`patients`, {
//       page,
//       per_page,
//       order,
//       order_direction,
//     });
//     if (!result.data) throw new ApiError('Unable to fetch patients');
//     const { data, meta } = result.data;
//     return {
//       data: data.map((p) => ({
//         ...p,
//         links: {
//           self: p.self_link,
//           owner: p.owner_link,
//           jobs: p.jobs_link,
//         },
//       })),
//       meta: {
//         ...meta,
//         sorting,
//       },
//     };
//   },
// };
