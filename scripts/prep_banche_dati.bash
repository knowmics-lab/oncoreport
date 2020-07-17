#!/bin/bash
PATH_COSMIC=Cosmic_downloads
PATH_INDEX=index
echo "database creation"
cd $PATH_INDEX
wget ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/hg19.zip
unzip hg19.zip
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz
gunzip hg19.fa.gz
cd ..
gunzip -f $PATH_COSMIC/CosmicCodingMuts.vcf.gz
gunzip -f $PATH_COSMIC/CosmicResistanceMutations.tsv.gz
cat $PATH_COSMIC/CosmicResistanceMutations.tsv >> $PATH_COSMIC/CosmicResistanceMutations.txt
rm $PATH_COSMIC/CosmicResistanceMutations.tsv
cat nightly-ClinicalEvidenceSummaries.tsv >> civic.txt
sed '1,27d' clinvar_20200327.vcf > clinvar_databasehg19.vcf
cut -f1,2,3,4,5 $PATH_COSMIC/CosmicCodingMuts.vcf > $PATH_COSMIC/CosmicCodMutDef.txt
echo "R banche"
Rscript Script_prep_banche_linea_di_comando.R
