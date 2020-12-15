import {
  createSlice,
  PayloadAction,
  SliceCaseReducers,
} from '@reduxjs/toolkit';
import { Draft } from 'immer';
import uniqid from 'uniqid';
import type { Notification, NotificationsState } from '../../interfaces';
import { Utils } from '../../api';
import { AppThunk, RootState } from '../../store';
import {
  PushedNotification,
  SimpleMapType,
  TypeOfNotification,
} from '../../interfaces';

interface Reducers extends SliceCaseReducers<NotificationsState> {
  push: (
    state: Draft<NotificationsState>,
    action: PayloadAction<Notification>
  ) => void;
  close: (
    state: Draft<NotificationsState>,
    action: PayloadAction<string>
  ) => void;
  destroy: (
    state: Draft<NotificationsState>,
    action: PayloadAction<string>
  ) => void;
}

const notificationsSlice = createSlice<NotificationsState, Reducers>({
  name: 'notifications',
  initialState: {
    notifications: {},
  },
  reducers: {
    close(
      state: Draft<NotificationsState>,
      action: PayloadAction<string>
    ): void {
      state.notifications = {
        ...state.notifications,
        [action.payload]: {
          ...state.notifications[action.payload],
          shown: false,
        },
      };
    },
    destroy(
      state: Draft<NotificationsState>,
      action: PayloadAction<string>
    ): void {
      state.notifications = Utils.filterByKey(
        state.notifications,
        (k) => k !== action.payload
      );
    },
    push(
      state: Draft<NotificationsState>,
      action: PayloadAction<Notification>
    ): void {
      const id = uniqid();
      state.notifications = {
        ...state.notifications,
        [id]: {
          ...action.payload,
          id,
          shown: true,
        },
      };
    },
  },
});

export const { actions } = notificationsSlice;

export const pushSimple = (
  message: string,
  variant: TypeOfNotification
): AppThunk => (dispatch) => {
  dispatch(actions.push({ message, variant }));
};

export default notificationsSlice.reducer;

export const selectNotifications = (
  state: RootState
): SimpleMapType<PushedNotification> => state.notifications.notifications;

// export const selectDiseases = (state: RootState): DiseaseEntity[] =>
//   state.diseases.diseasesList.data;
