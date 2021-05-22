import React, {useEffect, useState, useMemo} from 'react';
import { Field } from 'formik';

import TagFacesIcon from '@material-ui/icons/TagFaces';

import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import {
  TextField as FormikTextField,
  TextFieldProps as FormikTextFieldProps,
} from 'formik-material-ui';
import { Interface } from 'readline';
import SelectField from '../../ui/Form/SelectField';
import {
  Gender,
  SimpleMapArray,
  TypeOfNotification,
} from '../../../../interfaces';
import { createStyles, makeStyles } from '@material-ui/core/styles';
import { green } from '@material-ui/core/colors';

import {
  DiseaseEntity,
  DiseaseRepository,
  PatientEntity,
  PatientRepository,
} from '../../../../api';

import { runAsync } from '../../utils';
import { useService } from '../../../../reactInjector';

import { Form, Formik } from 'formik';
import { useHistory, useParams } from 'react-router-dom';

import Button, { SubmitButton } from '../../ui/Button';
import Routes from '../../../../constants/routes.json';
import { generatePath } from 'react-router';
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  FormGroup,
  Grid,
  Icon,
  Input,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
} from '@material-ui/core';

import TextField from '../../ui/Form/TextField';


import * as Yup from 'yup';
import makeAnimated from 'react-select/animated'
import { FormikSelect } from '../../ui/Form/FormikSelect';
import { number } from 'yup/lib/locale';
import { Autocomplete } from '@material-ui/lab';

import MenuItem from '@material-ui/core/MenuItem';
import FormHelperText from '@material-ui/core/FormHelperText';
import FormControl from '@material-ui/core/FormControl';
import Select from '@material-ui/core/Select';
import { TumorList } from '../tumorList';

const useStyles = makeStyles((theme) =>
  createStyles({
    paper: {
      padding: 16,
    },
    formControl: {
      margin: theme.spacing(1),
      minWidth: 120,
    },
    buttonWrapper: {
      margin: theme.spacing(1),
      position: 'relative',
    },
    buttonProgress: {
      color: green[500],
      position: 'absolute',
      top: '50%',
      left: '50%',
      marginTop: -12,
      marginLeft: -12,
    },
    backdrop: {
      zIndex: theme.zIndex.drawer + 1,
      color: '#fff',
    },
  })
);

type MaybePatient = PatientEntity | undefined;

export interface TextFieldProps
  extends Omit<FormikTextFieldProps, 'form' | 'meta' | 'field' | 'fullWidth'> {
  name: string;
}

interface TumorInterface{
  id: number;
  name: string;
}

