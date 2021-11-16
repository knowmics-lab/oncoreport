get.raw.primary.annotations <- function (all.annotations, pt_tumor) {
  primary.annotations <- all.annotations[all.annotations$Evidence_direction == "Supports" & 
                                           all.annotations$DOID == pt_tumor, , drop = F]
  primary.annotations$DOID <- NULL
  primary.annotations <- unique(primary.annotations)
  return (primary.annotations)
}

build.primary.annotations <- function (all.annotations, pt_tumor) {
  primary.annotations <- get.raw.primary.annotations(all.annotations, pt_tumor)
  if (nrow(primary.annotations) > 0) {
    substitutes         <- primary.annotations[primary.annotations$Drug_interaction_type == "Substitutes",]
    primary.annotations <- primary.annotations[primary.annotations$Drug_interaction_type != "Substitutes",]
    substitutes         <- substitutes %>% 
      mutate(Drug = strsplit(as.character(Drug), ","), Approved = strsplit(as.character(Approved), ",")) %>%
      unnest(c(Drug, Approved))
    primary.annotations <- rbind(primary.annotations, substitutes)
    primary.annotations$Drug <- gsub(", ", ",", primary.annotations$Drug, fixed = TRUE)
    primary.annotations$Drug_interaction_type <- NULL
    primary.annotations <- inner_join(primary.annotations, therapeutic.references) %>%
      arrange(Gene, Evidence_level, Evidence_type, Variant, Drug, Clinical_significance, Reference) %>%
      group_by(Disease, Database, Gene, Variant, Drug, Evidence_type, Evidence_direction, Clinical_significance, Variant_summary, PMID,
               Citation, Chromosome, Start, Stop, Ref_base, Var_base, Type, Approved, Score, Reference, id) %>%
      summarize(Evidence_level = str_c(Evidence_level, collapse = ", "), Evidence_statement = str_c(Evidence_statement, collapse = ", "),
                Citation = str_c(Citation, collapse = ", "), id = str_c(id, collapse = ", "))
    primary.annotations$Evidence_level <- gsub("(.*),.*", "\\1", primary.annotations$Evidence_level)
    primary.annotations$Evidence_statement <- gsub(".,", ".", primary.annotations$Evidence_statement)
    primary.annotations <- primary.annotations[, c(
      "Disease", "Database", "Gene", "Variant", "Drug", "Evidence_type", 
      "Evidence_level", "Evidence_direction", "Clinical_significance", 
      "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome", 
      "Start", "Stop", "Ref_base", "Var_base", "Type", "Approved", "Score", 
      "Reference", "id")]
    primary.annotations$Evidence_level <- ordered(primary.annotations$Evidence_level, levels = c(
      "Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence", 
      "Late trials", "Early trials", "Case study", "Case report", "Preclinical evidence", 
      "Pre-clinical", "Inferential association"))
    primary.annotations <- primary.annotations[order(primary.annotations$Evidence_level),]
    primary.annotations$Approved <- mapply(function (dcount, approved) {
      if (dcount < 1) return(approved)
      sapproved <- unlist(strsplit(approved, ","))
      if (length(unique(sapproved)) == 1) return (unique(sapproved))
      agencies <- names(which(table(unlist(sapply(sapproved, function(x)(unlist(strsplit(x, "/")))))) == length(sapproved)))
      if (length(agencies) < 1) return ("Not approved")
      return (paste0(agencies, collapse = "/"))
    }, str_count(primary.annotations$Drug, ","), primary.annotations$Approved)
    primary.annotations$Citation   <- gsub("(,)([0-9]+)", "\\1 \\2,", primary.annotations$Citation)
    primary.annotations$year       <- gsub(".*, (\\w+),.*", "\\1", primary.annotations$Citation)
    primary.annotations$Score      <- as.numeric(primary.annotations$Score)
    current_year                   <- as.numeric(format(Sys.time(), "%Y"))
    primary.annotations$y_score    <- sapply(
      current_year - as.numeric(primary.annotations$year), 
      function(y.diff) {
        if (y.diff < 3) return (3)
        if (y.diff < 6) return (2)
        if (y.diff < 9) return (1)
        if (y.diff < 12) return (0.5)
        return (0)
      }
    )
    s.primary.annotations <- lapply(
      split(primary.annotations, primary.annotations$Gene), 
      function (x) (unique(x[x$Drug != "",]))
    )
    if (length(s.primary.annotations) > 1) {
      d_score <- table(unlist(lapply(s.primary.annotations, function(x)(unique(x$Drug))))) - 1
      df.d_score <- data.frame(Drug=names(d_score), d_score=as.vector(d_score))
      
      df.scores <- unique(primary.annotations[primary.annotations$Drug != "", c("Drug", "Score", "y_score")] %>% 
                            left_join(df.d_score))
      df.scores$tot <- rowSums(df.scores[, c("Score", "y_score", "d_score")])
      df.scores <- aggregate(tot ~ Drug, df.scores, mean)
      primary.annotations <- primary.annotations %>% left_join(df.scores, by="Drug")
    } else {
      primary.annotations$tot <- rowSums(primary.annotations[, c("Score", "y_score")])
    }
    primary.annotations$Score <- NULL
    primary.annotations$y_score <- NULL
    colnames(primary.annotations)[colnames(primary.annotations) == "tot"] <- "Score"
    primary.annotations$Score[is.na(primary.annotations$Score)] <- 0
    primary.annotations <- unique(
      primary.annotations %>%
        rowwise() %>%
        mutate(Drug = paste(sort(unlist(strsplit(Drug, ",", fixed = TRUE))), collapse = ","))
    )
    primary.annotations$AIFA <- "{{NOTAPPROVED}}"
    primary.annotations$AIFA[grepl("AIFA", primary.annotations$Approved)] <- "{{APPROVED}}"
    primary.annotations$FDA  <- "{{NOTAPPROVED}}"
    primary.annotations$FDA[grepl("FDA", primary.annotations$Approved)] <- "{{APPROVED}}"
    primary.annotations$EMA  <- "{{NOTAPPROVED}}"
    primary.annotations$EMA[grepl("EMA", primary.annotations$Approved)] <- "{{APPROVED}}"
    primary.annotations$Approved <- NULL
    if (nrow(primary.annotations) > 0) {
      primary.annotations$Reference <- paste0(
        '<a href="Javascript:;" class="ref-link" data-id="#ref-', 
        primary.annotations$Reference, '">', primary.annotations$Reference, 
        '</a>'
      )
    }
    primary.annotations$Evidence_level <- factor(
      primary.annotations$Evidence_level, 
      levels = c("Validated association", "FDA guidelines", "NCCN guidelines", 
                 "Clinical evidence", "Late trials", "Early trials", "Case study", 
                 "Case report", "Preclinical evidence", "Pre-clinical", 
                 "Inferential association")
    )
    primary.annotations <- primary.annotations[
      order(primary.annotations$Gene, primary.annotations$Evidence_level, 
            primary.annotations$Evidence_type, primary.annotations$Variant, 
            primary.annotations$Drug, primary.annotations$Clinical_significance, 
            primary.annotations$Reference),,drop=FALSE]
  }
  return (primary.annotations)
}

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
all.annotations$id <- 1:nrow(all.annotations)

