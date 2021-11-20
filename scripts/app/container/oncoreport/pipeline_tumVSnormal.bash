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
  [-project_path/-pp project_path path]
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
  -city)
    city="$2"
    echo "The value provided for city is $city"
    shift
    ;;
  -phone)
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

#TUMOR ANALYSIS
if [ -n "$ubamt" ]; then
  UB=$(basename "${ubamt%.*}")
  PATH_FASTQ="$PATH_PROJECT/fastq"
  [[ ! -d "$PATH_FASTQ" ]] && mkdir "$PATH_FASTQ"
  if [[ "$paired" == "yes" ]]; then
    bamToFastq -i "$ubamt" -fq "$PATH_FASTQ/${UB}_1.fq" -fq2 "$PATH_FASTQ/${UB}_2.fq" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 101
    fastq1="$PATH_FASTQ/${UB}_1.fq"
    fastq2="$PATH_FASTQ/${UB}_2.fq"
  elif [[ "$paired" == "no" ]]; then
    bamToFastq -i "$ubamt" -fq "$PATH_FASTQ/${UB}.fq" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 101
    fastq1="$PATH_FASTQ/${UB}.fq"
  fi
fi

if [ -n "$fastq1" ]; then
  FQ1=$(basename "$fastq1")
  FASTQ1_NAME=$(basename "${FQ1%.*}")
  if [ "${FQ1: -3}" == ".gz" ]; then
    FASTQ1_NAME=$(basename "${FASTQ1_NAME%.*}")
  fi
  if ((threads > 7)); then
    RT=6
  else
    RT=$threads
  fi
  if [ -z "$fastq2" ]; then
    echo "Tumor FASTQ file is not paired."
    echo "Tumor sample trimming"
    trim_galore -j "$RT" -o "$PATH_TRIM_TUMOR/" --dont_gzip "$fastq1" || exit_abnormal_code "Unable to trim input file" 102
    echo "Tumor sample alignment"
    bowtie2 -p "$threads" -x "$ONCOREPORT_INDEXES_PATH/${index}" -U "$PATH_TRIM_TUMOR/${FASTQ1_NAME}_trimmed.fq" -S "$PATH_SAM_TUMOR/aligned.sam" || exit_abnormal_code "Unable to align input file" 103
  else
    echo "Tumor FASTQ file is paired."
    FQ2=$(basename "$fastq2")
    FASTQ2_NAME=$(basename "${FQ2%.*}")
    if [ "${FQ2: -3}" == ".gz" ]; then
      FASTQ2_NAME=$(basename "${FASTQ2_NAME%.*}")
    fi
    echo "Tumor sample trimming"
    trim_galore -j "$RT" -o "$PATH_TRIM_TUMOR/" --dont_gzip --paired "$fastq1" "$fastq2" || exit_abnormal_code "Unable to trim input file" 102
    echo "Tumor sample alignment"
    bowtie2 -p "$threads" -x "$ONCOREPORT_INDEXES_PATH/${index}" -1 "$PATH_TRIM_TUMOR/${FASTQ1_NAME}_val_1.fq" -2 "$PATH_TRIM_TUMOR/${FASTQ2_NAME}_val_2.fq" -S "$PATH_SAM_TUMOR/aligned.sam" || exit_abnormal_code "Unable to align input file" 103
  fi
fi

if [ -z "$bamt" ] && [ -z "$vcf" ]; then
  echo "Adding Read Group"
  java -jar "$PICARD_PATH" AddOrReplaceReadGroups I="$PATH_SAM_TUMOR/aligned.sam" O="$PATH_BAM_ANNO_TUMOR/annotated.bam" RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM="$FASTQ1_NAME" || exit_abnormal_code "Unable to add read groups" 104
elif [ -n "$bamt" ]; then
  FASTQ1_NAME=$(basename "${bamt%.*}")
  echo "Adding Read Group"
  java -jar "$PICARD_PATH" AddOrReplaceReadGroups I="$bamt" O="$PATH_BAM_ANNO_TUMOR/annotated.bam" RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM="$FASTQ1_NAME" || exit_abnormal_code "Unable to add read groups" 104
fi

