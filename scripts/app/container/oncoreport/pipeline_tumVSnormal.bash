#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 [-gender/-g patient gender ]
  [-surname/-s patient surname ]
  [-name/-n patient name] [-id/-i patient id] [-age/-a patient age]
  [-city/-c where patient lives] [-phone/-ph telephone number of the patient]
  [-tumor/-t patient tumor, you must choose a type of tumor from disease_list.txt]
  [-stage/-sg stage of the tumor]
  [-project_path/-pp project_path path] [-depth/-dp analysis depth ]
  [-threads/-th number of bowtie2 threads, leave 1 if you are uncertain]
  [-genome/-gn genome version: hg19 or hg38]
  [-drug_path/-d_path file path where patient drugs are listed (.txt, one drug per row)]
  [-fastq1/-fq1 first fastq sample]
  [-fastq2/-fq2 second fastq sample]
  [-normal1/-nm1 first fastq sample]
  [-normal2/-nm2 second fastq sample]
  [-ubamt/-ubt ubam tumor sample]
  [-ubamn/-ubn ubam normal sample]
  [-paired/-pr must be yes if ubam paired sample is loaded otherwise, if ubam is not paired, it must be no]
  [-no_downsample disable reads down-sampling in Mutect2]
  [-bamt/-bt bam or sam tumor sample]
  [-bamn/-bn bam or sam normal sample]
  [-vcf/-v vcf sample]" 1>&2
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

DOWNSAMPLE=1
while [ -n "$1" ]; do
  case "$1" in
  -fastq1 | -fq1)
    fastq1="$2"
    shift
    ;;
  -fastq2 | -fq2)
    fastq2="$2"
    shift
    ;;
  -ubamt | -ubt)
    ubamt="$2"
    shift
    ;;
  -ubamn | -ubn)
    ubamn="$2"
    shift
    ;;
  -normal1 | -nm1)
    normal1="$2"
    shift
    ;;
  -normal2 | -nm2)
    normal2="$2"
    shift
    ;;
  -bamt | -bt)
    bamt="$2"
    shift
    ;;
  -bamn | -bn)
    bamn="$2"
    shift
    ;;
  -vcf | -v)
    vcf="$2"
    shift
    ;;
  -paired | -pr)
    paired="$2"
    echo "The value provided for paired is $paired"
    if ! { [ "$paired" = "yes" ] || [ "$paired" = "no" ]; }; then
      exit_abnormal_usage "Error: paired must be equal to yes or no."
    fi
    shift
    ;;
  -name | -n)
    name="$2"
    echo "The value provided for patient name is $name"
    shift
    ;;
  -surname | -s)
    surname="$2"
    echo "The value provided for patient surname is $surname"
    shift
    ;;
  -drug_path | -d_path)
    drug_path="$2"
    echo "The path for patient drugs is $drug_path"
    shift
    ;;
  -id | -i)
    id="$2"
    echo "The value provided for patient ID is $id"
    shift
    ;;
  -gender | -g)
    gender="$2"
    echo "The value provided for patient gender is $gender"
    shift
    ;;
  -age | -a)
    age="$2"
    re_isanum='^[0-9]+$'
    echo "The value provided for patient age is $age"
    if ! [[ "$age" =~ $re_isanum ]]; then
      exit_abnormal_usage "Error: Age must be a positive integer number."
    elif ((age < 0)); then
      exit_abnormal_usage "Error: Age must be greater than zero."
    fi
    shift
    ;;
  -stage | -sg)
    stage="$2"
    echo "The value provided for stage is $stage"
    shift
    ;;
  -city | -c)
    city="$2"
    echo "The value provided for city is $city"
    shift
    ;;
  -phone | -ph)
    phone="$2"
    echo "The value provided for phone is $phone"
    shift
    ;;
  -tumor | -t)
    tumor="$2"
    echo "The value provided for patient tumor is $tumor"
    if ! grep -w "$tumor" "$ONCOREPORT_DATABASES_PATH/Disease.txt" >/dev/null; then
      exit_abnormal_usage "Error: Invalid tumor supplied."
    fi
    shift
    ;;
  -project_path | -pp)
    project_path="$2"
    echo "The value provided for project path is $project_path"
    if [ ! -d "$project_path" ] && ! mkdir -p "$project_path"; then
      exit_abnormal_usage "Error: You must pass a valid directory."
    fi
    shift
    ;;
  -threads | -th)
    threads="$2"
    MAX_PROC=$(nproc)
    echo "The value provided for threads is $threads"
    if ((threads <= 0)); then
      exit_abnormal_usage "Error: Threads must be greater than zero."
    elif ((threads > MAX_PROC)); then
      exit_abnormal_usage "Error: Thread number is greater than the maximum value ($MAX_PROC)."
    fi
    shift
    ;;
  -genome | -gn)
    index="$2"
    echo "The value provided for genome is $index"
    if ! { [ "$index" = "hg19" ] || [ "$index" = "hg38" ]; }; then
      exit_abnormal_usage "Error: genome should be equal to hg19 or hg38."
    fi
    shift
    ;;
  -no_downsample)
    DOWNSAMPLE=0
    echo "Downsampling is disabled"
    ;;
  -depth | -dp)
    depth="$2"
    echo "The value provided for filter-expression of DP is $depth"
    shift
    ;;
  *)
    exit_abnormal_usage "Error: invalid parameter \"$1\"."
    shift
    ;;
  esac
  shift
