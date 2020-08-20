#!/bin/bash
#CAMBIA I NOMI DEI FILE R
# usage() {
#   echo "Usage: $0 [ -g patient gender ]
#   [ -s patient surname ] [-n patient name] [-i patient id] [-a patient age]
#   [-t patient tumor, you must choose a type of tumor from disease_list.txt]
#   [-p prep_database must be yes or no]
#   [-b number of bowtie2 threads, leave 1 if you are uncertain]
#   [-i index must be hg19 or hg38]
#   [-f path of the sample]
#   [-o path of COSMIC]
#   [-h database path]" 1>&2
# }
usage() {
  echo "Usage: $0 [-depth/-d analysis depth ] [-gender/-g patient gender ]
  [-surname/-s patient surname ] [-af filter-expression of AF ]
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
  [-bamt/-bt bam or sam tumor sample]
  [-bamn/-bn bam or sam normal sample]
  [-vcf/-v vcf sample]
  [-cosmic/-c path of COSMIC]
  [-database/-d database path]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}
# while getopts "n:s:i:g:a:t:p:h:b:c:f:o:h:" OPTION; do
#   case "${OPTION}" in
#     n)
#       name=$OPTARG
#       echo "The value provided for patient name is $OPTARG"
#       ;;
#     s)
#      surname=$OPTARG
#      echo "The value provided for patient surname is $OPTARG"
#      ;;
#     i)
#       id=$OPTARG
#       echo "The value provided for patient ID is $OPTARG"
#       ;;
#     g)
#       gender=$OPTARG
#       echo "The value provided for patient gender is $OPTARG"
#       ;;
#     a)
#       age=$OPTARG
#       re_isanum='^[0-9]+$'
#       echo "The value provided for patient age is $OPTARG"
#       if ! [[ $age =~ $re_isanum ]] ; then
#         echo "Error: Age must be a positive, whole number."
#         exit_abnormal
#         exit 1
#       elif [ $age -eq "0" ]; then
#         echo "Error: Age must be greater than zero."
#         exit_abnormal
#       fi
#       ;;
#     t)
#       tumor=$OPTARG
#       echo "The value provided for patient tumor is $OPTARG"
#       if cat disease_list.txt | grep -w "$tumor" > /dev/null; then
#       command;
#       else echo "Error: Tumor must be a value from the list disease_list.txt";
#       exit_abnormal
#       exit 1
#       fi
#       ;;
#     p)
#       prep_databases=$OPTARG
#       echo "The value provided for database_preparation is $OPTARG"
#       if ! [ $prep_databases = "yes" ] ; then
#         if !  [ $prep_databases = "no" ] ; then
#         echo "Error: prep_database must be equal to yes or no."
#         exit_abnormal
#         exit 1
#         fi
#       fi
#         ;;
#     b)
#       threads=$OPTARG
#       echo "The value provided for threads is $OPTARG"
#       if [ $threads -eq "0" ]; then
#         echo "Error: Threads must be greater than zero."
#         exit_abnormal
#       fi
#         ;;
#     c)
#       index=$OPTARG
#       echo "The value provided for index is $OPTARG"
#       if ! [ $index = "hg19" ] ; then
#         if !  [ $index = "hg38" ] ; then
#         echo "Error: index must be equal to hg19 or hg38."
#         exit_abnormal
#         exit 1
#         fi
#       fi
#         ;;
#      f)
#       folder=$OPTARG
#       echo "The value provided for folder is $OPTARG"
#       if [ ! -d "$folder" ]; then
#         echo "Error: You must pass a valid directory"
#         exit_abnormal
#       fi
#         ;;
#      o)
#      cosmic=$OPTARG
#      echo "The value provided for cosmic is $OPTARG"
#      if [ ! -d "$cosmic" ]; then
#        echo "Error: You must pass a valid cosmic directory"
#        exit_abnormal
#      fi
#        ;;
#      h)
#      database=$OPTARG
#      echo "The value provided for database path is $OPTARG"
#      if [ ! -d "$database" ]; then
#        echo "Error: You must pass a valid database directory"
#        exit_abnormal
#      fi
#        ;;
#     :)
#       echo "Error: ${OPTARG} requires an argument."
#       usage
#       exit_abnormal
#         ;;
#     *)
#       exit_abnormal
#         ;;
#     /? | h)
#       echo "ERROR: Invalid option $OPTARG"
#       usage
#       exit 1
#         ;;
#         esac
#       done
while [ -n "$1" ]
do
  case "$1" in
    -fastq1 | -fq1) fastq1="$2"
    shift;;
    -fastq2 | -fq2) fastq2="$2"
    shift;;
    -normal1 | -nm1) normal1="$2"
    shift;;
    -normal2 | -nm2) normal2="$2"
    shift;;
    -bam_tumor | -bt) bamt="$2"
    shift;;
    -bam_normal | -bn) bamn="$2"
    shift;;
    -vcf | -v) vcf="$2"
    shift;;
    -depth | -d) depth="$2"
    echo "The value provided for filter-expression of DP is $depth"
    shift;;
    -af) AF="$2"
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
    -cosmic | -c) cosmic="$2"
    echo "The value provided for cosmic is $cosmic"
    if [ ! -d "$cosmic" ]; then
      echo "Error: You must pass a valid cosmic directory"
      exit_abnormal
    fi
    shift;;
    -database | -d) database="$2"
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

