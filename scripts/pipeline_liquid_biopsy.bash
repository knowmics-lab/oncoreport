#!/bin/bash
usage() {
  echo "Usage: $0 [ -d analysis depth ] [ -g patient gender ]
  [ -s patient surname ] [ -e filter-expression of AF ]
  [-n patient name] [-i patient id] [-a patient age]
  [-t patient tumor, you must choose a type of tumor from disease_list.txt]
  [-p prep_database must be yes or no]
  [-b number of bowtie2 threads, leave 1 if you are uncertain]
  [-i index must be hg19 or hg38]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}
while getopts "n:s:i:g:a:t:d:e:p:h:b:c:" OPTION; do
  case "${OPTION}" in
    d)
      depth=$OPTARG
      echo "The value provided for filter-expression of DP is $OPTARG"
      ;;
		e)
      AF=$OPTARG
      echo "The value provided for filter-expression of AF is $OPTARG"
      ;;
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

      if [[ -z "$prep_databases" ]] || [[ -z "$name" ]] || [[ -z "$surname" ]] || [[ -z "$tumor" ]] || [[ -z "$age" ]] || [[ -z "$index" ]] || [[ -z "$gender" ]] || [[ -z "$depth" ]] || [[ -z "$AF" ]] || [[ -z "$id" ]] || [[ -z "$threads" ]]; then
         echo "all parameters must be passed"
         usage
         exit
      fi

      PATH_INDEX=index
      PATH_FASTQ=input
      PATH_TRIM=trim
      PATH_SAM=sam
      PATH_BAM_ANNO=bam_annotato
      PATH_BAM_SORT=bam_sortato
      PATH_BAM_ORD=bam_ordinato
      PATH_VCF_MUT=mutect
      PATH_VCF_FILTERED=filtered
      PATH_VCF_PASS=pass_filtrati
      PATH_VCF_DP=dp_filtered
      PATH_VCF_IN_SN=in_snp
      PATH_VCF_AF=vcf_af
      PATH_VCF_PASS_AF=pass_finale
      PATH_VCF_MERGE=merge
      PATH_VCF_DA_CONVERTIRE=vcf_convertire
      PATH_CONVERTITI=convertiti
      PATH_TXT_CIVIC=txt_civic
      PATH_TXT_CGI=txt_cgi
      PATH_TXT_PHARM=txt_pharm
      PATH_TXT_COSMIC=txt_cosmic
      PATH_TXT_CLINVAR=txt_clinvar
      PATH_TXT_REFGENE=txt_refgene

      echo "Removing old folders"

      if [[ -d $PATH_CONVERTITI ]]; then
      rm -r $PATH_CONVERTITI
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
      if [[ -d /civic/ ]]; then
      rm -r /civic/
      fi
      if [[ -d /cgi/ ]]; then
      rm -r /cgi/
      fi
      if [[ -d /pharm/ ]]; then
      rm -r /pharm/
      fi
      if [[ -d /clinvar/ ]]; then
      rm -r /clinvar/
      fi
      if [[ -d /cosmic/ ]]; then
      rm -r /cosmic/
      fi
      if [[ -d /refgene/ ]]; then
      rm -r /refgene/
      fi
      if [[ -d /definitive/ ]]; then
      rm -r /definitive/
      fi
      if [[ -d /Trial/ ]]; then
      rm -r /Trial/
      fi
      if [[ -d /Reference/ ]]; then
      rm -r /Reference/
      fi
      if [[ -d /Food/ ]]; then
      rm -r /Food/
      fi


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
      mkdir $PATH_VCF_DA_CONVERTIRE
      mkdir $PATH_CONVERTITI
      mkdir $PATH_TXT_CGI
      mkdir $PATH_TXT_CIVIC
      mkdir $PATH_TXT_PHARM
      mkdir $PATH_TXT_CLINVAR
      mkdir $PATH_TXT_COSMIC
      mkdir $PATH_TXT_REFGENE
      mkdir $PATH_TRIM
      mkdir /civic
      mkdir /cgi
      mkdir /pharm
      mkdir /cosmic
      mkdir /refgene
      mkdir /clinvar
      mkdir /civic/results
      mkdir /cgi/results
      mkdir /cosmic/results
      mkdir /pharm/results
      mkdir /definitive
      mkdir /Trial
      mkdir /Reference
      mkdir /Food
      mkdir /output

