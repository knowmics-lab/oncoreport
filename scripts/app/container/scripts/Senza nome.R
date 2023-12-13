library(dplyr)
library(readr)
library(tidyr)
library(seqinr)

hg19 <- read.fasta("~/Downloads/hg19.fa.gz", seqtype = "DNA", as.string = FALSE)
cgi <- read_delim("~/Downloads/cgi_biomarkers_20221006.tsv", 
                  delim = "\t", escape_double = FALSE, 
                  trim_ws = TRUE)
catalog <- read_delim("~/Downloads/catalog_of_validated_oncogenic_mutations_latest/catalog_of_validated_oncogenic_mutations.tsv", 
                      delim = "\t", escape_double = FALSE, 
                      trim_ws = TRUE) %>%
  separate_rows(cancer_acronym, sep = "__") %>%
  separate_rows(cancer_acronym, sep = "/")

catalog_by_gene <- catalog %>%
  group_by(gene, cancer_acronym) %>%
  summarise(
    gdna = paste0(gdna, collapse = ";;"),
    mutation = paste0(gsub("p.", "", protein, fixed = TRUE), collapse = ";;")
  ) %>%
  mutate(Alteration = paste0(gene, ":.")) %>%
  select(gene, gdna, mutation, Alteration, cancer_acronym) %>%
  unique()

catalog_by_alteration <- catalog %>% 
  mutate(
    protein=gsub("p.", "", protein, fixed=TRUE),
    Alteration=paste(gene,gsub("p.", "", protein, fixed=TRUE), sep=":")
  ) %>% 
  select(gene, gdna, mutation=protein, Alteration, cancer_acronym) %>%
  unique()

catalog_by_reference <- catalog %>%
  mutate(
    alt_part = gsub("^p.([A-Za-z]+[0-9]+).*", "\\1", protein, perl = TRUE)
  ) %>%
  mutate(
    Alteration = paste0(gene, ":", alt_part, ".")
  ) %>%
  group_by(gene, Alteration, cancer_acronym) %>%
  summarise(
    gdna = paste0(gdna, collapse = ";;"),
    mutation = paste0(gsub("p.", "", protein, fixed = TRUE), collapse = ";;")
  ) %>%
  select(gene, gdna, mutation, Alteration, cancer_acronym) %>%
  unique()

catalog_map <- unique(rbind(
  catalog_by_gene,
  catalog_by_alteration,
  catalog_by_reference
)) %>% 
  mutate(
    Alteration = gsub(":..", ":.", Alteration, fixed = TRUE)
  ) %>%
  unique() %>%
  group_by(gene, Alteration, cancer_acronym) %>% 
  mutate(
    gdna=paste0(gdna, collapse=";;"), 
    mutation=paste0(mutation, collapse=";;")
  ) %>%
  unique()

rm(catalog_by_gene, catalog_by_alteration, catalog_by_reference)

muts <- lapply(strsplit(cgi$Alteration, ";"), function(x) {
  return (unlist(lapply(strsplit(x, ":"), function(y) {
    gene        <- y[1]
    alterations <- unlist(strsplit(y[2], ","))
    if (all(is.na(alterations))) {
      return(gene)
    }
    return(paste(gene, alterations, sep = ":"))
  })))
})
cgi_sep            <- cgi[rep(1:nrow(cgi), sapply(muts, length)),]
cgi_sep$Alteration <- unlist(muts)
cgi_sep            <- unique(cgi_sep) %>%
  separate_rows(`Primary Tumor type`, sep = ";") %>%
  unique()

cgi_mapped_1 <- cgi_sep %>%
  inner_join(
    catalog_map,
    by = c(
      "Alteration" = "Alteration",
      "Primary Tumor type" = "cancer_acronym"
    ),
    relationship = "many-to-many"
  ) %>%
  unique()

cgi_mapped_2 <- cgi_sep %>%
  inner_join(
    catalog_map,
    by = join_by(Alteration),
    relationship = "many-to-many"
  ) %>%
  filter(
    cancer_acronym == "CANCER" | cancer_acronym == "CANCER-PR"
  ) %>%
  unique()

cgi_mapped <- unique(rbind(cgi_mapped_1, cgi_mapped_2[,colnames(cgi_mapped_1)]))
rm(cgi_mapped_1, cgi_mapped_2)

gdnas     <- strsplit(cgi_mapped$gdna, ";;")
mutations <- strsplit(cgi_mapped$mutation, ";;")

cgi_split            <- cgi_mapped[rep(1:nrow(cgi_mapped), sapply(gdnas, length)), ]
cgi_split$gdna       <- unlist(gdnas)
cgi_split$mutation   <- unlist(mutations)
cgi_split$Alteration <- NULL
cgi_split            <- unique(cgi_split) %>%
  separate_rows(gdna, sep = "__") %>%
  unique()

