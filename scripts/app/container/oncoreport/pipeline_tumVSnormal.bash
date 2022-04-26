#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: bash $0 [options]" 1>&2
  echo 1>&2
  echo "Options:" 1>&2
  echo "  -t STRING                 Input type (one of 'fastq', 'bam', 'vcf', 'ubam', required)" 1>&2
  echo "  -p                        Input is paired-end" 1>&2
  echo "  -1 FILE                   Tumor first input file (required for all input types)" 1>&2
  echo "  -2 FILE                   Tumor second input file (required if type is 'fastq' and -p flag is set)" 1>&2
  echo "  -3 FILE                   Normal first input file (required for all input types except for 'vcf')" 1>&2
  echo "  -4 FILE                   Normal second input file (required if type is 'fastq' and -p flag is set)" 1>&2
  echo "  -P DIRECTORY              Project directory (required)" 1>&2
  echo "  -C STRING                 Enable one caller. Valid values are: 'mutect', 'lofreq', 'varscan'. To enable" 1>&2
  echo "                            more than one caller, specify this option multiple times." 1>&2
  echo "  -i STRING                 Patient ID (required)" 1>&2
  echo "  -n STRING                 Patient name (required)" 1>&2
  echo "  -s STRING                 Patient surname (required)" 1>&2
  echo "  -g STRING                 Patient gender ('m' or 'f', required)" 1>&2
  echo "  -d STRING                 Patient tumor disease id in disease ontology (required)" 1>&2
  echo "  -D FILE                   File containing list of drugbank ids of drugs taken by the patient (required)" 1>&2
  echo "  -a INT                    Patient age (required)" 1>&2
  echo "  -c STRING                 Patient city" 1>&2
  echo "  -l STRING                 Patient telephone" 1>&2
  echo "  -S STRING                 Patient tumor stage" 1>&2
  echo "  -T INT                    Number of threads (default: 1)" 1>&2
  echo "  -G STRING                 Genome version ('hg19' or 'hg38', default: 'hg19')" 1>&2
  echo "  -E STRING                 Depth filter expression. Only variants matching this expression will be" 1>&2
  echo "                            considered in the analysis (default: '>0.0')" 1>&2
  echo "  -M STRING                 An expression to add to the Mutect2 call. Multiple options can be provided." 1>&2
  echo "  -L STRING                 An expression to add to the LoFreq call. Multiple options can be provided." 1>&2
  echo "  -V STRING                 An expression to add to the VarScan call. Multiple options can be provided." 1>&2
  echo 1>&2
}

exit_abnormal_code() {
  echo "$1" 1>&2
  # shellcheck disable=SC2086
  exit $2
}

exit_abnormal_usage() {
  echo "$1" 1>&2
  usage
  exit 1
}

exit_abnormal() {
  usage
  exit 1
}

PAIRED=false
REALIGN_BAM=false
PROCESS_VCF=false
THREADS=1
GENOME="hg19"
DEPTH_FILTER=">0.0"
MUTECT_ENABLE=false
MUTECT_OPTIONS=()
LOFREQ_ENABLE=false
LOFREQ_OPTIONS=()
VARSCAN_ENABLE=false
VARSCAN_OPTIONS=()
while getopts t:1:2:3:4:P:C:i:n:s:g:d:D:a:c:l:S:T:G:E:M:L:V:p flag; do
  case "${flag}" in
  t) INPUT_TYPE="${OPTARG}" ;;
  p) PAIRED=true ;;
  1) INPUT_FILE_1="${OPTARG}" ;;
  2) INPUT_FILE_2="${OPTARG}" ;;
  3) INPUT_FILE_3="${OPTARG}" ;;
  4) INPUT_FILE_4="${OPTARG}" ;;
  P) PROJECT_DIR="${OPTARG}" ;;
  C)
    [[ "${OPTARG}" == "mutect" ]] && MUTECT_ENABLE=true
    [[ "${OPTARG}" == "lofreq" ]] && LOFREQ_ENABLE=true
    [[ "${OPTARG}" == "varscan" ]] && VARSCAN_ENABLE=true
    ;;
  i) PATIENT_ID="${OPTARG}" ;;
  n) PATIENT_NAME="${OPTARG}" ;;
  s) PATIENT_SURNAME="${OPTARG}" ;;
  g) PATIENT_SEX="${OPTARG}" ;;
  d) PATIENT_TUMOR="${OPTARG}" ;;
  D) PATIENT_DRUGS="${OPTARG}" ;;
  a) PATIENT_AGE="${OPTARG}" ;;
  c) PATIENT_CITY="${OPTARG}" ;;
  l) PATIENT_TELEPHONE="${OPTARG}" ;;
  S) PATIENT_STAGE="${OPTARG}" ;;
  T) THREADS="${OPTARG}" ;;
  G) GENOME="${OPTARG}" ;;
  E) DEPTH_FILTER="${OPTARG}" ;;
  M) MUTECT_OPTIONS+=("${OPTARG}") ;;
  L) LOFREQ_OPTIONS+=("${OPTARG}") ;;
  V) VARSCAN_OPTIONS+=("${OPTARG}") ;;
  *) exit_abnormal_usage "Invalid Parameter ${flag}" ;;
  esac
