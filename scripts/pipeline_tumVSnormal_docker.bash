#!/bin/bash
usage() {
  echo "Usage: $0 [ -g patient gender ]
  [ -s patient surname ] [-n patient name] [-i patient id] [-a patient age]
  [-t patient tumor, you must choose a type of tumor from disease_list.txt]
  [-p prep_database must be yes or no]
  [-b number of bowtie2 threads, leave 1 if you are uncertain]
  [-i index must be hg19 or hg38]
  [-f path of the sample]
  [-o path of COSMIC]
  [-h database path]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}
while getopts "n:s:i:g:a:t:p:h:b:c:f:o:h:" OPTION; do
  case "${OPTION}" in
    n)
      name=$OPTARG
      echo "The value provided for patient name is $OPTARG"
      ;;
    s)
     surname=$OPTARG
     echo "The value provided for patient surname is $OPTARG"
     ;;
    i)
      id=$OPTARG
      echo "The value provided for patient ID is $OPTARG"
      ;;
    g)
      gender=$OPTARG
      echo "The value provided for patient gender is $OPTARG"
      ;;
    a)
      age=$OPTARG
      re_isanum='^[0-9]+$'
      echo "The value provided for patient age is $OPTARG"
      if ! [[ $age =~ $re_isanum ]] ; then
        echo "Error: Age must be a positive, whole number."
        exit_abnormal
        exit 1
      elif [ $age -eq "0" ]; then
        echo "Error: Age must be greater than zero."
        exit_abnormal
      fi
      ;;
    t)
      tumor=$OPTARG
      echo "The value provided for patient tumor is $OPTARG"
      if cat disease_list.txt | grep -w "$tumor" > /dev/null; then
      command;
    else echo "Error: Tumor must be a value from the list disease_list.txt";
      exit_abnormal
      exit 1
      fi
      ;;
    p)
      prep_databases=$OPTARG
      echo "The value provided for database_preparation is $OPTARG"
      if ! [ $prep_databases = "yes" ] ; then
        if !  [ $prep_databases = "no" ] ; then
        echo "Error: prep_database must be equal to yes or no."
        exit_abnormal
        exit 1
        fi
      fi
        ;;
    b)
      threads=$OPTARG
      echo "The value provided for threads is $OPTARG"
      if [ $threads -eq "0" ]; then
        echo "Error: Threads must be greater than zero."
        exit_abnormal
      fi
        ;;
    c)
      index=$OPTARG
      echo "The value provided for index is $OPTARG"
      if ! [ $index = "hg19" ] ; then
        if !  [ $index = "hg38" ] ; then
        echo "Error: index must be equal to hg19 or hg38."
        exit_abnormal
        exit 1
        fi
      fi
        ;;
     f)
      folder=$OPTARG
      echo "The value provided for folder is $OPTARG"
      if [ ! -d "$folder" ]; then
        echo "Error: You must pass a valid directory"
        exit_abnormal
      fi
        ;;
     o)
     cosmic=$OPTARG
     echo "The value provided for cosmic is $OPTARG"
     if [ ! -d "$cosmic" ]; then
       echo "Error: You must pass a valid cosmic directory"
       exit_abnormal
     fi
       ;;
     h)
     database=$OPTARG
     echo "The value provided for database path is $OPTARG"
     if [ ! -d "$database" ]; then
       echo "Error: You must pass a valid database directory"
       exit_abnormal
     fi
       ;;
    :)
      echo "Error: ${OPTARG} requires an argument."
      usage
      exit_abnormal
        ;;
    *)
      exit_abnormal
        ;;
    /? | h)
      echo "ERROR: Invalid option $OPTARG"
      usage
      exit 1
        ;;
        esac
      done

      if [[ -z "$prep_databases" ]] || [[ -z "$name" ]] || [[ -z "$surname" ]] || [[ -z "$tumor" ]] || [[ -z "$age" ]] || [[ -z "$index" ]] || [[ -z "$gender" ]] || [[ -z "$id" ]] || [[ -z "$threads" ]] || [[ -z "$folder" ]] || [[ -z "$cosmic" ]] || [[ -z "$database" ]]; then
         echo "all parameters must be passed"
         usage
         exit
      fi