.variables.to.keep <- ls()
order_id <- c()
order_evidence <- c()

primary.annotations <- build.primary.annotations(all.annotations, pt_tumor)
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
    e.annotations <- e.annotations %>% 
      inner_join(aggregate(Score ~ ., data = e.annotations.clean, FUN = mean)) %>%
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
    es$Evidence <- 1:nrow(es)
    es$Details <- paste0('[<a href="Javascript:;" class="evidence-details-link" data-id="#det-', es$id, '-', es$Evidence, '">+</a>]')
    es$Details[!complete.cases(es[, c("Evidence_statement", "Reference"), drop = FALSE]) | trimws(es$Evidence_statement) == ""] <- ""
    es$Evidence <- paste0('<a id="evi-', es$id, '"></a>', es$Evidence + last_evidence)
    list.trials <- paste0("https://clinicaltrials.gov/ct2/results?cond=", es$Variant, "&term=", es$Drug, "&cntry=&state=&city=&dist=")
    es$Trials <- paste0("[", "<a href=\"", list.trials, "\">+</a>", "]")
    es$Trials[!list.trials %in% list.all.trials] <- ""
    es$Drug <- gsub(",", ", ", es$Drug, fixed = T)
    es <- es[, c("Evidence", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", 
                 "Type", "Details", "Trials", "Evidence_statement", "Reference", "Score", "AIFA", "EMA", "FDA", "year", "id")]
    colfunc  <- colorRampPalette(c("green", "yellow", "red"))
    es$Score <- as.numeric(es$Score)
    es$Score <- round(es$Score, digits = 2)
    scores        <- es$Score
    sorted.scores <- sort(scores, decreasing = TRUE)
    unique.scores <- unique(sorted.scores)
    scores.colors <- setNames(colfunc(length(unique.scores)), as.character(unique.scores))
    assigned.colors <- unname(scores.colors[as.character(scores)])
    names(es) <- c("#", "Gene", "Variant", "Drug", "Evidence Type", "Clinical Significance", "Evidence Level", "Type", 
                   "Details", "Trials", "Evidence_statement", "References", "Score", "AIFA", "EMA", "FDA", 
                   "Publication year", "id")
    if (tumor_type == "tumnorm") {
      es$Type <- NULL
    }
    last_evidence <<- nrow(es)
    if (nrow(es) == 0) return (NULL)
    if (is.null(sorted_evidences)) sorted_evidences <<- es
    else sorted_evidences <<- rbind(sorted_evidences, es)
    es <- es[,-which(colnames(es) %in% c("Evidence_statement", "id"))]
    table <- kable(es, "html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("striped", "hover")) %>%
      column_spec(11, bold = T, color = "black", background = assigned.colors)
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
      kable_styling(bootstrap_options = c("striped", "hover", align = "justify"))
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
      summarise(Variant_summary = paste0("<ul>", paste0("<li>", Variant_summary, "</li>", collapse = ""), "</ul>")) %>% 
      arrange(Gene, Variant, Chromosome, Start, Stop) %>%
      mutate(Start = format(as.numeric(Start), digits=0, big.mark=",", scientific = FALSE), 
             Stop = format(as.numeric(Stop), digits=0, big.mark=",", scientific = FALSE))
    
    details.genes <- annot.details$Gene
    annot.details$Gene <- NULL
    names(annot.details) <- c("Variant", "Chromosome", "Ref. Base", "Var. Base", "Start", "Stop", "Details")
    table <- kable(annot.details, "html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("striped", "hover", align = "justify"))
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

rm(list = setdiff(ls(), .variables.to.keep))