done

[[ "$INPUT_TYPE" != "fastq" ]] && [[ "$INPUT_TYPE" != "bam" ]] && [[ "$INPUT_TYPE" != "vcf" ]] && [[ "$INPUT_TYPE" != "ubam" ]] && exit_abnormal_usage "Error: input type must be one of 'fastq', 'bam', 'vcf', 'ubam'."
[[ "$INPUT_TYPE" != "vcf" ]] && [[ "$MUTECT_ENABLE" == "false" ]] && [[ "$LOFREQ_ENABLE" == "false" ]] &&
  [[ "$VARSCAN_ENABLE" == "false" ]] && exit_abnormal_usage "Error: you must enable a variant caller when input type is '$INPUT_TYPE'."
{ [ -z "$INPUT_FILE_1" ] || [ ! -f "$INPUT_FILE_1" ]; } && exit_abnormal_usage "Error: tumor input file 1 is required."
[[ "$INPUT_TYPE" == "fastq" ]] && [[ "$PAIRED" == "true" ]] && { [ -z "$INPUT_FILE_2" ] || [ ! -f "$INPUT_FILE_2" ]; } && exit_abnormal_usage "Error: tumor input file 2 is required."
[[ "$INPUT_TYPE" != "vcf" ]] && { [ -z "$INPUT_FILE_3" ] || [ ! -f "$INPUT_FILE_3" ]; } && exit_abnormal_usage "Error: normal input file 1 is required."
[[ "$INPUT_TYPE" == "fastq" ]] && [[ "$PAIRED" == "true" ]] && { [ -z "$INPUT_FILE_4" ] || [ ! -f "$INPUT_FILE_4" ]; } && exit_abnormal_usage "Error: normal input file 2 is required."
[[ "$PATIENT_SEX" != "m" ]] && [[ "$PATIENT_SEX" != "f" ]] && exit_abnormal_usage "Error: sex must be either 'm' or 'f'."
[[ "$GENOME" != "hg19" ]] && [[ "$GENOME" != "hg38" ]] && exit_abnormal_usage "Error: genome must be either 'hg19' or 'hg38'."
[ -z "$PROJECT_DIR" ] && exit_abnormal_usage "Error: project directory is required."
[ -z "$PATIENT_ID" ] && exit_abnormal_usage "Error: patient id is required."
[ -z "$PATIENT_NAME" ] && exit_abnormal_usage "Error: patient name is required."
[ -z "$PATIENT_SURNAME" ] && exit_abnormal_usage "Error: patient surname is required."
[ -z "$PATIENT_TUMOR" ] && exit_abnormal_usage "Error: patient tumor is required."
{ [ -z "$PATIENT_DRUGS" ] || [ ! -f "$PATIENT_DRUGS" ]; } && exit_abnormal_usage "Error: patient drugs file is required and must be a valid file."
[ -z "$PATIENT_AGE" ] && exit_abnormal_usage "Error: patient age is required."
IS_A_NUM='^[0-9]+$'
{ ! [[ "$PATIENT_AGE" =~ $IS_A_NUM ]] || ((PATIENT_AGE < 0)); } && exit_abnormal_usage "Error: patient age must be a positive integer."
if ! grep -w "$PATIENT_TUMOR" "$ONCOREPORT_DATABASES_PATH/Disease.txt" >/dev/null; then
  exit_abnormal_usage "Error: Invalid tumor supplied."
