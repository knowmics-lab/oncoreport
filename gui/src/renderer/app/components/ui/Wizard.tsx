/* eslint-disable no-nested-ternary,no-plusplus */
import React, { useCallback, useMemo, useState } from 'react';
import { has } from 'lodash';
import { FormikErrors, FormikTouched, useFormikContext } from 'formik';
import {
  FormGroup,
  Button,
  Grid,
  Stepper,
  Step,
  StepLabel,
  Theme,
  styled,
} from '@mui/material';
import { formControlStyle } from '../utils';

type ButtonClickHandler = (e: React.MouseEvent<HTMLButtonElement>) => void;

// const rootStyle = (theme: Theme) => ({ padding: theme.spacing(3, 2) });
// const stepperContentStyle = (theme: Theme) => ({ padding: theme.spacing(3) });
// const buttonWrapperStyle = (theme: Theme) => ({
//   margin: theme.spacing(1),
//   position: 'relative',
// });
// const buttonProgressStyle = (theme: Theme) => ({
//   color: colors.green[500],
//   position: 'absolute',
//   top: '50%',
//   left: '50%',
//   marginTop: -12,
//   marginLeft: -12,
// });
const backButtonStyle = (theme: Theme) => ({ marginRight: theme.spacing(1) });
// const instructionsStyle = (theme: Theme) => ({
//   marginTop: theme.spacing(1),
//   marginBottom: theme.spacing(1),
// });

const ButtonWrapperDiv = styled('div')(({ theme }) => ({
  margin: theme.spacing(1),
  position: 'relative',
}));
const StepperContentDiv = styled('div')(({ theme }) => ({
  padding: theme.spacing(3),
}));

export type WizardProps<E> = {
  steps: string[] | (() => string[]);
  children: React.ReactNode[] | ((page: number) => React.ReactNode);
  connectedFields?: (keyof E)[][] | ((page: number) => (keyof E)[]);
  fieldsErrors?: FormikErrors<E>;
  fieldsTouched?: FormikTouched<E>;
  hasErrors?: (page: number) => boolean;
  prevButton?: string | ((handler: ButtonClickHandler) => React.ReactNode);
  nextButton?: string | ((handler: ButtonClickHandler) => React.ReactNode);
  submitButton?: string | (() => React.ReactNode);
  onChangeActiveStep?: (page: number) => void;
};

type PropsWithName<E> = { name: keyof E };
type PropsWithChildren = {
  children: React.ReactNode | React.ReactNode[] | Iterable<React.ReactNode>;
};
type MaybeComponent = Parameters<typeof React.isValidElement>[0];

function hasName<E>(
  props: React.ReactElement['props'],
): props is PropsWithName<E> {
  return has(props, 'name');
}

function hasChildren(
  props: React.ReactElement['props'],
): props is PropsWithChildren {
  return has(props, 'children');
}

function findFieldNames<E>(component: MaybeComponent): (keyof E)[] {
  if (!React.isValidElement(component)) return [];
  const { props } = component;
  if (hasName<E>(props)) return [props.name];
  if (hasChildren(props)) {
    return React.Children.toArray(props.children).flatMap(findFieldNames);
  }
  // if (has(props, 'name')) return [get(props, 'name')!];
  // if (has(props, 'children')) {
  //   return React.Children.toArray(get(props, 'children')).flatMap(
  //     findFieldNames,
  //   );
  // }
  return [];
}

function findAllFields<E>(
  getF: (i: number) => MaybeComponent,
  n: number,
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
  touched?: FormikTouched<E>,
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
    [children],
  );
  const detectedFields = useMemo(() => {
    return findAllFields(getStepContent, numberOfSteps);
  }, [getStepContent, numberOfSteps]);
  const getConnectedFields = useCallback(
    (index: number): (keyof E)[] => {
      if (typeof connectedFields === 'function') return connectedFields(index);
      if (connectedFields) return connectedFields[index];
      return detectedFields[index];
    },
    [connectedFields, detectedFields],
  );
  const errors = useCallback(
    (index: number): boolean => {
      if (hasErrors && typeof hasErrors === 'function') {
        return hasErrors(index);
      }
      const fields = getConnectedFields(index);
      if (formik) {
        return findFormikErrors(fields, formik.errors, formik.touched);
      }
      return findFormikErrors(fields, fieldsErrors, fieldsTouched);
    },
    [fieldsErrors, fieldsTouched, formik, getConnectedFields, hasErrors],
  );
  const currentStepContent = useMemo(
    () => getStepContent(step),
    [getStepContent, step],
  );

  const handleNext = useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      setStep((s) => s + 1);
      if (onChangeActiveStep) onChangeActiveStep(step + 1);
      e.preventDefault();
    },
    [onChangeActiveStep, step],
  );
  const handleBack = useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      setStep((s) => s - 1);
      if (onChangeActiveStep) onChangeActiveStep(step - 1);
      e.preventDefault();
    },
    [onChangeActiveStep, step],
  );
  const backButtonElement = useMemo((): React.ReactNode => {
    if (typeof prevButton === 'function') {
      return prevButton(handleBack);
    }
    return (
      <Button disabled={step === 0} onClick={handleBack} sx={backButtonStyle}>
        {prevButton || 'Previous'}
      </Button>
    );
  }, [handleBack, prevButton, step]);
  const nextButtonElement = useMemo((): React.ReactNode => {
    if (typeof nextButton === 'function') {
      return nextButton(handleNext);
    }
    return (
      <Button variant="contained" color="primary" onClick={handleNext}>
        {nextButton || 'Next'}
      </Button>
    );
  }, [handleNext, nextButton]);
  const submitButtonElement = useMemo((): React.ReactNode => {
    if (typeof submitButton === 'function') {
      return submitButton();
    }
    return (
      <Button type="submit" variant="contained" color="primary">
        {submitButton || 'Submit'}
      </Button>
    );
  }, [submitButton]);

  return (
    <>
      <Stepper
        activeStep={step}
        alternativeLabel
        sx={{
          pt: 2,
        }}
      >
        {allSteps.map((label, i) => (
          <Step key={label}>
            <StepLabel error={errors(i)}>{label}</StepLabel>
          </Step>
        ))}
      </Stepper>
      <StepperContentDiv>
        {currentStepContent}
        <FormGroup row sx={formControlStyle}>
          <Grid container justifyContent="flex-end">
            <Grid item xs="auto">
              <ButtonWrapperDiv>{backButtonElement}</ButtonWrapperDiv>
            </Grid>
            <Grid item xs="auto">
              {step === numberOfSteps - 1 ? (
                <ButtonWrapperDiv>{submitButtonElement}</ButtonWrapperDiv>
              ) : (
                <ButtonWrapperDiv>{nextButtonElement}</ButtonWrapperDiv>
              )}
            </Grid>
          </Grid>
        </FormGroup>
      </StepperContentDiv>
    </>
  );
}

Wizard.defaultProps = {
  connectedFields: undefined,
  fieldsErrors: undefined,
  fieldsTouched: undefined,
  hasErrors: undefined,
  prevButton: undefined,
  nextButton: undefined,
  submitButton: undefined,
  onChangeActiveStep: undefined,
};
