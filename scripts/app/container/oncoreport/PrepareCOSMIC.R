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

cat("Processing COSMIC Resistance Mutations database...\n")
resistance_file <- file.path(
  cosmic_path, paste0("CosmicResistanceMutations_", genome, ".txt.gz")
)
coding_muts_file <- file.path(
  cosmic_path, paste0("CosmicCodMutDef_", genome, ".txt")
)
a <- fread(resistance_file)
b <- fread(coding_muts_file)
a$`Gene Name` <- gsub("_ENST.*", "", a$`Gene Name`)
colnames(a)[8] <- "ID"
names(b) <- c("Chromosome", "Stop", "ID", "Ref_base", "Alt_base")
cosm <- inner_join(a, b, by = NULL, copy = FALSE, relationship = "many-to-many")
names(cosm)[grep("Genome Coordinates", names(cosm))] <- "Genome Coordinates"
cosm <- cosm[, c(
  "Gene Name", "Drug Name", "AA Mutation", "Primary Tissue", "Tissue Subtype 1",
  "Tissue Subtype 2", "Histology", "Histology Subtype 1", "Histology Subtype 2",
  "Pubmed Id", "Somatic Status", "Sample Type", "Zygosity",
  "Genome Coordinates", "HGVSP", "HGVSC", "HGVSG", "Chromosome", "Stop",
  "Ref_base", "Alt_base"
)]
cosm$Chromosome <- paste0("chr", cosm$Chromosome)
cosm$Stop <- as.character(cosm$Stop)
names(cosm)[names(cosm) == "Pubmed Id"] <- "PMID"
names(cosm)[names(cosm) == "AA Mutation"] <- "Variant"
names(cosm)[names(cosm) == "Gene Name"] <- "Gene"
names(cosm)[names(cosm) == "Drug Name"] <- "Drug"
cosm$Variant <- gsub(cosm$Variant, pattern = "p.", replace = "")
cosm$Stop <- sub(".*\\.", "", cosm$`Genome Coordinates`)
a <- sub(".*\\:", "", cosm$`Genome Coordinates`)
cosm$Start <- gsub("\\..*", "", a)
cosm$`Genome Coordinates` <- NULL
saveRDS(cosm, file.path(cosmic_genome_path, "cosmic_database.rds"))
rm(a, b, cosm)

cat("Processing COSMIC All Variants database...\n")
raw_variants_file <- file.path(
  cosmic_path, paste0("CosmicVariantsRaw_", genome, ".tsv.gz")
)
a <- na.omit(fread(raw_variants_file))
colnames(a) <- c(
  "ID", "GeneName", "Mutation", "Chromosome", "Start", "Stop",
  "Effect", "PMID"
)
b <- fread(coding_muts_file)
colnames(b) <- c("Chromosome", "Start", "ID", "Ref_base", "Var_base")
b <- b[, c("ID", "Ref_base", "Var_base")]
a <- a %>%
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
  filter(Effect %in% c("PATHOGENIC", "NEUTRAL")) %>%
  arrange(Chromosome, Start, Stop) %>%
  mutate(Chromosome = paste0("chr", Chromosome))
saveRDS(a, file.path(cosmic_genome_path, "cosmic_all_variants_database.rds"))
