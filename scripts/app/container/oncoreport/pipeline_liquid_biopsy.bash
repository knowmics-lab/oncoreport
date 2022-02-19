#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/path.bash"

usage() {
  echo "Usage: $0 [-depth/-dp analysis depth ] [-gender/-g patient gender ]
  [-surname/-s patient surname ] [-allfreq/-af filter-expression of AF ]
  [-name/-n patient name] [-id/-i patient id] [-age/-a patient age]
  [-city/-c where patient lives] [-phone/-ph telephone number of the patient]
  [-tumor/-t patient tumor]
  [-stage/-sg stage of the tumor]
  [-project_path/-pp project_path path]
  [-threads/-th number of bowtie2 threads, leave 1 if you are uncertain]
  [-genome/-gn index must be hg19 or hg38]
  [-drug_path/-d_path file path where drugs are listed (.txt, one drug per row)]
  [-fastq1/-fq1 first fastq sample]
  [-fastq2/-fq2 second fastq sample]
  [-ubam/-ub ubam sample]
  [-paired/-pr must be yes if ubam paired sample is loaded otherwise, if ubam is not paired, it must be no]
  [-bam/-b bam or sam sample]
  [-vcf/-v vcf sample]" 1>&2
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
  -ubam | -ub)
    ubam="$2"
    shift
    ;;
  -bam | -b)
    bam="$2"
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
  -depth | -dp)
    depth="$2"
    echo "The value provided for filter-expression of DP is $depth"
    shift
    ;;
  -allfreq | -af)
    AF="$2"
    echo "The value provided for filter-expression of AF is $AF"
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
  *)
    exit_abnormal_usage "Error: invalid parameter \"$1\"."
    shift
    ;;
  esac
  shift
done

if [[ -z "$fastq1" ]] && { [[ -z "$ubam" ]] || [[ -z "$paired" ]]; } && [[ -z "$bam" ]] && [[ -z "$vcf" ]]; then
  exit_abnormal_usage "One input file should be specified."
fi

if [[ -z "$name" ]] || [[ -z "$surname" ]] || [[ -z "$tumor" ]] || [[ -z "$age" ]] || [[ -z "$drug_path" ]] || [[ -z "$gender" ]] || [[ -z "$depth" ]] || [[ -z "$AF" ]] || [[ -z "$id" ]] || [[ -z "$threads" ]] || [[ -z "$project_path" ]]; then
  exit_abnormal_usage "All parameters must be passed"
fi

PATH_PROJECT=$project_path
PATH_TRIM=$PATH_PROJECT/trim
PATH_SAM=$PATH_PROJECT/sam
PATH_BAM_ANNO=$PATH_PROJECT/bam_annotated
PATH_BAM_SORT=$PATH_PROJECT/bam_sorted
PATH_BAM_ORD=$PATH_PROJECT/bam_ordered
PATH_VCF_MUT=$PATH_PROJECT/mutect
PATH_VCF_FILTERED=$PATH_PROJECT/filtered
PATH_VCF_PASS=$PATH_PROJECT/pass_filtered
PATH_VCF_DP=$PATH_PROJECT/dp_filtered
PATH_VCF_IN_SN=$PATH_PROJECT/in_snp
PATH_VCF_AF=$PATH_PROJECT/vcf_af
PATH_VCF_PASS_AF=$PATH_PROJECT/pass_final
PATH_VCF_MERGE=$PATH_PROJECT/merge
PATH_VCF_TO_CONVERT=$PATH_PROJECT/vcf_converted
PATH_CONVERTED=$PATH_PROJECT/converted
PATH_TXT=$PATH_PROJECT/txt
PATH_TRIAL=$PATH_TXT/trial
PATH_REFERENCE=$PATH_TXT/reference
PATH_OUTPUT=$PATH_PROJECT/report

echo "Removing old folders"

[[ -d "$PATH_CONVERTED" ]] && rm -r "$PATH_CONVERTED"
[[ -d "$PATH_BAM_ORD" ]] && rm -r "$PATH_BAM_ORD"
[[ -d "$PATH_VCF_PASS" ]] && rm -r "$PATH_VCF_PASS"
[[ -d "$PATH_VCF_PASS_AF" ]] && rm -r "$PATH_VCF_PASS_AF"
[[ -d "$PATH_VCF_MUT" ]] && rm -r "$PATH_VCF_MUT"
[[ -d "$PATH_TXT" ]] && rm -r "$PATH_TXT"

