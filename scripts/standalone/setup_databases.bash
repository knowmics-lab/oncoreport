#!/bin/bash

usage() {
  echo "Usage: $0 [-database/-db database path]
  [-index/-idx index must be hg19 or hg38]
  [-idx_path/-ip index path]
  [-cosmic/-c path of COSMIC]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}

while [ -n "$1" ]
do
  case "$1" in
    -database | -db) database="$2"
    echo "The value provided for database path is $database"
    if [ ! -d "$database" ]; then
      echo "Error: You must pass a valid database directory"
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
    -idx_path | -ip) index_path="$2"
    echo "The value provided for path index is $index_path"
    if [ ! -d "$index_path" ]; then
      echo "Error: You must pass a valid directory"
      exit_abnormal
      exit 1
      fi
    shift;;
    -cosmic | -c) cosmic="$2"
    echo "The value provided for cosmic is $cosmic"
    if [ ! -d "$cosmic" ]; then
      echo "Error: You must pass a valid cosmic directory"
      exit_abnormal
    fi
    shift;;
    *)
      exit_abnormal
    shift;;
    --help | -h) help="$2"
    usage
    exit_abnormal
    exit 1
    shift;;
  esac
  shift
done

if [[ -z "$index_path" ]] || [[ -z "$index" ]] || [[ -z "$cosmic" ]] || [[ -z "$database" ]]; then
  echo "all parameters must be passed"
  usage
  exit
fi


if [ $index == "hg19" ]; then
   	echo "Creating hg19 index..."
	wget ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/hg19.zip -P $index_path
	unzip $index_path/hg19.zip
	wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz -P $index_path
	gunzip $index_path/hg19.fa.gz
	java -jar picard.jar CreateSequenceDictionary REFERENCE=$index_path/hg19.fa OUTPUT=$index_path/hg19.dict
	samtools faidx $index_path/hg19.fa
	gunzip -f $cosmic/CosmicCodingMuts.vcf.gz
	gunzip -f $cosmic/CosmicResistanceMutations.tsv.gz
	cat $cosmic/CosmicResistanceMutations.tsv >> $cosmic/CosmicResistanceMutations.txt
	rm $cosmic/CosmicResistanceMutations.tsv
	cut -f1,2,3,4,5 $cosmic/CosmicCodingMuts.vcf > $cosmic/CosmicCodMutDef.txt
	#rm $cosmic/CosmicCodingMuts.vcf
else
	echo "Creating hg38 index..."
	wget ftp://ftp.ncbi.nlm.nih.gov/genomes/archive/old_genbank/Eukaryotes/vertebrates_mammals/Homo_sapiens/GRCh38/seqs_for_alignment_pipelines/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz -P $index_path
	tar xzf $index_path/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz
	wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz -P $index_path
	gunzip $index_path/hg38.fa.gz
	rename 's/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index/hg38/g' $index_path/*
	java -jar tools/picard.jar CreateSequenceDictionary REFERENCE=$index_path/hg38.fa OUTPUT=$index_path/hg38.dict
	samtools faidx $index_path/hg38.fa
	gunzip -f $cosmic/CosmicCodingMuts_hg38.vcf.gz
	gunzip -f $cosmic/CosmicResistanceMutations_hg38.tsv.gz
	cat $cosmic/CosmicResistanceMutations_hg38.tsv >> $cosmic/CosmicResistanceMutations_hg38.txt
	rm $cosmic/CosmicResistanceMutations_hg38.tsv
	cut -f1,2,3,4,5 $cosmic/CosmicCodingMuts_hg38.vcf > $cosmic/CosmicCodMutDef_hg38.txt
	#rm $cosmic/CosmicCodingMuts_hg38.vcf
	Rscript CreateCivicBed.R $database
	CrossMap.py bed hg19ToHg38.over.chain.gz $database/civic_bed.bed $database/civic_bed_hg38.bed
fi


echo "Processing databases..."
Rscript PrepareDatabases.R $database $index $cosmic