if [[ -z "$fastq1" ]] || [[ -z "$normal1" ]] || [[ -z "$bamt" ]] || [[ -z "$vcf" ]]; then
  echo "At least one parameter between \$fastq1, \$normal1, \$bam_tumor or \$vcf must be passed"
  usage
  exit
fi

if [[ -z "$index_path" ]] || [[ -z "$name" ]] || [[ -z "$surname" ]] || [[ -z "$tumor" ]] || [[ -z "$age" ]] || [[ -z "$index" ]] || [[ -z "$gender" ]] ||    [[ -z "$depth" ]] || [[ -z "$AF" ]] || [[ -z "$id" ]] || [[ -z "$threads" ]] || [[ -z "$cosmic" ]] || [[ -z "$database" ]] || [[ -z "$project_path" ]]; then
  echo "all parameters must be passed"
  usage
  exit
fi


PATH_PROJECT=$project_path/project
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
PATH_VCF_PASS=$PATH_PROJECT/pass_filtrati
PATH_CONVERTITI=$PATH_PROJECT/convertiti
PATH_TXT_CIVIC=$PATH_PROJECT/txt_civic
PATH_TXT_CGI=$PATH_PROJECT/txt_cgi
PATH_TXT_PHARM=$PATH_PROJECT/txt_pharm
PATH_TXT_COSMIC=$PATH_PROJECT/txt_cosmic
PATH_TXT_CLINVAR=$PATH_PROJECT/txt_clinvar
PATH_TXT_REFGENE=$PATH_PROJECT/txt_refgene
PATH_DEFINITIVE=$PATH_PROJECT/definitive
PATH_TRIAL=$PATH_PROJECT/Trial
PATH_REFERENCE=$PATH_PROJECT/Reference
PATH_FOOD=$PATH_PROJECT/Food
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
if [[ -d $PATH_DEFINITIVE ]]; then
rm -r $PATH_DEFINITIVE
fi
if [[ -d $PATH_TRIAL ]]; then
rm -r $PATH_TRIAL
fi
if [[ -d $PATH_REFERENCE ]]; then
rm -r $PATH_REFERENCE
fi
if [[ -d $PATH_FOOD ]]; then
rm -r $PATH_FOOD
fi

mkdir $PATH_TRIM_TUMOR
mkdir $PATH_TRIM_NORMAL
mkdir $PATH_SAM_TUMOR
mkdir $PATH_SAM_NORMAL
mkdir $PATH_BAM_ANNO_TUMOR
mkdir $PATH_BAM_ANNO_NORMAL
mkdir $PATH_BAM_ORD_TUMOR
mkdir $PATH_BAM_ORD_NORMAL
mkdir $PATH_BAM_SORT_TUMOR
mkdir $PATH_BAM_SORT_NORMAL
mkdir $PATH_MARK_DUP_TUMOR
mkdir $PATH_MARK_DUP_NORMAL
mkdir $PATH_VCF_MUT
mkdir $PATH_VCF_FILTERED
mkdir $PATH_VCF_PASS
mkdir $PATH_CONVERTITI
mkdir $PATH_TXT_CGI
mkdir $PATH_TXT_CIVIC
mkdir $PATH_TXT_PHARM
mkdir $PATH_TXT_CLINVAR
mkdir $PATH_TXT_COSMIC
mkdir $PATH_TXT_REFGENE
mkdir $PATH_DEFINITIVE
mkdir $PATH_TRIAL
mkdir $PATH_REFERENCE
mkdir $PATH_FOOD
mkdir $PATH_PROJECT/output
mkdir $PATH_TXT_CIVIC/results
mkdir $PATH_TXT_CGI/results
mkdir $PATH_TXT_COSMIC/results
mkdir $PATH_TXT_PHARM/results
mkdir $PATH_OUTPUT