#Problema doppio input
PATH_INDEX=index
PATH_FASTQ_TUMOR=input_tumor
PATH_FASTQ_BLOOD=input_blood
PATH_TRIM_TUMOR=$PATH_PROJECT/trim_tumor
PATH_TRIM_BLOOD=$PATH_PROJECT/trim_blood
PATH_SAM_TUMOR=$PATH_PROJECT/sam_tumor
PATH_SAM_BLOOD=$PATH_PROJECT/sam_blood
PATH_BAM_ANNO_TUMOR=$PATH_PROJECT/bam_annotato_tumor
PATH_BAM_ANNO_BLOOD=$PATH_PROJECT/bam_annotato_blood
PATH_BAM_SORT_TUMOR=$PATH_PROJECT/bam_sortato_tumor
PATH_BAM_SORT_BLOOD=$PATH_PROJECT/bam_sortato_blood
PATH_BAM_ORD_TUMOR=$PATH_PROJECT/bam_ordinato_tumor
PATH_BAM_ORD_BLOOD=$PATH_PROJECT/bam_ordinato_blood
PATH_MARK_DUP_TUMOR=$PATH_PROJECT/mark_dup_tumor
PATH_MARK_DUP_BLOOD=$PATH_PROJECT/mark_dup_blood
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

echo "Removing old folders"

if [[ -d $PATH_MARK_DUP_TUMOR ]]; then
rm -r $PATH_MARK_DUP_TUMOR
fi
if [[ -d $PATH_MARK_DUP_BLOOD ]]; then
rm -r $PATH_MARK_DUP_BLOOD
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
mkdir $PATH_TRIM_BLOOD
mkdir $PATH_SAM_TUMOR
mkdir $PATH_SAM_BLOOD
mkdir $PATH_BAM_ANNO_TUMOR
mkdir $PATH_BAM_ANNO_BLOOD
mkdir $PATH_BAM_ORD_TUMOR
mkdir $PATH_BAM_ORD_BLOOD
mkdir $PATH_BAM_SORT_TUMOR
mkdir $PATH_BAM_SORT_BLOOD
mkdir $PATH_MARK_DUP_TUMOR
mkdir $PATH_MARK_DUP_BLOOD
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

echo "Index download"

if [[ "$prep_databases" = "yes" ]] && [[ "$index" = "hg19" ]]; then
bash prep_banche_dati.bash
  elif [[ "$prep_databases" = "yes" ]] && [[ "$index" = "hg38" ]]; then
  bash prep_banche_dati_hg38.bash
fi

if [[ "$prep_databases" = "yes" ]]; then
  echo "Index creation"
  java -jar picard.jar CreateSequenceDictionary REFERENCE=$PATH_INDEX/${index}.fa OUTPUT=$PATH_INDEX/${index}.dict
  samtools faidx $PATH_INDEX/${index}.fa
fi

