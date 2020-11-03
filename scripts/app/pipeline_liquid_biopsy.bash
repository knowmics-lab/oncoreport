#!/bin/bash

usage() {
  echo "Usage: $0 [-depth/-dp analysis depth ] [-gender/-g patient gender ]
  [-surname/-s patient surname ] [-allfreq/-af filter-expression of AF ]
  [-name/-n patient name] [-id/-i patient id] [-age/-a patient age]
  [-tumor/-t patient tumor, you must choose a type of tumor from disease_list.txt]
  [-idx_path/-ip index path]
  [-project_path/-pp project_path path]
  [-threads/-th number of bowtie2 threads, leave 1 if you are uncertain]
  [-index/-idx index must be hg19 or hg38]
  [-fastq1/-fq1 first fastq sample]
  [-fastq2/-fq2 second fastq sample]
  [-ubam/-ub ubam sample]
  [-paired/-pr must be yes if ubam paired sample is loaded otherwise, if ubam is not paired, it must be no]
  [-bam/-b bam or sam sample]
  [-vcf/-v vcf sample]
  [-database/-db database path]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}

while [ -n "$1" ]
do
  case "$1" in
    -fastq1 | -fq1) fastq1="$2"
    shift;;
    -fastq2 | -fq2) fast2="$2"
    shift;;
    -ubam | -ub) ubam="$2"
    shift;;
    -bam | -b) bam="$2"
    shift;;
    -vcf | -v) vcf="$2"
    shift;;
    -paired | -pr) paired="$2"
    echo "The value provided for paired is $paired"
    if ! [ $paired = "yes" ] ; then
      if !  [ $paired = "no" ] ; then
        echo "Error: paired must be equal to yes or no."
        exit_abnormal
        exit 1
      fi
    fi
    shift;;
    -depth | -dp) depth="$2"
    echo "The value provided for filter-expression of DP is $depth"
    shift;;
    -allfreq | -af) AF="$2"
    echo "The value provided for filter-expression of AF is $AF"
    shift;;
    -name | -n) name="$2"
    echo "The value provided for patient name is $name"
    shift;;
    -surname | -s) surname="$2"
    echo "The value provided for patient surname is $surname"
    shift;;
    -id | -i) id="$2"
    echo "The value provided for patient ID is $id"
    shift;;
    -gender | -g) gender="$2"
    echo "The value provided for patient gender is $gender"
    shift;;
    -age | -a) age="$2"
    re_isanum='^[0-9]+$'
    echo "The value provided for patient age is $age"
    if ! [[ $age =~ $re_isanum ]] ; then
      echo "Error: Age must be a positive, whole number."
      exit_abnormal
      exit 1
    elif [ $age -eq "0" ]; then
      echo "Error: Age must be greater than zero."
      exit_abnormal
      exit 1
    fi
    shift;;
    -tumor | -t) tumor="$2"
    echo "The value provided for patient tumor is $tumor"
    if cat disease_list.txt | grep -w "$tumor" > /dev/null; then
    command;
    else echo "Error: Tumor must be a value from the list disease_list.txt";
    exit_abnormal
    exit 1
    fi
    shift;;
    -idx_path | -ip) index_path="$2"
    echo "The value provided for path index is $index_path"
    if [ ! -d "$index_path" ]; then
      echo "Error: You must pass a valid directory"
      exit_abnormal
      exit 1
      fi
    shift;;
    -project_path | -pp) project_path="$2"
    echo "The value provided for project path is $project_path"
    if [ ! -d "$project_path" ]; then
      echo "Error: You must pass a valid directory"
      exit_abnormal
      exit 1
      fi
    shift;;
    -threads | -th) threads="$2"
    echo "The value provided for threads is $threads"
    if [ $threads -eq "0" ]; then
      echo "Error: Threads must be greater than zero."
      exit_abnormal
    fi
    shift;;
    -index | -idx) index="$2"
    echo "The value provided for index is $index"
    if ! [ $index = "hg19" ] ; then
      if !  [ $index = "hg38" ] ; then
      echo "Error: index must be equal to hg19 or hg38."
      exit_abnormal
      exit 1
      fi
    fi
    shift;;
    -database | -db) database="$2"
    echo "The value provided for database path is $database"
    if [ ! -d "$database" ]; then
      echo "Error: You must pass a valid database directory"
      exit_abnormal
    fi
    shift;;
    *)
      exit_abnormal
    shift;;
    #Questo non so se lasciarlo perché non so se funziona come su getopts
    --help | -h) help="$2"
      usage
      exit_abnormal
      exit 1
      shift;;
  esac
  shift