done

if { [[ -z "$fastq1" ]] || [[ -z "$normal1" ]]; } && { [[ -z "$ubamt" ]] || [[ -z "$ubamn" ]] || [[ -z "$paired" ]]; } && { [[ -z "$bamt" ]] || [[ -z "$bamn" ]]; } && [[ -z "$vcf" ]]; then
  exit_abnormal_usage "One input file should be specified."
fi

if [[ -z "$name" ]] || [[ -z "$surname" ]] || [[ -z "$tumor" ]] || [[ -z "$age" ]] || [[ -z "$drug_path" ]] || [[ -z "$gender" ]] || [[ -z "$id" ]] || [[ -z "$threads" ]] || [[ -z "$project_path" ]]; then
  exit_abnormal_usage "All parameters must be passed"
fi

PATH_PROJECT=$project_path
PATH_TRIM_TUMOR=$PATH_PROJECT/trim_tumor
PATH_TRIM_NORMAL=$PATH_PROJECT/trim_normal
PATH_SAM_TUMOR=$PATH_PROJECT/sam_tumor
PATH_SAM_NORMAL=$PATH_PROJECT/sam_normal
PATH_BAM_ANNO_TUMOR=$PATH_PROJECT/bam_annotated_tumor
PATH_BAM_ANNO_NORMAL=$PATH_PROJECT/bam_annotated_normal
PATH_BAM_SORT_TUMOR=$PATH_PROJECT/bam_sorted_tumor
PATH_BAM_SORT_NORMAL=$PATH_PROJECT/bam_sorted_normal
PATH_BAM_ORD_TUMOR=$PATH_PROJECT/bam_ordered_tumor
PATH_BAM_ORD_NORMAL=$PATH_PROJECT/bam_ordered_normal
PATH_MARK_DUP_TUMOR=$PATH_PROJECT/mark_dup_tumor
PATH_MARK_DUP_NORMAL=$PATH_PROJECT/mark_dup_normal
PATH_VCF_MUT=$PATH_PROJECT/mutect
PATH_VCF_FILTERED=$PATH_PROJECT/filtered
PATH_VCF_PASS=$PATH_PROJECT/pass_filtered
PATH_CONVERTED=$PATH_PROJECT/converted
PATH_TXT=$PATH_PROJECT/txt
PATH_TRIAL=$PATH_TXT/trial
PATH_REFERENCE=$PATH_TXT/reference
PATH_OUTPUT=$PATH_PROJECT/report

echo "Removing old folders"

[[ -d $PATH_MARK_DUP_TUMOR ]] && rm -r "$PATH_MARK_DUP_TUMOR"
[[ -d $PATH_MARK_DUP_NORMAL ]] && rm -r "$PATH_MARK_DUP_NORMAL"
[[ -d $PATH_VCF_FILTERED ]] && rm -r "$PATH_VCF_FILTERED"
[[ -d $PATH_VCF_PASS ]] && rm -r "$PATH_VCF_PASS"
[[ -d $PATH_TXT ]] && rm -r "$PATH_TXT"

