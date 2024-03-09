#!/usr/bin/env python3
import argparse
import csv
import os
from pathlib import Path

from dotenv import load_dotenv

from Annotator import GenomicChangeQuery, set_oncokb_api_token, validate_oncokb_token, query_genomic_change, \
    process_annotation

parser = argparse.ArgumentParser(
    prog="annotate_oncokb.py",
    description="Annotate a variants file with the OncoKB webservice."
)
parser.add_argument("input_file", help="The input variants file.")
parser.add_argument("-o", "--output_file", help="The output TSV file.", default="output.tsv")
parser.add_argument("-g", "--genome", help="The reference genome (hg19 or hg38).", default="hg19")
parser.add_argument("-e", "--env_file", help=".env file", default=None)
args = parser.parse_args()

input_file = args.input_file
output_file = args.output_file
env_file = args.env_file
genome = args.genome

if env_file is None or not os.path.exists(env_file):
    load_dotenv()
else:
    dotenv_path = Path(env_file)
    load_dotenv(dotenv_path=dotenv_path)

# Import metapub after loading the .env file otherwise it might not get the NCBI API key
from metapub import PubMedFetcher

if not os.path.exists(input_file):
    print(f"File '{input_file}' non trovato.")
    exit(1)

if genome not in ["hg19", "hg38"]:
    print(f"Genome '{args.genome}' non valido.")
    exit(1)

ONCOKB_BEARER_TOKEN = os.getenv('ONCOKB_BEARER_TOKEN')
OUTPUT_FILE_FIELDS = ["Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type", "Evidence_type",
                      "Evidence_level", "Evidence_direction", "Clinical_significance", "Evidence_statement",
                      "Variant_summary", "PMID", "Citation", "Chromosome", "Start", "Stop", "Ref_base", "Var_base",
                      "Type"]

print(f"Annotating '{input_file}' with OncoKB.")


def write_empty_output_file(output_file_name: str):
    with open(output_file_name, "w") as of:
        writer = csv.writer(of, delimiter="\t")
        writer.writerow(OUTPUT_FILE_FIELDS)


if ONCOKB_BEARER_TOKEN is None:
    print("No token provided...Skipping OncoKB annotation.")
    write_empty_output_file(output_file)
    exit(0)

set_oncokb_api_token(ONCOKB_BEARER_TOKEN)
if not validate_oncokb_token():
    print("Invalid OncoKB token...Skipping OncoKB annotation.")
    write_empty_output_file(output_file)
    exit(0)

variants_cache = {}
query_list = []
variant_types_list = []
parsed_annotations = []


def query_and_parse():
    global query_list, parsed_annotations, variant_types_list
    genomic_changes = query_genomic_change(query_list)
    for i, genomic_change in enumerate(genomic_changes):
        parsed = process_annotation(genomic_change, query_list[i], variant_types_list[i])
        if parsed is not None and len(parsed) > 0:
            parsed_annotations += parsed
    query_list = []
    variant_types_list = []


print("Reading variants...", end="", flush=True)
total_variants = 0
with open(input_file, "r") as variants:
    next(variants)  # Skip header
    for _ in variants:
        total_variants += 1
print(f"\rReading variants...{total_variants} variants found.")

print("Annotating VCF file...", end="", flush=True)
current_variant = 0
with open(input_file, "r") as variants:
    reader = csv.reader(variants, delimiter="\t")
    for record in reader:
        if current_variant == 0:  # Skip header
            current_variant += 1
            continue
        print(f"\rAnnotating VCF file...{current_variant}/{total_variants}", end="", flush=True)
        chrom = record[0]
        pos = int(record[1])
        ref = record[2]
        alts = record[3]
        variant_type = record[8] or "Somatic"
        for alt in alts:
            query = GenomicChangeQuery(
                chromosome=chrom,
                start=str(pos),
                end=str(pos + len(ref) - 1),
                ref_allele=ref,
                var_allele=alt,
                reference_genome=genome
            )
            if query.genomicLocation in variants_cache:
                continue
            query_list.append(query)
            variant_types_list.append(variant_type)
            variants_cache[query.genomicLocation] = True

            if len(query_list) == 100:
                query_and_parse()
        current_variant += 1

if len(query_list) > 0:
    query_and_parse()
print()
print(f"Found {len(parsed_annotations)} annotations.")
pmids = [pmid for a in parsed_annotations for pmid in a[12]]
pmids = list(set(pmids))
fetcher = PubMedFetcher()
articles_map = {}
print("Processing PMIDs...", end="", flush=True)
for i, pmid in enumerate(pmids):
    print(f"\rProcessing PMIDs...{i + 1}/{len(pmids)}", end="", flush=True)
    article = fetcher.article_by_pmid(pmid)
    if article is None:
        continue
    articles_map[pmid] = f"{article.authors[0]} et al.,{article.journal},{article.year}"
print()
for a in parsed_annotations:
    pmids = a[12]
    clean_pmids = []
    citations = []
    for pmid in pmids:
        if pmid in articles_map:
            clean_pmids.append(pmid)
            citations.append(articles_map[pmid])
    a[12] = ';;'.join(clean_pmids)
    a[13] = ';;'.join(citations)

print(f"Writing output to '{output_file}'.")
with open(output_file, "wt") as of:
    writer = csv.writer(of, delimiter="\t")
    writer.writerow(OUTPUT_FILE_FIELDS)
    writer.writerows(parsed_annotations)
print("Done.")