done

if [[ -z "$fastq1" ]] && ( [[ -z "$ubam" ]] || [[ -z "$paired" ]] ) && [[ -z "$bam" ]] && [[ -z "$vcf" ]]; then
  echo "At least one parameter between \$fastq1, \$fastq2, \$ubam, \$bam or \$vcf must be passed"
  usage
  exit
fi

if [[ -z "$index_path" ]] || [[ -z "$name" ]] || [[ -z "$surname" ]] || [[ -z "$tumor" ]] || [[ -z "$age" ]] || [[ -z "$index" ]] || [[ -z "$gender" ]] ||    [[ -z "$depth" ]] || [[ -z "$AF" ]] || [[ -z "$id" ]] || [[ -z "$threads" ]] || [[ -z "$database" ]] || [[ -z "$project_path" ]]; then
  echo "all parameters must be passed"
  usage
  exit
fi

      PATH_INDEX=$index_path
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
      PATH_OUTPUT=$PATH_PROJECT/output

      echo "Removing old folders"

      if [[ -d $PATH_CONVERTED ]]; then
      rm -r $PATH_CONVERTED
      fi
      if [[ -d $PATH_BAM_ORD ]]; then
      rm -r $PATH_BAM_ORD
      fi
      if [[ -d $PATH_VCF_PASS ]]; then
      rm -r $PATH_VCF_PASS
      fi
      if [[ -d $PATH_VCF_PASS_AF ]]; then
      rm -r $PATH_VCF_PASS_AF
      fi
      if [[ -d $PATH_VCF_MUT ]]; then
      rm -r $PATH_VCF_MUT
      fi
      if [[ -d $PATH_TXT ]]; then
      rm -r $PATH_TXT
      fi

      mkdir $PATH_TRIM
      mkdir $PATH_SAM
      mkdir $PATH_BAM_ANNO
      mkdir $PATH_BAM_ORD
      mkdir $PATH_BAM_SORT
      mkdir $PATH_VCF_MUT
      mkdir $PATH_VCF_FILTERED
      mkdir $PATH_VCF_PASS
      mkdir $PATH_VCF_DP
      mkdir $PATH_VCF_IN_SN
      mkdir $PATH_VCF_AF
      mkdir $PATH_VCF_PASS_AF
      mkdir $PATH_VCF_MERGE
      mkdir $PATH_VCF_TO_CONVERT
      mkdir $PATH_CONVERTED
      mkdir $PATH_TXT
      mkdir $PATH_TRIAL
      mkdir $PATH_REFERENCE
      mkdir $PATH_OUTPUT

#Setting cutadapt path
export PATH=/root/.local/bin/:$PATH

if [ ! -z "$ubam" ]; then
  UB=$(basename "${ubam%.*}")
  PATH_FASTQ=$PATH_PROJECT/fastq
  mkdir $PATH_FASTQ
  if [[ "$paired" = "yes" ]]; then
    bamToFastq -i $ubam -fq $PATH_FASTQ/${UB}.fq -fq2 $PATH_FASTQ/${UB}_2.fq
    $fastq1 = $PATH_FASTQ/${UB}.fq
    $fastq2 = $PATH_FASTQ/${UB}_2.fq
  elif [[ "$paired" = "no" ]]; then
    bamToFastq -i $ubam -fq $PATH_FASTQ/${UB}.fq
    $fastq1 = $PATH_FASTQ/${UB}.fq
  fi
fi

if [ ! -z "$fastq1" ] && [ -z "$fastq2" ]; then 
  FQ1=$(basename "$fastq1")
  if [ ${FQ1: -3} == ".gz" ]; then
    echo "Fastq extraction"
    gunzip $fastq1
  fi