if [ -z "$vcf" ]; then
  echo "Sorting"
  java -jar "$PICARD_PATH" SortSam I="$PATH_BAM_ANNO_TUMOR/annotated.bam" O="$PATH_BAM_SORT_TUMOR/sorted.bam" SORT_ORDER=coordinate || exit_abnormal_code "Unable to sort" 105
  echo "Reordering"
  java -jar "$PICARD_PATH" ReorderSam I="$PATH_BAM_SORT_TUMOR/sorted.bam" O="$PATH_BAM_ORD_TUMOR/ordered.bam" SEQUENCE_DICTIONARY="$ONCOREPORT_INDEXES_PATH/${index}.dict" CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true || exit_abnormal_code "Unable to reorder" 106
  echo "Duplicates Removal"
  java -jar "$PICARD_PATH" MarkDuplicates I="$PATH_BAM_ORD_TUMOR/ordered.bam" REMOVE_DUPLICATES=TRUE O="$PATH_MARK_DUP_TUMOR/nodup.bam" CREATE_INDEX=TRUE M="$PATH_MARK_DUP_TUMOR/marked.txt" || exit_abnormal_code "Unable to remove duplicates" 107
fi

#NORMAL ANALYSIS
if [ -n "$ubamn" ]; then
  UBN=$(basename "${ubamn%.*}")
  PATH_NORMAL="$PATH_PROJECT/normal"
  [[ ! -d "$PATH_NORMAL" ]] && mkdir "$PATH_NORMAL"
  if [[ "$paired" == "yes" ]]; then
    bamToFastq -i "$ubamn" -fq "$PATH_NORMAL/${UBN}_1.fq" -fq2 "$PATH_NORMAL/${UBN}_2.fq" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 108
    normal1="$PATH_NORMAL/${UBN}_1.fq"
    normal2="$PATH_NORMAL/${UBN}_2.fq"
  elif [[ "$paired" == "no" ]]; then
    bamToFastq -i "$ubamn" -fq "$PATH_NORMAL/${UBN}.fq" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 108
    normal1="$PATH_NORMAL/${UBN}.fq"
  fi
fi

if [ -n "$normal1" ]; then
  NM1=$(basename "$normal1")
  NORMAL1_NAME=$(basename "${NM1%.*}")
  if [ "${NM1: -3}" == ".gz" ]; then
    NORMAL1_NAME=$(basename "${NORMAL1_NAME%.*}")
  fi
  if ((threads > 7)); then
    RT=6
  else
    RT=$threads
  fi
  if [ -z "$normal2" ]; then
    echo "Normal FASTQ file is not paired."
    echo "Normal sample trimming"
    trim_galore -j "$RT" -o "$PATH_TRIM_NORMAL/" --dont_gzip "$normal1" || exit_abnormal_code "Unable to trim input file" 109
    echo "Normal sample alignment"
    bowtie2 -p "$threads" -x "$ONCOREPORT_INDEXES_PATH/${index}" -U "$PATH_TRIM_NORMAL/${NORMAL1_NAME}_trimmed.fq" -S "$PATH_SAM_NORMAL/aligned.sam" || exit_abnormal_code "Unable to align input file" 110
  else
    echo "Normal FASTQ file is paired."
    NM2=$(basename "$normal2")
    NORMAL2_NAME=$(basename "${NM2%.*}")
    if [ "${NM2: -3}" == ".gz" ]; then
      NORMAL2_NAME=$(basename "${NORMAL2_NAME%.*}")
    fi
    echo "Normal sample trimming"
    trim_galore -j "$RT" -o "$PATH_TRIM_NORMAL/" --dont_gzip --paired "$normal1" "$normal2" || exit_abnormal_code "Unable to trim input file" 109
    echo "Normal sample alignment"
    bowtie2 -p "$threads" -x "$ONCOREPORT_INDEXES_PATH/${index}" -1 "$PATH_TRIM_NORMAL/${NORMAL1_NAME}_val_1.fq" -2 "$PATH_TRIM_NORMAL/${NORMAL2_NAME}_val_2.fq" -S "$PATH_SAM_NORMAL/aligned.sam" || exit_abnormal_code "Unable to align input file" 110
  fi
fi

if [ -z "$bamn" ] && [ -z "$vcf" ]; then
  echo "AddingRead Group"
  java -jar "$PICARD_PATH" AddOrReplaceReadGroups I="$PATH_SAM_NORMAL/aligned.sam" O="$PATH_BAM_ANNO_NORMAL/annotated.bam" RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM="$NORMAL1_NAME" || exit_abnormal_code "Unable to add read groups" 111
