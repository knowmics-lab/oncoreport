library(optparse)
library(dplyr)
library(tidyr)
library(kableExtra)
library(stringr)
library(brew)
library(DT)
library(htmlwidgets)

read.diseases <- function(path_db) {
  diseases_db <- read.csv(
    file.path(path_db, "diseases.tsv"),
    sep = "\t",
    stringsAsFactors = FALSE
  )
  colnames(diseases_db)[1] <- "Disease"
  diseases_db_simple <- unique(diseases_db[, c("Disease", "DOID")])
  return(list(diseases_db, diseases_db_simple))
}

get.raw.primary.annotations <- function(all_annotations, pt_tumor) {
  selection <- all_annotations$Evidence_direction == "Supports" &
    all_annotations$DOID == pt_tumor
  primary_annotations <- all_annotations[selection, , drop = FALSE]
  primary_annotations$DOID <- NULL
  primary_annotations <- unique(primary_annotations) %>%
    distinct_at(vars(-id), .keep_all = TRUE)
  return(primary_annotations)
}

get.raw.other.annotations <- function(all_annotations, pt_tumor) {
  excluded_disease <- unique(
    all_annotations$Disease[all_annotations$DOID == pt_tumor]
  )
  selection <- all_annotations$Evidence_direction == "Supports" &
    !(all_annotations$Disease %in% excluded_disease)
  other_annotations <- all_annotations[selection, , drop = FALSE]
  other_annotations$DOID <- NULL
  other_annotations <- unique(other_annotations) %>%
    distinct_at(vars(-id), .keep_all = TRUE)
  return(other_annotations)
}

