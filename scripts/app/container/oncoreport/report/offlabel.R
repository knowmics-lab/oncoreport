cat("Building Off-label Indications File\n")

template.env$offlabel <- list(
  summary=NULL,
  evidences=NULL,
  details=NULL
)


offlabel.references <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_off.txt"), sep = "\t", 
                                stringsAsFactors = FALSE, colClasses = "character") %>%
  select(PMID, Reference) %>% distinct(PMID, .keep_all = TRUE)

offlabel.trials <- read.csv(paste0(path_project, "/txt/trial/", pt_fastq, ".txt"), sep = "\t", 
                            stringsAsFactors = FALSE)
list.all.trials    <- unique(offlabel.trials$Clinical_trial)

.variables.to.keep <- ls()
offlabel.annotations <- build.other.annotations(all.annotations, pt_tumor)
order_id <- c()
order_evidence <- c()
if (nrow(offlabel.annotations) > 0) {
  sorted_evidences <- NULL
  e.annotations <- offlabel.annotations[, c("Disease", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", 
                                            "Evidence_level", "Evidence_statement", "Type", "Reference", "Score", "AIFA", 
                                            "EMA", "FDA", "year", "id"), drop=FALSE]
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
    group_by(Disease, Gene, Evidence_level, Evidence_type, Variant, Drug, Clinical_significance, Type, Score, AIFA, 
             EMA, FDA, .add = FALSE) %>%
    summarise(Evidence_statement = paste0("<li>", Evidence_statement, "</li>", collapse = ""),
              Reference = paste(sort(Reference), collapse = ", "), year = paste(sort(year), collapse = ", "), 
              id = paste(sort(id), collapse = "-"))
  sorted_id <- e.annotations$id
  last_evidence <- 0
  
  
  es <- e.annotations[,c("Disease", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", 
                         "Evidence_level", "Type", "Evidence_statement", "Reference", "Score", "AIFA", "EMA", "FDA", 
                         "year", "id"), drop = F]
  es$Evidence <- seq_len(nrow(es))
  es$Details <- paste0('[<a href="Javascript:;" class="evidence-details-link" data-id="#det-', es$id, '">+</a>]')
  es$Details[!complete.cases(es[, c("Evidence_statement", "Reference"), drop = FALSE]) | trimws(es$Evidence_statement) == ""] <- ""
  es$Evidence <- paste0('<a id="evi-', es$id, '"></a>', es$Evidence + last_evidence)
  list.trials <- paste0("https://clinicaltrials.gov/ct2/results?cond=", es$Variant, "&term=", es$Drug, "&cntry=&state=&city=&dist=")
  es$Trials <- paste0("[", "<a href=\"", list.trials, "\" target=\"_blank\">+</a>", "]")
  es$Trials[!list.trials %in% list.all.trials] <- ""
  es$Drug <- gsub(",", ", ", es$Drug, fixed = T)
  es <- es[, c("Evidence", "Disease", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", 
               "Type", "Details", "Trials", "Evidence_statement", "Reference", "Score", "AIFA", "EMA", "FDA", "year", "id")]
  es$Score <- as.numeric(es$Score)
  assigned.colors <- assign.colors(es)
  es$Score <- round(es$Score, digits = 2)
  names(es) <- c("#", "Disease", "Gene", "Variant", "Drug", "Evidence Type", "Clinical Significance", "Evidence Level",
                 "Type", "Details", "Trials", "Evidence_statement", "References", "Score", "AIFA", "EMA", "FDA", 
                 "Publication year", "id")
  color_column <- 13
  last_evidence <<- nrow(es)
  if (nrow(es) == 0) return (NULL)
  if (is.null(sorted_evidences)) sorted_evidences <<- es
  else sorted_evidences <<- rbind(sorted_evidences, es)
  es <- es[,-which(colnames(es) %in% c("Evidence_statement", "id"))]
  table <- kable(es, "html", escape = FALSE) %>%
    kable_styling(bootstrap_options = c("striped", "hover", "condensed")) %>%
    column_spec(color_column, bold = T, color = "black", background = assigned.colors)
  diseases <- unique(es$Disease)
  if (length(diseases) > 1) {
    for (d in diseases) {
      rows <- which(es$Disease == d)
      if (length(rows) > 0) {
        rng  <- range(rows)
        table <- table %>% pack_rows(group_label = d, start_row = rng[1], end_row = rng[2], indent = FALSE)
      }
    }
  }
  template.env$offlabel$summary <- gsub("{{APPROVED}}", "&#9989;", 
                                        gsub("{{NOTAPPROVED}}", "&#10060;", as.character(table), fixed = TRUE), fixed = TRUE)
  
  evidence.annotations <- sorted_evidences[,c("Disease", "#", "Gene", "Evidence_statement", "References", "id")]
  colnames(evidence.annotations) <- c("Disease", "Evidence", "Gene", "Evidence_statement", "References", "id")
  evidence.annotations$Evidence <- gsub("evi-", "det-", evidence.annotations$Evidence, fixed = TRUE)
  evidence.annotations$Evidence_statement <- paste0("<ul>",iconv(evidence.annotations$Evidence_statement, to = "ASCII//TRANSLIT"),"</ul>")
  evidence.annotations$Less <- paste0('[<a href="Javascript:;" class="evidence-summary-link" data-id="#evi-', evidence.annotations$id , '">-</a>]')
  evidence.annotations <- evidence.annotations %>% group_by(Disease, Gene, Evidence_statement, References) %>%
    summarize(Evidence = str_c(Evidence, collapse = ", "), 
              Less = str_c(Less, collapse = ", "),
              id = str_c(id, collapse = "-"))
  evidence.annotations <- evidence.annotations[order(match(evidence.annotations$id, sorted_id)),]
  if (nrow(evidence.annotations) > 0) {
    evidence.diseases <- evidence.annotations$Disease
    evidence.annotations$Disease <- NULL
    evidence.annotations <- evidence.annotations[, c("Evidence", "Gene", "Evidence_statement", "References", "Less"), drop = FALSE]
    names(evidence.annotations) <- c("#", "Gene", "Evidence Statement", "References", "")
    table <- kable(evidence.annotations, "html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("striped", "hover", "condensed", align = "justify"))
    diseases <- unique(evidence.diseases)
    for (d in diseases) {
      rows <- which(evidence.diseases == d)
      if (length(rows) > 0) {
        rng  <- range(rows)
        table <- table %>% pack_rows(group_label = d, start_row = rng[1], end_row = rng[2], indent = FALSE)
      }
    }
    template.env$offlabel$evidences <- table
    rm(table)
  }
  
  annot.details <- get.raw.other.annotations(all.annotations, pt_tumor)
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
      mutate(Start = format(as.numeric(Start), digits=0, big.mark=",", scientific = FALSE),
             Stop = format(as.numeric(Stop), digits=0, big.mark=",", scientific = FALSE))
    
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
    template.env$offlabel$details <- table
    rm(table, annot.details, details.genes, genes)
  }
}

brew(
  file = paste0(path_html_source, "/offlabel.html"),
  output = paste0(report_output_dir, "offlabel.html"),
  envir = template.env
)

rm(list = setdiff(ls(), .variables.to.keep))