elif [ -n "$bamn" ]; then
  NORMAL1_NAME=$(basename "${bamn%.*}")
  java -jar "$PICARD_PATH" AddOrReplaceReadGroups I="$bamn" O="$PATH_BAM_ANNO_NORMAL/annotated.bam" RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM="$NORMAL1_NAME" || exit_abnormal_code "Unable to add read groups" 111
fi

if [ -z "$vcf" ]; then
  echo "Sorting"
  java -jar "$PICARD_PATH" SortSam I="$PATH_BAM_ANNO_NORMAL/annotated.bam" O="$PATH_BAM_SORT_NORMAL/sorted.bam" SORT_ORDER=coordinate || exit_abnormal_code "Unable to sort" 112
  echo "Reordering"
  java -jar "$PICARD_PATH" ReorderSam I="$PATH_BAM_SORT_NORMAL/sorted.bam" O="$PATH_BAM_ORD_NORMAL/ordered.bam" SEQUENCE_DICTIONARY="$ONCOREPORT_INDEXES_PATH/${index}.dict" CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true || exit_abnormal_code "Unable to reorder" 113
  echo "Duplicates Removal"
  java -jar "$PICARD_PATH" MarkDuplicates I="$PATH_BAM_ORD_NORMAL/ordered.bam" REMOVE_DUPLICATES=TRUE O="$PATH_MARK_DUP_NORMAL/nodup.bam" CREATE_INDEX=TRUE M="$PATH_MARK_DUP_NORMAL/marked.txt" || exit_abnormal_code "Unable to remove duplicates" 114
fi

# VCF ANALYSIS

if [ -z "$vcf" ]; then
  echo "Variant Calling"
  java -jar "$GATK_PATH" Mutect2 -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -I "$PATH_MARK_DUP_TUMOR/nodup.bam" -tumor "$FASTQ1_NAME" -I "$PATH_MARK_DUP_NORMAL/nodup.bam" -normal "$NORMAL1_NAME" -O "$PATH_VCF_MUT/variants.vcf" -mbq 25 || exit_abnormal_code "Unable to call variants" 115
  echo "Variant Filtering"
  java -jar "$GATK_PATH" FilterMutectCalls -V "$PATH_VCF_MUT/variants.vcf" -O "$PATH_VCF_FILTERED/variants.vcf" || exit_abnormal_code "Unable to filter variants" 116
  echo "PASS Selection"
  awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$PATH_VCF_FILTERED/variants.vcf" >"$PATH_VCF_PASS/variants.vcf" || exit_abnormal_code "Unable to select PASS variants" 117
else
  FASTQ1_NAME=$(basename "$vcf" ".vcf")
  cp "$vcf" "$PATH_VCF_PASS/variants.vcf" || exit_abnormal_code "Unable to copy VCF file" 118
fi

type=tumnorm
{ sed -i '/#CHROM/,$!d' "$PATH_VCF_PASS/variants.vcf" &&
  sed -i '/chr/,$!d' "$PATH_VCF_PASS/variants.vcf" &&
  cut -f1,2,4,5 "$PATH_VCF_PASS/variants.vcf" >"$PATH_CONVERTED/variants.txt"; } ||
  exit_abnormal_code "Unable to prepare variants for annotation" 119

[[ ! -s "$PATH_CONVERTED/variants.txt" ]] && exit_abnormal_code "Unable to continue since no variants have been found!" 200

echo "Annotation of VCF files"
Rscript "$ONCOREPORT_SCRIPT_PATH/MergeInfo.R" -g "$index" -d "$ONCOREPORT_DATABASES_PATH" -c "$ONCOREPORT_COSMIC_PATH" \
  -p "$PATH_PROJECT" -s "$FASTQ1_NAME" -t "$tumor" -a "$type" || exit_abnormal_code "Unable to prepare report input files" 120
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
  rm -r "$PATH_VCF_MUT" &&
  rm -r "$PATH_CONVERTED" &&
  chmod -R 777 "$PATH_PROJECT"; } || exit_abnormal_code "Unable to clean up folders" 122

echo "Done"