prepare.annotation <- function(all_annotations, pt_tumor, therapeutic.references, get.raw.function, ref.base = "ref") {
  primary.annotations <- get.raw.function(all_annotations, pt_tumor)
  if (nrow(primary.annotations) > 0) {
    substitutes <- primary.annotations[primary.annotations$Drug_interaction_type == "Substitutes", ]
    primary.annotations <- primary.annotations[primary.annotations$Drug_interaction_type != "Substitutes", ]
    substitutes <- substitutes %>%
      mutate(Drug = strsplit(as.character(Drug), ","), Approved = strsplit(as.character(Approved), ",")) %>%
      unnest(c(Drug, Approved))
    primary.annotations <- rbind(primary.annotations, substitutes)
    primary.annotations$Drug <- gsub(", ", ",", primary.annotations$Drug, fixed = TRUE)
    primary.annotations$Drug_interaction_type <- NULL
    primary.annotations <- inner_join(primary.annotations, therapeutic.references) %>%
      arrange(Gene, Evidence_level, Evidence_type, Variant, Drug, Clinical_significance, Reference) %>%
      group_by(
        Disease, Database, Gene, Variant, Drug, Evidence_type, Evidence_direction, Clinical_significance,
        Variant_summary, PMID, Citation, Chromosome, Start, Stop, Ref_base, Var_base, Type, Approved, Score,
        Reference, id
      ) %>%
      summarize(
        Evidence_level = str_c(Evidence_level, collapse = ", "),
        Evidence_statement = str_c(Evidence_statement, collapse = ", "),
        Citation = str_c(Citation, collapse = ", "),
        id = str_c(id, collapse = ", ")
      ) %>%
      mutate(
        Evidence_level = gsub("(.*),.*", "\\1", Evidence_level),
        Evidence_statement = gsub(".,", ".", Evidence_statement)
      ) %>%
      select(
        Disease, Database, Gene, Variant, Drug, Evidence_type, Evidence_level, Evidence_direction,
        Clinical_significance, Evidence_statement, Variant_summary, PMID, Citation, Chromosome, Start, Stop,
        Ref_base, Var_base, Type, Approved, Score, Reference, id
      )
    primary.annotations$Evidence_level <- ordered(primary.annotations$Evidence_level, levels = c(
      "Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence",
      "Late trials", "Early trials", "Case study", "Case report", "Preclinical evidence",
      "Pre-clinical", "Inferential association"
    ))
    primary.annotations <- primary.annotations[order(primary.annotations$Evidence_level), ]
    primary.annotations$Approved <- mapply(function(dcount, approved) {
      if (dcount < 1) {
        return(approved)
      }
      sapproved <- unlist(strsplit(approved, ","))
      if (length(unique(sapproved)) == 1) {
        return(unique(sapproved))
      }
      agencies <- names(which(table(unlist(sapply(sapproved, function(x) (unlist(strsplit(x, "/")))))) == length(sapproved)))
      if (length(agencies) < 1) {
        return("Not approved")
      }
      return(paste0(agencies, collapse = "/"))
    }, str_count(primary.annotations$Drug, ","), primary.annotations$Approved)
    primary.annotations$Citation <- gsub("(,)\\s*([0-9]+)", "\\1 \\2,", primary.annotations$Citation)
    primary.annotations$year <- gsub(".*, (\\w+),.*", "\\1", primary.annotations$Citation)
    primary.annotations$Score <- as.numeric(primary.annotations$Score)
    current_year <- as.numeric(format(Sys.time(), "%Y"))
    primary.annotations$y_score <- sapply(
      current_year - as.numeric(primary.annotations$year),
      function(y.diff) {
        if (all(is.na(y.diff))) {
          return(0)
        }
        if (y.diff < 3) {
          return(3)
        }
        if (y.diff < 6) {
          return(2)
        }
        if (y.diff < 9) {
          return(1)
        }
        if (y.diff < 12) {
          return(0.5)
        }
        return(0)
      }
    )
    s.primary.annotations <- lapply(
      split(primary.annotations, primary.annotations$Gene),
      function(x) (unique(x[x$Drug != "", ]))
    )
    if (length(s.primary.annotations) > 1) {
      d_score <- table(unlist(lapply(s.primary.annotations, function(x) (unique(x$Drug))))) - 1
      df.d_score <- data.frame(Drug = names(d_score), d_score = as.vector(d_score))

      df.scores <- unique(primary.annotations[primary.annotations$Drug != "", c("Drug", "Score", "y_score")] %>%
        left_join(df.d_score))
      df.scores$tot <- rowSums(df.scores[, c("Score", "y_score", "d_score")])
      if (nrow(df.scores) > 0) {
        df.scores <- aggregate(tot ~ Drug, df.scores, mean)
      }
      primary.annotations <- primary.annotations %>% left_join(df.scores, by = "Drug")
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
    primary.annotations$FDA <- "{{NOTAPPROVED}}"
    primary.annotations$FDA[grepl("FDA", primary.annotations$Approved)] <- "{{APPROVED}}"
    primary.annotations$EMA <- "{{NOTAPPROVED}}"
    primary.annotations$EMA[grepl("EMA", primary.annotations$Approved)] <- "{{APPROVED}}"
    primary.annotations$Approved <- NULL
    if (nrow(primary.annotations) > 0) {
      primary.annotations$Reference <- paste0(
        '<a href="Javascript:;" class="ref-link" data-id="#', ref.base, "-",
        primary.annotations$Reference, '">', primary.annotations$Reference,
        "</a>"
      )
    }
    primary.annotations$Evidence_level <- factor(
      primary.annotations$Evidence_level,
      levels = c(
        "Validated association", "FDA guidelines", "NCCN guidelines",
        "Clinical evidence", "Late trials", "Early trials", "Case study",
        "Case report", "Preclinical evidence", "Pre-clinical",
        "Inferential association"
      )
    )
    primary.annotations <- primary.annotations[
      order(
        primary.annotations$Gene, primary.annotations$Evidence_level,
        primary.annotations$Evidence_type, primary.annotations$Variant,
        primary.annotations$Drug, primary.annotations$Clinical_significance,
        primary.annotations$Reference
      ), ,
      drop = FALSE
    ]
  }
  return(primary.annotations)
}

build.primary.annotations <- function(
    all_annotations, pt_tumor, therapeutic.references) {
  return(
    prepare.annotation(
      all_annotations, pt_tumor, therapeutic.references,
      get.raw.primary.annotations
    )
  )
}

build.other.annotations <- function(
    all_annotations, pt_tumor, therapeutic.references) {
  return(
    prepare.annotation(
      all_annotations, pt_tumor, therapeutic.references,
      get.raw.other.annotations, "off"
    )
  )
}

get.color <- function(x, start, end) {
  cl <- colorRamp(c(start, end))(x)
  return(rgb(cl[, 1], cl[, 2], cl[, 3], maxColorValue = 255))
}

make_color_gradient <- function(
    values, start_color, end_color, default_color = end_color) {
  if (length(values) == 1) {
    return(colorRampPalette(default_color)(1))
  }
  r <- range(values)
  if (r[1] == r[2]) {
    v_norm <- rep(1.0, length(values))
  } else {
    v_norm <- (values - r[1]) / (r[2] - r[1])
  }
  v_norm[is.na(v_norm)] <- 0
  return(get.color(v_norm, start_color, end_color))
}

assign.colors <- function(df) {
  green <- df$Evidence_type %in% c("Predictive", "Prognostic") &
    df$Clinical_significance %in% c(
      "Sensitivity/Response", "Responsive", "Better Outcome"
    )
  orange <- df$Evidence_type == "Diagnostic" |
    (df$Evidence_type == "Predictive" &
      df$Clinical_significance %in% "Reduced Sensitivity")
  red <- df$Evidence_type %in% c("Predictive", "Prognostic") &
    df$Clinical_significance %in% c(
      "Resistance", "Adverse Response", "Resistant", "Increased Toxicity",
      "No Responsive", "Poor Outcome"
    )
  color <- rep("#FFFFFF", nrow(df))
  if (length(which(green)) > 0) {
    color[green] <- make_color_gradient(df$Score[green], "#E6FFE6", "green")
  }
  if (length(which(orange)) > 0) {
    color[orange] <- make_color_gradient(df$Score[orange], "#FFF6E6", "orange")
  }
  if (length(which(red)) > 0) {
    color[red] <- make_color_gradient(df$Score[red], "#FFE6E6", "red")
  }
  return(color)
}
