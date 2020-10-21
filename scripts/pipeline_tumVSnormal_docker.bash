#!/bin/bash

usage() {
  echo "Usage: $0 [-gender/-g patient gender ]
  [-surname/-s patient surname ]
  [-name/-n patient name] [-id/-i patient id] [-age/-a patient age]
  [-tumor/-t patient tumor, you must choose a type of tumor from disease_list.txt]
  [-idx_path/-ip index path]
  [-project_path/-pp project_path path]
  [-threads/-th number of bowtie2 threads, leave 1 if you are uncertain]
  [-index/-idx index must be hg19 or hg38]
  [-fastq1/-fq1 first fastq sample]
  [-fastq2/-fq2 second fastq sample]
  [-normal1/-nm1 first fastq sample]
  [-normal2/-nm2 second fastq sample]
  [-ubamt/-ubt ubam tumor sample]
  [-ubamn/-ubn ubam normal sample]
  [-bamt/-bt bam or sam tumor sample]
  [-bamn/-bn bam or sam normal sample]
  [-paired/-pr paired sample]
  [-vcf/-v vcf sample]
  [-cosmic/-c path of COSMIC]
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
    -fastq2 | -fq2) fastq2="$2"
    shift;;
    -ubamt | -ubt) ubamt="$2"
    shift;;
    -ubamn | -ubn) ubamn="$2"
    shift;;
    -normal1 | -nm1) normal1="$2"
    shift;;
    -normal2 | -nm2) normal2="$2"
    shift;;
    -bamt | -bt) bamt="$2"
    shift;;
    -bamn | -bn) bamn="$2"
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
    -cosmic | -c) cosmic="$2"
    echo "The value provided for cosmic is $cosmic"
    if [ ! -d "$cosmic" ]; then
      echo "Error: You must pass a valid cosmic directory"
      exit_abnormal
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

if ( [[ -z "$fastq1" ]] || [[ -z "$normal1" ]] ) && ( [[ -z "$ubamt" ]] || [[ -z "$ubamn" ]] || [[ -z "$paired" ]] ) && ( [[ -z "$bamt" ]] || [[ -z "$bamn" ]] ) && [[ -z "$vcf" ]]; then
  echo "At least one couple of parameter between \$fastq1 - \$normal1, \$ubamt -\$ubamn - \$paired, \$bamt - \$bamn, or the parameter \$vcf must be passed"
  usage
  exit
fi

if [[ -z "$index_path" ]] || [[ -z "$name" ]] || [[ -z "$surname" ]] || [[ -z "$tumor" ]] || [[ -z "$age" ]] || [[ -z "$index" ]] || [[ -z "$gender" ]] || [[ -z "$id" ]] || [[ -z "$threads" ]] || [[ -z "$cosmic" ]] || [[ -z "$database" ]] || [[ -z "$project_path" ]]; then
  echo "all parameters must be passed"
  usage
  exit
fi


PATH_PROJECT=$project_path
PATH_INDEX=$index_path
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
PATH_OUTPUT=$PATH_PROJECT/output

echo "Removing old folders"

if [[ -d $PATH_MARK_DUP_TUMOR ]]; then
rm -r $PATH_MARK_DUP_TUMOR
fi
if [[ -d $PATH_MARK_DUP_NORMAL ]]; then
rm -r $PATH_MARK_DUP_NORMAL
fi
if [[ -d $PATH_VCF_FILTERED ]]; then
rm -r $PATH_VCF_FILTERED
fi
if [[ -d $PATH_VCF_PASS ]]; then
rm -r $PATH_VCF_PASS
fi
if [[ -d $PATH_TXT ]]; then
rm -r $PATH_TXT
fi


echo "Creating temp folders"