if [[ "$prep_databases" = "yes" ]] && [[ "$index" = "hg19" ]]; then
bash prep_banche_dati.bash
  elif [[ "$prep_databases" = "yes" ]] && [[ "$index" = "hg38" ]]; then
  bash prep_banche_dati_hg38.bash
fi

if [[ "$prep_databases" = "yes" ]]; then
  echo "Creation of the index"
  java -jar picard.jar CreateSequenceDictionary REFERENCE=$PATH_INDEX/${index}.fa OUTPUT=$PATH_INDEX/${index}.dict
  samtools faidx $PATH_INDEX/${index}.fa
fi

for FASTQ in $(ls $PATH_FASTQ)
  do
    if [ ${FASTQ: -9} == ".fastq.gz" ]; then
    echo "Fastq extraction"
    gunzip $PATH_FASTQ/*R1_001.fastq.gz
    gunzip $PATH_FASTQ/*R2_001.fastq.gz
  fi
done

echo "Starting the analysis"
for FASTQ in $(ls $PATH_FASTQ)
  do
    if [ ${FASTQ: -6} == ".fastq" ]; then
      if [ ${FASTQ: -13} == "_R1_001.fastq" ]; then
		     FASTQ_NAME=$(basename $FASTQ "_R1_001.fastq")
         echo "The file loaded is a fastq"
		  #Setting cutadapt path
		     export PATH=/root/.local/bin/:$PATH
		     echo "Trimming"
		     TrimGalore-0.6.0/trim_galore -paired $PATH_FASTQ/*R1_001.fastq $PATH_FASTQ/*R2_001.fastq -o $PATH_TRIM/
		     echo "Alignment"
		     bowtie2 -p $threads -x $PATH_INDEX/$index -1 $PATH_TRIM/*R1_001_val_1.fq -2 $PATH_TRIM/*R2_001_val_2.fq -S $PATH_SAM/$FASTQ_NAME.sam
         echo "Adding Read Group"
  		   java -jar picard.jar AddOrReplaceReadGroups I=$PATH_SAM/$FASTQ_NAME.sam O=$PATH_BAM_ANNO/${FASTQ_NAME}_annotato.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ_NAME
  		   echo "Sorting"
  		   java -jar picard.jar SortSam I=$PATH_BAM_ANNO/${FASTQ_NAME}_annotato.bam O=$PATH_BAM_SORT/${FASTQ_NAME}_sortato.bam SORT_ORDER=coordinate
  		   echo "Reordering"
  		   java -jar picard.jar ReorderSam I=$PATH_BAM_SORT/${FASTQ_NAME}_sortato.bam O=$PATH_BAM_ORD/${FASTQ_NAME}_ordinato.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
  		   echo "Variant Calling"
  		   java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar Mutect2 -R $PATH_INDEX/${index}.fa -I $PATH_BAM_ORD/${FASTQ_NAME}_ordinato.bam -tumor $FASTQ_NAME -O $PATH_VCF_MUT/$FASTQ_NAME.vcf -mbq 25
         echo "Variant Filtration"
  		   java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar FilterMutectCalls -V $PATH_VCF_MUT/$FASTQ_NAME.vcf -O $PATH_VCF_FILTERED/$FASTQ_NAME.vcf
  		   echo "PASS Selection"
  		   awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_FILTERED/$FASTQ_NAME.vcf > $PATH_VCF_PASS/$FASTQ_NAME.vcf
  		   echo "DP Filtering"
  		   java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $PATH_VCF_PASS/$FASTQ_NAME.vcf -O $PATH_VCF_DP/$FASTQ_NAME.vcf --filter-name "LowDP" --filter-expression $depth
  		   echo "Splitting indel and snp"
  		   java -jar picard.jar SplitVcfs I= $PATH_VCF_DP/$FASTQ_NAME.vcf SNP_OUTPUT= $PATH_VCF_IN_SN/$FASTQ_NAME.SNP.vcf INDEL_OUTPUT= $PATH_VCF_IN_SN/$FASTQ_NAME.INDEL.vcf STRICT=false
  		   echo "AF Filtering"
  	     java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $PATH_VCF_IN_SN/$FASTQ_NAME.SNP.vcf -O $PATH_VCF_AF/$FASTQ_NAME.vcf --genotype-filter-name "Germline" --genotype-filter-expression $AF
  		   echo "Merge indel and snp"
         java -jar picard.jar MergeVcfs I=$PATH_VCF_IN_SN/$FASTQ_NAME.INDEL.vcf I=$PATH_VCF_AF/$FASTQ_NAME.vcf O=$PATH_VCF_MERGE/$FASTQ_NAME.vcf
  		   echo "PASS Selection"
  		   awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_MERGE/$FASTQ_NAME.vcf > $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf
  		   echo "Germline"
  		   grep Germline $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf > $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf
  	     echo "Somatic"
  		   grep Germline -v $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf > $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
         echo "Annotation"
         sed -i '/#CHROM/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
         sed -i '/chr/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf
         sed -i '/chr/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
         cut -f1,2,4,5 $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf > $PATH_CONVERTITI/${FASTQ_NAME}_Somatic.txt
         cut -f1,2,4,5 $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf > $PATH_CONVERTITI/${FASTQ_NAME}_Germline.txt
         Rscript merge_database.R $index
         echo "Report creation"
         echo >> $PATH_TXT_CIVIC/${FASTQ_NAME}_Somatic.txt
         echo >> $PATH_TXT_CIVIC/${FASTQ_NAME}_Germline.txt
         echo >> $PATH_TXT_CGI/${FASTQ_NAME}_Somatic.txt
         echo >> $PATH_TXT_CGI/${FASTQ_NAME}_Germline.txt
         echo >> $PATH_TXT_COSMIC/${FASTQ_NAME}_Somatic.txt
         echo >> $PATH_TXT_COSMIC/${FASTQ_NAME}_Germline.txt
         echo >> $PATH_TXT_PHARM/${FASTQ_NAME}_Somatic.txt
         echo >> $PATH_TXT_PHARM/${FASTQ_NAME}_Germline.txt
         echo >> $PATH_TXT_CLINVAR/${FASTQ_NAME}_Somatic.txt
         echo >> $PATH_TXT_CLINVAR/${FASTQ_NAME}_Germline.txt
         echo >> $PATH_TXT_REFGENE/${FASTQ_NAME}_Somatic.txt
         echo >> $PATH_TXT_REFGENE/${FASTQ_NAME}_Germline.txt
         Rscript report_definitivo_biospia_liquida_linea_di_comando.R $FASTQ_NAME "$tumor"
         R -e "rmarkdown::render('./Generazione_report_definitivo_docker_bl.Rmd',output_file='/output/report_$FASTQ_NAME.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ_NAME
        fi
    elif [ ${FASTQ: -4} == ".bam" ] || [ ${FASTQ: -4} == ".sam" ]; then
      echo "bam/sam analysis"
      FASTQ_NAME="${FASTQ%.*}"
  		echo "Adding Read Group"
  		java -jar picard.jar AddOrReplaceReadGroups I=$PATH_FASTQ/$FASTQ O=$PATH_BAM_ANNO/${FASTQ_NAME}_annotato.bam RGID=0 RGLB=lib1 RGPL=illumina RGPU=SN166 RGSM= $FASTQ_NAME
  		echo "Sorting"
  		java -jar picard.jar SortSam I=$PATH_BAM_ANNO/${FASTQ_NAME}_annotato.bam O=$PATH_BAM_SORT/${FASTQ_NAME}_sortato.bam SORT_ORDER=coordinate
  		echo "Reordering"
  		java -jar picard.jar ReorderSam I=$PATH_BAM_SORT/${FASTQ_NAME}_sortato.bam O=$PATH_BAM_ORD/${FASTQ_NAME}_ordinato.bam SEQUENCE_DICTIONARY=$PATH_INDEX/${index}.dict CREATE_INDEX=true ALLOW_INCOMPLETE_DICT_CONCORDANCE=true
  		echo "Variant Calling"
  		java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar Mutect2 -R $PATH_INDEX/${index}.fa -I $PATH_BAM_ORD/${FASTQ_NAME}_ordinato.bam -tumor $FASTQ_NAME -O $PATH_VCF_MUT/$FASTQ_NAME.vcf -mbq 25
      echo "Variant Filtration"
  		java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar FilterMutectCalls -V $PATH_VCF_MUT/$FASTQ_NAME.vcf -O $PATH_VCF_FILTERED/$FASTQ_NAME.vcf
  		echo "PASS Selection"
  		awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_FILTERED/$FASTQ_NAME.vcf > $PATH_VCF_PASS/$FASTQ_NAME.vcf
  		echo "DP Filtering"
      java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $PATH_VCF_PASS/$FASTQ_NAME.vcf -O $PATH_VCF_DP/$FASTQ_NAME.vcf --filter-name "LowDP" --filter-expression $depth
  		echo "Splitting indel and snp"
  		java -jar picard.jar SplitVcfs I= $PATH_VCF_DP/$FASTQ_NAME.vcf SNP_OUTPUT= $PATH_VCF_IN_SN/$FASTQ_NAME.SNP.vcf INDEL_OUTPUT= $PATH_VCF_IN_SN/$FASTQ_NAME.INDEL.vcf STRICT=false
  		echo "AF Filtration"
  		java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $PATH_VCF_IN_SN/$FASTQ_NAME.SNP.vcf -O $PATH_VCF_AF/$FASTQ_NAME.vcf --genotype-filter-name "Germline" --genotype-filter-expression $AF
  		echo "Merge indel and snp"
      java -jar picard.jar MergeVcfs I=$PATH_VCF_IN_SN/$FASTQ_NAME.INDEL.vcf I=$PATH_VCF_AF/$FASTQ_NAME.vcf O=$PATH_VCF_MERGE/$FASTQ_NAME.vcf
  		echo "PASS Selection"
  		awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_MERGE/$FASTQ_NAME.vcf > $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf
  		echo "Germline"
  		grep Germline $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf > $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf
  		echo "Somatic"
  		grep Germline -v $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf > $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
      echo "Annotation"
      sed -i '/#CHROM/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
      sed -i '/chr/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf
      sed -i '/chr/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
      cut -f1,2,4,5 $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf > $PATH_CONVERTITI/${FASTQ_NAME}_Somatic.txt
      cut -f1,2,4,5 $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf > $PATH_CONVERTITI/${FASTQ_NAME}_Germline.txt
      Rscript merge_database.R $index
      echo "Report creation"
      echo >> $PATH_TXT_CIVIC/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_CIVIC/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_CGI/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_CGI/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_COSMIC/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_COSMIC/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_PHARM/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_PHARM/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_CLINVAR/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_CLINVAR/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_REFGENE/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_REFGENE/${FASTQ_NAME}_Germline.txt
      Rscript report_definitivo_biospia_liquida_linea_di_comando.R $FASTQ_NAME "$tumor"
      R -e "rmarkdown::render('./Generazione_report_definitivo_docker_bl.Rmd',output_file='/output/report_$FASTQ_NAME.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ_NAME
    elif [ ${FASTQ: -4} == ".vcf" ]; then
      echo "vcf analysis"
      FASTQ_NAME=$(basename $FASTQ ".vcf")
      echo "DP Filtering"
      java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $PATH_FASTQ/$FASTQ_NAME.vcf -O $PATH_VCF_DP/$FASTQ_NAME.vcf --filter-name "LowDP" --filter-expression $depth
    	echo "Splitting indel and snp"
  		java -jar picard.jar SplitVcfs I= $PATH_VCF_DP/$FASTQ_NAME.vcf SNP_OUTPUT= $PATH_VCF_IN_SN/$FASTQ_NAME.SNP.vcf INDEL_OUTPUT= $PATH_VCF_IN_SN/$FASTQ_NAME.INDEL.vcf STRICT=false
    	echo "AF Filtration"
  		java -jar gatk-4.1.0.0/gatk-package-4.1.0.0-local.jar VariantFiltration -R $PATH_INDEX/${index}.fa -V $PATH_VCF_IN_SN/$FASTQ_NAME.SNP.vcf -O $PATH_VCF_AF/$FASTQ_NAME.vcf --genotype-filter-name "Germline" --genotype-filter-expression $AF
  		echo "Merge indel and snp"
      java -jar picard.jar MergeVcfs I=$PATH_VCF_IN_SN/$FASTQ_NAME.INDEL.vcf I=$PATH_VCF_AF/$FASTQ_NAME.vcf O=$PATH_VCF_MERGE/$FASTQ_NAME.vcf
    	echo "PASS Selection"
    	awk -F '\t' '{if($0 ~ /\#/) print; else if($7 == "PASS") print}' $PATH_VCF_MERGE/$FASTQ_NAME.vcf > $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf
    	echo "Germline"
    	grep Germline $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf > $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf
    	echo "Somatic"
    	grep Germline -v $PATH_VCF_PASS_AF/$FASTQ_NAME.vcf > $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
      echo "Annotation"
      sed -i '/#CHROM/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
      sed -i '/chr/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf
      sed -i '/chr/,$!d' $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf
      cut -f1,2,4,5 $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Somatic.vcf > $PATH_CONVERTITI/${FASTQ_NAME}_Somatic.txt
      cut -f1,2,4,5 $PATH_VCF_DA_CONVERTIRE/${FASTQ_NAME}_Germline.vcf > $PATH_CONVERTITI/${FASTQ_NAME}_Germline.txt
      Rscript merge_database.R $index
      echo "Report creation"
      echo >> $PATH_TXT_CIVIC/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_CIVIC/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_CGI/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_CGI/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_COSMIC/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_COSMIC/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_PHARM/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_PHARM/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_CLINVAR/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_CLINVAR/${FASTQ_NAME}_Germline.txt
      echo >> $PATH_TXT_REFGENE/${FASTQ_NAME}_Somatic.txt
      echo >> $PATH_TXT_REFGENE/${FASTQ_NAME}_Germline.txt
      Rscript report_definitivo_biospia_liquida_linea_di_comando.R $FASTQ_NAME "$tumor"
      R -e "rmarkdown::render('./Generazione_report_definitivo_docker_bl.Rmd',output_file='/output/report_$FASTQ_NAME.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ_NAME
    fi
done



for FASTQ in $(ls $PATH_FASTQ)
  do
    if [ ${FASTQ: -17} == ".varianttable.txt" ]; then
    FASTQ_NAME=$(basename $FASTQ ".varianttable.txt")
    echo "Annotation vcf illumina"
    Rscript illumina_vcf.R $depth $AF $FASTQ_NAME $index
    echo "Report generation"
    Rscript report_definitivo_vcf_illumina.R $FASTQ_NAME "$tumor"
    R -e "rmarkdown::render('./Generazione_report_definitivo_docker_bl.Rmd',output_file='/output/report_$FASTQ_NAME.html')" --args $name $surname $id $gender $age "$tumor" $FASTQ_NAME
  fi
done

echo "Removing folders"
rm -r $PATH_TRIM
rm -r $PATH_SAM
rm -r $PATH_BAM_ANNO
rm -r $PATH_BAM_SORT
rm -r $PATH_VCF_DA_CONVERTIRE
rm -r $PATH_VCF_FILTERED
rm -r $PATH_VCF_DP
rm -r $PATH_VCF_IN_SN
rm -r $PATH_VCF_AF
rm -r $PATH_VCF_MERGE
rm -r $PATH_TXT_CIVIC
rm -r $PATH_TXT_CGI
rm -r $PATH_TXT_PHARM
rm -r $PATH_TXT_COSMIC
rm -r $PATH_TXT_CLINVAR
rm -r $PATH_TXT_REFGENE

echo "Done"


