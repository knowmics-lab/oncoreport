cat("Building Mutations Annotation File\n")

.variables.to.keep <- ls()

refgene <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_refgene.txt"), sep = "\t", colClasses = c("character"))
clinvar <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_clinvar.txt"), sep = "\t", colClasses = c("character"))

mutations_data <- refgene %>% 
  inner_join(clinvar) %>%
  mutate(Stop = as.numeric(Stop)) %>%
  select(Gene, Chromosome, Stop, Ref_base, Var_base, Change_type, Clinical_significance, Type)
mutations_data[is.na(mutations_data)] <- " "
if (tumor_type != "tumnorm") {
  mutations_data$Type <- factor(mutations_data$Type, levels = c("Somatic", "Germline"))
}
mutations_data <- mutations_data[order(mutations_data$Type, mutations_data$Gene, mutations_data$Stop),]
if (tumor_type == "tumnorm") {
  mutations_data$Type <- NULL
}
mutations_data$Stop <- format(mutations_data$Stop, digits=0, big.mark=",", scientific = FALSE)
names(mutations_data) <- c("Gene", "Chromosome", "Position", "Ref. Base", "Var. Base", "Change Type", 
                           "Clinical Significance")
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