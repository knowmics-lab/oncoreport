import {
  createSlice,
  PayloadAction,
  SliceCaseReducers,
} from '@reduxjs/toolkit';
import { Draft } from 'immer';
import { has } from 'lodash';
import { container } from 'tsyringe';
import type { Collection, PatientsState, SortingSpec } from '../../interfaces';
import { SortingDirection, TypeOfNotification } from '../../interfaces';
import { PatientEntity, PatientRepository, Utils } from '../../api';
import { AppThunk } from '../../store';
import { pushSimple } from './notifications';

type State = PatientsState<PatientEntity>;

interface Reducers extends SliceCaseReducers<State> {
  setPerPage: (state: Draft<State>, payload: PayloadAction<number>) => void;
  setSorting: (
    state: Draft<State>,
    payload: PayloadAction<SortingSpec>
  ) => void;
  listFetching: (state: Draft<State>) => void;
  listFetched: (
    state: Draft<State>,
    payload: PayloadAction<Collection<PatientEntity>>
  ) => void;
  listRequestResetPages: (
    state: Draft<State>,
    payload: PayloadAction<number[] | null>
  ) => void;
  listResetFetching: (state: Draft<State>) => void;
  listReset: (state: Draft<State>) => void;
  listGoToPage: (state: Draft<State>, payload: PayloadAction<number>) => void;
  listResetPages: (
    state: Draft<State>,
    payload: PayloadAction<number[]>
  ) => void;
  singleFetching: (state: Draft<State>) => void;
  singleDeleted: (state: Draft<State>, payload: PayloadAction<number>) => void;
  singleFetched: (
    state: Draft<State>,
    payload: PayloadAction<PatientEntity>
  ) => void;
  singleResetFetching: (state: Draft<State>) => void;
}

const patientsSlice = createSlice<State, Reducers>({
  name: 'patients',
  initialState: {
    patients: {
      fetching: false,
      items: {},
    },
    patientsList: {
      pages: {},
      refreshAll: false,
      refreshPages: [],
      state: {
        current_page: undefined,
        fetching: false,
        last_page: undefined,
        per_page: 15,
        sorting: { created_at: SortingDirection.desc },
        total: undefined,
      },
    },
  },
  reducers: {
    listFetched(state, payload) {
      const { data, meta } = payload.payload;
      state.patientsList.pages[meta.current_page] = data;
      state.patientsList.state = {
        ...state.patientsList.state,
        ...meta,
        fetching: false,
      };
    },
    listFetching(state): void {
      state.patientsList.state.fetching = true;
    },
    listGoToPage(state, payload) {
      state.patientsList.state.current_page = payload.payload;
    },
    listRequestResetPages(state, payload) {
      const pages = payload.payload;
      if (!pages) {
        state.patientsList.refreshAll = true;
        state.patientsList.refreshPages = [];
      } else {
        state.patientsList.refreshPages = [
          ...state.patientsList.refreshPages,
          ...pages,
        ];
      }
    },
    listReset(state): void {
      state.patientsList = {
        pages: {},
        refreshAll: false,
        refreshPages: [],
        state: {
          current_page: undefined,
          fetching: false,
          last_page: undefined,
          per_page: 15,
          sorting: { created_at: SortingDirection.desc },
          total: undefined,
        },
      };
    },
    listResetFetching(state): void {
      state.patientsList.state.fetching = false;
    },
    listResetPages(state, payload) {
      state.patientsList.pages = Utils.filterByKey(
        state.patientsList.pages,
        (key) => !payload.payload.includes(key)
      );
      state.patientsList.refreshPages = [];
    },
    setPerPage(state, payload) {
      state.patientsList.state.per_page = payload.payload;
      state.patientsList.refreshAll = true;
      state.patientsList.refreshPages = [];
    },
    setSorting(state, payload) {
      state.patientsList.state.sorting = payload.payload;
      state.patientsList.refreshAll = true;
      state.patientsList.refreshPages = [];
    },
    singleDeleted(state, payload) {
      state.patientsList.refreshAll = true;
      state.patients.items = Utils.filterByKey(
        state.patients.items,
        (k) => k !== payload.payload
      );
    },
    singleFetched(state, payload) {
      state.patients.fetching = false;
      if (payload.payload.id) {
        state.patients.items[payload.payload.id] = payload.payload;
      }
    },
    singleFetching(state) {
      state.patients.fetching = true;
    },
    singleResetFetching(state) {
      state.patients.fetching = false;
    },
  },
});

