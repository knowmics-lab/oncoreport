#!/bin/bash

source /oncoreport/scripts/path.bash

# @TODO questo script e' da rivedere

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

while [ -n "$1" ]; do
  case "$1" in
  -database | -db)
    database="$2"
    echo "The value provided for database path is $database"
    if [ ! -d "$database" ]; then
      echo "Error: You must pass a valid database directory"
      exit_abnormal
    fi
    shift
    ;;
  -index | -idx)
    index="$2"
    echo "The value provided for index is $index"
    if ! [ $index = "hg19" ]; then
      if ! [ $index = "hg38" ]; then
        echo "Error: index must be equal to hg19 or hg38."
        exit_abnormal
        exit 1
      fi
    fi
    shift
    ;;
  -idx_path | -ip)
    index_path="$2"
    echo "The value provided for path index is $index_path"
    if [ ! -d "$index_path" ]; then
      echo "Error: You must pass a valid directory"
      exit_abnormal
      exit 1
    fi
    shift
    ;;
  -cosmic | -c)
    cosmic="$2"
    echo "The value provided for cosmic is $cosmic"
    if [ ! -d "$cosmic" ]; then
      echo "Error: You must pass a valid cosmic directory"
      exit_abnormal
    fi
    shift
    ;;
  *)
    exit_abnormal
    shift
    ;;
  --help | -h)
    help="$2"
    usage
    exit_abnormal
    exit 1
    shift
    ;;
  esac
  shift
done

if [[ -z "$index_path" ]] || [[ -z "$index" ]] || [[ -z "$cosmic" ]] || [[ -z "$database" ]]; then
  echo "all parameters must be passed"
  usage
  exit
fi

if [ $index == "hg19" ]; then
  gunzip -f $cosmic/CosmicCodingMuts.vcf.gz
  gunzip -f $cosmic/CosmicResistanceMutations.tsv.gz
  cat $cosmic/CosmicResistanceMutations.tsv >>$cosmic/CosmicResistanceMutations.txt
  rm $cosmic/CosmicResistanceMutations.tsv
  cut -f1,2,3,4,5 $cosmic/CosmicCodingMuts.vcf >$cosmic/CosmicCodMutDef.txt
  #rm $cosmic/CosmicCodingMuts.vcf
else
  gunzip -f $cosmic/CosmicCodingMuts_hg38.vcf.gz
  gunzip -f $cosmic/CosmicResistanceMutations_hg38.tsv.gz
  cat $cosmic/CosmicResistanceMutations_hg38.tsv >>$cosmic/CosmicResistanceMutations_hg38.txt
  rm $cosmic/CosmicResistanceMutations_hg38.tsv
  cut -f1,2,3,4,5 $cosmic/CosmicCodingMuts_hg38.vcf >$cosmic/CosmicCodMutDef_hg38.txt
  #rm $cosmic/CosmicCodingMuts_hg38.vcf
fi

echo "Processing databases..."
Rscript PrepareDatabases.R $database $index $cosmic
