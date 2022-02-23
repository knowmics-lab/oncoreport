cat("Building Mutations Annotation File\n")

.variables.to.keep <- ls()

refgene <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_refgene.txt"), sep = "\t", colClasses = "character")
clinvar <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_clinvar.txt"), sep = "\t", colClasses = "character")
cosmic  <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_cosmic_all_variants.txt"), sep = "\t", colClasses = "character")

if (any(colnames(cosmic) == "Alt_base")) {
  colnames(cosmic)[colnames(cosmic) == "Alt_base"] <- "Var_base"
}

mutations_data <- refgene %>% 
  inner_join(clinvar) %>%
  full_join(cosmic) %>%
  mutate(Stop = as.numeric(Stop), Gene = ifelse(is.na(Gene), GeneName, Gene),
         Change_type = ifelse(is.na(Change_type), "Not_provided", gsub(";.*", "", Change_type))) %>%
  select(Gene, Chromosome, Stop, Ref_base, Var_base, Change_type, Clinical_significance, Effect, Type)
mutations_data[is.na(mutations_data)] <- " "
if (tumor_type != "tumnorm") {
  mutations_data$Type <- factor(mutations_data$Type, levels = c("Somatic", "Germline"))
}
mutations_data <- mutations_data[order(mutations_data$Type, mutations_data$Gene, mutations_data$Stop),]
if (tumor_type == "tumnorm") {
  mutations_data$Type <- NULL
}
mutations_data$Stop <- format(mutations_data$Stop, digits=0, big.mark=",", scientific = FALSE)
names(mutations_data)[1:8] <- c("Gene", "Chromosome", "Position", "Ref. Base", "Var. Base", "Change Type", 
                                "Clinical Significance (Clinvar)", "Clinical Significance (COSMIC)")
rows_to_remove <- is.na(mutations_data$Gene) | trimws(mutations_data$Gene) == ""
mutations_data <- unique(mutations_data[!rows_to_remove,])
rownames(mutations_data) <- NULL
if (nrow(mutations_data) > 0) {
  table <- kable(mutations_data, "html", escape = FALSE) %>%
    kable_styling(bootstrap_options = c("striped", "hover", "condensed")) %>%
    column_spec(1, bold = T, border_right = T)
} else {
  table <- NULL
}
template.env$mutations_data <- table

brew(
  file = paste0(path_html_source, "/mutations.html"),
  output = paste0(report_output_dir, "mutations.html"),
  envir = template.env
)

rm(list = setdiff(ls(), .variables.to.keep))