[[ ! -d "$PATH_TRIM" ]] && mkdir "$PATH_TRIM"
[[ ! -d "$PATH_SAM" ]] && mkdir "$PATH_SAM"
[[ ! -d "$PATH_BAM_ANNO" ]] && mkdir "$PATH_BAM_ANNO"
[[ ! -d "$PATH_BAM_ORD" ]] && mkdir "$PATH_BAM_ORD"
[[ ! -d "$PATH_BAM_SORT" ]] && mkdir "$PATH_BAM_SORT"
[[ ! -d "$PATH_VCF_MUT" ]] && mkdir "$PATH_VCF_MUT"
[[ ! -d "$PATH_VCF_FILTERED" ]] && mkdir "$PATH_VCF_FILTERED"
[[ ! -d "$PATH_VCF_PASS" ]] && mkdir "$PATH_VCF_PASS"
[[ ! -d "$PATH_VCF_DP" ]] && mkdir "$PATH_VCF_DP"
[[ ! -d "$PATH_VCF_IN_SN" ]] && mkdir "$PATH_VCF_IN_SN"
[[ ! -d "$PATH_VCF_AF" ]] && mkdir "$PATH_VCF_AF"
[[ ! -d "$PATH_VCF_PASS_AF" ]] && mkdir "$PATH_VCF_PASS_AF"
[[ ! -d "$PATH_VCF_MERGE" ]] && mkdir "$PATH_VCF_MERGE"
[[ ! -d "$PATH_VCF_TO_CONVERT" ]] && mkdir "$PATH_VCF_TO_CONVERT"
[[ ! -d "$PATH_CONVERTED" ]] && mkdir "$PATH_CONVERTED"
[[ ! -d "$PATH_TXT" ]] && mkdir "$PATH_TXT"
[[ ! -d "$PATH_TRIAL" ]] && mkdir "$PATH_TRIAL"
[[ ! -d "$PATH_REFERENCE" ]] && mkdir "$PATH_REFERENCE"
[[ ! -d "$PATH_OUTPUT" ]] && mkdir "$PATH_OUTPUT"

if [ -n "$ubam" ]; then
  UB=$(basename "${ubam%.*}")
  PATH_FASTQ="$PATH_PROJECT/fastq"
  mkdir "$PATH_FASTQ"
  if [[ "$paired" == "yes" ]]; then
    bamToFastq -i "$ubam" -fq "$PATH_FASTQ/${UB}.fq" -fq2 "$PATH_FASTQ/${UB}_2.fq" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 100
    fastq1=$PATH_FASTQ/${UB}.fq
    fastq2=$PATH_FASTQ/${UB}_2.fq
  elif [[ "$paired" == "no" ]]; then
    bamToFastq -i "$ubam" -fq "$PATH_FASTQ/${UB}.fq" || exit_abnormal_code "Unable to convert uBAM to FASTQ" 100
    fastq1="$PATH_FASTQ/${UB}.fq"
  fi
fi

echo "Starting the analysis"

if [ -n "$fastq1" ] && [ -z "$fastq2" ]; then
  FQ1=$(basename "$fastq1")
  FASTQ1_NAME=$(basename "${FQ1%.*}")
  if [ "${FQ1: -3}" == ".gz" ]; then
    FASTQ1_NAME=$(basename "${FASTQ1_NAME%.*}")
  fi
  echo "The FASTQ file is not paired."
  echo "Trimming"
  if ((threads > 7)); then
    RT=6
  else
    RT=$threads
  fi
  trim_galore -j "$RT" -o "$PATH_TRIM/" --dont_gzip "$fastq1" || exit_abnormal_code "Unable to trim input file" 101
  echo "Alignment"
  bwa mem -M -t "$threads" "$ONCOREPORT_INDEXES_PATH/$index.fa" "$PATH_TRIM/${FASTQ1_NAME}_trimmed.fq" | samtools view -1 - > "$PATH_SAM/aligned.bam" || exit_abnormal_code "Unable to align input file" 103