for FASTQ in $(ls $PATH_FASTQ_TUMOR)
  do
    if [ ${FASTQ: -9} == ".fastq.gz" ]; then
    echo "Tumor fastq extraction"
    gunzip $PATH_FASTQ_TUMOR/*.fastq.gz
  fi
done


for FASTQB in $(ls $PATH_FASTQ_BLOOD)
  do
    if [ ${FASTQB: -9} == ".fastq.gz" ]; then
    echo "Blood fastq extraction"
    gunzip $PATH_FASTQ_BLOOD/*.fastq.gz
  fi
done


for FASTQ in $(ls $PATH_FASTQ_TUMOR)
 do
  if [ ${FASTQ: -6} == ".fastq" ]; then
		FASTQ_NAME_T=$(basename $FASTQ ".fastq")
	  #Setting cutadapt path
		export PATH=/root/.local/bin/:$PATH
		echo "Tumor sample trimming"
		TrimGalore-0.6.0/trim_galore $PATH_FASTQ_TUMOR/$FASTQ_NAME_T.fastq -o $PATH_TRIM_TUMOR/
		echo "Tumor sample alignment"
		bowtie2 -p $threads -x $PATH_INDEX/${index} -U $PATH_TRIM_TUMOR/${FASTQ_NAME_T}_trimmed.fq -S $PATH_SAM_TUMOR/$FASTQ_NAME_T.sam
		echo "Adding Read Group"
		java -jar picard.jar AddOrReplaceReadGroups I=$PATH_SAM_TUMOR/$FASTQ_NAME_T.sam O=$PATH_BAM_ANNO_TUMOR/${FASTQ_NAME_T}_annotato.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ_NAME_T
		echo "Sorting"
		java -jar picard.jar SortSam I=$PATH_BAM_ANNO_TUMOR/${FASTQ_NAME_T}_annotato.bam O=$PATH_BAM_SORT_TUMOR/${FASTQ_NAME_T}_sortato.bam SORT_ORDER=coordinate
		echo "Reordering"
		java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_TUMOR/${FASTQ_NAME_T}_sortato.bam O=$PATH_BAM_ORD_TUMOR/${FASTQ_NAME_T}_ordinato.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
		echo "Duplicates Removal"
		java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_TUMOR/${FASTQ_NAME_T}_ordinato.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_TUMOR/${FASTQ_NAME_T}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_TUMOR/${FASTQ_NAME_T}_marked.txt
    rm -r $PATH_SAM_TUMOR
    rm -r $PATH_BAM_ANNO_TUMOR
    rm -r $PATH_BAM_SORT_TUMOR
  echo "bam/sam analysis"
  elif [ ${FASTQ: -4} == ".bam" ] || [ ${FASTQ: -4} == ".sam" ]; then
    FASTQ_NAME_T="${FASTQ%.*}"
    echo "Adding Read Group"
		java -jar picard.jar AddOrReplaceReadGroups I=$PATH_FASTQ_TUMOR/$FASTQ O=$PATH_BAM_ANNO_TUMOR/${FASTQ_NAME_T}_annotato.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ_NAME_T
		echo "Sorting"
		java -jar picard.jar SortSam I=$PATH_BAM_ANNO_TUMOR/${FASTQ_NAME_T}_annotato.bam O=$PATH_BAM_SORT_TUMOR/${FASTQ_NAME_T}_sortato.bam SORT_ORDER=coordinate
		echo "Reordering"
		java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_TUMOR/${FASTQ_NAME_T}_sortato.bam O=$PATH_BAM_ORD_TUMOR/${FASTQ_NAME_T}_ordinato.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
		echo "Duplicates Removal"
		java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_TUMOR/${FASTQ_NAME_T}_ordinato.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_TUMOR/${FASTQ_NAME_T}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_TUMOR/${FASTQ_NAME_T}_marked.txt
    rm -r $PATH_BAM_ANNO_TUMOR
    rm -r $PATH_BAM_SORT_TUMOR
  fi
done

for FASTQB in $(ls $PATH_FASTQ_BLOOD)
	do
    if [ ${FASTQB: -6} == ".fastq" ]; then
		    FASTQ_NAME_B=$(basename $FASTQB ".fastq")
  	    echo "Blood sample trimming"
				TrimGalore-0.6.0/trim_galore $PATH_FASTQ_BLOOD/$FASTQ_NAME_B.fastq -o $PATH_TRIM_BLOOD/
				echo "Blood sample alignment"
				bowtie2 -p $threads -x $PATH_INDEX/${index} -U $PATH_TRIM_BLOOD/${FASTQ_NAME_B}_trimmed.fq -S $PATH_SAM_BLOOD/$FASTQ_NAME_B.sam
				echo "AddingRead Group"
				java -jar picard.jar AddOrReplaceReadGroups I=$PATH_SAM_BLOOD/$FASTQ_NAME_B.sam O=$PATH_BAM_ANNO_BLOOD/${FASTQ_NAME_B}_annotato.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ_NAME_B
				echo "Sorting"
				java -jar picard.jar SortSam I=$PATH_BAM_ANNO_BLOOD/${FASTQ_NAME_B}_annotato.bam O=$PATH_BAM_SORT_BLOOD/${FASTQ_NAME_B}_sortato.bam SORT_ORDER=coordinate
				echo "Reordering"
				java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_BLOOD/${FASTQ_NAME_B}_sortato.bam O=$PATH_BAM_ORD_BLOOD/${FASTQ_NAME_B}_ordinato.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
				echo "Duplicates Removal"
				java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_BLOOD/${FASTQ_NAME_B}_ordinato.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_BLOOD/${FASTQ_NAME_B}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_BLOOD/${FASTQ_NAME_B}_marked.txt
        rm -r $PATH_SAM_BLOOD
        rm -r $PATH_BAM_ANNO_BLOOD
        rm -r $PATH_BAM_SORT_BLOOD
        echo "bam/sam analysis"
    elif [ ${FASTQB: -4} == ".bam" ] || [ ${FASTQB: -4} == ".sam" ]; then
        FASTQ_NAME_B="${FASTQ%.*}"
        echo "Adding Read Group"
      	java -jar picard.jar AddOrReplaceReadGroups I=$PATH_FASTQ_BLOOD/$FASTQB O=$PATH_BAM_ANNO_BLOOD/${FASTQ_NAME_B}_annotato.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ_NAME_B
      	echo "Sorting"
      	java -jar picard.jar SortSam I=$PATH_BAM_ANNO_BLOOD/${FASTQ_NAME_B}_annotato.bam O=$PATH_BAM_SORT_BLOOD/${FASTQ_NAME_B}_sortato.bam SORT_ORDER=coordinate
      	echo "Reordering"
      	java -jar picard.jar ReorderSam I=$PATH_BAM_SORT_BLOOD/${FASTQ_NAME_B}_sortato.bam O=$PATH_BAM_ORD_BLOOD/${FASTQ_NAME_B}_ordinato.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
      	echo "Duplicates Removal"
      	java -jar picard.jar MarkDuplicates I=$PATH_BAM_ORD_BLOOD/${FASTQ_NAME_B}_ordinato.bam REMOVE_DUPLICATES=TRUE O=$PATH_MARK_DUP_BLOOD/${FASTQ_NAME_B}_nodup.bam CREATE_INDEX=TRUE M=$PATH_MARK_DUP_BLOOD/${FASTQ_NAME_B}_marked.txt
        rm -r $PATH_BAM_ANNO_BLOOD
        rm -r $PATH_BAM_SORT_BLOOD
    fi
done

for FILE in $(ls $PATH_MARK_DUP_TUMOR)
do
		echo "Variant Calling"
		java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar Mutect2 -R $PATH_INDEX/${index}.fa -I $PATH_MARK_DUP_TUMOR/${FASTQ_NAME_T}_nodup.bam -tumor $FASTQ_NAME_T -I $PATH_MARK_DUP_BLOOD/${FASTQ_NAME_B}_nodup.bam -normal $FASTQ_NAME_B -O $PATH_VCF_MUT/$FASTQ_NAME_T.vcf -mbq 25
		echo "Variant Filtering"
		java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar FilterMutectCalls -V $PATH_VCF_MUT/$FASTQ_NAME_T.vcf -O $PATH_VCF_FILTERED/$FASTQ_NAME_T.vcf
		echo "PASS Selection"
		awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_FILTERED/$FASTQ_NAME_T.vcf > $PATH_VCF_PASS/$FASTQ_NAME_T.vcf
		done

    echo "Annotation"
    sed -i '/#CHROM/,$!d' $PATH_VCF_PASS/$FASTQ_NAME_T.vcf
    sed -i '/chr/,$!d' $PATH_VCF_PASS/$FASTQ_NAME_T.vcf
    cut -f1,2,4,5 $PATH_VCF_PASS/$FASTQ_NAME_T.vcf > $PATH_CONVERTITI/$FASTQ_NAME_T.txt
    Rscript merge_database.R $index

    echo "Report creation"
		mkdir /txt_civic/results
		mkdir /txt_cgi/results
		mkdir /txt_cosmic/results
		mkdir /txt_pharm/results

		echo >> $PATH_TXT_CIVIC/$FASTQ_NAME_T.txt
		echo >> $PATH_TXT_CGI/$FASTQ_NAME_T.txt
		echo >> $PATH_TXT_COSMIC/$FASTQ_NAME_T.txt
		echo >> $PATH_TXT_PHARM/$FASTQ_NAME_T.txt
		echo >> $PATH_TXT_CLINVAR/$FASTQ_NAME_T.txt
		echo >> $PATH_TXT_REFGENE/$FASTQ_NAME_T.txt


		Rscript report_definitivo_docker_tmVSnm.R $FASTQ_NAME_T "$tumor" $PATH_PROJECT
		R -e "rmarkdown::render('./Generazione_report_definitivo_docker_tmVSnm.Rmd',output_file='/output/report_$FASTQ_NAME_T.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ_NAME_T


    for FASTQ in $(ls $PATH_FASTQ_TUMOR)
    	do
        if [ ${FASTQ: -4} == ".vcf" ]; then
    		    FASTQ_NAME_T=$(basename $FASTQ ".vcf")
            echo "Annotation"
            cp $PATH_FASTQ_TUMOR/$FASTQ $PATH_VCF_PASS/
            sed -i '/#CHROM/,$!d' $PATH_VCF_PASS/$FASTQ_NAME_T.vcf
            sed -i '/chr/,$!d' $PATH_VCF_PASS/$FASTQ_NAME_T.vcf
            cut -f1,2,4,5 $PATH_VCF_PASS/$FASTQ_NAME_T.vcf > $PATH_CONVERTITI/$FASTQ_NAME_T.txt
            Rscript merge_database.R $index

            echo "Report creation"
        		mkdir /txt_civic/results
        		mkdir /txt_cgi/results
        		mkdir /txt_cosmic/results
        		mkdir /txt_pharm/results
        		mkdir /definitive
        		mkdir /Trial
        		mkdir /Reference
        		mkdir /Food
        		mkdir /output

        		echo >> $PATH_TXT_CIVIC/$FASTQ_NAME_T.txt
        		echo >> $PATH_TXT_CGI/$FASTQ_NAME_T.txt
        		echo >> $PATH_TXT_COSMIC/$FASTQ_NAME_T.txt
        		echo >> $PATH_TXT_PHARM/$FASTQ_NAME_T.txt
        		echo >> $PATH_TXT_CLINVAR/$FASTQ_NAME_T.txt
        		echo >> $PATH_TXT_REFGENE/$FASTQ_NAME_T.txt


        		Rscript report_definitivo_docker_tmVSnm.R $FASTQ_NAME_T "$tumor" $PATH_PROJECT
        		R -e "rmarkdown::render('./Generazione_report_definitivo_docker_tmVSnm.Rmd',output_file='/output/report_$FASTQ_NAME_T.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ_NAME_T
        fi
      done

    rm -r $PATH_TRIM_BLOOD
    rm -r $PATH_BAM_ORD_BLOOD
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
