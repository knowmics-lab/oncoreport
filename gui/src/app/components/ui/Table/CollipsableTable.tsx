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
import Button from '@material-ui/core/Button';






const useRowStyles = makeStyles({
  root: {
    '& > *': {
      borderBottom: 'unset',
    },
  },
});

function Row(props: {
  row: {
    fields:any[],
    data:{head:string[], name:string,  fields:any[]}}[],
  }) {
  const { row }= props;
  const [open, setOpen] = React.useState(false);
  const classes = useRowStyles();

  return (
    <React.Fragment>
      <TableRow className={classes.root}>
        <TableCell>
          <IconButton aria-label="expand row" size="small" onClick={() => setOpen(!open)}>
            {open ? <KeyboardArrowUpIcon /> : <KeyboardArrowDownIcon />}
          </IconButton>
        </TableCell>
        {row.fields.map( f => <TableCell>{f}</TableCell>)}
        {/*
        <TableCell component="th" scope="row">
          {row.name}
        </TableCell>
        <TableCell align="right">{row.type}</TableCell>
        <TableCell align="right">{row.sede}</TableCell>
        <TableCell align="right">{row.stadio.T}</TableCell>
        <TableCell align="right">{row.stadio.M}</TableCell>
        <TableCell align="right">{row.stadio.N}</TableCell>
        */}
      </TableRow>
      <TableRow>
        <TableCell style={{ paddingBottom: 0, paddingTop: 0 }} colSpan={6}>
          <Collapse in={open} timeout="auto" unmountOnExit>
            <Box margin={1}>
              <Typography variant="h6" gutterBottom component="div">{row.data.name}</Typography>
              <Table size="small" aria-label="purchases">
                <TableHead>
                  <TableRow >
                    {row.data.head.map ( h => <TableCell align="right" >{h}</TableCell> )}
                  </TableRow>
                </TableHead>
                <TableBody>
                  {row.data.fields.map( f =>
                  <TableRow>
                    {f.map( innerRow => <TableCell align="right">{innerRow}</TableCell> )}
                  </TableRow> )}
                  {/**
                  {row.drugs.map((drug:any, i:number) => (
                    <TableRow key={drug.id}>
                      <TableCell component="th" scope="row">
                        {drug.name}
                      </TableCell>
                      <TableCell>{drug.start_date}</TableCell>
                      <TableCell align="right">{drug.end_date}</TableCell>
                      <TableCell align="right">
                        {JSON.stringify(drug.reasons.map (r => r.name))}
                      </TableCell>
                      <TableCell>
                        <Button variant="contained" color="secondary" disabled={drug.end_date != null} >Interrompi</Button>
                      </TableCell>
                    </TableRow>
                  ))}
                   */}
                </TableBody>
              </Table>
            </Box>
          </Collapse>
        </TableCell>
      </TableRow>
    </React.Fragment>
  );
}

export default function CollapsibleTable( props: {
  data: { head:string[], name:string,  fields:any[], innerField:{head:string[], name:string,  fields:any[]}}[],
}) {
  const {data} = props;
  return (
    <TableContainer component={Paper}>
      <Table aria-label={data.name}>
        <TableHead>
          <TableRow>
            <TableCell component="th" scope="row"/>
              {data.head.map( h => <TableCell>{h}</TableCell> )}
          </TableRow>
        </TableHead>
        <TableBody>
          {data.fields.map( row =>  <Row row={row} /> )}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