gdna_parse_expressions <- c(
  "chr([0-9XY]+):g\\.([0-9]+)([A-Z]+)>([A-Z]+)"="\\1__\\2__\\2__\\3__\\4__snp",
  "chr([0-9XY]+):g\\.([0-9]+)_([0-9]+)del([A-Z]+)$"="\\1__\\2__\\3__\\4____del",
  "chr([0-9XY]+):g\\.([0-9]+)del([A-Z]+)$"="\\1__\\2__\\2__\\3____del",
  "chr([0-9XY]+):g\\.([0-9]+)_([0-9]+)ins([A-Z]+)$"="\\1__\\2__\\3____\\4__ins",
  "chr([0-9XY]+):g\\.([0-9]+)ins([A-Z]+)$"="\\1__\\2__\\2____\\3__ins",
  "chr([0-9XY]+):g\\.([0-9]+)_([0-9]+)del([A-Z]+)ins([A-Z]+)$"="\\1__\\2__\\3__\\4__\\5__del_ins",
  "chr([0-9XY]+):g\\.([0-9]+)_([0-9]+)delins([A-Z]+)$"="\\1__\\2__\\3____\\4__delins",
  "chr([0-9XY]+):g\\.([0-9]+)delins([A-Z]+)$"="\\1__\\2__\\2____\\3__delins",
  "chr([0-9XY]+):g\\.([0-9]+)_([0-9]+)dup([A-Z]+)$"="\\1__\\2__\\3__\\4__\\4\\4__dup",
  "chr([0-9XY]+):g\\.([0-9]+)dup([A-Z]+)$"="\\1__\\2__\\2__\\3__\\3\\3__dup"
)
gdna <- cgi_split$gdna
for (i in seq_along(gdna_parse_expressions)) {
  gdna <- gsub(names(gdna_parse_expressions)[i], gdna_parse_expressions[i], gdna, perl = TRUE)
}
gdna_split <- strsplit(gdna, "__")
cgi_split$chromosome <- paste0("chr", sapply(gdna_split, function(x) x[1]))
cgi_split$start      <- sapply(gdna_split, function(x) x[2])
cgi_split$end        <- sapply(gdna_split, function(x) x[3])
cgi_split$ref        <- sapply(gdna_split, function(x) x[4])
cgi_split$alt        <- sapply(gdna_split, function(x) x[5])
cgi_split$type       <- sapply(gdna_split, function(x) x[6])

to_update <- which(cgi_split$type == "delins" & cgi_split$ref == "")
for (i in to_update) {
  seq <- hg19[[cgi_split$chromosome[i]]][cgi_split$start[i]:cgi_split$end[i]]
  cgi_split$ref[i] <- toupper(paste0(seq, collapse = ""))
}
to_update <- which(cgi_split$type == "ins" & cgi_split$ref == "")
for (i in to_update) {
  seq <- hg19[[cgi_split$chromosome[i]]][cgi_split$start[i]:cgi_split$end[i]]
  seq <- toupper(paste0(seq, collapse = ""))
  ins <- paste0(seq, cgi_split$alt[i])
  cgi_split$ref[i] <- seq
  cgi_split$alt[i] <- ins
}

cgi_split <- cgi_split %>% 
  separate_rows(`Primary Tumor type full name`, sep = ";") %>% 
  mutate("Disease"=trimws(`Primary Tumor type full name`)) %>%
  select(-`Primary Tumor type full name`) %>%
  unique()

cgi_split <- cgi_split[, c("chromosome", "start", "end", "ref", "alt", "Gene",
                           "mutation", "Association", "Drug full name",
                           "Evidence level", "Disease", "Source", "Comments")]
names(cgi_split) <- c("Chromosome", "Start", "Stop", "Ref_base", "Var_base",
                      "Gene", "Variant", "Clinical_significance", "Drug",
                      "Evidence_level", "Disease", "Source",
                      "Evidence_statement")
cgi_split$Database <- "Cancer Genome Interpreter"
stop()
cgi <- cgi_split
cgi <- cgi %>% separate_rows(Source, sep = ";")

pmids <- gsub(".*PMID:\\s*([0-9]+).*", "\\1", unique(grep("PMID:", cgi$Source, value = TRUE)))
q <- paste0(paste0(pmids, "[UID]")[1:10], collapse=" OR ")
r <- easyPubMed::get_pubmed_ids(q)
d <- easyPubMed::fetch_pubmed_data(r)
l <- easyPubMed::articles_to_list(d)

cgi$Variant <- gsub(".*:(.*)", "\\1", cgi$Variant)
cgi$Drug <- gsub(cgi$Drug, pattern = " *\\[.*?\\] *", replace = "")
cgi$Drug <- gsub(cgi$Drug, pattern = " *\\(.*?\\) *", replace = "")
cgi$Drug <- gsub(cgi$Drug, pattern = ";", replace = ",", fixed = T)
cgi$Evidence_type <- "Predictive"
cgi$Evidence_direction <- "Supports"
cgi$Evidence_statement <- gsub(cgi$Evidence_statement, pattern = "\\\\x2c", replace = ",")
cgi$Citation <- gsub(cgi$Citation, pattern = "\\\\x2c", replace = ",")
cgi$Drug_interaction_type <- ""
cgi$Drug_interaction_type[grep(" + ", cgi$Drug, fixed = T)] <- "Combination"
cgi$Drug <- gsub(cgi$Drug, pattern = " + ", replace = ",", fixed = T)



cgi <- separate_rows(cgi, Chromosome, Ref_base, Var_base, Gene, Variant, Clinical_significance, Drug, 
                     Evidence_level, Disease, PMID, Evidence_statement, Citation, sep=";;")
cgi$PMID <- gsub(";", ",,", cgi$PMID)
cgi <- separate_rows(cgi, Chromosome, Ref_base, Var_base, Gene, Variant, Clinical_significance, Drug, 
                     Evidence_level, Disease, PMID, Evidence_statement, Citation, sep=",,")
cgi <- separate_rows(cgi, Disease, sep=";")
cgi <- separate_rows(cgi, PMID, sep=",")
cgi <- cgi[grep("PMID:", cgi$PMID),]
cgi$PMID <- gsub(cgi$PMID, pattern = "PMID:", replace = "")
cgi$Variant_summary <- ""
cgi <- cgi[, c(1:7, 14, 9, 18, 16, 10, 17, 8, 11, 19, 15, 12, 13)]