elif [ ! -z "$fastq1" ] && [ ! -z "$fastq2" ]; then
  FQ1=$(basename "$fastq1")
  FQ2=$(basename "$fastq2")
  if [ ${FQ1: -3} == ".gz" ] && [ ${FQ2: -3} == ".gz" ] ; then
    echo "Fastq extraction"
    gunzip $fastq1
    gunzip $fastq2
  fi
fi

echo "Starting the analysis"

if [ ! -z "$fastq1" ] && [ -z "$fastq2" ]; then
  FASTQ1_NAME=$(basename "${FQ1%.*}")
  echo "The file loaded is a not paired fastq"
  echo "Trimming"
  TrimGalore-0.6.0/trim_galore $fastq1 -o $PATH_TRIM/
  echo "Alignment"
  bowtie2 -p $threads -x $PATH_INDEX/$index -U $PATH_TRIM/${FASTQ1_NAME}_trimmed.fq -S $PATH_SAM/${FASTQ1_NAME}.sam
elif [ ! -z "$fastq1" ] && [ ! -z "$fastq2" ]; then
  FASTQ1_NAME=$(basename "${FQ1%.*}")
  FASTQ2_NAME=$(basename "${FQ2%.*}")
  echo "The file loaded is a paired fastq"
  echo "Trimming"
  TrimGalore-0.6.0/trim_galore -paired $fastq1 $fastq2 -o $PATH_TRIM/
  echo "Alignment"
  bowtie2 -p $threads -x $PATH_INDEX/$index -1 $PATH_TRIM/${FASTQ1_NAME}_val_1.fq -2 $PATH_TRIM/${FASTQ2_NAME}_val_2.fq -S $PATH_SAM/${FASTQ1_NAME}.sam
fi
        
