import React from 'react';
import { Dayjs } from 'dayjs';
import {
  DiseaseEntity,
  DrugEntity,
  PatientDrugRepository,
  PatientEntity,
} from '../../../../api';
import TabPanel from './TabPanel';
import GoBackRow from './GoBackRow';
import RepositoryTable from '../../ui/RepositoryTable';

interface PanelProps {
  index: number;
  currentTab: number;
  patient: PatientEntity;
}

export default function DrugsPanel({ currentTab, patient, index }: PanelProps) {
  const { id } = patient;
  // const classes = useStyles();
  return (
    <TabPanel value={currentTab} index={index}>
      <RepositoryTable
        columns={[
          {
            dataField: 'drug',
            label: 'Drug',
            format: (v: DrugEntity) => v.name,
          },
          {
            dataField: 'disease',
            label: 'Disease',
            format: (v?: DiseaseEntity) => v?.name ?? 'Not Specified',
          },
          {
            dataField: 'start_date',
            label: 'Start',
            format: (v: Dayjs) => v.format('YYYY-MM-DD'),
          },
          {
            dataField: 'end_date',
            label: 'End',
            format: (v?: Dayjs) => v?.format('YYYY-MM-DD') ?? 'Current',
          },
        ]}
        repositoryToken={PatientDrugRepository}
        parameters={{ patient_id: id }}
        collapsible
        collapsibleContent={(row) => {
          return <>TODO: {row.id}</>;
        }}
      />
      {/* {patient.diseases.length === 0 && ( */}
      {/*  <Typography variant="overline" display="block" gutterBottom> */}
      {/*    Nothing to show here. */}
      {/*  </Typography> */}
      {/* )} */}
      {/* {patient.diseases.map((disease: any) => ( */}
      {/*  <Accordion */}
      {/*    key={`accordion-${disease.id}`} */}
      {/*    TransitionProps={{ unmountOnExit: true }} */}
      {/*    expanded={expanded === disease.id} */}
      {/*    onChange={(_e, isExpanded: boolean) => { */}
      {/*      setExpanded(isExpanded ? disease.id : -1); */}
      {/*    }} */}
      {/*  > */}
      {/*    <AccordionSummary expandIcon={<ExpandMoreIcon />}> */}
      {/*      <Typography>{disease.name}</Typography> */}
      {/*    </AccordionSummary> */}
      {/*    <AccordionDetails> */}
      {/*      <TableContainer component={Paper}> */}
      {/*        <Table> */}
      {/*          <TableHead> */}
      {/*            <TableRow className={classes.stickyStyle}> */}
      {/*              <TableCell>Drugs</TableCell> */}
      {/*            </TableRow> */}
      {/*          </TableHead> */}
      {/*          <TableBody> */}
      {/*            {disease.medicines.map((medicine: any) => ( */}
      {/*              <TableRow */}
      {/*                key={`accordion-${disease.id}-drug-${medicine.id}`} */}
      {/*              > */}
      {/*                <TableCell>{medicine.name}</TableCell> */}
      {/*              </TableRow> */}
      {/*            ))} */}
      {/*          </TableBody> */}
      {/*        </Table> */}
      {/*      </TableContainer> */}
      {/*    </AccordionDetails> */}
      {/*  </Accordion> */}
      {/* ))} */}
      <GoBackRow id={id} />
    </TabPanel>
  );
}