export default function TumorForm() {
  const classes = useStyles();
  const repository = useService(PatientRepository);
  const [loading, setLoading] = useState(true);
  const [patient, setPatient] = useState<MaybePatient>();
  const [submitting, setSubmitting] = useState(false);
  const history = useHistory();
  const { id } = useParams<{ id?: string }>();

  useEffect(() => {
    runAsync(async () => {
      setLoading(true);
      if (id) {
        setPatient(await (await repository.fetch(+id)).refresh());
      } else {
        setPatient(repository.new());
      }
      setLoading(false);
    });
  }, [id, repository]);

  const backUrl = generatePath(Routes.PATIENTS);
  const testDrugs = [{'id': 1, 'name':'cose', 'start_date':'2000-03-02', 'end_date':null},{'id': 1, 'name':'cose', 'start_date':'2000-03-02', 'end_date':null},{'id': 1, 'name':'cose', 'start_date':'2000-03-02', 'end_date':null},{'id': 1, 'name':'cose', 'start_date':'2000-03-02', 'end_date':null},{'id': 1, 'name':'cose', 'start_date':'2000-03-02', 'end_date':null}];
  const [tumors, setTumors] = useState<{id: number, name: string}[]>();
  const [tumorsOptions, setTumorOptions] = useState<{value: string, label:string}[]>();
  const [drugs, setDrugs] = useState<{id: number, name: string}[]>();
  const [dialogData, setDialogData] = useState< {index: number, drug: any, tumor:any} | false >(false);
  const [update, setUpdate] = useState<number>(Math.random());

  function forceUpdate(){
    let v = Math.random();
    while (v == update) v = Math.random();
    setUpdate(v);
  }
  const [reasons, setReasons] = useState<{id:number, name:string}[]>([]);

  useEffect(() => {
   fetch('http://localhost:8000/api/tumors').then(res => res.json()).then((data) => {
     setTumors(data.data);
     setTumorOptions(data.data.map((d: any) => {return {'value':d.id, 'label': d.name}}))
   }).catch(console.log);
  }, []);

  useEffect(() => {
    fetch('http://localhost:8000/api/drugs').then(res => res.json()).then((data) => {
      setDrugs(data.data.map((d: any) => {return {'value':d.id, 'label': d.name}}));
    }).catch(console.log);
   }, []);

   useEffect(() => {
    fetch('http://localhost:8000/api/reasons').then(res => res.json()).then((data) => {
      setReasons(data.map((d: any) => {return {'id':d.id, 'name': d.name}}));
    }).catch(console.log);
   }, []);


  const validationSchema = Yup.object().shape({});
  const [expanded, setExpanded] = React.useState<number | false>(false);


  function handleStopDrug(index:number, tumor:any, drug: any){
    fetch('http://localhost:8000/api/detach/'+patient.id+'/'+tumor.id+'/'+drug.id).then(res => res.json()).then((data) => {
                                        alert(JSON.stringify(data.data));
                                        tumor.drugs[index] = data.data;
                                        forceUpdate();
                                      }).catch(console.log);
  }




  return (<>


      {/*
      <Dialog open={dialogData} onClose={() => {setDialogData(false)}} aria-labelledby="form-dialog-title">
        <DialogTitle id="form-dialog-title">Perchè interrompere {dialogData ? dialogData.drug.name : ''} ?</DialogTitle>
        <Formik
            initialValues={{ragioni:[]}}
            onSubmit={ (d) => {alert(JSON.stringify(d)); handleStopDrug(dialogData.index, dialogData.tumor, dialogData.drug); setDialogData(false);}  }
          >
            <Form>
          <DialogContent>
          <DialogContentText>
            Puoi selezionare una o più ragioni.
          </DialogContentText>
            <Field name={'ragioni'} isMulti component={FormikSelect} options={reasons.map((r) => {return {'value':r.id, 'label':r.name}})} label="perchè"/>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {setDialogData(false)}} color="primary">
            Cancel
          </Button>
          <SubmitButton onClick={() => {setDialogData(false)}} color="primary">
            Save
          </SubmitButton>
        </DialogActions>
        </Form>

          </Formik>
      </Dialog>
      */}



    <Paper elevation={1} className={classes.paper}>


      {loading || !patient ? (
        <>
          <Grid container justify="center">
            <Grid item xs="auto">
              <CircularProgress color="inherit" />
            </Grid>
          </Grid>
          <Grid container justify="center">
            <Grid item xs="auto">
              Please wait...
            </Grid>
          </Grid>
        </>
      ) : (
        <>
          {patient && (<Typography variant="h5" component="h3">Tumors list</Typography>)}
          <Typography component="p" />
          {patient && (<>{!loading ? <TumorList tumors={patient.tumors} patient={patient}/> : <></>} </>)}
        </>
      )}
    </Paper>
</>
  );
  /*<ul>{drugOptions}</ul>
  <SelectField
                  name="tumors"
                  label="Tumors"
                  emptyText="Select a Disease"
                  addEmpty={false}
                  options={tumorOptions}
                />

                <SelectField
                  name="type"
                  label="Tipo"
                  emptyText="Select a type"
                  addEmpty={false}
                  options={["primario", "secondario"]}
                />
  return (
    <SelectField
                  name="tumors"
                  label="Tumors"
                  emptyText="Select a Disease"
                  addEmpty={false}
                  options={tumorOptions}
                />
  );
  */
}
