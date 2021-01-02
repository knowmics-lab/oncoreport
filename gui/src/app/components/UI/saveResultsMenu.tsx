import React, { useState } from 'react';
import { Icon, Menu, MenuItem } from '@material-ui/core';
import PopupState, { bindMenu, bindTrigger } from 'material-ui-popup-state';
import { JobEntity } from '../../../api';
import { JobStatus, OutputTypes } from '../../../interfaces';
import IconButton, { IconButtonType } from './IconButton';
import { runAsync } from '../utils';

type SaveMenuProps = {
  job: JobEntity;
  size: 'small' | 'medium';
};

const resultsMenuItems: [string, string][] = [
  ['reportOutputFile', 'Report Archive'],
  ['vcfOutputFile', 'VCF Output File'],
  ['vcfPASSOutputFile', 'VCF Output File (Passed Variants only)'],
];

export default function SaveResultsMenu({ job, size }: SaveMenuProps) {
  const { id, status } = job;
  const type = job.output?.type;
  const [downloading, setDownloading] = useState(false);

  if (
    status !== JobStatus.completed ||
    (type !== OutputTypes.tumorNormal && type !== OutputTypes.tumorOnly)
  ) {
    return <></>;
  }

  if (downloading) {
    return (
      <IconButton
        key={`action-button-job-${id}`}
        size={size}
        color="inherit"
        onClick={(e) => e.preventDefault()}
        title="Saving..."
      >
        <Icon className="fas fa-circle-notch fa-spin" fontSize="inherit" />
      </IconButton>
    );
  }
  return (
    <PopupState
      variant="popover"
      popupId={`popup-menu-job-${id}`}
      key={`popup-menu-job-${id}`}
    >
      {(popupState) => {
        const iconProps = ({
          size,
          color: 'inherit',
          title: 'Save',
          ...bindTrigger(popupState),
          key: `popup-button-job-${id}`,
        } as unknown) as IconButtonType;
        return (
          <>
            <IconButton {...iconProps}>
              <Icon className="fas fa-save" fontSize="inherit" />
            </IconButton>
            <Menu {...bindMenu(popupState)} key={`popup-menu-job-${id}`}>
              {resultsMenuItems.map((i) => (
                <MenuItem
                  key={`popup-menu-item-${i[0]}-job-${id}`}
                  onClick={(e) => {
                    popupState.close();
                    e.preventDefault();
                    runAsync(
                      async () => {
                        job.download(
                          i[0],
                          () => setDownloading(true),
                          () => setDownloading(false)
                        );
                      },
                      () => setDownloading(false)
                    );
                  }}
                >
                  {i[1]}
                </MenuItem>
              ))}
            </Menu>
          </>
        );
      }}
    </PopupState>
  );
}