if [[ ! -d $PATH_TRIM_TUMOR ]]; then
mkdir $PATH_TRIM_TUMOR
fi
if [[ ! -d $PATH_TRIM_NORMAL ]]; then
mkdir $PATH_TRIM_NORMAL
fi
if [[ ! -d $PATH_SAM_TUMOR ]]; then
mkdir $PATH_SAM_TUMOR
fi
if [[ ! -d $PATH_SAM_NORMAL ]]; then
mkdir $PATH_SAM_NORMAL
fi
if [[ ! -d $PATH_BAM_ANNO_TUMOR ]]; then
mkdir $PATH_BAM_ANNO_TUMOR
fi
if [[ ! -d $PATH_BAM_ANNO_NORMAL ]]; then
mkdir $PATH_BAM_ANNO_NORMAL
fi
if [[ ! -d $PATH_BAM_ORD_TUMOR ]]; then
mkdir $PATH_BAM_ORD_TUMOR
fi
if [[ ! -d $PATH_BAM_ORD_NORMAL ]]; then
mkdir $PATH_BAM_ORD_NORMAL
fi
if [[ ! -d $PATH_BAM_SORT_TUMOR ]]; then
mkdir $PATH_BAM_SORT_TUMOR
fi
if [[ ! -d $PATH_BAM_SORT_NORMAL ]]; then
mkdir $PATH_BAM_SORT_NORMAL
fi
if [[ ! -d $PATH_MARK_DUP_TUMOR ]]; then
mkdir $PATH_MARK_DUP_TUMOR
fi
if [[ ! -d $PATH_MARK_DUP_NORMAL ]]; then
mkdir $PATH_MARK_DUP_NORMAL
fi
if [[ ! -d $PATH_VCF_MUT ]]; then
mkdir $PATH_VCF_MUT
fi
if [[ ! -d $PATH_VCF_FILTERED ]]; then
mkdir $PATH_VCF_FILTERED
fi
if [[ ! -d $PATH_VCF_PASS ]]; then
mkdir $PATH_VCF_PASS
fi
if [[ ! -d $PATH_CONVERTED ]]; then
mkdir $PATH_CONVERTED
fi
if [[ ! -d $PATH_TXT ]]; then
mkdir $PATH_TXT
fi
if [[ ! -d $PATH_TRIAL ]]; then
mkdir $PATH_TRIAL
fi
if [[ ! -d $PATH_REFERENCE ]]; then
mkdir $PATH_REFERENCE
fi
if [[ ! -d $PATH_OUTPUT ]]; then
mkdir $PATH_OUTPUT
fi

#TUMOR ANALYSIS

if [ ! -z "$ubamt" ]; then
  UB=$(basename "${ubamt%.*}")
  PATH_FASTQ=$PATH_PROJECT/fastq
  mkdir $PATH_FASTQ
  if [[ "$paired" = "yes" ]]; then
    bamToFastq -i $ubamt -fq $PATH_FASTQ/${UB}.fq -fq2 $PATH_FASTQ/${UB}_2.fq
    $fastq1 = $PATH_FASTQ/${UB}.fq
    $fastq2 = $PATH_FASTQ/${UB}_2.fq
  elif [[ "$paired" = "no" ]]; then
    bamToFastq -i $ubamt -fq $PATH_FASTQ/${UB}.fq
    $fastq1 = $PATH_FASTQ/${UB}.fq
  fi
fi

if [ ! -z "$fastq1" ] && [ ! -z "$normal1" ]; then
  FQ1=$(basename "$fastq1")
  if [ ${FQ1: -3} == ".gz" ]; then
    echo "Fastq1 tumor extraction"
    gunzip $fastq1
  fi
fi

if [ ! -z "$fastq2" ] && [ ! -z "$normal2" ]; then
  FQ2=$(basename "$fastq2")
  if [ ${FQ2: -3} == ".gz" ]; then
    echo "Fastq2 tumor extraction"
    gunzip $fastq2
  fi
fi

if [ ! -z "$fastq1" ]; then
  FASTQ1_NAME=$(basename "${FQ1%.*}")
  echo "The file loaded is a fastq"
  #Setting cutadapt path
  export PATH=/root/.local/bin/:$PATH
  if [ -z "$fastq2" ]; then
	echo "Tumor sample trimming"
	TrimGalore-0.6.0/trim_galore $fastq1 -o $PATH_TRIM_TUMOR/
	echo "Tumor sample alignment"
    bowtie2 -p $threads -x $PATH_INDEX/${index} -U $PATH_TRIM_TUMOR/${FASTQ1_NAME}_trimmed.fq -S $PATH_SAM_TUMOR/$FASTQ1_NAME.sam
  else
    FASTQ2_NAME=$(basename "${FQ2%.*}")
    echo "Tumor sample trimming"
    TrimGalore-0.6.0/trim_galore -paired $fastq1 $fastq2 -o $PATH_TRIM_TUMOR/
  	echo "Tumor sample alignment"
  	bowtie2 -p $threads -x $PATH_INDEX/${index} -1 $PATH_TRIM/${FASTQ1_NAME}_val_1.fq -2 $PATH_TRIM/${FASTQ2_NAME}_val_2.fq -S $PATH_SAM_TUMOR/$FASTQ1_NAME.sam
  fi
