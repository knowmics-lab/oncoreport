cat("Building PharmGKB File\n")

template.env$pharmgkb <- list(
  summary=NULL,
  evidences=NULL,
  details=NULL
)
.variables.to.keep <- ls()

id_evidence <- 0
pharmgkb_references <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_pharm.txt"), sep = "\t", 
                                colClasses = "character", stringsAsFactors = FALSE)
pharmgkb_references <- pharmgkb_references[, c("PMID", "Reference")]

pharmgkb_annot <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_pharm.txt"), sep = "\t", 
                           colClasses = "character", stringsAsFactors = FALSE)
pharmgkb_annot[is.na(pharmgkb_annot)] <- " "
pharmgkb_annot$Drug <- gsub(", ", ",", pharmgkb_annot$Drug, fixed = TRUE)
pharmgkb_annot$Clinical_significance <- gsub(pattern = " ", replace = "", pharmgkb_annot$Clinical_significance)

pharmgkb_annot <- pharmgkb_annot %>%
  inner_join(pharmgkb_references) %>%
  arrange(Gene, Variant, Drug, Clinical_significance, Reference)
pharmgkb_annot <- pharmgkb_annot[!duplicated(pharmgkb_annot$PMID),,drop=FALSE]

if (nrow(pharmgkb_annot) > 0) {
  pharmgkb_annot$Reference <- paste0(
    '<a href="Javascript:;" class="ref-link" data-id="#pharm-', 
    pharmgkb_annot$Reference, '">', pharmgkb_annot$Reference, 
    '</a>'
  )
  pharmgkb_annot$id <- 1:nrow(pharmgkb_annot)
  
  pharmgkb_annot <- pharmgkb_annot %>% 
    group_by(Variant, Drug, Clinical_significance, Type, Gene) %>%
    summarise(id=paste0(id, collapse = "-"),
              Evidence_statement = paste0("<ul>", paste0("<li>",trimws(Evidence_statement),"</li>", collapse = ""), "</ul>"), 
              Reference = paste(Reference, collapse = ", "))
  
  pharmgkb_mutations  <- pharmgkb_annot %>% select(Gene, Variant, Drug, Clinical_significance, Type, Reference, id)
  pharmgkb_references <- pharmgkb_annot %>% select(Gene, Evidence_statement, Reference, id)
  pharmgkb_mutations$Details <- paste0('[<a href="Javascript:;" class="evidence-details-link" data-id="#det-', 
                                       pharmgkb_mutations$id, '">+</a>]')
  empty <- !complete.cases(pharmgkb_references) | trimws(pharmgkb_references$Evidence_statement) == "" | 
    trimws(pharmgkb_references$Evidence_statement) == "<ul><li></li></ul>"
  pharmgkb_references$Evidence <- 1:nrow(pharmgkb_references)
  if (length(which(empty)) > 0) {
    pharmgkb_mutations$Details[empty] <- ""
    pharmgkb_references               <- pharmgkb_references[!empty,,drop=FALSE]
  }
  pharmgkb_mutations$Evidence <- paste0('<a id="mut-', pharmgkb_mutations$id, '"></a>', 1:nrow(pharmgkb_mutations))
  pharmgkb_mutations$Drug <- gsub(",", ", ", pharmgkb_mutations$Drug, fixed = TRUE)
  pharmgkb_mutations <- pharmgkb_mutations[, c("Evidence", "Gene", "Variant", "Drug", "Clinical_significance", "Type", 
                                               "Details", "Reference")]
  names(pharmgkb_mutations) <- c("#", "Gene", "Variant", "Drug", "Clinical Significance", "Type", "Details", "References")
  if (tumor_type == "tumnorm") {
    pharmgkb_mutations$Type <- NULL
  }
  table <- kable(pharmgkb_mutations, "html", escape = FALSE) %>% kable_styling(bootstrap_options = c("striped", "hover"))
  genes <- unique(pharmgkb_mutations$Gene)
  if (length(genes) > 1) {
    for (g in genes) {
      rows <- which(pharmgkb_mutations$Gene == g)
      if (length(rows) > 0) {
        rng  <- range(rows)
        table <- table %>% pack_rows(group_label = g, start_row = rng[1], end_row = rng[2], indent = FALSE)
      }
    }
  }
  template.env$pharmgkb$summary <- table
  pharmgkb_references$Less <- paste0('[<a href="Javascript:;" class="evidence-summary-link" data-id="#mut-', 
                                     pharmgkb_references$id , '">-</a>]')
  pharmgkb_references$Evidence <- paste0('<a id="det-', pharmgkb_references$id,'"></a>', pharmgkb_references$Evidence)
  if (nrow(pharmgkb_references) > 0) {
    pharmgkb_references <- pharmgkb_references[, c("Evidence", "Evidence_statement", "Reference", "Less"), drop = FALSE]
    names(pharmgkb_references) <- c("#", "Evidence Statement", "References", "")
    template.env$pharmgkb$evidences <- kable(pharmgkb_references, "html", escape = FALSE) %>% 
      kable_styling(bootstrap_options = c("striped", "hover", align = "justify"))
  }
}