if [ -z "$bam" ] && [ -z "$vcf" ]; then
  echo "Adding Read Group"
  java -jar picard.jar AddOrReplaceReadGroups I=$PATH_SAM/$FASTQ1_NAME.sam O=$PATH_BAM_ANNO/${FASTQ1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ1_NAME
elif [ ! -z "$bam" ]; then
  FASTQ1_NAME=$(basename "${bam%.*}")
  echo "Adding Read Group"
  java -jar picard.jar AddOrReplaceReadGroups I=$bam O=$PATH_BAM_ANNO/${FASTQ1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ1_NAME
fi
         
if [ ! -z "$fastq1" ] || [ ! -z "$bam" ]; then
  echo "Sorting"
  java -jar picard.jar SortSam I=$PATH_BAM_ANNO/${FASTQ1_NAME}_annotated.bam O=$PATH_BAM_SORT/${FASTQ1_NAME}_sorted.bam SORT_ORDER=coordinate
  echo "Reordering"
  java -jar picard.jar ReorderSam I=$PATH_BAM_SORT/${FASTQ1_NAME}_sorted.bam O=$PATH_BAM_ORD/${FASTQ1_NAME}_ordered.bam   SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
  echo "Variant Calling"
  java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar Mutect2 -R $PATH_INDEX/${index}.fa -I $PATH_BAM_ORD/${FASTQ1_NAME}_ordered.bam -tumor $FASTQ1_NAME -O $PATH_VCF_MUT/$FASTQ1_NAME.vcf -mbq 25
  echo "Variant Filtration"
  java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar FilterMutectCalls -V $PATH_VCF_MUT/$FASTQ1_NAME.vcf -O $PATH_VCF_FILTERED/$FASTQ1_NAME.vcf
  echo "PASS Selection"
  awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_FILTERED/$FASTQ1_NAME.vcf > $PATH_VCF_PASS/$FASTQ1_NAME.vcf
fi
         
if [ ! -z "$vcf" ]; then
  VCF_NAME=$(basename "$vcf")
  if [ ${VCF_NAME: -17} != ".varianttable.txt" ]; then
    FASTQ1_NAME=$(basename "${vcf%.*}")
    echo "DP Filtering"
    java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $vcf -O $PATH_VCF_DP/$FASTQ1_NAME.vcf --filter-name "LowDP" --filter-expression $depth
  fi
else
  echo "DP Filtering"
  java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $PATH_VCF_PASS/$FASTQ1_NAME.vcf -O $PATH_VCF_DP/$FASTQ1_NAME.vcf --filter-name "LowDP" --filter-expression $depth
fi

#VARIANTTABLE format
if [ ! -z "$vcf" ] && [ ${vcf: -17} == ".varianttable.txt" ]; then
  FASTQ1_NAME=$(basename $vcf ".varianttable.txt")
  type=illumina
  Rscript ProcessVariantTable.R $depth $AF $vcf $FASTQ1_NAME $PATH_PROJECT
else
  echo "Splitting indel and snp"
  java -jar picard.jar SplitVcfs I= $PATH_VCF_DP/$FASTQ1_NAME.vcf SNP_OUTPUT= $PATH_VCF_IN_SN/$FASTQ1_NAME.SNP.vcf INDEL_OUTPUT= $PATH_VCF_IN_SN/$FASTQ1_NAME.INDEL.vcf STRICT=false
  echo "AF Filtering"
  java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $PATH_VCF_IN_SN/$FASTQ1_NAME.SNP.vcf -O $PATH_VCF_AF/$FASTQ1_NAME.vcf --genotype-filter-name "Germline" --genotype-filter-expression $AF
  echo "Merge indel and snp"
  java -jar picard.jar MergeVcfs I=$PATH_VCF_IN_SN/$FASTQ1_NAME.INDEL.vcf I=$PATH_VCF_AF/$FASTQ1_NAME.vcf O=$PATH_VCF_MERGE/$FASTQ1_NAME.vcf
  echo "PASS Selection"
  awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_MERGE/$FASTQ1_NAME.vcf > $PATH_VCF_PASS_AF/$FASTQ1_NAME.vcf
  echo "Germline"
  grep Germline $PATH_VCF_PASS_AF/$FASTQ1_NAME.vcf > $PATH_VCF_TO_CONVERT/${FASTQ1_NAME}_Germline.vcf
  echo "Somatic"
  grep Germline -v $PATH_VCF_PASS_AF/$FASTQ1_NAME.vcf > $PATH_VCF_TO_CONVERT/${FASTQ1_NAME}_Somatic.vcf
  echo "Annotation"
  sed -i '/#CHROM/,$!d' $PATH_VCF_TO_CONVERT/${FASTQ1_NAME}_Somatic.vcf
  sed -i '/chr/,$!d' $PATH_VCF_TO_CONVERT/${FASTQ1_NAME}_Germline.vcf
  sed -i '/chr/,$!d' $PATH_VCF_TO_CONVERT/${FASTQ1_NAME}_Somatic.vcf
  cut -f1,2,4,5 $PATH_VCF_TO_CONVERT/${FASTQ1_NAME}_Somatic.vcf > $PATH_CONVERTED/${FASTQ1_NAME}_Somatic.txt
  cut -f1,2,4,5 $PATH_VCF_TO_CONVERT/${FASTQ1_NAME}_Germline.vcf > $PATH_CONVERTED/${FASTQ1_NAME}_Germline.txt
  type=biopsy
fi

echo "Annotation of illumina vcf"
Rscript MergeInfo.R $index $database $PATH_PROJECT $FASTQ1_NAME "$tumor" $type

echo "Report creation"
R -e "rmarkdown::render('./CreateReport.Rmd',output_file='$PATH_OUTPUT/report_$FASTQ1_NAME.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ1_NAME $PATH_PROJECT $database $type

echo "Removing folders"
rm -r $PATH_TRIM
rm -r $PATH_SAM
rm -r $PATH_BAM_ANNO
rm -r $PATH_BAM_SORT
rm -r $PATH_VCF_TO_CONVERT
rm -r $PATH_VCF_FILTERED
rm -r $PATH_VCF_DP
rm -r $PATH_VCF_IN_SN
rm -r $PATH_VCF_AF
rm -r $PATH_VCF_MERGE

echo "Done"