fi
if [ ! -d "$PROJECT_DIR" ] && ! mkdir -p "$PROJECT_DIR"; then
  exit_abnormal_usage "Error: You must pass a valid directory."
fi
MAX_PROC=$(nproc)
((THREADS <= 0)) && exit_abnormal_usage "Error: Threads must be greater than zero."
((THREADS > MAX_PROC)) && exit_abnormal_usage "Error: Thread number is greater than the maximum value ($MAX_PROC)."
[[ "$INPUT_TYPE" == "vcf" ]] && PROCESS_VCF=true

echo "==============================================================================================="
echo "Input Parameters"
echo "==============================================================================================="
echo "Input Type: $INPUT_TYPE"
echo "Paired: $PAIRED"
echo "Input File 1: $INPUT_FILE_1"
echo "Input File 2: $INPUT_FILE_2"
echo "Input File 3: $INPUT_FILE_3"
echo "Input File 4: $INPUT_FILE_4"
echo "Working Directory: $(pwd)"
echo "Project Directory: $PROJECT_DIR"
echo "Patient ID: $PATIENT_ID"
echo "Patient Name: $PATIENT_NAME"
echo "Patient Surname: $PATIENT_SURNAME"
echo "Patient Age: $PATIENT_AGE"
echo "Patient Sex: $PATIENT_SEX"
echo "Patient Tumor: $PATIENT_TUMOR"
echo "Patient Drugs Input File: $PATIENT_DRUGS"
echo "Number of threads: $THREADS"
echo "Genome: $GENOME"
echo "Depth Filter: $DEPTH_FILTER"
echo "Callers:"
echo "  - Mutect: $MUTECT_ENABLE"
echo "    Custom options:" "${MUTECT_OPTIONS[@]}"
echo "  - LoFreq: $LOFREQ_ENABLE"
echo "    Custom options:" "${LOFREQ_OPTIONS[@]}"
echo "  - VarScan: $VARSCAN_ENABLE"
echo "    Custom options:" "${VARSCAN_OPTIONS[@]}"
echo "==============================================================================================="

PATH_FASTQ="$PROJECT_DIR/fastq"
PATH_TRIM="$PROJECT_DIR/trim"
PATH_TRIM_TUMOR="$PATH_TRIM/tumor"
PATH_TRIM_NORMAL="$PATH_TRIM/normal"
PATH_PREPROCESS="$PROJECT_DIR/preprocess"
PATH_VARIANTS_RAW="$PROJECT_DIR/variants"
PATH_VARIANTS_PASS="$PROJECT_DIR/variants_pass"
PATH_TXT="$PROJECT_DIR/txt"
PATH_TRIAL="$PATH_TXT/trial"
PATH_REFERENCE="$PATH_TXT/reference"
PATH_OUTPUT="$PATH_PROJECT/report"

echo "Removing old folders"
[ -d "$PATH_FASTQ" ] && rm -r "$PATH_FASTQ"
[ -d "$PATH_TRIM" ] && rm -r "$PATH_TRIM"
[ -d "$PATH_PREPROCESS" ] && rm -r "$PATH_PREPROCESS"
[ -d "$PATH_VARIANTS_RAW" ] && rm -r "$PATH_VARIANTS_RAW"
[ -d "$PATH_VARIANTS_PASS" ] && rm -r "$PATH_VARIANTS_PASS"
[ -d "$PATH_TXT" ] && rm -r "$PATH_TXT"
[ -d "$PATH_OUTPUT" ] && rm -r "$PATH_OUTPUT"