mut_details <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_pharm.txt"), sep = "\t", 
                        colClasses = "character", stringsAsFactors = FALSE)
mut_details[is.na(mut_details)] <- " "
mut_details[is.na(mut_details$Var_base), "Var_base"] <- "T"
mut_details[is.na(mut_details$Ref_base), "Ref_base"] <- "T"
mut_details <- mut_details %>% arrange(Gene, Variant)
mut_details <- mut_details[, c("Variant", "Variant_summary"), drop=FALSE]
mut_details <- mut_details[complete.cases(mut_details) & trimws(mut_details$Variant_summary) != "",,drop=FALSE]
mut_details <- unique(mut_details) %>%
  group_by(Variant) %>% 
  summarise(Variant_summary = paste0("<ul>",paste0("<li>", Variant_summary, "</li>", collapse = ""),"</ul>"))
if (nrow(mut_details) > 0) {
  colnames(mut_details) <- c("Variant", "Details")
  template.env$pharmgkb$details <- kable(mut_details, "html", escape = FALSE) %>% 
    kable_styling(bootstrap_options = c("striped", "hover", align = "justify"))
}

brew(
  file = paste0(path_html_source, "/pharmgkb.html"),
  output = paste0(report_output_dir, "pharmgkb.html"),
  envir = template.env
)

stop()






cat("PHARMGKB - Variant Details\n")
children_phgkb_vd <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(pharmgkb, 2), 1), 2), 4), 3), 1)
array_table <- c()
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  
  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_pharm.txt"), sep = "\t", colClasses = c("character"))
  x[is.na(x)] <- " "
  x$Gene <- as.character(x$Gene, levels = (x$Gene))
  x$Var_base <- as.character(x$Var_base)
  x$Ref_base <- as.character(x$Ref_base)
  x[is.na(x$Var_base), "Var_base"] <- "T"
  x[is.na(x$Ref_base), "Ref_base"] <- "T"
  
  x <- inner_join(x, x_url)
  x <- x[order(x$Gene, x$Variant),]
  
  hgx <- split(x, paste(x$Gene))
  empty <- T
  for (n in hgx)
  {
    if (dim(n)[1] != 0)
    {
      cat("  \n#### Gene", as.character(n$Gene)[1], " \n")
      ya <- n[, c("Variant", "Chromosome", "Ref_base", "Var_base", "Start", "Stop")]
      ya <- unique(ya)
      row.names(ya) <- NULL
      print(kable(ya[1,]) %>%
              kable_styling(bootstrap_options = c("striped", "hover", "responsive")))
      yc <- n[, c("Variant", "Variant_summary"), drop = F]
      yc <- yc[complete.cases(yc),]
      yc <- unique(yc)
      yc <- yc[!(yc$Variant_summary == " "),]
      yc <- yc[!(yc$Variant_summary == ""),]
      if (nrow(yc) > 0)
      {
        tmp <- group_by(yc, Variant)
        tmp2 <- summarise(tmp, Variant_summary = paste(Variant_summary, collapse = " "))
        array_table <- rbind(array_table, tmp2)
      }
      empty <- F
    }
  }
  if (empty)
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
  }
}, silent = TRUE)
array_table <- kable(array_table, "html", escape = FALSE) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive", align = "justify"))
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_phgkb_vd
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(pharmgkb, paste0(path_project, "/", pt_fastq, "/pharmgkb.html"))







brew(
  file = paste0(path_html_source, "/pharmgkb.html"),
  output = paste0(report_output_dir, "pharmgkb.html"),
  envir = template.env
)

rm(list = setdiff(ls(), .variables.to.keep))
