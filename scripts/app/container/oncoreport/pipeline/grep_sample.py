#!/usr/bin/env python3
import pysam
import os
import sys
n = len(sys.argv)
if n < 4:
    print("Usage: append_type.py <input.vcf> <output.vcf> <sample>")
    sys.exit(1)
input_file = sys.argv[1]
output_file = sys.argv[2]
sample = sys.argv[3]

if not os.path.isfile(input_file):
    print("Input file does not exist")
    sys.exit(1)

vcf = pysam.VariantFile(input_file, "r")
vcf.subset_samples([sample])
vcf_out = pysam.VariantFile(output_file, 'w', header=vcf.header)
vcf_out.close()
with open(output_file, "a") as out:
    for variant in vcf:
        out.write(str(variant))
vcf.close()
