import { Dialog, DialogActions, DialogContent, DialogContentText, DialogTitle, IconButton } from "@material-ui/core";
//import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import { Field, Form, Formik } from "formik";
import React, {useState} from 'react';
import Button, { SubmitButton } from "../ui/Button";
import { FormikSelect } from "../ui/Form/FormikSelect";
import CollapsibleTable from "../ui/Table/CollipsableTable";
import TextField from '../ui/Form/TextField';
import PauseCircleFilledRoundedIcon from '@material-ui/icons/PauseCircleFilledRounded';
import Connector from "../../../api/adapters/connector";
import { useService } from "../../../reactInjector";
import { Resource } from "../../../interfaces";




export const TumorList = (props:any ) => {
  //const [expanded, setExpanded] = React.useState<number | false>(false);
  const [dialogData, setDialogData] = useState< {index: number, drug: any, tumor:any} | false >(false);
  //const [reasons, setReasons] = useState<{id:number, name:string}[]>([]);
  const [update, setUpdate] = useState<number>(Math.random());
  const reasons: Resource[] = props.reasons ?? [];
  const connector: Connector  = useService(Connector);
  function reasonDialog(onSubmit: Function) {
    const dRef: React.RefObject<any> = React.createRef();
    return (
      <Dialog
        open={dialogData != false}
        onClose={() => {
          setDialogData(false);
        }}
        aria-labelledby="form-dialog-title"
      >
        <DialogTitle id="form-dialog-title">
          Perchè interrompere {dialogData ? dialogData.drug.name : ''} ?
        </DialogTitle>
        <Formik
          initialValues={{ ragioni: [], comment: '' }}
          onSubmit={(d) =>{
            //alert(d.comment);
            onSubmit(d);
            setDialogData(false);
          }}
        >
          <Form>
            <DialogContent>
              <DialogContentText>Puoi selezionare una o più ragioni.</DialogContentText>
              <Field
                name={'ragioni'}
                isMulti
                component={FormikSelect}
                options={reasons.map((r) => {
                  return { value: r.id, label: r.name };
                })}
                label="perchè"
                onChangeCallback={(options: any) => {
                  dRef.current.style.display =
                    options.filter((option: any) => {
                      return option.label == 'altro';
                    }).length > 0
                      ? 'block'
                      : 'none';
                }}
              />
              <div ref={dRef} style={{ display: 'none' }}>
                <TextField label="Spiegaci perchè interrompere" name="comment"/>
              </div>
            </DialogContent>
            <DialogActions>
              <Button
                onClick={() => {
                  setDialogData(false);
                }}
                color="primary"
              >
                Cancel
              </Button>
              <SubmitButton text="Save"/>
            </DialogActions>
          </Form>
        </Formik>
      </Dialog>
    );
  }

  function forceUpdate(){
    let v = Math.random();
    while (v == update) v = Math.random();
    setUpdate(v);
  }


  function handleStopDrug(index:number, tumor:any, drug: any, reasons: number[], comment:string){
    let url = 'http://localhost:8000/api/detach/'+props.patient.id+'/'+tumor.id+'/'+drug.id + '?reasons=' + JSON.stringify(reasons) + (comment ? "&comment="+comment:'');
    console.log(url);

    connector.callGet('detach/'+props.patient.id+'/'+tumor.id+'/'+drug.id, { reasons: JSON.stringify(reasons), comment: comment ?? '' })
    //fetch(url).then(res => res.json())
    .then((data: any) => {
      tumor.drugs[index] = data.data.data;
      forceUpdate();
    }).catch(console.log);
  }

  return (
    <>

    <CollapsibleTable data = {
      {
        name : 'Tumors',
        head : ['Tumor', 'Type', 'Sede', 'T', 'M', 'N'],
        fields: props.patient.tumors.map ((tumor:any) => {
          return {
            'fields' : [tumor.name, tumor.type, tumor.sede && tumor.sede[0] ? tumor.sede[0].name : '', tumor.stadio.T, tumor.stadio.M, tumor.stadio.N,],
            'data' : {
              'name' : 'Drugs',
              'head' : ['Drug', 'Start date', 'End date', 'Stop reasons', ''],
              'fields' : tumor.drugs.map ( (drug:any, i:number) => [
                drug.name,
                drug.start_date,
                drug.end_date ? drug.end_date : 'in corso...',
                drug.reasons.reduce ((map:string, drug:any) => {
                  if(drug.name == "altro") return map;
                  if (map) map += ", ";
                  map = map + drug.name;
                  return map;
                }, "") + (drug.comment ? ", " + drug.comment : ""),
                <IconButton
                  size="small"
                  color="secondary"
                  disabled={drug.end_date != null}
                  onClick={async () => {
                    setDialogData({'drug':drug, index: i, 'tumor': tumor});
                  }}><PauseCircleFilledRoundedIcon /></IconButton>
              ])
            }
          }
        })
      }
    }/>



    {reasonDialog( (d: any) => {
      if(dialogData !== false)
        handleStopDrug(dialogData.index, dialogData.tumor, dialogData.drug, d.ragioni, d.comment);
      setDialogData(false);
    })}

     </>
  );
}
