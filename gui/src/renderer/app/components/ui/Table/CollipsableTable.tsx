/* eslint-disable react/no-array-index-key */
import React from 'react';
import Box from '@mui/material/Box';
import Collapse from '@mui/material/Collapse';
import IconButton from '@mui/material/IconButton';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Typography from '@mui/material/Typography';
import Paper from '@mui/material/Paper';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp';

interface NestedRowData {
  id: number;
  data: React.ReactNode[];
}

interface RowData {
  id: number;
  row: React.ReactNode[];
  nestedTable: {
    name: string;
    head: string[];
    data: NestedRowData[];
  };
}

function Row({ id, row, nestedTable }: RowData) {
  const [open, setOpen] = React.useState(false);
  const colSpan = row.length + 1;
  return (
    <>
      <TableRow
        sx={{
          '& > *': {
            borderBottom: 'unset',
          },
        }}
      >
        <TableCell>
          {nestedTable && (
            <IconButton size="small" onClick={() => setOpen(!open)}>
              {open ? <KeyboardArrowUpIcon /> : <KeyboardArrowDownIcon />}
            </IconButton>
          )}
        </TableCell>
        {row.map((f, i) => (
          <TableCell key={`row-${id}-cell-${i}`}>{f}</TableCell>
        ))}
      </TableRow>
      {nestedTable && (
        <TableRow>
          <TableCell
            style={{ paddingBottom: 0, paddingTop: 0 }}
            colSpan={colSpan}
          >
            <Collapse in={open} timeout="auto" unmountOnExit>
              <Box margin={1}>
                <Typography variant="h6" gutterBottom component="div">
                  {nestedTable.name}
                </Typography>
                <Table size="small" aria-label="purchases">
                  <TableHead>
                    <TableRow>
                      {nestedTable.head.map((h) => (
                        <TableCell
                          key={`nested-table-cell-${id}-head-${h}`}
                          align="right"
                        >
                          <Typography variant="body2">{h}</Typography>
                        </TableCell>
                      ))}
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {nestedTable.data.map((f) => (
                      <TableRow key={`nested-table-cell-${id}-row-${f.id}`}>
                        {f.data.map((d, i) => (
                          <TableCell
                            key={`nested-table-cell-${id}-row-${f.id}-column-${i}`}
                            align="right"
                          >
                            {d}
                          </TableCell>
                        ))}
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </Box>
            </Collapse>
          </TableCell>
        </TableRow>
      )}
    </>
  );
}

interface CollapsibleTableProps {
  head: string[];
  data: RowData[];
}

export default function CollapsibleTable({
  head,
  data,
}: CollapsibleTableProps) {
  return (
    <TableContainer component={Paper}>
      <Table>
        <TableHead>
          <TableRow
            sx={(theme) => ({
              backgroundColor: theme.palette.background.default,
            })}
          >
            <TableCell component="th" scope="row" />
            {head.map((h) => (
              <TableCell key={`table-cell-${h}`}>{h}</TableCell>
            ))}
          </TableRow>
        </TableHead>
        <TableBody>
          {data.map((row) => (
            <Row key={`table-row-${row.id}`} {...row} />
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
