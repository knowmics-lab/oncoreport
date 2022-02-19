#!/bin/sh

#
# Downloads sequence for the hg19 version of H. spiens (human) from
# UCSC.
#
# Note that UCSC's hg19 build has three categories of compressed fasta
# files:
#
# 1. The base files, named chr??.fa.gz
# 2. The unplaced-sequence files, named chr??_gl??????_random.fa.gz
# 3. The alternative-haplotype files, named chr??_?????_hap?.fa.gz
#
# By default, this script builds and index for just the base files,
# since alignments to those sequences are the most useful.  To change
# which categories are built by this script, edit the CHRS_TO_INDEX
# variable below.
#

BASE_CHRS="\
chr1 \
chr2 \
chr3 \
chr4 \
chr5 \
chr6 \
chr7 \
chr8 \
chr9 \
chr10 \
chr11 \
chr12 \
chr13 \
chr14 \
chr15 \
chr16 \
chr17 \
chr18 \
chr19 \
chr20 \
chr21 \
chr22 \
chrX \
chrY \
chrM"

RANDOM_CHRS=""

CHRS_TO_INDEX="$BASE_CHRS"

UCSC_HG19_BASE=ftp://hgdownload.cse.ucsc.edu/goldenPath/hg38/chromosomes

get() {
	file=$1
	if ! wget --version >/dev/null 2>/dev/null ; then
		if ! curl --version >/dev/null 2>/dev/null ; then
			echo "Please install wget or curl somewhere in your PATH"
			exit 1
		fi
		curl -o `basename $1` $1
		return $?
	else
		wget $1
		return $?
	fi
}

INPUTS=
for c in $CHRS_TO_INDEX ; do
	if [ ! -f ${c}.fa ] ; then
		F=${c}.fa.gz
		get ${UCSC_HG19_BASE}/$F || (echo "Error getting $F" && exit 1)
		gunzip $F || (echo "Error unzipping $F" && exit 1)
	fi
	[ -n "$INPUTS" ] && INPUTS="$INPUTS ${c}.fa"
	[ -z "$INPUTS" ] && INPUTS="${c}.fa"
done

cat ${INPUTS} > "hg38.fa"
samtools faidx hg38.fa
java -jar /usr/local/bin/gatk-package-local.jar CreateSequenceDictionary --REFERENCE "hg38.fa" --OUTPUT "hg38.dict"
bwa index hg38.fa
rm ${INPUTS}