echo "Creating temp folders"

[[ ! -d $PATH_TRIM_TUMOR ]] && mkdir "$PATH_TRIM_TUMOR"
[[ ! -d $PATH_TRIM_NORMAL ]] && mkdir "$PATH_TRIM_NORMAL"
[[ ! -d $PATH_SAM_TUMOR ]] && mkdir "$PATH_SAM_TUMOR"
[[ ! -d $PATH_SAM_NORMAL ]] && mkdir "$PATH_SAM_NORMAL"
[[ ! -d $PATH_BAM_ANNO_TUMOR ]] && mkdir "$PATH_BAM_ANNO_TUMOR"
[[ ! -d $PATH_BAM_ANNO_NORMAL ]] && mkdir "$PATH_BAM_ANNO_NORMAL"
[[ ! -d $PATH_BAM_ORD_TUMOR ]] && mkdir "$PATH_BAM_ORD_TUMOR"
[[ ! -d $PATH_BAM_ORD_NORMAL ]] && mkdir "$PATH_BAM_ORD_NORMAL"
[[ ! -d $PATH_BAM_SORT_TUMOR ]] && mkdir "$PATH_BAM_SORT_TUMOR"
[[ ! -d $PATH_BAM_SORT_NORMAL ]] && mkdir "$PATH_BAM_SORT_NORMAL"
[[ ! -d $PATH_MARK_DUP_TUMOR ]] && mkdir "$PATH_MARK_DUP_TUMOR"
[[ ! -d $PATH_MARK_DUP_NORMAL ]] && mkdir "$PATH_MARK_DUP_NORMAL"
[[ ! -d $PATH_VCF_MUT ]] && mkdir "$PATH_VCF_MUT"
[[ ! -d $PATH_VCF_FILTERED ]] && mkdir "$PATH_VCF_FILTERED"
[[ ! -d $PATH_VCF_PASS ]] && mkdir "$PATH_VCF_PASS"
[[ ! -d $PATH_CONVERTED ]] && mkdir "$PATH_CONVERTED"
[[ ! -d $PATH_TXT ]] && mkdir "$PATH_TXT"
[[ ! -d $PATH_TRIAL ]] && mkdir "$PATH_TRIAL"
[[ ! -d $PATH_REFERENCE ]] && mkdir "$PATH_REFERENCE"
[[ ! -d $PATH_OUTPUT ]] && mkdir "$PATH_OUTPUT"

echo "Starting the analysis"

echo "Analyzing TUMOR sample"

#TUMOR ANALYSIS
if [ -n "$ubamt" ]; then
  echo "Converting uBAM to FASTQ"
  UB=$(basename "${ubamt%.*}")
  PATH_FASTQ="$PATH_PROJECT/fastq"
  [ ! -d "$PATH_FASTQ" ] && mkdir "$PATH_FASTQ"
  fastq1="$PATH_FASTQ/${UB}_1.fq"
  if [[ "$paired" == "yes" ]]; then
    fastq2="$PATH_FASTQ/${UB}_2.fq"
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/ubam_to_fastq.sh" -p -i "$ubamt" -1 "$fastq1" -2 "$fastq2" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 101
  else
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/ubam_to_fastq.sh" -i "$ubamt" -1 "$fastq1" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 101
  fi
fi

if [ -n "$fastq1" ]; then
  FASTQ1_NAME=$(. "$ONCOREPORT_SCRIPT_PATH/pipeline/get_name.sh" "$fastq1")
  if [ -n "$fastq2" ]; then
    FASTQ2_NAME=$(. "$ONCOREPORT_SCRIPT_PATH/pipeline/get_name.sh" "$fastq2")
  fi
  ALIGNED_TUMOR_FILE="$PATH_SAM_TUMOR/aligned.bam"
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/trim_and_align.sh" -1 "$fastq1" -2 "$fastq2" -i "$index" -t "$threads" \
    -r "$PATH_TRIM_TUMOR" -o "$ALIGNED_TUMOR_FILE" || exit_abnormal_code "Unable to perform alignment of tumor sample" 102
fi

if [ -n "$bamt" ]; then
  ALIGNED_TUMOR_FILE="$bamt"
  FASTQ1_NAME=$(basename "${bamt%.*}")
