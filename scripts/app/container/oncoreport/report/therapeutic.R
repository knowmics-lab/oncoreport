cat("Building Therapeutic Indications File\n")

template.env$therapeutic_indications <- vector("list", 0)

therapeutic.references <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, ".txt"), sep = "\t", 
                                   stringsAsFactors = FALSE, colClasses = "character")
therapeutic.references <- therapeutic.references[, c("PMID", "Reference")]
therapeutic.references <- therapeutic.references[!duplicated(therapeutic.references$PMID),]

therapeutic.trials <- read.csv(paste0(path_project, "/txt/trial/", pt_fastq, ".txt"), sep = "\t", 
                               stringsAsFactors = FALSE)
list.all.trials    <- unique(therapeutic.trials$Clinical_trial)

all.annotations <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), sep = "\t", 
                            colClasses = "character", stringsAsFactors = FALSE)
all.annotations <- diseases_db_simple %>% inner_join(all.annotations, by = "Disease")
all.annotations[is.na(all.annotations)] <- " "
all.annotations$id <- seq_len(nrow(all.annotations))

.variables.to.keep <- c(ls(), "recommended_drugs")
primary.annotations <- build.primary.annotations(all.annotations, pt_tumor)
order_id <- c()
order_evidence <- c()
if (nrow(primary.annotations) > 0) {
  evidence.groups <- list(clinical.impact=evidence_list[1:4], others=evidence_list[5:11])
  sorted_id <- character(0)
  sorted_evidences <- NULL
  evidence.groups <- suppressMessages(lapply(evidence.groups, function (eg) {
    e.annotations <- primary.annotations[primary.annotations$Evidence_level %in% eg,,drop=FALSE]
    e.annotations <- e.annotations[, c("Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", 
                                       "Evidence_level", "Evidence_statement", "Type", "Reference", "Score", "AIFA", 
                                       "EMA", "FDA", "year", "id")]
    e.annotations.clean <- e.annotations
    e.annotations.clean$Evidence_statement <- NULL
    e.annotations.clean$Reference <- NULL
    e.annotations.clean$year <- NULL
    e.annotations.clean$id <- NULL
    if (nrow(e.annotations.clean) > 0) {
      e.annotations.clean <- aggregate(Score ~ ., data = e.annotations.clean, FUN = mean)
    }
    e.annotations <- e.annotations %>% 
      inner_join(e.annotations.clean) %>%
      group_by(Gene, Evidence_level, Evidence_type, Variant, Drug, Clinical_significance, Type, Score, AIFA, EMA, 
               FDA, .add = FALSE) %>%
      summarise(Evidence_statement = paste0("<li>", Evidence_statement, "</li>", collapse = ""),
                Reference = paste(sort(Reference), collapse = ", "), year = paste(sort(year), collapse = ", "), 
                id = paste(sort(id), collapse = "-"))
    sorted_id <<- c(sorted_id, e.annotations$id)
    return (e.annotations)
  }))
  last_evidence <- 0
  template.env$therapeutic_indications$summary <- suppressMessages(lapply(evidence.groups, function(eg) {
    es <- eg[,c("Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", "Type",
                "Evidence_statement", "Reference", "Score", "AIFA", "EMA", "FDA", "year", "id"), drop = F]
    es$Evidence <- seq_len(nrow(es))
    es$Details <- paste0('[<a href="Javascript:;" class="evidence-details-link" data-id="#det-', es$id, '">+</a>]')
    es$Details[!complete.cases(es[, c("Evidence_statement", "Reference"), drop = FALSE]) | trimws(es$Evidence_statement) == ""] <- ""
    es$Evidence <- paste0('<a id="evi-', es$id, '"></a>', es$Evidence + last_evidence)
    list.trials <- paste0("https://clinicaltrials.gov/ct2/results?cond=", es$Variant, "&term=", es$Drug, "&cntry=&state=&city=&dist=")
    es$Trials <- paste0("[", "<a href=\"", list.trials, "\" target=\"_blank\">+</a>", "]")
    es$Trials[!list.trials %in% list.all.trials] <- ""
    es$Drug <- gsub(",", ", ", es$Drug, fixed = T)
    es <- es[, c("Evidence", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", 
                 "Type", "Details", "Trials", "Evidence_statement", "Reference", "Score", "AIFA", "EMA", "FDA", "year", "id")]
    es$Score <- as.numeric(es$Score)
    assigned.colors <- assign.colors(es)
    es$Score <- round(es$Score, digits = 2)
    names(es) <- c("#", "Gene", "Variant", "Drug", "Evidence Type", "Clinical Significance", "Evidence Level", "Type",
                   "Details", "Trials", "Evidence_statement", "References", "Score", "AIFA", "EMA", "FDA", 
                   "Publication year", "id")
    color_column <- 12
    last_evidence <<- nrow(es)
    if (nrow(es) == 0) return (NULL)
    if (is.null(sorted_evidences)) sorted_evidences <<- es
    else sorted_evidences <<- rbind(sorted_evidences, es)
    es <- es[,-which(colnames(es) %in% c("Evidence_statement", "id"))]
    table <- kable(es, "html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("striped", "hover", "condensed")) %>%
      column_spec(color_column, bold = T, color = "black", background = assigned.colors)
    genes <- unique(es$Gene)
    if (length(genes) > 1) {
      for (g in genes) {
        rows <- which(es$Gene == g)
        if (length(rows) > 0) {
          rng  <- range(rows)
          table <- table %>% pack_rows(group_label = g, start_row = rng[1], end_row = rng[2], indent = FALSE)
        }
      }
    }
    table <- gsub("{{APPROVED}}", "&#9989;", 
                  gsub("{{NOTAPPROVED}}", "&#10060;", as.character(table), fixed = TRUE), fixed = TRUE)
    return (table)
  }))
  
  evidence.annotations <- sorted_evidences[,c("Gene", "#", "Evidence_statement", "References", "id")]
  colnames(evidence.annotations) <- c("Gene", "Evidence", "Evidence_statement", "References", "id")
  evidence.annotations$Evidence <- gsub("evi-", "det-", evidence.annotations$Evidence, fixed = TRUE)
  evidence.annotations$Evidence_statement <- paste0("<ul>",iconv(evidence.annotations$Evidence_statement, to = "ASCII//TRANSLIT"),"</ul>")
  evidence.annotations$Less <- paste0('[<a href="Javascript:;" class="evidence-summary-link" data-id="#evi-', evidence.annotations$id , '">-</a>]')
  evidence.annotations <- evidence.annotations %>% group_by(Gene, Evidence_statement, References) %>%
    summarize(Evidence = str_c(Evidence, collapse = ", "), Less = str_c(Less, collapse = ", "), 
              id = str_c(id, collapse = "-"))
  evidence.annotations <- evidence.annotations[order(match(evidence.annotations$id, sorted_id)),]
  if (nrow(evidence.annotations) > 0) {
    evidence.genes <- evidence.annotations$Gene
    evidence.annotations$Gene <- NULL
    evidence.annotations <- evidence.annotations[, c("Evidence", "Evidence_statement", "References", "Less"), drop = FALSE]
    names(evidence.annotations) <- c("#", "Evidence Statement", "References", "")
    table <- kable(evidence.annotations, "html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("striped", "hover", "condensed", align = "justify"))
    genes <- unique(evidence.genes)
    for (g in genes) {
      rows <- which(evidence.genes == g)
      if (length(rows) > 0) {
        rng  <- range(rows)
        table <- table %>% pack_rows(group_label = g, start_row = rng[1], end_row = rng[2], indent = FALSE)
      }
    }
    template.env$therapeutic_indications$evidences <- table
    rm(table)
  }
  
  annot.details <- get.raw.primary.annotations(all.annotations, pt_tumor)
  if (nrow(annot.details) > 0) {
    annot.details$Disease <- NULL
    annot.details$Category <- NULL
    annot.details$Var_base <- as.character(annot.details$Var_base)
    annot.details$Ref_base <- as.character(annot.details$Ref_base)
    annot.details$Var_base[is.na(annot.details$Var_base)] <- "T"
    annot.details$Ref_base[is.na(annot.details$Ref_base)] <- "T"
    annot.details <- annot.details %>% 
      arrange(Gene, Variant) %>%
      select(Gene, Variant, Chromosome, Ref_base, Var_base, Start, Stop, Variant_summary)
    annot.details <- unique(annot.details)
    annot.details <- annot.details %>% 
      group_by(Gene, Variant, Chromosome, Ref_base, Var_base, Start, Stop) %>%
      summarise(Variant_summary = paste0("<ul>", paste0("<li>", Variant_summary[trimws(Variant_summary) != ""], "</li>", collapse = ""), "</ul>")) %>% 
      arrange(Gene, Variant, Chromosome, Start, Stop) %>%
      mutate(Start = format(as.numeric(Start), big.mark=",", scientific = FALSE),
             Stop = format(as.numeric(Stop), big.mark=",", scientific = FALSE))
    
    details.genes <- annot.details$Gene
    annot.details$Gene <- NULL
    names(annot.details) <- c("Variant", "Chromosome", "Ref. Base", "Var. Base", "Start", "Stop", "Details")
    table <- kable(annot.details, "html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("striped", "hover", "condensed", align = "justify"))
    genes <- unique(details.genes)
    for (g in genes) {
      rows <- which(details.genes == g)
      if (length(rows) > 0) {
        rng  <- range(rows)
        table <- table %>% pack_rows(group_label = g, start_row = rng[1], end_row = rng[2], indent = FALSE)
      }
    }
    template.env$therapeutic_indications$details <- table
    rm(table, annot.details, details.genes, genes)
  }
} else {
  template.env$therapeutic_indications <- list(
    summary=list(clinical.impact=NULL, others=NULL),
    evidences=NULL,
    details=NULL
  )
}

brew(
  file = paste0(path_html_source, "/therapeutic.html"),
  output = paste0(report_output_dir, "therapeutic.html"),
  envir = template.env
)

recommended_drugs <- list(
  primary=unique(unlist(strsplit(primary.annotations$Drug, ","))),
  others=unique(unlist(strsplit(all.annotations$Drug, ",")))
)
recommended_drugs$others <- setdiff(recommended_drugs$others, recommended_drugs$primary)

rm(list = setdiff(ls(), .variables.to.keep))

writeLines(
  sapply(recommended_drugs, function(x)(paste0(x, collapse = ","))), 
  paste0(path_project, "/txt/", pt_fastq, "_drug.txt")
)