echo "Index download"

# if [[ "$prep_databases" = "yes" ]] && [[ "$index" = "hg19" ]]; then
# bash prep_banche_dati.bash
#   elif [[ "$prep_databases" = "yes" ]] && [[ "$index" = "hg38" ]]; then
#   bash prep_banche_dati_hg38.bash
# fi
#
# if [[ "$prep_databases" = "yes" ]]; then
#   echo "Index creation"
#   java -jar picard.jar CreateSequenceDictionary REFERENCE=$PATH_INDEX/${index}.fa OUTPUT=$PATH_INDEX/${index}.dict
#   samtools faidx $PATH_INDEX/${index}.fa
# fi

# for FASTQ in $(ls $PATH_FASTQ_TUMOR)
#   do
#     if [ ${FASTQ: -9} == ".fastq.gz" ]; then
#     echo "Tumor fastq extraction"
#     gunzip $PATH_FASTQ_TUMOR/*.fastq.gz
#   fi
# done


# for FASTQB in $(ls $PATH_FASTQ_NORMAL)
#   do
#     if [ ${FASTQB: -9} == ".fastq.gz" ]; then
#     echo "NORMAL fastq extraction"
#     gunzip $PATH_FASTQ_NORMAL/*.fastq.gz
#   fi
# done

if [ ! -z "$fastq1" ] && [ ! -z "$normal1" ]; then
  FQ1=$(basename "$fastq1")
  NM1=$(basename "$normal1")
  if [ ${FQ1: -3} == ".gz" ] && [ ${NM1: -3} == ".gz" ] ; then
    echo "Fastq extraction"
    gunzip $fastq1
    gunzip $normal1
  fi
fi

if [ ! -z "$fastq2" ] && [ ! -z "$normal2" ]; then
  FQ2=$(basename "$fastq2")
  NM2=$(basename "$normal2")
  if [ ${FQ2: -3} == ".gz" ] && [ ${NM2: -3} == ".gz" ] ; then
    echo "Fastq extraction"
    gunzip $fastq2
    gunzip $normal2
  fi
fi