const { actions } = patientsSlice;

const requestPage = (page: number): AppThunk => async (dispatch, getState) => {
  try {
    const state = getState();
    const { refreshAll, refreshPages } = state.patients.patientsList;
    if (refreshAll) dispatch(actions.listReset());
    if (refreshPages.length > 0) {
      dispatch(actions.listResetPages(refreshPages));
    }
    dispatch(actions.listFetching());
    const {
      pages,
      state: { per_page: perPage, sorting },
    } = state.patients.patientsList;
    if (!has(pages, page)) {
      const pageCollection = await container
        .resolve(PatientRepository)
        .fetchPage(perPage, sorting, page);
      dispatch(actions.listFetched(pageCollection));
    } else {
      dispatch(actions.listResetFetching());
      dispatch(actions.listGoToPage(page));
    }
  } catch (e) {
    dispatch(actions.listResetFetching());
    dispatch(
      pushSimple(`An error occurred: ${e.message}!`, TypeOfNotification.error)
    );
  }
};

const setPerPage = (perPage = 15): AppThunk => (dispatch, getState) => {
  const state = getState();
  const oldValue = state.patients.patientsList.state.per_page;
  if (oldValue !== perPage) {
    dispatch(actions.setPerPage(perPage));
    dispatch(requestPage(1));
  }
};

const setSorting = (
  sorting: SortingSpec = { created_at: SortingDirection.desc }
): AppThunk => (dispatch) => {
  dispatch(actions.setSorting(sorting));
  dispatch(requestPage(1));
};

const refreshPage = (page?: number): AppThunk => (dispatch) => {
  dispatch(actions.listRequestResetPages(page ? [page] : null));
  if (page) dispatch(requestPage(page));
};

const requestPatient = (id: number, force = false): AppThunk => async (
  dispatch,
  getState
) => {
  try {
    const state = getState();
    dispatch(actions.singleFetching());
    const { items } = state.patients.patients;
    if (!has(items, id) || force) {
      const patient = await container.resolve(PatientRepository).fetch(id);
      dispatch(actions.singleFetched(patient));
    } else {
      dispatch(actions.singleResetFetching());
    }
  } catch (e) {
    dispatch(actions.singleResetFetching());
    dispatch(
      pushSimple(`An error occurred: ${e.message}!`, TypeOfNotification.error)
    );
  }
};

const deletePatient = (id: number, page?: number): AppThunk => async (
  dispatch,
  getState
) => {
  try {
    const state = getState();
    const { items } = state.patients.patients;
    const item = has(items, id)
      ? items[id]
      : await container.resolve(PatientRepository).fetch(id);
    await item.delete();
    dispatch(pushSimple('Patient deleted!', TypeOfNotification.success));
    dispatch(actions.singleDeleted(id));
    if (page) dispatch(refreshPage(page));
  } catch (e) {
    dispatch(
      pushSimple(`An error occurred: ${e.message}!`, TypeOfNotification.error)
    );
  }
};

export const patientsThunks = {
  requestPage,
  setPerPage,
  setSorting,
  refreshPage,
  requestPatient,
  deletePatient,
};

export default patientsSlice.reducer;

// export const selectIsFetchingList = (state: RootState): boolean =>
//   state.diseases.diseasesList.fetching;
//
// export const selectDiseases = (state: RootState): PatientEntity[] =>
//   state.diseases.diseasesList.data;