fi

if [ -n "$ALIGNED_TUMOR_FILE" ]; then
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/preprocess_alignment.sh" -g "$FASTQ1_NAME" -t "$threads" -i "$index" \
    -b "$ALIGNED_TUMOR_FILE" -a "$PATH_BAM_ANNO_TUMOR/annotated.bam" -s "$PATH_BAM_SORT_TUMOR/sorted.bam" \
    -d "$PATH_MARK_DUP_TUMOR/nodup.bam" -m "$PATH_MARK_DUP_TUMOR/marked.txt" \
    -r "$PATH_BAM_SORT_TUMOR/recal_data.csv" -R "$PATH_BAM_SORT_TUMOR/recal.bam" -o "$PATH_BAM_ORD_TUMOR/ordered.bam" || exit_abnormal_code "Unable to pre-process aligned BAM" 103
fi

echo "Analyzing NORMAL sample"
#NORMAL ANALYSIS
if [ -n "$ubamn" ]; then
  echo "Converting uBAM to FASTQ"
  UBN=$(basename "${ubamn%.*}")
  PATH_FASTQ_NORMAL="$PATH_PROJECT/fastq/normal"
  [ ! -d "$PATH_FASTQ_NORMAL" ] && mkdir -p "$PATH_FASTQ_NORMAL"
  normal1="$PATH_FASTQ_NORMAL/${UBN}_1.fq"
  if [[ "$paired" == "yes" ]]; then
    normal2="$PATH_FASTQ_NORMAL/${UBN}_2.fq"
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/ubam_to_fastq.sh" -p -i "$ubamn" -1 "$normal1" -2 "$normal2" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 104
  else
    bash "$ONCOREPORT_SCRIPT_PATH/pipeline/ubam_to_fastq.sh" -i "$ubamn" -1 "$normal1" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 104
  fi
fi

if [ -n "$normal1" ]; then
  NORMAL1_NAME=$(. "$ONCOREPORT_SCRIPT_PATH/pipeline/get_name.sh" "$normal1")
  if [ -n "$normal2" ]; then
    NORMAL2_NAME=$(. "$ONCOREPORT_SCRIPT_PATH/pipeline/get_name.sh" "$normal2")
  fi
  ALIGNED_NORMAL_FILE="$PATH_SAM_NORMAL/aligned.bam"
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/trim_and_align.sh" -1 "$normal1" -2 "$normal2" -i "$index" -t "$threads" \
    -r "$PATH_TRIM_NORMAL" -o "$ALIGNED_NORMAL_FILE" || exit_abnormal_code "Unable to perform alignment of tumor sample" 105
fi

if [ -n "$bamn" ]; then
  ALIGNED_NORMAL_FILE="$bamn"
  NORMAL1_NAME=$(basename "${bamn%.*}")
fi

if [ -n "$ALIGNED_NORMAL_FILE" ]; then
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/preprocess_alignment.sh" -g "$NORMAL1_NAME" -t "$threads" -i "$index" \
    -b "$ALIGNED_NORMAL_FILE" -a "$PATH_BAM_ANNO_NORMAL/annotated.bam" -s "$PATH_BAM_SORT_NORMAL/sorted.bam" \
    -d "$PATH_MARK_DUP_NORMAL/nodup.bam" -m "$PATH_MARK_DUP_NORMAL/marked.txt" \
    -r "$PATH_BAM_SORT_NORMAL/recal_data.csv" -R "$PATH_BAM_SORT_NORMAL/recal.bam" -o "$PATH_BAM_ORD_NORMAL/ordered.bam" || exit_abnormal_code "Unable to pre-process aligned BAM" 106
fi

