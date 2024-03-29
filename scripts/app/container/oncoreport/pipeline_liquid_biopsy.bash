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
  echo "  -1 FILE                   First input file (required for all input types)" 1>&2
  echo "  -2 FILE                   Second input file (required if type is 'fastq' and -p flag is set)" 1>&2
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
  echo "  -S STRING                 Patient tumor stage" 1>&2
  echo "  -T INT                    Number of threads (default: 1)" 1>&2
  echo "  -G STRING                 Genome version ('hg19' or 'hg38', default: 'hg19')" 1>&2
  echo "  -E STRING                 Depth filter expression. Only variants matching this expression will be" 1>&2
  echo "                            considered in the analysis (default: '>0.0')" 1>&2
  echo "  -A STRING                 Allele frequency filter expression. Any mutation matching this filter will be" 1>&2
  echo "                            considered as Germline (default: '>0.0')" 1>&2
  echo "  -M STRING                 An expression to add to the Mutect2 call. Multiple options can be provided." 1>&2
  echo "  -L STRING                 An expression to add to the LoFreq call. Multiple options can be provided." 1>&2
  echo "  -V STRING                 An expression to add to the VarScan call. Multiple options can be provided." 1>&2
  echo 1>&2
}

exit_abnormal_code() {
  echo "$1" 1>&2
  exit "$2"
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
AF_FILTER=">0.0"
MUTECT_ENABLE=false
MUTECT_OPTIONS=()
LOFREQ_ENABLE=false
LOFREQ_OPTIONS=()
VARSCAN_ENABLE=false
VARSCAN_OPTIONS=()
while getopts t:1:2:P:C:i:n:s:g:d:D:a:S:T:G:E:A:M:L:V:p flag; do
  case "${flag}" in
  t) INPUT_TYPE="${OPTARG}" ;;
  p) PAIRED=true ;;
  1) INPUT_FILE_1="${OPTARG}" ;;
  2) INPUT_FILE_2="${OPTARG}" ;;
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
  S) PATIENT_STAGE="${OPTARG}" ;;
  T) THREADS="${OPTARG}" ;;
  G) GENOME="${OPTARG}" ;;
  E) DEPTH_FILTER="${OPTARG}" ;;
  A) AF_FILTER="${OPTARG}" ;;
  M) MUTECT_OPTIONS+=("${OPTARG}") ;;
  L) LOFREQ_OPTIONS+=("${OPTARG}") ;;
  V) VARSCAN_OPTIONS+=("${OPTARG}") ;;
  *) exit_abnormal_usage "Invalid Parameter ${flag}" ;;
  esac
done

[[ "$INPUT_TYPE" != "fastq" ]] && [[ "$INPUT_TYPE" != "bam" ]] && [[ "$INPUT_TYPE" != "vcf" ]] && [[ "$INPUT_TYPE" != "ubam" ]] && exit_abnormal_usage "Error: input type must be one of 'fastq', 'bam', 'vcf', 'ubam'."
[[ "$INPUT_TYPE" != "vcf" ]] && [[ "$MUTECT_ENABLE" == "false" ]] && [[ "$LOFREQ_ENABLE" == "false" ]] &&
  [[ "$VARSCAN_ENABLE" == "false" ]] && exit_abnormal_usage "Error: you must enable a variant caller when input type is '$INPUT_TYPE'."
{ [ -z "$INPUT_FILE_1" ] || [ ! -f "$INPUT_FILE_1" ]; } && exit_abnormal_usage "Error: input file 1 is required."
[[ "$INPUT_TYPE" == "fastq" ]] && [[ "$PAIRED" == "true" ]] && { [ -z "$INPUT_FILE_2" ] || [ ! -f "$INPUT_FILE_2" ]; } && exit_abnormal_usage "Error: input file 2 is required."
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
if ! grep -w "$PATIENT_TUMOR" "$ONCOREPORT_DATABASES_PATH/diseases.tsv" >/dev/null; then
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
echo "Allele Fraction Filter: $AF_FILTER"
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
  mkdir -p "$PATH_PREPROCESS" &&
  mkdir -p "$PATH_VARIANTS_RAW" &&
  mkdir -p "$PATH_VARIANTS_PASS" &&
  mkdir -p "$PATH_TXT" &&
  mkdir -p "$PATH_TRIAL" &&
  mkdir -p "$PATH_REFERENCE" &&
  mkdir -p "$PATH_OUTPUT"; } || exit_abnormal_code "Unable to create working directories" 101

DO_TRIM=true
if [[ "$INPUT_TYPE" == "bam" ]] && ! java -jar "$GATK_PATH" ValidateSamFile -I "$INPUT_FILE_1" \
  -R "$ONCOREPORT_INDEXES_PATH/${GENOME}.fa" -M SUMMARY --VALIDATION_STRINGENCY SILENT; then
  echo "Warning: An invalid BAM file has been detected performing realignment"
  REALIGN_BAM=true
  DO_TRIM=false
fi

