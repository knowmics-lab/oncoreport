/* eslint-disable no-restricted-syntax */
import React from 'react';
import path from 'path';
import {
  List,
  ListItem,
  ListItemAvatar,
  ListItemSecondaryAction,
  ListItemText,
  Avatar,
  IconButton,
  ListSubheader,
  Icon,
  Box,
  Divider,
} from '@mui/material';
import mimetype2fa from 'mimetype-to-fontawesome';
import { fileTypeFromFile } from 'file-type';
import { FileFilter } from '../../../../interfaces';
import { Utils } from '../../../../api';
import electronApi, { activeWindow } from '../../../../electronApi';

export type File = {
  name: string;
  path: string;
  type: string;
  ext: string;
};

type Props = {
  title?: string;
  value?: File[];
  onFileAdd: (files: File[]) => void;
  onFileRemove: (file: File) => void;
  multiple?: boolean;
  disabled?: boolean;
  filters?: FileFilter[];
};

function processFiltersList(filters?: FileFilter[]): string[] {
  const res = [];
  for (const filter of filters || []) {
    for (const ext of filter.extensions) {
      if (ext === '*') res.unshift('*');
      else res.push(`.${ext.toLowerCase()}`);
    }
  }
  return res;
}

function isExtensionAllowed(ext: string, filters: string[]): boolean {
  if (filters.length && filters[0] === '*') return true;
  const lowerExt = ext.toLowerCase();
  return filters.includes(lowerExt);
}

export default function FileSelector({
  title,
  value,
  multiple,
  disabled,
  filters,
  onFileAdd,
  onFileRemove,
}: Props) {
  const [files, setFiles] = React.useState<File[]>(value || []);
  const processedFilters = React.useMemo(
    () => processFiltersList(filters),
    [filters],
  );

  const processFiles = async (paths: string[]): Promise<File[]> => {
    return Promise.all(
      paths.map(async (f) => {
        const t = await fileTypeFromFile(f);
        return {
          name: path.basename(f),
          path: f,
          type: (t && t.mime) || 'text/plain',
          ext: path.extname(f),
        };
      }),
    );
  };

  const fileExists = (file: File) => {
    for (let i = 0, l = files.length; i < l; i += 1) {
      if (files[i].path === file.path) return true;
    }
    return false;
  };

  const realAddFile = async (filePaths: string[]) => {
    if (filePaths.length === 0) return;
    const selectedFiles = (await processFiles(filePaths)).filter(
      (f) => isExtensionAllowed(f.ext, processedFilters) && !fileExists(f),
    );
    if (selectedFiles.length === 0) return;
    setFiles((prevFiles) => [...prevFiles, ...selectedFiles]);
    onFileAdd(selectedFiles);
  };

  const handleAdd = async () => {
    const { canceled, filePaths } = await electronApi.dialog.showOpenDialog(
      activeWindow()!,
      {
        filters,
        properties: multiple ? ['multiSelections'] : [],
      },
    );
    if (!canceled) {
      if (filePaths) {
        await realAddFile(filePaths);
      }
    }
  };

  const handleRemove = (f: File) => () => {
    setFiles((prevFiles) => [...prevFiles.filter((o) => o.path !== f.path)]);
    onFileRemove(f);
  };

  const handlePrevent = (e: React.DragEvent<HTMLElement>) => {
    e.preventDefault();
  };

  const handleDrop = (e: React.DragEvent<HTMLElement>) => {
    e.preventDefault();
    if (!multiple && files.length < 1) {
      const fileArray = Utils.toArray<File>(e.dataTransfer.files);
      let filePaths = fileArray.map((t) => t.path);
      if (!multiple) {
        filePaths = [filePaths[0]];
      }
      realAddFile(filePaths)
        .then(() => true)
        .catch(() => false);
    }
    return false;
  };

  const getTitle = () => {
    if (title !== null) return title;
    return multiple ? 'Select Files' : 'Select a file';
  };

  const makeSubheader = (): React.ReactElement | undefined => {
    if (!multiple && files.length > 0) return undefined;
    return (
      <ListSubheader>
        {getTitle()}
        <ListItemSecondaryAction>
          {(multiple || (!multiple && files.length < 1)) && (
            <IconButton edge="end" onClick={handleAdd} disabled={disabled}>
              <Icon className="fas fa-plus" />
            </IconButton>
          )}
        </ListItemSecondaryAction>
      </ListSubheader>
    );
  };

  const m2f = mimetype2fa({ prefix: 'fa-' });
  return (
    <Box
      boxShadow={2}
      borderRadius="borderRadius"
      onDragOver={handlePrevent}
      onDragEnter={handlePrevent}
      onDragLeave={handlePrevent}
      onDragEnd={handlePrevent}
      onDrop={handleDrop}
      sx={(theme) => ({
        width: '100%',
        backgroundColor: theme.palette.background.paper,
      })}
    >
      <List subheader={makeSubheader()} dense>
        {multiple && files.length > 0 && <Divider />}
        {files.map((f) => (
          <ListItem key={f.path}>
            <ListItemAvatar>
              <Avatar>
                <i className={`fas ${m2f(f.type)}`} />
              </Avatar>
            </ListItemAvatar>
            <ListItemText
              primary={f.name}
              title={f.name}
              sx={{
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
              }}
            />
            {!disabled && (
              <ListItemSecondaryAction>
                <IconButton
                  edge="end"
                  color="secondary"
                  onClick={handleRemove(f)}
                >
                  <i className="fas fa-times" />
                </IconButton>
              </ListItemSecondaryAction>
            )}
          </ListItem>
        ))}
      </List>
    </Box>
  );
}

FileSelector.defaultProps = {
  title: null,
  value: [],
  multiple: false,
  disabled: false,
  filters: [{ name: 'All Files', extensions: ['*'] }],
};