elif [ -n "$fastq1" ] && [ -n "$fastq2" ]; then
  FQ1=$(basename "$fastq1")
  FQ2=$(basename "$fastq2")
  FASTQ1_NAME=$(basename "${FQ1%.*}")
  FASTQ2_NAME=$(basename "${FQ2%.*}")
  if [ "${FQ1: -3}" == ".gz" ]; then
    FASTQ1_NAME=$(basename "${FASTQ1_NAME%.*}")
  fi
  if [ "${FQ2: -3}" == ".gz" ]; then
    FASTQ2_NAME=$(basename "${FASTQ2_NAME%.*}")
  fi
  echo "The FASTQ file is paired"
  echo "Trimming"
  if ((threads > 7)); then
    RT=6
  else
    RT=$threads
  fi
  trim_galore -j "$RT" --paired --dont_gzip -o "$PATH_TRIM/" "$fastq1" "$fastq2" || exit_abnormal_code "Unable to trim input file" 101
  echo "Running fastq-pair"
  FILE1="$PATH_TRIM/${FASTQ1_NAME}_val_1.fq"
  FILE2="$PATH_TRIM/${FASTQ2_NAME}_val_2.fq"
  fastq_pair "$FILE1" "$FILE2" || exit_abnormal_code "Unable to perform reads pairing" 102
  O_FILE1="$PATH_TRIM/${FASTQ1_NAME}_val_1.fq.paired.fq"
  O_FILE2="$PATH_TRIM/${FASTQ2_NAME}_val_2.fq.paired.fq"
  if [ ! -f "$O_FILE1" ] || [ ! -f "$O_FILE2" ]; then
    exit_abnormal_code "Unable to perform reads pairing" 102
  fi
  echo "Alignment"
  bwa mem -M -t "$threads" "$ONCOREPORT_INDEXES_PATH/${index}.fa" "$O_FILE1" "$O_FILE2" | samtools view -1 - > "$PATH_SAM/aligned.bam" || exit_abnormal_code "Unable to align input file" 103
fi

if [ -z "$bam" ] && [ -z "$vcf" ]; then
  echo "Adding Read Group"
  samtools sort -@ "$threads" "$PATH_SAM/aligned.bam" -o /dev/stdout | java -jar "$GATK_PATH" AddOrReplaceReadGroups -I /dev/stdin -O "$PATH_BAM_ANNO/annotated.bam" --RGID 0 --RGLB lib1 --RGPL "illumina" --RGPU "SN166" --RGSM "$FASTQ1_NAME" --VALIDATION_STRINGENCY SILENT || exit_abnormal_code "Unable to add read group" 104
elif [ -n "$bam" ]; then
  FASTQ1_NAME=$(basename "${bam%.*}")
  echo "Validating BAM"
  java -jar "$PICARD_PATH" ValidateSamFile I="$bam" MODE=SUMMARY
  echo "Adding Read Group"
  samtools sort -@ "$threads" "$bam" -o /dev/stdout | java -jar "$GATK_PATH" AddOrReplaceReadGroups -I /dev/stdin -O "$PATH_BAM_ANNO/annotated.bam" --RGID 0 --RGLB lib1 --RGPL "illumina" --RGPU "SN166" --RGSM "$FASTQ1_NAME" --VALIDATION_STRINGENCY SILENT || exit_abnormal_code "Unable to add read group" 104
fi