if [[ "$INPUT_TYPE" == "ubam" ]] || { [[ "$INPUT_TYPE" == "bam" ]] && [[ "$REALIGN_BAM" == "true" ]]; }; then
  UB=$(basename "${INPUT_FILE_1%.*}")
  UBAM_FILE="$INPUT_FILE_1"
  { [ ! -d "$PATH_FASTQ" ] && mkdir "$PATH_FASTQ"; } || exit_abnormal_code "Unable to create FASTQ directory" 100
  INPUT_FILE_1="$PATH_FASTQ/${UB}_1.fq"
  if [[ "$PAIRED" == "true" ]]; then
    INPUT_FILE_2="$PATH_FASTQ/${UB}_2.fq"
    bash "$ONCOREPORT_PIPELINE_PATH/ubam_to_fastq.sh" -t "$THREADS" -p -i "$UBAM_FILE" -1 "$INPUT_FILE_1" -2 "$INPUT_FILE_2" || exit_abnormal_code "Unable to convert BAM to FASTQ" 102
  else
    bash "$ONCOREPORT_PIPELINE_PATH/ubam_to_fastq.sh" -t "$THREADS" -i "$UBAM_FILE" -1 "$INPUT_FILE_1" || exit_abnormal_code "Unable to convert BAM to FASTQ" 102
  fi
  INPUT_TYPE="fastq"
fi

echo "Starting analysis"
FILE_1_NAME=$(. "$ONCOREPORT_PIPELINE_PATH/get_name.sh" "$INPUT_FILE_1")
if [[ "$INPUT_TYPE" == "fastq" ]]; then
  bash "$ONCOREPORT_PIPELINE_PATH/trim_and_align.sh" -1 "$INPUT_FILE_1" -2 "$INPUT_FILE_2" -i "$GENOME" \
    -t "$THREADS" -r "$PATH_TRIM" -o "$PATH_PREPROCESS/aligned_raw.bam" -n "$DO_TRIM" || exit_abnormal_code "Unable to perform alignment of tumor sample" 103
  INPUT_FILE_1="$PATH_PREPROCESS/aligned_raw.bam"
  INPUT_TYPE="bam"
fi

RAW_VARIANTS=false
if [[ "$INPUT_TYPE" == "bam" ]]; then

  bash "$ONCOREPORT_PIPELINE_PATH/preprocess_alignment.sh" -g "$FILE_1_NAME" -t "$THREADS" -i "$GENOME" \
    -b "$INPUT_FILE_1" -a "$PATH_PREPROCESS/annotated.bam" -s "$PATH_PREPROCESS/sorted.bam" \
    -r "$PATH_PREPROCESS/recal_data.csv" -R "$PATH_PREPROCESS/recal.bam" -o "$PATH_PREPROCESS/ordered.bam" || exit_abnormal_code "Unable to pre-process aligned BAM" 104

  VAR_INPUTS=()

  if [[ "$MUTECT_ENABLE" == "true" ]]; then
    bash "$ONCOREPORT_PIPELINE_PATH/call_mutect.sh" -i "$GENOME" -t "$PATH_PREPROCESS/ordered.bam" \
      -T "$FILE_1_NAME" -v "$PATH_VARIANTS_RAW/variants_mutect.vcf" -f "$PATH_VARIANTS_RAW/variants_mutect_with_filter.vcf" \
      -p "$PATH_VARIANTS_PASS/variants_mutect.vcf" "${MUTECT_OPTIONS[@]}" || exit_abnormal_code "Unable to call variants with Mutect2" 105
    VAR_INPUTS+=("-i" "$PATH_VARIANTS_PASS/variants_mutect.vcf")
  fi

  if [[ "$LOFREQ_ENABLE" == "true" ]]; then
    bash "$ONCOREPORT_PIPELINE_PATH/call_lofreq.sh" -@ "$THREADS" -i "$GENOME" -t "$PATH_PREPROCESS/ordered.bam" \
      -T "$FILE_1_NAME" -v "$PATH_VARIANTS_RAW/variants_lofreq.vcf" -p "$PATH_VARIANTS_PASS/variants_lofreq.vcf" "${LOFREQ_OPTIONS[@]}" || exit_abnormal_code "Unable to call variants with LoFreq" 106
    VAR_INPUTS+=("-i" "$PATH_VARIANTS_PASS/variants_lofreq.vcf")
  fi

  if [[ "$VARSCAN_ENABLE" == "true" ]]; then
    bash "$ONCOREPORT_PIPELINE_PATH/call_varscan.sh" -i "$GENOME" -t "$PATH_PREPROCESS/annotated.bam" \
      -T "$FILE_1_NAME" -v "$PATH_VARIANTS_RAW/variants_varscan.vcf" -p "$PATH_VARIANTS_PASS/variants_varscan.vcf" "${VARSCAN_OPTIONS[@]}" || exit_abnormal_code "Unable to call variants with VarScan" 107
    VAR_INPUTS+=("-i" "$PATH_VARIANTS_PASS/variants_varscan.vcf")
  fi

  echo "Concatenating calls"
  bash "$ONCOREPORT_PIPELINE_PATH/merge_calls.sh" -o "$PATH_VARIANTS_PASS/variants.vcf" "${VAR_INPUTS[@]}" || exit_abnormal_code "Unable to concatenate variant calls" 108

  INPUT_FILE_1="$PATH_VARIANTS_PASS/variants.vcf"
  INPUT_TYPE="vcf"
  RAW_VARIANTS=true