{ mkdir -p "$PATH_TRIM" &&
  mkdir -p "$PATH_TRIM_TUMOR" &&
  mkdir -p "$PATH_TRIM_NORMAL" &&
  mkdir -p "$PATH_PREPROCESS" &&
  mkdir -p "$PATH_VARIANTS_RAW" &&
  mkdir -p "$PATH_VARIANTS_PASS" &&
  mkdir -p "$PATH_TXT" &&
  mkdir -p "$PATH_TRIAL" &&
  mkdir -p "$PATH_REFERENCE" &&
  mkdir -p "$PATH_OUTPUT"; } || exit_abnormal_code "Unable to create working directories" 101

echo "Starting analysis"

DO_TRIM=true
if [[ "$INPUT_TYPE" == "bam" ]] && ! java -jar "$GATK_PATH" ValidateSamFile -I "$INPUT_FILE_1" \
  -R "$ONCOREPORT_INDEXES_PATH/${GENOME}.fa" -M SUMMARY --VALIDATION_STRINGENCY SILENT; then
  echo "Warning: An invalid BAM file has been detected performing realignment"
  REALIGN_BAM=true
  DO_TRIM=false
fi

if [[ "$INPUT_TYPE" == "ubam" ]] || { [[ "$INPUT_TYPE" == "bam" ]] && [[ "$REALIGN_BAM" == "true" ]]; }; then
  { [ ! -d "$PATH_FASTQ" ] && mkdir "$PATH_FASTQ"; } || exit_abnormal_code "Unable to create FASTQ directory" 100
  TUMOR_UB=$(basename "${INPUT_FILE_1%.*}")
  NORMAL_UB=$(basename "${INPUT_FILE_3%.*}")
  TUMOR_UBAM_FILE="$INPUT_FILE_1"
  NORMAL_UBAM_FILE="$INPUT_FILE_3"
  INPUT_FILE_1="$PATH_FASTQ/${TUMOR_UB}_1.fq"
  INPUT_FILE_3="$PATH_FASTQ/${NORMAL_UB}_1.fq"
  if [[ "$PAIRED" == "true" ]]; then
    INPUT_FILE_2="$PATH_FASTQ/${TUMOR_UB}_2.fq"
    INPUT_FILE_4="$PATH_FASTQ/${NORMAL_UB}_2.fq"
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/ubam_to_fastq.sh" -p -t "$THREADS" -i "$TUMOR_UBAM_FILE" -1 "$INPUT_FILE_1" -2 "$INPUT_FILE_2" || exit_abnormal_code "Unable to convert tumor uBAM to FASTQ" 102
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/ubam_to_fastq.sh" -p -t "$THREADS" -i "$NORMAL_UBAM_FILE" -1 "$INPUT_FILE_3" -2 "$INPUT_FILE_4" || exit_abnormal_code "Unable to convert normal uBAM to FASTQ" 103
  else
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/ubam_to_fastq.sh" -t "$THREADS" -i "$TUMOR_UBAM_FILE" -1 "$INPUT_FILE_1" || exit_abnormal_code "Unable to convert tumor uBAM to FASTQ" 102
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/ubam_to_fastq.sh" -t "$THREADS" -i "$NORMAL_UBAM_FILE" -1 "$INPUT_FILE_3" || exit_abnormal_code "Unable to convert normal uBAM to FASTQ" 103
  fi
  INPUT_TYPE="fastq"
fi

TUMOR_NAME=$(. "$ONCOREPORT_SCRIPT_PATH/pipeline/get_name.sh" "$INPUT_FILE_1")
[[ "$INPUT_TYPE" != "vcf" ]] && NORMAL_NAME=$(. "$ONCOREPORT_SCRIPT_PATH/pipeline/get_name.sh" "$INPUT_FILE_3")

if [[ "$INPUT_TYPE" == "fastq" ]]; then
  echo "Aligning TUMOR sample"
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/trim_and_align.sh" -1 "$INPUT_FILE_1" -2 "$INPUT_FILE_2" -i "$GENOME" \
    -t "$THREADS" -r "$PATH_TRIM_TUMOR" -o "$PATH_PREPROCESS/tumor_aligned_raw.bam" -n "$DO_TRIM" || exit_abnormal_code "Unable to perform alignment of tumor sample" 104
  echo "Aligning NORMAL sample"
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/trim_and_align.sh" -1 "$INPUT_FILE_3" -2 "$INPUT_FILE_4" -i "$GENOME" \
    -t "$THREADS" -r "$PATH_TRIM_NORMAL" -o "$PATH_PREPROCESS/normal_aligned_raw.bam" -n "$DO_TRIM" || exit_abnormal_code "Unable to perform alignment of normal sample" 105
  INPUT_FILE_1="$PATH_PREPROCESS/tumor_aligned_raw.bam"
  INPUT_FILE_3="$PATH_PREPROCESS/normal_aligned_raw.bam"
  INPUT_TYPE="bam"