if [ -n "$fastq1" ] || [ -n "$bam" ]; then
  echo "Sorting"
  java -jar "$GATK_PATH" SortSam --INPUT "$PATH_BAM_ANNO/annotated.bam" --OUTPUT /dev/stdout --SORT_ORDER "coordinate" \
    --CREATE_INDEX false --CREATE_MD5_FILE false --VALIDATION_STRINGENCY SILENT | \
    java -jar "$GATK_PATH" SetNmMdAndUqTags --INPUT /dev/stdin --OUTPUT "$PATH_BAM_SORT/sorted.bam" \
    --CREATE_INDEX true --REFERENCE_SEQUENCE "$ONCOREPORT_INDEXES_PATH/${index}.fa" || exit_abnormal_code "Unable to sort" 105
  echo "Recalibrating Quality Scores"
  java -jar "$GATK_PATH" BaseRecalibrator -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -I "$PATH_BAM_SORT/sorted.bam" \
    --use-original-qualities -O "$PATH_BAM_SORT/recal_data.csv" \
    --known-sites "$ONCOREPORT_RECALIBRATION_PATH/${index}.vcf.gz" || exit_abnormal_code "Unable to compute recalibration data" 106
  java -jar "$GATK_PATH" ApplyBQSR -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -I "$PATH_BAM_SORT/sorted.bam" \
    -O "$PATH_BAM_SORT/recal.bam" -bqsr "$PATH_BAM_SORT/recal_data.csv" --static-quantized-quals 10 \
    --static-quantized-quals 20 --static-quantized-quals 30 --add-output-sam-program-record \
    --create-output-bam-md5 --use-original-qualities || exit_abnormal_code "Unable to apply base quality recalibration" 107
  echo "Reordering"
  java -jar "$PICARD_PATH" ReorderSam I="$PATH_BAM_SORT/recal.bam" O="$PATH_BAM_ORD/ordered.bam" SEQUENCE_DICTIONARY="$ONCOREPORT_INDEXES_PATH/${index}.dict" CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true VALIDATION_STRINGENCY=SILENT || exit_abnormal_code "Unable to reorder" 108
  echo "Variant Calling"
  java -jar "$GATK_PATH" Mutect2 -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -I "$PATH_BAM_ORD/ordered.bam" -tumor "$FASTQ1_NAME" -O "$PATH_VCF_MUT/variants.vcf" -mbq 25 || exit_abnormal_code "Unable to call variants" 109
  echo "Variant Filtration"
  java -jar "$GATK_PATH" FilterMutectCalls -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -V "$PATH_VCF_MUT/variants.vcf" -O "$PATH_VCF_FILTERED/variants.vcf" --stats "$PATH_VCF_FILTERED/variants.vcf.stats" || exit_abnormal_code "Unable to filter variants" 110
  echo "PASS Selection"
  awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$PATH_VCF_FILTERED/variants.vcf" >"$PATH_VCF_PASS/variants.vcf" || exit_abnormal_code "Unable to select PASS variants" 111
fi

if [ -n "$vcf" ]; then
  VCF_NAME=$(basename "$vcf")
  if [ "${VCF_NAME: -17}" != ".varianttable.txt" ]; then
    FASTQ1_NAME=$(basename "${vcf%.*}")
    echo "DP Filtering"
    java -jar "$GATK_PATH" VariantFiltration -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -V "$vcf" -O "$PATH_VCF_DP/variants.vcf" --filter-name "LowDP" --filter-expression "$depth" || exit_abnormal_code "Unable to filter by DP" 112
  fi
else
  echo "DP Filtering"
  java -jar "$GATK_PATH" VariantFiltration -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -V "$PATH_VCF_PASS/variants.vcf" -O "$PATH_VCF_DP/variants.vcf" --filter-name "LowDP" --filter-expression "$depth" || exit_abnormal_code "Unable to filter by DP" 112
fi

#VARIANTTABLE format
if [ -n "$vcf" ] && [ "${vcf: -17}" == ".varianttable.txt" ]; then
  FASTQ1_NAME=$(basename "$vcf" ".varianttable.txt")
  type=illumina
  Rscript "$ONCOREPORT_SCRIPT_PATH/ProcessVariantTable.R" "$depth" "$AF" "$vcf" "$FASTQ1_NAME" "$PATH_PROJECT" || exit_abnormal_code "Unable to process Illumina VariantTable" 113
