args <- commandArgs(trailingOnly = TRUE)

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(stringr))

cosmic_path <- args[1]
genome <- args[2]

################################################################################
# COSMIC

cosmic_genome_path <- file.path(cosmic_path, genome)

dir.create(cosmic_genome_path, recursive = TRUE, showWarnings = FALSE)

cat("   - Processing COSMIC Resistance Mutations database...\n")
resistance_file <- file.path(
  cosmic_path, paste0("CosmicResistanceMutations_", genome, ".txt.gz")
)
coding_muts_file <- file.path(
  cosmic_path, paste0("CosmicCodMutDef_", genome, ".txt")
)
classification_file <- file.path(
  cosmic_path, paste0("CosmicClassification_", genome, ".tsv.gz")
)
samples_file <- file.path(
  cosmic_path, paste0("CosmicSamples_", genome, ".tsv.gz")
)
a <- fread(resistance_file)
b <- fread(coding_muts_file, header = FALSE)
c <- fread(classification_file)
d <- fread(samples_file)
colnames(a)[8] <- "ID"
names(b) <- c("Chromosome", "Stop", "ID", "Ref_base", "Alt_base")
cosm <- a %>%
  inner_join(c, by = "COSMIC_PHENOTYPE_ID", relationship = "many-to-many") %>%
  inner_join(b, relationship = "many-to-many") %>%
  inner_join(d, relationship = "many-to-many")
cosm <- cosm %>%
  select(
    GENE_SYMBOL, DRUG_NAME, MUTATION_AA, PRIMARY_SITE, SITE_SUBTYPE_1,
    SITE_SUBTYPE_2, PRIMARY_HISTOLOGY, HISTOLOGY_SUBTYPE_1, HISTOLOGY_SUBTYPE_2,
    PUBMED_PMID, MUTATION_SOMATIC_STATUS, SAMPLE_TYPE, MUTATION_ZYGOSITY, HGVSP,
    HGVSC, HGVSG, CHROMOSOME, GENOME_START, GENOME_STOP, Ref_base, Alt_base
  ) %>%
  unique()
colnames(cosm) <- c(
  "Gene", "Drug", "Variant", "Primary Tissue", "Tissue Subtype 1",
  "Tissue Subtype 2", "Histology", "Histology Subtype 1", "Histology Subtype 2",
  "PMID", "Somatic Status", "Sample Type", "Zygosity", "HGVSP", "HGVSC",
  "HGVSG", "Chromosome", "Start", "Stop", "Ref_base", "Alt_base"
)

cosm$Chromosome <- paste0("chr", cosm$Chromosome)
cosm$Start <- as.character(cosm$Start)
cosm$Stop <- as.character(cosm$Stop)
cosm$Variant <- gsub(cosm$Variant, pattern = "p.", replace = "")
saveRDS(cosm, file.path(cosmic_genome_path, "cosmic_database.rds"))
rm(a, b, c, d, cosm)

cat("   - Processing COSMIC All Variants database...\n")
raw_variants_file <- file.path(
  cosmic_path, paste0("CosmicVariantsRaw_", genome, ".tsv.gz")
)
tiers_file <- file.path(
  cosmic_path, paste0("tiers_", genome, ".tsv.gz")
)
a <- na.omit(fread(raw_variants_file, header = FALSE))
colnames(a) <- c(
  "ID", "GeneName", "Mutation", "Chromosome", "Start", "Stop", "PMID"
)
b <- fread(coding_muts_file, header = FALSE)
colnames(b) <- c("Chromosome", "Start", "ID", "Ref_base", "Var_base")
b <- b[, c("ID", "Ref_base", "Var_base")]
c <- fread(tiers_file, header = FALSE)
colnames(c) <- c("ID", "Effect")
c$Effect[c$Effect != "Other"] <- paste0("Tier ", c$Effect[c$Effect != "Other"])
a <- a %>%
  inner_join(c, by = "ID", relationship = "many-to-many") %>%
  group_by(ID, GeneName, Mutation, Chromosome, Start, Stop) %>%
  summarise(
    Effect = paste0(unique(Effect), collapse = ", "),
    PMID = paste0(unique(PMID), collapse = ", ")
  ) %>%
  inner_join(b, by = "ID", relationship = "many-to-many") %>%
  ungroup() %>%
  select(
    Chromosome, Start, Stop, Ref_base, Var_base, GeneName,
    Mutation, Effect, PMID
  ) %>%
  arrange(Chromosome, Start, Stop) %>%
  mutate(Chromosome = paste0("chr", Chromosome))
saveRDS(a, file.path(cosmic_genome_path, "cosmic_all_variants_database.rds"))