fi

RAW_VARIANTS=false
if [[ "$INPUT_TYPE" == "bam" ]]; then
  echo "Pre-processing TUMOR sample"
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/preprocess_alignment.sh" -g "$TUMOR_NAME" -t "$THREADS" -i "$GENOME" \
    -b "$INPUT_FILE_1" -a "$PATH_PREPROCESS/tumor_annotated.bam" -s "$PATH_PREPROCESS/tumor_sorted.bam" \
    -d "$PATH_PREPROCESS/tumor_nodup.bam" -m "$PATH_PREPROCESS/tumor_marked.txt" \
    -r "$PATH_PREPROCESS/tumor_recal_data.csv" -R "$PATH_PREPROCESS/tumor_recal.bam" \
    -o "$PATH_PREPROCESS/tumor_ordered.bam" || exit_abnormal_code "Unable to pre-process TUMOR BAM" 106
  echo "Pre-processing NORMAL sample"
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/preprocess_alignment.sh" -g "$NORMAL_NAME" -t "$THREADS" -i "$GENOME" \
    -b "$INPUT_FILE_3" -a "$PATH_PREPROCESS/normal_annotated.bam" -s "$PATH_PREPROCESS/normal_sorted.bam" \
    -d "$PATH_PREPROCESS/normal_nodup.bam" -m "$PATH_PREPROCESS/normal_marked.txt" \
    -r "$PATH_PREPROCESS/normal_recal_data.csv" -R "$PATH_PREPROCESS/normal_recal.bam" \
    -o "$PATH_PREPROCESS/normal_ordered.bam" || exit_abnormal_code "Unable to pre-process NORMAL BAM" 107

  echo "Calling variants"
  VAR_INPUTS=()

  if [[ "$MUTECT_ENABLE" == "true" ]]; then
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/call_mutect.sh" -i "$GENOME" -t "$PATH_PREPROCESS/tumor_ordered.bam" \
      -T "$TUMOR_NAME" -n "$PATH_PREPROCESS/normal_ordered.bam" -N "$NORMAL_NAME" \
      -v "$PATH_VARIANTS_RAW/variants_mutect.vcf" -f "$PATH_VARIANTS_RAW/variants_mutect_with_filter.vcf" \
      -p "$PATH_VARIANTS_PASS/variants_mutect.vcf" -d "$DOWNSAMPLE" || exit_abnormal_code "Unable to call variants with Mutect2" 108
    VAR_INPUTS+=("-i" "$PATH_VARIANTS_PASS/variants_mutect.vcf")
  fi

  if [[ "$LOFREQ_ENABLE" == "true" ]]; then
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/call_lofreq.sh" -@ "$THREADS" -i "$GENOME" -t "$PATH_PREPROCESS/tumor_ordered.bam" \
      -T "$TUMOR_NAME" -n "$PATH_PREPROCESS/normal_ordered.bam" -v "$PATH_VARIANTS_RAW/variants_lofreq.vcf" \
      -p "$PATH_VARIANTS_PASS/variants_lofreq.vcf" || exit_abnormal_code "Unable to call variants with LoFreq" 109
    VAR_INPUTS+=("-i" "$PATH_VARIANTS_PASS/variants_lofreq.vcf")
  fi

  if [[ "$VARSCAN_ENABLE" == "true" ]]; then
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/call_varscan.sh" -i "$GENOME" -t "$PATH_PREPROCESS/tumor_annotated.bam" \
      -T "$TUMOR_NAME" -n "$PATH_PREPROCESS/normal_annotated.bam" -v "$PATH_VARIANTS_RAW/variants_varscan.vcf" \
      -p "$PATH_VARIANTS_PASS/variants_varscan.vcf" || exit_abnormal_code "Unable to call variants with VarScan" 110
    VAR_INPUTS+=("-i" "$PATH_VARIANTS_PASS/variants_varscan.vcf")
  fi

  echo "Concatenating calls"
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/merge_calls.sh" -o "$PATH_VARIANTS_PASS/variants.vcf" "${VAR_INPUTS[@]}" || exit_abnormal_code "Unable to concatenate variant calls" 111

  INPUT_FILE_1="$PATH_VARIANTS_PASS/variants.vcf"
  INPUT_TYPE="vcf"
  RAW_VARIANTS=true
