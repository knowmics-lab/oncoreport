/* eslint-disable no-nested-ternary,no-plusplus */
import React, { useCallback, useMemo, useState } from 'react';
import { has, get } from 'lodash';
import { FormikErrors, FormikTouched, useFormikContext } from 'formik';
import {
  FormGroup,
  Button,
  Grid,
  Stepper,
  Step,
  StepLabel,
  createStyles,
  makeStyles,
  colors,
} from '@material-ui/core';

type ButtonClickHandler = (e: React.MouseEvent<HTMLButtonElement>) => void;

export type WizardProps<E> = {
  steps: string[] | (() => string[]);
  children: React.ReactNodeArray | ((page: number) => React.ReactNode);
  connectedFields?: (keyof E)[][] | ((page: number) => (keyof E)[]);
  fieldsErrors?: FormikErrors<E>;
  fieldsTouched?: FormikTouched<E>;
  hasErrors?: (page: number) => boolean;
  prevButton?: string | ((handler: ButtonClickHandler) => React.ReactNode);
  nextButton?: string | ((handler: ButtonClickHandler) => React.ReactNode);
  submitButton?: string | (() => React.ReactNode);
  onChangeActiveStep?: (page: number) => void;
};

const useStyles = makeStyles((theme) =>
  createStyles({
    root: {
      padding: theme.spacing(3, 2),
    },
    stepperContent: {
      padding: theme.spacing(3),
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
      color: colors.green[500],
      position: 'absolute',
      top: '50%',
      left: '50%',
      marginTop: -12,
      marginLeft: -12,
    },
    backButton: {
      marginRight: theme.spacing(1),
    },
    instructions: {
      marginTop: theme.spacing(1),
      marginBottom: theme.spacing(1),
    },
  })
);

type MaybeComponent = Parameters<typeof React.isValidElement>[0];

function findFieldNames<E>(component: MaybeComponent): (keyof E)[] {
  if (!React.isValidElement(component)) return [];
  const { props } = component;
  if (has(props, 'name')) return [get(props, 'name')];
  if (has(props, 'children')) {
    return React.Children.toArray(get(props, 'children')).flatMap(
      findFieldNames
    );
  }
  return [];
}

function findAllFields<E>(
  getF: (i: number) => MaybeComponent,
  n: number
): (keyof E)[][] {
  const connectedFields = [];
  for (let i = 0, l = n; i < l; i++) {
    connectedFields.push(findFieldNames(getF(i)));
  }
  return connectedFields;
}

function findFormikErrors<E>(
  fields?: (keyof E)[],
  errors?: FormikErrors<E>,
  touched?: FormikTouched<E>
): boolean {
  if (!errors || !touched) return false;
  if (!fields) return false;
  return fields
    .map((f) => has(touched, f) && touched[f] && has(errors, f) && !!errors[f])
    .reduce((a, v) => a || v, false);
}

export default function Wizard<E>({
  steps,
  children,
  connectedFields,
  fieldsErrors,
  fieldsTouched,
  hasErrors,
  prevButton,
  nextButton,
  submitButton,
  onChangeActiveStep,
}: WizardProps<E>) {
  const classes = useStyles();
  const formik = useFormikContext<E>();
  const [step, setStep] = useState(0);
  const allSteps = typeof steps === 'function' ? steps() : steps;
  const numberOfSteps = allSteps.length;
  const getStepContent = useCallback(
    (index: number) => {
      return typeof children === 'function'
        ? children(index)
        : React.Children.toArray(children)[index] || undefined;
    },
    [children]
  );
  const detectedFields = useMemo(() => {
    return findAllFields(getStepContent, numberOfSteps);
  }, [getStepContent, numberOfSteps]);
  const getConnectedFields = (index: number): (keyof E)[] => {
    if (typeof connectedFields === 'function') return connectedFields(index);
    if (connectedFields) return connectedFields[index];
    return detectedFields[index];
  };
  const errors = (index: number): boolean => {
    if (hasErrors && typeof hasErrors === 'function') {
      return hasErrors(index);
    }
    const fields = getConnectedFields(index);
    if (formik) {
      return findFormikErrors(fields, formik.errors, formik.touched);
    }
    return findFormikErrors(fields, fieldsErrors, fieldsTouched);
  };
  const currentStepContent = getStepContent(step);

  const handleNext = (e: React.MouseEvent<HTMLButtonElement>) => {
    setStep((s) => s + 1);
    if (onChangeActiveStep) onChangeActiveStep(step + 1);
    e.preventDefault();
  };
  const handleBack = (e: React.MouseEvent<HTMLButtonElement>) => {
    setStep((s) => s - 1);
    if (onChangeActiveStep) onChangeActiveStep(step - 1);
    e.preventDefault();
  };
  const backButtonElement = ((): React.ReactNode => {
    if (typeof prevButton === 'function') {
      return prevButton(handleBack);
    }
    return (
      <Button
        disabled={step === 0}
        onClick={handleBack}
        className={classes.backButton}
      >
        {prevButton || 'Previous'}
      </Button>
    );
  })();
  const nextButtonElement = ((): React.ReactNode => {
    if (typeof nextButton === 'function') {
      return nextButton(handleNext);
    }
    return (
      <Button variant="contained" color="primary" onClick={handleNext}>
        {nextButton || 'Next'}
      </Button>
    );
  })();
  const submitButtonElement = ((): React.ReactNode => {
    if (typeof submitButton === 'function') {
      return submitButton();
    }
    return (
      <Button type="submit" variant="contained" color="primary">
        {submitButton || 'Submit'}
      </Button>
    );
  })();
  const bottomNavigation = (() => {
    return (
      <FormGroup row className={classes.formControl}>
        <Grid container justifyContent="flex-start">
          <Grid item xs="auto">
            <div className={classes.buttonWrapper}>{backButtonElement}</div>
          </Grid>
          <Grid item xs="auto">
            {step === numberOfSteps - 1 ? (
              <div className={classes.buttonWrapper}>{submitButtonElement}</div>
            ) : (
              <div className={classes.buttonWrapper}>{nextButtonElement}</div>
            )}
          </Grid>
        </Grid>
      </FormGroup>
    );
  })();

  return (
    <>
      <Stepper activeStep={step} alternativeLabel>
        {allSteps.map((label, i) => (
          <Step key={label}>
            <StepLabel error={errors(i)}>{label}</StepLabel>
          </Step>
        ))}
      </Stepper>
      <div className={classes.stepperContent}>
        {currentStepContent}
        {bottomNavigation}
      </div>
    </>
  );
}
