import { Accordion, AccordionDetails, AccordionSummary, Dialog, DialogActions, DialogContent, DialogContentText, DialogTitle, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography } from "@material-ui/core";
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import { Field, Form, Formik } from "formik";
import React, {useEffect, useState} from 'react';
import Button, { SubmitButton } from "../ui/Button";
import { FormikSelect } from "../ui/Form/FormikSelect";
import CollapsibleTable from "../ui/Table/CollipsableTable";






export const TumorList = (props:any ) => {
  const [expanded, setExpanded] = React.useState<number | false>(false);
  const [dialogData, setDialogData] = useState< {index: number, drug: any, tumor:any} | false >(false);
  const [reasons, setReasons] = useState<{id:number, name:string}[]>([]);
  const [update, setUpdate] = useState<number>(Math.random());


  function forceUpdate(){
    let v = Math.random();
    while (v == update) v = Math.random();
    setUpdate(v);
  }

  useEffect(() => {
    fetch('http://localhost:8000/api/reasons').then(res => res.json()).then((data) => {
      setReasons(data.map((d: any) => {return {'id':d.id, 'name': d.name}}));
    }).catch(console.log);
   }, []);

  function handleStopDrug(index:number, tumor:any, drug: any, reasons: number[]){
    console.log('url=' + 'http://localhost:8000/api/detach/'+props.patient.id+'/'+tumor.id+'/'+drug.id + '?reasons=' + JSON.stringify(reasons));
    fetch('http://localhost:8000/api/detach/'+props.patient.id+'/'+tumor.id+'/'+drug.id + '?reasons=' + JSON.stringify(reasons)).then(res => res.json()).then((data) => {
                                        alert(JSON.stringify(data.data));
                                        tumor.drugs[index] = data.data;
                                        forceUpdate();
                                      }).catch(console.log);
  }

  return (
    <>

    <CollapsibleTable data = {
      {
        'name': 'Tumors',
        'head' : ['Tumor', 'Type', 'Sede', 'T', 'M', 'N'],
        fields: props.patient.tumors.map (tumor => {
          return {
            'fields' : [tumor.name, tumor.type, tumor.sede, tumor.stadio.T, tumor.stadio.M, tumor.stadio.N,],
            'data' : {
              'name' : 'Drugs',
              'head' : ['Drug', 'Start date', 'End date', 'Stop reasons', ''],
              'fields' : tumor.drugs.map ( (drug:any, i:number) => [
                drug.name,
                drug.start_date,
                drug.end_date ? drug.end_date : 'in corso...',
                JSON.stringify(drug.reasons.map( r => r.name )),
                <Button size="small" variant="contained" color="secondary" disabled={drug.end_date != null}  onClick={async () => {
                  setDialogData({'drug':drug, index: i, 'tumor': tumor});
                }}>Interrompi</Button>
              ])
            }
          }
        })
      }
    }/>

    <Dialog open={dialogData} onClose={() => {setDialogData(false)}} aria-labelledby="form-dialog-title">
        <DialogTitle id="form-dialog-title">Perchè interrompere {dialogData ? dialogData.drug.name : ''} ?</DialogTitle>
        <Formik
            initialValues={{ragioni:[]}}
            onSubmit={(d) => {
              alert(JSON.stringify(d));
              handleStopDrug(dialogData.index, dialogData.tumor, dialogData.drug, d.ragioni);
              setDialogData(false);}} >
          <Form>
            <DialogContent>
              <DialogContentText>Puoi selezionare una o più ragioni.</DialogContentText>
              <Field name={'ragioni'} isMulti component={FormikSelect} options={reasons.map((r) => {return {'value':r.id, 'label':r.name}})} label="perchè"/>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => {setDialogData(false)}} color="primary">Cancel</Button>
              <SubmitButton onClick={() => {setDialogData(false)}} color="primary">Save</SubmitButton>
            </DialogActions>
          </Form>
        </Formik>
      </Dialog>
{/**
    {props.patient.tumors.map((tumor:any) =>
        <Accordion TransitionProps={{ unmountOnExit: true }} expanded={expanded == tumor.id} onChange={ (event: React.ChangeEvent<{}>, isExpanded: boolean) =>{setExpanded( isExpanded ? tumor.id : false)}}>
          <AccordionSummary
            expandIcon={<ExpandMoreIcon />}
            aria-controls="panel1a-content"
            id="panel1a-header"
          >
            <Typography>{tumor.name}</Typography>
          </AccordionSummary>
          <AccordionDetails>

            <TableContainer component={Paper}>
              <Table >
                <TableHead><TableRow><TableCell>Drug</TableCell><TableCell align="right">start date</TableCell><TableCell align="right">end date</TableCell><TableCell align="right">why</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
                <TableBody>
                  { tumor.drugs.map((drug:any, i:number) =>
                      <TableRow>
                        <TableCell>{drug.name}</TableCell>
                        <TableCell align="right">{drug.start_date}</TableCell>
                        <TableCell align="right">{drug.end_date ?? 'in corso...'}</TableCell>
                        <TableCell align="right">{JSON.stringify(drug.reasons.map( (r) => r.name ) ?? '')}</TableCell>
                        <TableCell align="right">
                          <Button variant="contained" color="secondary" disabled={drug.end_date != null}  onClick={async () => {
                            setDialogData({'drug':drug, index: i, 'tumor': tumor});
                          }}>Interrompi</Button>
                        </TableCell>
                      </TableRow>
                      )}
                </TableBody>
              </Table>
            </TableContainer>
          </AccordionDetails>
        </Accordion>
     )}
      */}
     </>
  );
}