fi

[[ "$INPUT_TYPE" != "vcf" ]] && exit_abnormal_code "Input is not a VCF file. This should never happen!!" 112
TYPE="tumnorm"

if [[ "$PROCESS_VCF" == "true" ]]; then
  echo "Filtering user variants"
  awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$INPUT_FILE_1" >"$PATH_VARIANTS_PASS/variants.vcf" || exit_abnormal_code "Unable to filter variants" 118
  INPUT_FILE_1="$PATH_VARIANTS_PASS/variants.vcf"
  COUNT_VARIANTS=$(grep -c -v '^#' "$INPUT_FILE_1")
  ((COUNT_VARIANTS <= 0)) && exit_abnormal_code "Error: No PASS variants found after filtering." 119
fi

echo "Pre-processing variants"
Rscript "$ONCOREPORT_SCRIPT_PATH/PreprocessVCF.R" -i "$INPUT_FILE_1" -o "$PATH_TXT/variants.txt" -d "$DEPTH_FILTER" || exit_abnormal_code "Unable to pre-process variants" 113
echo "Annotation of VCF files"
Rscript "$ONCOREPORT_SCRIPT_PATH/MergeInfo.R" -g "$GENOME" -d "$ONCOREPORT_DATABASES_PATH" -c "$ONCOREPORT_COSMIC_PATH" \
  -p "$PROJECT_DIR" -s "$TUMOR_NAME" -t "$PATIENT_TUMOR" || exit_abnormal_code "Unable to prepare report input files" 114
php "$ONCOREPORT_SCRIPT_PATH/../ws/artisan" esmo:parse "$PATIENT_TUMOR" "$PROJECT_DIR" || exit_abnormal_code "Unable to prepare ESMO guidelines" 115
echo "Report creation"
Rscript "$ONCOREPORT_SCRIPT_PATH/CreateReport.R" -n "$PATIENT_NAME" -s "$PATIENT_SURNAME" -c "$PATIENT_ID" \
  -g "$PATIENT_SEX" -a "$PATIENT_AGE" -t "$PATIENT_TUMOR" -f "$TUMOR_NAME" -p "$PROJECT_DIR" \
  -d "$ONCOREPORT_DATABASES_PATH" -A "$TYPE" -C "$PATIENT_CITY" -P "$PATIENT_TELEPHONE" \
  -T "$PATIENT_STAGE" -D "$PATIENT_DRUGS" -H "$ONCOREPORT_HTML_TEMPLATE" -E "$DEPTH_FILTER" || exit_abnormal_code "Unable to create report" 116

echo "Archiving results"
[[ "$RAW_VARIANTS" == "true" ]] && tar -zcf "$PROJECT_DIR/variants_raw.tgz" "$PATH_VARIANTS_RAW"
[[ "$RAW_VARIANTS" == "true" ]] && mv "$INPUT_FILE_1" "$PROJECT_DIR/variants.vcf"
[[ "$RAW_VARIANTS" == "true" ]] && tar -zcf "$PROJECT_DIR/variants_pass.tgz" "$PATH_VARIANTS_PASS"

echo "Removing folders"
[ -d "$PATH_FASTQ" ] && rm -r "$PATH_FASTQ"
{ rm -r "$PATH_TRIM" &&
  rm -r "$PATH_VARIANTS_RAW" &&
  rm -r "$PATH_VARIANTS_PASS" &&
  chmod -R 777 "$PROJECT_DIR"; } || exit_abnormal_code "Unable to clean up folders" 117

echo "Done"