else
  echo "Splitting indel and snp"
  java -jar "$PICARD_PATH" SplitVcfs I="$PATH_VCF_DP/variants.vcf" SNP_OUTPUT="$PATH_VCF_IN_SN/variants.SNP.vcf" INDEL_OUTPUT="$PATH_VCF_IN_SN/variants.INDEL.vcf" STRICT=false || exit_abnormal_code "Unable to split INDELs and SNPs" 114
  echo "AF Filtering"
  java -jar "$GATK_PATH" VariantFiltration -R "$ONCOREPORT_INDEXES_PATH/${index}.fa" -V "$PATH_VCF_IN_SN/variants.SNP.vcf" -O "$PATH_VCF_AF/variants.vcf" --genotype-filter-name "Germline" --genotype-filter-expression "$AF" || exit_abnormal_code "Unable to filter SNPs by AF" 115
  echo "Merge indel and snp"
  java -jar "$PICARD_PATH" MergeVcfs I="$PATH_VCF_IN_SN/variants.INDEL.vcf" I="$PATH_VCF_AF/variants.vcf" O="$PATH_VCF_MERGE/variants.vcf" || exit_abnormal_code "Unable to merge filtered SNPs with INDELs" 116
  echo "PASS Selection"
  awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' "$PATH_VCF_MERGE/variants.vcf" >"$PATH_VCF_PASS_AF/variants.vcf" || exit_abnormal_code "Unable to select PASS variants" 117
  echo "Germline"
  grep Germline "$PATH_VCF_PASS_AF/variants.vcf" >"$PATH_VCF_TO_CONVERT/variants_Germline.vcf" || exit_abnormal_code "Unable to grep Germline variants" 118
  echo "Somatic"
  grep Germline -v "$PATH_VCF_PASS_AF/variants.vcf" >"$PATH_VCF_TO_CONVERT/variants_Somatic.vcf" || exit_abnormal_code "Unable to grep Somatic variants" 119
  echo "Annotation"
  { sed -i '/#CHROM/,$!d' "$PATH_VCF_TO_CONVERT/variants_Somatic.vcf" &&
    sed -i '/chr/,$!d' "$PATH_VCF_TO_CONVERT/variants_Germline.vcf" &&
    sed -i '/chr/,$!d' "$PATH_VCF_TO_CONVERT/variants_Somatic.vcf" &&
    cut -f1,2,4,5 "$PATH_VCF_TO_CONVERT/variants_Somatic.vcf" >"$PATH_CONVERTED/variants_Somatic.txt" &&
    cut -f1,2,4,5 "$PATH_VCF_TO_CONVERT/variants_Germline.vcf" >"$PATH_CONVERTED/variants_Germline.txt"; } ||
    exit_abnormal_code "Unable to prepare variants for annotation" 120
  type=biopsy
fi

echo "Annotation of VCF files"
Rscript "$ONCOREPORT_SCRIPT_PATH/MergeInfo.R" -g "$index" -d "$ONCOREPORT_DATABASES_PATH" -c "$ONCOREPORT_COSMIC_PATH" \
  -p "$PATH_PROJECT" -s "$FASTQ1_NAME" -t "$tumor" -a "$type" || exit_abnormal_code "Unable to prepare report input files" 121
php "$ONCOREPORT_SCRIPT_PATH/../ws/artisan" esmo:parse "$tumor" "$PATH_PROJECT" || exit_abnormal_code "Unable to prepare ESMO guidelines" 122
echo "Report creation"
Rscript "$ONCOREPORT_SCRIPT_PATH/CreateReport.R" -n "$name" -s "$surname" -c "$id" -g "$gender" -a "$age" -t "$tumor" \
  -f "$FASTQ1_NAME" -p "$PATH_PROJECT" -d "$ONCOREPORT_DATABASES_PATH" -A "$type" -C "$city" -P "$phone" \
  -T "$stage" -D "$drug_path" -H "$ONCOREPORT_HTML_TEMPLATE" -E "$depth" -F "$AF" || exit_abnormal_code "Unable to create report" 123

echo "Removing folders"
{ rm -r "$PATH_TRIM" &&
  rm -r "$PATH_SAM" &&
  rm -r "$PATH_BAM_ANNO" &&
  rm -r "$PATH_BAM_SORT" &&
  rm -r "$PATH_VCF_TO_CONVERT" &&
  rm -r "$PATH_VCF_DP" &&
  rm -r "$PATH_VCF_IN_SN" &&
  rm -r "$PATH_VCF_AF" &&
  rm -r "$PATH_VCF_MERGE" &&
  chmod -R 777 "$PATH_PROJECT"; } || exit_abnormal_code "Unable to clean up folders" 124

echo "Done"
