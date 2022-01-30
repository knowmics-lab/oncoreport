read.diseases <- function (path_db) {
  diseases_db              <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t", stringsAsFactors = FALSE)
  colnames(diseases_db)[1] <- "Disease"
  diseases_db_simple       <- unique(diseases_db[,c("Disease", "DOID")])
  return (list(diseases_db, diseases_db_simple))
}

get.raw.primary.annotations <- function (all.annotations, pt_tumor) {
  primary.annotations <- all.annotations[all.annotations$Evidence_direction == "Supports" & 
                                           all.annotations$DOID == pt_tumor, , drop = F]
  primary.annotations$DOID <- NULL
  primary.annotations <- unique(primary.annotations) %>% distinct_at(vars(-id), .keep_all = TRUE)
  return (primary.annotations)
}

get.raw.other.annotations <- function (all.annotations, pt_tumor) {
  excluded.disease <- unique(all.annotations$Disease[all.annotations$DOID == pt_tumor])
  other.annotations <- all.annotations[all.annotations$Evidence_direction == "Supports" & 
                                           !(all.annotations$Disease %in% excluded.disease), , drop = F]
  other.annotations$DOID <- NULL
  other.annotations <- unique(other.annotations) %>% distinct_at(vars(-id), .keep_all = TRUE)
  return (other.annotations)
}

prepare.annotation <- function (all.annotations, pt_tumor, get.raw.function, ref.base="ref") {
  primary.annotations <- get.raw.function(all.annotations, pt_tumor)
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
      group_by(Disease, Database, Gene, Variant, Drug, Evidence_type, Evidence_direction, Clinical_significance, 
               Variant_summary, PMID, Citation, Chromosome, Start, Stop, Ref_base, Var_base, Type, Approved, Score, 
               Reference, id) %>%
      summarize(Evidence_level = str_c(Evidence_level, collapse = ", "), 
                Evidence_statement = str_c(Evidence_statement, collapse = ", "),
                Citation = str_c(Citation, collapse = ", "), 
                id = str_c(id, collapse = ", ")) %>%
      mutate(Evidence_level=gsub("(.*),.*", "\\1", Evidence_level),
             Evidence_statement=gsub(".,", ".", Evidence_statement)) %>%
      select(Disease, Database, Gene, Variant, Drug, Evidence_type, Evidence_level, Evidence_direction, 
             Clinical_significance, Evidence_statement, Variant_summary, PMID, Citation, Chromosome, Start, Stop,
             Ref_base, Var_base, Type, Approved, Score, Reference, id)
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
      if (nrow(df.scores) > 0) {
        df.scores <- aggregate(tot ~ Drug, df.scores, mean)
      }
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
        '<a href="Javascript:;" class="ref-link" data-id="#', ref.base,'-', 
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

build.primary.annotations <- function (all.annotations, pt_tumor) (
  prepare.annotation(all.annotations, pt_tumor, get.raw.primary.annotations)
)

build.other.annotations <- function (all.annotations, pt_tumor) (
  prepare.annotation(all.annotations, pt_tumor, get.raw.other.annotations, "off")
)