if [ -z "$vcf" ]; then
  VAR_INPUTS=()

  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/call_mutect.sh" -i "$index" -t "$PATH_BAM_ORD_TUMOR/ordered.bam" \
    -T "$FASTQ1_NAME" -n "$PATH_BAM_ORD_NORMAL/ordered.bam" -N "$NORMAL1_NAME" \
    -v "$PATH_VCF_MUT/variants_mutect.vcf" -f "$PATH_VCF_FILTERED/variants_mutect.vcf" \
    -p "$PATH_VCF_PASS/variants_mutect.vcf" -d "$DOWNSAMPLE" || exit_abnormal_code "Unable to call variants with Mutect2" 107
  VAR_INPUTS+=( "-i" "$PATH_VCF_PASS/variants_mutect.vcf" )

  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/call_lofreq.sh" -@ "$threads" -i "$index" -t "$PATH_BAM_ORD_TUMOR/ordered.bam" \
    -T "$FASTQ1_NAME" -n "$PATH_BAM_ORD_NORMAL/ordered.bam" -v "$PATH_VCF_MUT/variants_lofreq.vcf" -p "$PATH_VCF_PASS/variants_lofreq.vcf" || exit_abnormal_code "Unable to call variants with LoFreq" 108
  VAR_INPUTS+=( "-i" "$PATH_VCF_PASS/variants_lofreq.vcf" )

  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/call_varscan.sh" -i "$index" -t "$PATH_BAM_ANNO_TUMOR/annotated.bam" \
    -T "$FASTQ1_NAME" -n "$PATH_BAM_ANNO_NORMAL/annotated.bam" -v "$PATH_VCF_MUT/variants_varscan.vcf" -p "$PATH_VCF_PASS/variants_varscan.vcf" || exit_abnormal_code "Unable to call variants with VarScan" 109
  VAR_INPUTS+=( "-i" "$PATH_VCF_PASS/variants_varscan.vcf" )

  echo "Concatenating calls"
  bash "$ONCOREPORT_SCRIPT_PATH/pipeline/merge_calls.sh" -o "$PATH_VCF_PASS/variants.vcf" "${VAR_INPUTS[@]}" || exit_abnormal_code "Unable to concatenate variant calls" 110
else
  FASTQ1_NAME=$(basename "$vcf" ".vcf")
  cp "$vcf" "$PATH_VCF_PASS/variants.vcf" || exit_abnormal_code "Unable to copy VCF file" 111
fi

type=tumnorm
echo "Pre-processing VCF files"
Rscript "$ONCOREPORT_SCRIPT_PATH/PreprocessVCF.R" -i "$PATH_VCF_PASS/variants.vcf" -o "$PATH_TXT/variants.txt" -d "$depth" || exit_abnormal_code "Unable to pre-process variants" 119
echo "Annotation of VCF files"
Rscript "$ONCOREPORT_SCRIPT_PATH/MergeInfo.R" -g "$index" -d "$ONCOREPORT_DATABASES_PATH" -c "$ONCOREPORT_COSMIC_PATH" \
  -p "$PATH_PROJECT" -s "$FASTQ1_NAME" -t "$tumor" || exit_abnormal_code "Unable to prepare report input files" 120
php "$ONCOREPORT_SCRIPT_PATH/../ws/artisan" esmo:parse "$tumor" "$PATH_PROJECT" || exit_abnormal_code "Unable to prepare ESMO guidelines" 123
echo "Report creation"
Rscript "$ONCOREPORT_SCRIPT_PATH/CreateReport.R" -n "$name" -s "$surname" -c "$id" -g "$gender" -a "$age" -t "$tumor" \
  -f "$FASTQ1_NAME" -p "$PATH_PROJECT" -d "$ONCOREPORT_DATABASES_PATH" -A "$type" -C "$city" -P "$phone" \
  -T "$stage" -D "$drug_path" -H "$ONCOREPORT_HTML_TEMPLATE" || exit_abnormal_code "Unable to create report" 121

{ rm -r "$PATH_SAM_TUMOR" &&
  rm -r "$PATH_BAM_ANNO_TUMOR" &&
  rm -r "$PATH_BAM_SORT_TUMOR" &&
  rm -r "$PATH_SAM_NORMAL" &&
  rm -r "$PATH_BAM_ANNO_NORMAL" &&
  rm -r "$PATH_BAM_SORT_NORMAL" &&
  rm -r "$PATH_TRIM_NORMAL" &&
  rm -r "$PATH_BAM_ORD_NORMAL" &&
  rm -r "$PATH_TRIM_TUMOR" &&
  rm -r "$PATH_BAM_ORD_TUMOR" &&
  rm -r "$PATH_CONVERTED" &&
  chmod -R 777 "$PATH_PROJECT"; } || exit_abnormal_code "Unable to clean up folders" 122

echo "Done"