fi

[[ "$INPUT_TYPE" != "vcf" ]] && exit_abnormal_code "Input is not a VCF file. This should never happen!!" 109
FILE_1_NAME=$(basename "$FILE_1_NAME" ".varianttable")
TYPE="biopsy"

if [[ "$PROCESS_VCF" == "true" ]] && [[ "${INPUT_FILE_1: -17}" != ".varianttable.txt" ]]; then
  echo "Filtering user variants"
  awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$INPUT_FILE_1" >"$PATH_VARIANTS_PASS/variants.vcf" || exit_abnormal_code "Unable to filter variants" 115
  INPUT_FILE_1="$PATH_VARIANTS_PASS/variants.vcf"
  COUNT_VARIANTS=$(grep -c -v '^#' "$INPUT_FILE_1")
  ((COUNT_VARIANTS <= 0)) && exit_abnormal_code "Error: No PASS variants found after filtering." 116
fi

echo "Pre-processing variants"
PROCESSING_SCRIPT="$ONCOREPORT_SCRIPT_PATH/PreprocessVCF.R"
[[ "${INPUT_FILE_1: -17}" == ".varianttable.txt" ]] && PROCESSING_SCRIPT="$ONCOREPORT_SCRIPT_PATH/ProcessVariantTable.R"
Rscript "$PROCESSING_SCRIPT" -i "$INPUT_FILE_1" -o "$PATH_TXT/variants.txt" -d "$DEPTH_FILTER" -a "$AF_FILTER" || exit_abnormal_code "Unable to pre-process variants" 110

echo "Annotation of VCF files"
python3 "$ONCOREPORT_PIPELINE_PATH/annotate_oncokb.py" -g "$GENOME" \
   -o "$PATH_TXT/${FILE_1_NAME}_oncokb.txt" \
   -e "$ONCOREPORT_APP_PATH/.env_oncokb" "$PATH_TXT/variants.txt"
Rscript "$ONCOREPORT_SCRIPT_PATH/MergeInfo.R" -g "$GENOME" -d "$ONCOREPORT_DATABASES_PATH" -c "$ONCOREPORT_COSMIC_PATH" \
  -p "$PROJECT_DIR" -s "$FILE_1_NAME" -t "$PATIENT_TUMOR" || exit_abnormal_code "Unable to prepare report input files" 111
php "$ONCOREPORT_SCRIPT_PATH/../ws/artisan" esmo:parse "$PATIENT_TUMOR" "$PROJECT_DIR" || exit_abnormal_code "Unable to prepare ESMO guidelines" 112
echo "Report creation"
Rscript "$ONCOREPORT_SCRIPT_PATH/CreateReport.R" -n "$PATIENT_NAME" -s "$PATIENT_SURNAME" -c "$PATIENT_ID" \
  -g "$PATIENT_SEX" -a "$PATIENT_AGE" -t "$PATIENT_TUMOR" -f "$FILE_1_NAME" -p "$PROJECT_DIR" \
  -d "$ONCOREPORT_DATABASES_PATH" -A "$TYPE" -T "$PATIENT_STAGE" -D "$PATIENT_DRUGS" \
  -H "$ONCOREPORT_HTML_TEMPLATE" -E "$DEPTH_FILTER" -F "$AF_FILTER" || exit_abnormal_code "Unable to create report" 113

echo "Archiving results"
cat "$ONCOREPORT_DATABASES_PATH/versions.txt" \
  "$ONCOREPORT_COSMIC_PATH/version.txt" >"$PROJECT_DIR/database_versions.txt"
[[ "$RAW_VARIANTS" == "true" ]] && tar -zcf "$PROJECT_DIR/variants_raw.tgz" "$PATH_VARIANTS_RAW"
[[ "$RAW_VARIANTS" == "true" ]] && mv "$INPUT_FILE_1" "$PROJECT_DIR/variants.vcf"
[[ "$RAW_VARIANTS" == "true" ]] && tar -zcf "$PROJECT_DIR/variants_pass.tgz" "$PATH_VARIANTS_PASS"

echo "Removing folders"
[ -d "$PATH_FASTQ" ] && rm -r "$PATH_FASTQ"
{ rm -r "$PATH_TRIM" &&
  rm -r "$PATH_VARIANTS_RAW" &&
  rm -r "$PATH_VARIANTS_PASS" &&
  chmod -R 777 "$PROJECT_DIR"; } || exit_abnormal_code "Unable to clean up folders" 114

echo "Done"