fi

if [ -z "$bamt" ] && [ -z "$vcf" ]; then
  echo "Adding Read Group"
  java -jar picard.jar AddOrReplaceReadGroups I=$PATH_SAM_TUMOR/${FASTQ1_NAME}.sam O=$PATH_BAM_ANNO_TUMOR/${FASTQ1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ1_NAME
elif [ ! -z "$bamt" ]; then
  FASTQ1_NAME=$(basename "${bamt%.*}")
  echo "Adding Read Group"
  java -jar picard.jar AddOrReplaceReadGroups I=$bamt O=$PATH_BAM_ANNO_TUMOR/${FASTQ1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ1_NAME
fi

if [ -z "$vcf" ]; then
  echo "Sorting"
  java -jar picard.jar SortSam I=$PATH_BAM_ANNO_TUMOR/${FASTQ1_NAME}_annotated.bam O=$PATH_BAM_SORT_TUMOR/${FASTQ1_NAME}_sorted.bam SORT_ORDER=coordinate
  echo "Reordering"
  java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_TUMOR/${FASTQ1_NAME}_sorted.bam O=$PATH_BAM_ORD_TUMOR/${FASTQ1_NAME}_ordered.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
  echo "Duplicates Removal"
  java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_TUMOR/${FASTQ1_NAME}_ordered.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_TUMOR/${FASTQ1_NAME}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_TUMOR/${FASTQ1_NAME}_marked.txt
  rm -r $PATH_SAM_TUMOR
  rm -r $PATH_BAM_ANNO_TUMOR
  rm -r $PATH_BAM_SORT_TUMOR
fi



#NORMAL ANALYSIS

if [ ! -z "$ubamn" ]; then
  UBN=$(basename "${ubamn%.*}")
  PATH_NORMAL=$PATH_PROJECT/normal
  mkdir $PATH_NORMAL
  if [[ "$paired" = "yes" ]]; then
    bamToFastq -i $ubamn -fq $PATH_NORMAL/${UBN}.fq -fq2 $PATH_NORMAL/${UBN}_2.fq
    $normal1 = $PATH_NORMAL/${UBN}.fq
    $normal2 = $PATH_NORMAL/${UBN}_2.fq
  elif [[ "$paired" = "no" ]]; then
    bamToFastq -i $ubamn -fq $PATH_NORMAL/${UBN}.fq
    $normal1 = $PATH_NORMAL/${UBN}.fq
  fi
fi

if [ ! -z "$normal1" ]; then
  NM1=$(basename "$normal1")
  if [ ${NM1: -3} == ".gz" ]; then
    echo "Fastq1 normal extraction"
    gunzip $normal1
  fi
fi

if [ ! -z "$normal2" ]; then
  NM2=$(basename "$normal2")
  if [ ${NM2: -3} == ".gz" ]; then
    echo "Fastq2 normal extraction"
    gunzip $normal2
  fi
fi

if [ ! -z "$normal1" ]; then
  NORMAL1_NAME=$(basename "${NM1%.*}")
  echo "The file loaded is a fastq"
  #Setting cutadapt path
  if [ -z "$normal2" ]; then
    echo "Normal sample trimming"
    TrimGalore-0.6.0/trim_galore $normal1 -o $PATH_TRIM_TUMOR/
    echo "Normal sample alignment"
    bowtie2 -p $threads -x $PATH_INDEX/${index} -U $PATH_TRIM_NORMAL/${NORMAL1_NAME}_trimmed.fq -S $PATH_SAM_NORMAL/${NORMAL1_NAME}.sam
  else
    NORMAL2_NAME=$(basename "${NM2%.*}")
    echo "Normal sample trimming"
    TrimGalore-0.6.0/trim_galore -paired $normal1 $normal2 -o $PATH_TRIM_NORMAL/
    echo "Normal sample alignment"
    bowtie2 -p $threads -x $PATH_INDEX/${index} -1 $PATH_TRIM/${NORMAL1_NAME}_val_1.fq -2 $PATH_TRIM/${NORMAL2_NAME}_val_2.fq  -S $PATH_SAM_NORMAL/${NORMAL1_NAME}.sam
  fi
fi

if [ -z "$bamn" ] && [ -z "$vcf" ]; then
  echo "AddingRead Group"
  java -jar picard.jar AddOrReplaceReadGroups I=$PATH_SAM_NORMAL/$NORMAL1_NAME.sam O=$PATH_BAM_ANNO_NORMAL/${NORMAL1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $NORMAL1_NAME
elif [ ! -z "$bamn" ]; then
  NORMAL1_NAME=$(basename "${bamn%.*}")
  java -jar picard.jar AddOrReplaceReadGroups I=$bamn O=$PATH_BAM_ANNO_NORMAL/${NORMAL1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $NORMAL1_NAME
fi

if [ -z "$vcf" ]; then
  echo "Sorting"
  java -jar picard.jar SortSam I=$PATH_BAM_ANNO_NORMAL/${NORMAL1_NAME}_annotated.bam O=$PATH_BAM_SORT_NORMAL/${NORMAL1_NAME}_sorted.bam SORT_ORDER=coordinate
  echo "Reordering"
  java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_NORMAL/${NORMAL1_NAME}_sorted.bam O=$PATH_BAM_ORD_NORMAL/${NORMAL1_NAME}_ordered.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
  echo "Duplicates Removal"
  java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_NORMAL/${NORMAL1_NAME}_ordered.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_NORMAL/${NORMAL1_NAME}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_NORMAL/${NORMAL1_NAME}_marked.txt
  rm -r $PATH_SAM_NORMAL
  rm -r $PATH_BAM_ANNO_NORMAL
  rm -r $PATH_BAM_SORT_NORMAL
fi


# VCF ANALYSIS

if [ -z "$vcf" ]; then
  echo "Variant Calling"
  java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar Mutect2 -R $PATH_INDEX/${index}.fa -I $PATH_MARK_DUP_TUMOR/${FASTQ1_NAME}_nodup.bam -tumor $FASTQ1_NAME -I $PATH_MARK_DUP_NORMAL/${NORMAL1_NAME}_nodup.bam -normal $NORMAL1_NAME -O $PATH_VCF_MUT/$FASTQ1_NAME.vcf -mbq 25
  echo "Variant Filtering"
  java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar FilterMutectCalls -V $PATH_VCF_MUT/$FASTQ1_NAME.vcf -O $PATH_VCF_FILTERED/$FASTQ1_NAME.vcf
  echo "PASS Selection"
  awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_FILTERED/$FASTQ1_NAME.vcf > $PATH_VCF_PASS/$FASTQ1_NAME.vcf
else
  FASTQ1_NAME=$(basename $vcf ".vcf")
  cp $vcf $PATH_VCF_PASS/
fi

$type = tumnorm
echo "Annotation"
sed -i '/#CHROM/,$!d' $PATH_VCF_PASS/$FASTQ1_NAME.vcf
sed -i '/chr/,$!d' $PATH_VCF_PASS/$FASTQ1_NAME.vcf
cut -f1,2,4,5 $PATH_VCF_PASS/$FASTQ1_NAME.vcf > $PATH_CONVERTED/$FASTQ1_NAME.txt
Rscript MergeInfo.R $index $database $PATH_PROJECT $FASTQ1_NAME "$tumor" $type
# REPORT CREATION
echo "Report creation"
R -e "rmarkdown::render('./CreateReport.Rmd',output_file='$PATH_OUTPUT/report_$FASTQ1_NAME.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ1_NAME $PATH_PROJECT $database $type

rm -r $PATH_TRIM_NORMAL
rm -r $PATH_BAM_ORD_NORMAL
rm -r $PATH_TRIM_TUMOR
rm -r $PATH_BAM_ORD_TUMOR
rm -r $PATH_VCF_MUT
rm -r $PATH_CONVERTED

echo "done"
