import {
  createSlice,
  PayloadAction,
  SliceCaseReducers,
} from '@reduxjs/toolkit';
import { has } from 'lodash';
import { container } from 'tsyringe';
import { Draft } from 'immer';
import type { Collection, DiseasesState } from '../../interfaces';
import { TypeOfNotification } from '../../interfaces';
import { DiseaseEntity, DiseaseRepository } from '../../api';
import { AppThunk, RootState } from '../../store';
import { pushSimple } from './notifications';

interface Reducers extends SliceCaseReducers<DiseasesState<DiseaseEntity>> {
  listFetching: (state: Draft<DiseasesState<DiseaseEntity>>) => void;
  listFetched: (
    state: Draft<DiseasesState<DiseaseEntity>>,
    action: PayloadAction<Collection<DiseaseEntity>>
  ) => void;
  listResetFetching: (state: Draft<DiseasesState<DiseaseEntity>>) => void;
  listReset: (state: Draft<DiseasesState<DiseaseEntity>>) => void;
  listRefresh: (state: Draft<DiseasesState<DiseaseEntity>>) => void;
  singleFetching: (state: Draft<DiseasesState<DiseaseEntity>>) => void;
  singleFetched: (
    state: Draft<DiseasesState<DiseaseEntity>>,
    action: PayloadAction<DiseaseEntity>
  ) => void;
  singleResetFetching: (state: Draft<DiseasesState<DiseaseEntity>>) => void;
}

const diseasesSlice = createSlice<DiseasesState<DiseaseEntity>, Reducers>({
  name: 'diseases',
  initialState: {
    diseasesList: {
      refresh: false,
      data: [],
      fetching: false,
    },
    diseases: {
      fetching: false,
      items: {},
    },
  },
  reducers: {
    listFetching: (state) => {
      state.diseasesList.fetching = true;
    },
    listFetched: (state, action) => {
      if (state.diseasesList.fetching) {
        state.diseasesList.data = action.payload.data;
        state.diseasesList.fetching = false;
      }
    },
    listResetFetching: (state) => {
      state.diseasesList.fetching = false;
    },
    listReset: (state) => {
      state.diseasesList = {
        refresh: false,
        data: [],
        fetching: false,
      };
    },
    listRefresh: (state) => {
      state.diseasesList.refresh = true;
    },
    singleFetching: (state) => {
      state.diseases.fetching = true;
    },
    singleFetched: (state, action) => {
      if (state.diseases.fetching) {
        state.diseases.fetching = false;
        if (action.payload.id) {
          state.diseases.items = {
            ...state.diseases.items,
            [action.payload.id]: action.payload,
          };
        }
      }
    },
    singleResetFetching: (state) => {
      state.diseases.fetching = false;
    },
  },
});

const requestDiseasesList = (): AppThunk => async (dispatch, getState) => {
  const state = getState();
  const { data, refresh } = state.diseases.diseasesList;
  if (refresh) dispatch(diseasesSlice.actions.listReset());
  dispatch(diseasesSlice.actions.listFetching());
  if (refresh || !data || data.length === 0) {
    try {
      const diseases = await container.resolve(DiseaseRepository).fetchPage();
      dispatch(diseasesSlice.actions.listFetched(diseases));
    } catch (e) {
      dispatch(diseasesSlice.actions.listResetFetching());
      dispatch(
        pushSimple(`An error occurred: ${e.message}!`, TypeOfNotification.error)
      );
    }
  } else {
    dispatch(diseasesSlice.actions.listResetFetching());
  }
};

const refreshDiseases = (): AppThunk => (dispatch) => {
  dispatch(diseasesSlice.actions.listRefresh());
  dispatch(requestDiseasesList());
};

const requestDisease = (id: number, force = false): AppThunk => async (
  dispatch,
  getState
) => {
  dispatch(diseasesSlice.actions.singleFetching());
  const state = getState();
  const { items } = state.diseases.diseases;
  if (!has(items, id) || force) {
    try {
      const disease = await container.resolve(DiseaseRepository).fetch(id);
      dispatch(diseasesSlice.actions.singleFetched(disease));
    } catch (e) {
      dispatch(diseasesSlice.actions.singleResetFetching());
      dispatch(
        pushSimple(`An error occurred: ${e.message}!`, TypeOfNotification.error)
      );
    }
  } else {
    dispatch(diseasesSlice.actions.singleResetFetching());
  }
};

export const diseasesThunks = {
  requestDiseasesList,
  refreshDiseases,
  requestDisease,
};

export default diseasesSlice.reducer;

export const selectIsFetchingList = (state: RootState): boolean =>
  state.diseases.diseasesList.fetching;

export const selectDiseases = (state: RootState): DiseaseEntity[] =>
  state.diseases.diseasesList.data;