# for FASTQ in $(ls $PATH_FASTQ_TUMOR)
#  do
#   if [ ${FASTQ: -6} == ".fastq" ]; then
#    FASTQ1_NAME=$(basename $FASTQ ".fastq")
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
  		bowtie2 -p $threads -x $PATH_INDEX/${index} -1 $PATH_TRIM/${FASTQ1_NAME}_val_1.fq -2 $PATH_TRIM/${FASTQ2_NAME}_val_2.fq  -S $PATH_SAM_TUMOR/$FASTQ1_NAME.sam
    fi
  fi
  if [ -z "$bamt"] && [ -z "$vcf"]; then
		echo "Adding Read Group"
		java -jar picard.jar AddOrReplaceReadGroups I=$PATH_SAM_TUMOR/${FASTQ1_NAME}.sam O=$PATH_BAM_ANNO_TUMOR/${FASTQ1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ1_NAME
  elif [ ! -z "$bamt" ]; then
    FASTQ1_NAME=$(basename "${bamt%.*}")
    echo "Adding Read Group"
  	java -jar picard.jar AddOrReplaceReadGroups I=$bamt O=$PATH_BAM_ANNO_TUMOR/${FASTQ1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ1_NAME
  fi
		echo "Sorting"
		java -jar picard.jar SortSam I=$PATH_BAM_ANNO_TUMOR/${FASTQ1_NAME}_annotated.bam O=$PATH_BAM_SORT_TUMOR/${FASTQ1_NAME}_sorted.bam SORT_ORDER=coordinate
		echo "Reordering"
		java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_TUMOR/${FASTQ1_NAME}_sorted.bam O=$PATH_BAM_ORD_TUMOR/${FASTQ1_NAME}_ordered.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
		echo "Duplicates Removal"
		java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_TUMOR/${FASTQ1_NAME}_ordered.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_TUMOR/${FASTQ1_NAME}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_TUMOR/${FASTQ1_NAME}_marked.txt
    rm -r $PATH_SAM_TUMOR
    rm -r $PATH_BAM_ANNO_TUMOR
    rm -r $PATH_BAM_SORT_TUMOR
#   echo "bam/sam analysis"
#   elif [ ${FASTQ: -4} == ".bam" ] || [ ${FASTQ: -4} == ".sam" ]; then
#     FASTQ1_NAME="${FASTQ%.*}"
#     echo "Adding Read Group"
# 		java -jar picard.jar AddOrReplaceReadGroups I=$PATH_FASTQ_TUMOR/$FASTQ O=$PATH_BAM_ANNO_TUMOR/${FASTQ1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ1_NAME
# 		echo "Sorting"
# 		java -jar picard.jar SortSam I=$PATH_BAM_ANNO_TUMOR/${FASTQ1_NAME}_annotated.bam O=$PATH_BAM_SORT_TUMOR/${FASTQ1_NAME}_sorted.bam SORT_ORDER=coordinate
# 		echo "Reordering"
# 		java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_TUMOR/${FASTQ1_NAME}_sorted.bam O=$PATH_BAM_ORD_TUMOR/${FASTQ1_NAME}_ordered.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
# 		echo "Duplicates Removal"
# 		java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_TUMOR/${FASTQ1_NAME}_ordered.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_TUMOR/${FASTQ1_NAME}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_TUMOR/${FASTQ1_NAME}_marked.txt
#     rm -r $PATH_BAM_ANNO_TUMOR
#     rm -r $PATH_BAM_SORT_TUMOR
#   fi
# done

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

# for FASTQB in $(ls $PATH_FASTQ_NORMAL)
# 	do
#     if [ ${FASTQB: -6} == ".fastq" ]; then
# 		    NORMAL1_NAME=$(basename $FASTQB ".fastq")
#   	    echo "NORMAL sample trimming"
# 				TrimGalore-0.6.0/trim_galore $PATH_FASTQ_NORMAL/$NORMAL1_NAME.fastq -o $PATH_TRIM_NORMAL/
# 				echo "NORMAL sample alignment"
# 				bowtie2 -p $threads -x $PATH_INDEX/${index} -U $PATH_TRIM_NORMAL/${NORMAL1_NAME}_trimmed.fq -S $PATH_SAM_NORMAL/$NORMAL1_NAME.sam
  if [ -z "$bamn"] && [ -z "$vcf"]; then
	   echo "AddingRead Group"
	   java -jar picard.jar AddOrReplaceReadGroups I=$PATH_SAM_NORMAL/$NORMAL1_NAME.sam O=$PATH_BAM_ANNO_NORMAL/${NORMAL1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $NORMAL1_NAME
  elif [ ! -z "$bamn" ]; then
    NORMAL1_NAME=$(basename "${bamn%.*}")
    java -jar picard.jar AddOrReplaceReadGroups I=$bamn O=$PATH_BAM_ANNO_NORMAL/${NORMAL1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $NORMAL1_NAME
  fi
				echo "Sorting"
				java -jar picard.jar SortSam I=$PATH_BAM_ANNO_NORMAL/${NORMAL1_NAME}_annotated.bam O=$PATH_BAM_SORT_NORMAL/${NORMAL1_NAME}_sorted.bam SORT_ORDER=coordinate
				echo "Reordering"
				java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_NORMAL/${NORMAL1_NAME}_sorted.bam O=$PATH_BAM_ORD_NORMAL/${NORMAL1_NAME}_ordered.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
				echo "Duplicates Removal"
				java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_NORMAL/${NORMAL1_NAME}_ordered.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_NORMAL/${NORMAL1_NAME}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_NORMAL/${NORMAL1_NAME}_marked.txt
        rm -r $PATH_SAM_NORMAL
        rm -r $PATH_BAM_ANNO_NORMAL
        rm -r $PATH_BAM_SORT_NORMAL
#         echo "bam/sam analysis"
#     elif [ ${FASTQB: -4} == ".bam" ] || [ ${FASTQB: -4} == ".sam" ]; then
#         NORMAL1_NAME="${FASTQ%.*}"
#         echo "Adding Read Group"
#       	java -jar picard.jar AddOrReplaceReadGroups I=$PATH_FASTQ_NORMAL/$FASTQB O=$PATH_BAM_ANNO_NORMAL/${NORMAL1_NAME}_annotated.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $NORMAL1_NAME
#       	echo "Sorting"
#       	java -jar picard.jar SortSam I=$PATH_BAM_ANNO_NORMAL/${NORMAL1_NAME}_annotated.bam O=$PATH_BAM_SORT_NORMAL/${NORMAL1_NAME}_sorted.bam SORT_ORDER=coordinate
#       	echo "Reordering"
#       	java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_NORMAL/${NORMAL1_NAME}_sorted.bam O=$PATH_BAM_ORD_NORMAL/${NORMAL1_NAME}_ordered.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
#       	echo "Duplicates Removal"
#       	java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_NORMAL/${NORMAL1_NAME}_ordered.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_NORMAL/${NORMAL1_NAME}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_NORMAL/${NORMAL1_NAME}_marked.txt
#         rm -r $PATH_BAM_ANNO_NORMAL
#         rm -r $PATH_BAM_SORT_NORMAL
#     fi
# done

# for FILE in $(ls $PATH_MARK_DUP_TUMOR)
# do
		echo "Variant Calling"
		java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar Mutect2 -R $PATH_INDEX/${index}.fa -I $PATH_MARK_DUP_TUMOR/${FASTQ1_NAME}_nodup.bam -tumor $FASTQ1_NAME -I $PATH_MARK_DUP_NORMAL/${NORMAL1_NAME}_nodup.bam -normal $NORMAL1_NAME -O $PATH_VCF_MUT/$FASTQ1_NAME.vcf -mbq 25
		echo "Variant Filtering"
		java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar FilterMutectCalls -V $PATH_VCF_MUT/$FASTQ1_NAME.vcf -O $PATH_VCF_FILTERED/$FASTQ1_NAME.vcf
		echo "PASS Selection"
		awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_FILTERED/$FASTQ1_NAME.vcf > $PATH_VCF_PASS/$FASTQ1_NAME.vcf
		# done

if [ -z "$vcf"]; then
    echo "Annotation"
    sed -i '/#CHROM/,$!d' $PATH_VCF_PASS/$FASTQ1_NAME.vcf
    sed -i '/chr/,$!d' $PATH_VCF_PASS/$FASTQ1_NAME.vcf
    cut -f1,2,4,5 $PATH_VCF_PASS/$FASTQ1_NAME.vcf > $PATH_CONVERTITI/$FASTQ1_NAME.txt
    Rscript merge_database.R $index
else
    FASTQ1_NAME=$(basename $vcf ".vcf")
    echo "Annotation"
    cp $PATH_FASTQ_TUMOR/$FASTQ $PATH_VCF_PASS/
    sed -i '/#CHROM/,$!d' $PATH_VCF_PASS/$FASTQ1_NAME.vcf
    sed -i '/chr/,$!d' $PATH_VCF_PASS/$FASTQ1_NAME.vcf
    cut -f1,2,4,5 $PATH_VCF_PASS/$FASTQ1_NAME.vcf > $PATH_CONVERTITI/$FASTQ1_NAME.txt
    Rscript merge_database.R $index
fi

    echo "Report creation"
		echo >> $PATH_TXT_CIVIC/$FASTQ1_NAME.txt
		echo >> $PATH_TXT_CGI/$FASTQ1_NAME.txt
		echo >> $PATH_TXT_COSMIC/$FASTQ1_NAME.txt
		echo >> $PATH_TXT_PHARM/$FASTQ1_NAME.txt
		echo >> $PATH_TXT_CLINVAR/$FASTQ1_NAME.txt
		echo >> $PATH_TXT_REFGENE/$FASTQ1_NAME.txt

		Rscript report_definitivo_docker_tmVSnm.R $FASTQ1_NAME "$tumor" $PATH_PROJECT $database
		R -e "rmarkdown::render('./Generazione_report_definitivo_docker_tmVSnm.Rmd',output_file='$PATH_OUTPUT/report_$FASTQ1_NAME.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ1_NAME

    rm -r $PATH_TRIM_NORMAL
    rm -r $PATH_BAM_ORD_NORMAL
    rm -r $PATH_TRIM_TUMOR
    rm -r $PATH_BAM_ORD_TUMOR
    rm -r $PATH_VCF_MUT
    rm -r $PATH_CONVERTITI
    rm -r $PATH_TXT_CIVIC
    rm -r $PATH_TXT_CGI
    rm -r $PATH_TXT_PHARM
    rm -r $PATH_TXT_COSMIC
    rm -r $PATH_TXT_CLINVAR
    rm -r $PATH_TXT_REFGENE

    echo "done"
