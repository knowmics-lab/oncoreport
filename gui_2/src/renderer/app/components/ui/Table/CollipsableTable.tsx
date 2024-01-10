/* eslint-disable react/no-array-index-key */
import React from 'react';
import { makeStyles } from '@material-ui/core/styles';
import Box from '@material-ui/core/Box';
import Collapse from '@material-ui/core/Collapse';
import IconButton from '@material-ui/core/IconButton';
import Table from '@material-ui/core/Table';
import TableBody from '@material-ui/core/TableBody';
import TableCell from '@material-ui/core/TableCell';
import TableContainer from '@material-ui/core/TableContainer';
import TableHead from '@material-ui/core/TableHead';
import TableRow from '@material-ui/core/TableRow';
import Typography from '@material-ui/core/Typography';
import Paper from '@material-ui/core/Paper';
import KeyboardArrowDownIcon from '@material-ui/icons/KeyboardArrowDown';
import KeyboardArrowUpIcon from '@material-ui/icons/KeyboardArrowUp';

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

const useStyles = makeStyles((theme) => ({
  root: {
    '& > *': {
      borderBottom: 'unset',
    },
  },
  stickyStyle: {
    backgroundColor: theme.palette.background.default,
  },
}));

function Row({ id, row, nestedTable }: RowData) {
  const classes = useStyles();
  const [open, setOpen] = React.useState(false);
  const colSpan = row.length + 1;
  return (
    <>
      <TableRow className={classes.root}>
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
  const classes = useStyles();
  return (
    <TableContainer component={Paper}>
      <Table>
        <TableHead>
          <TableRow className={classes.stickyStyle}>
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
