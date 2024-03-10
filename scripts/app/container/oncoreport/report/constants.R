.evidence_types <- c(
  "Diagnostic", "Prognostic", "Predisposing",
  "Predictive", "Oncogenic", "Functional"
)

.evidence_list <- c(
  "Validated association", "FDA guidelines", "NCCN guidelines",
  "LEVEL_1", "LEVEL_R1", "LEVEL_2", "LEVEL_Dx1", "LEVEL_Dx2",
  "LEVEL_Px1", "LEVEL_R2", "Clinical evidence", "LEVEL_3A", "Late trials",
  "Early trials", "LEVEL_3B", "Case study", "Case report", "LEVEL_Px2",
  "LEVEL_Px3", "LEVEL_4", "LEVEL_Dx3", "Preclinical evidence",
  "Pre-clinical", "Inferential association"
)

.clinical_impact_evidences <- .evidence_list[1:11]
.other_impact_evidences <- .evidence_list[12:length(.evidence_list)]

.oncokb_levels_map <- c(
  "LEVEL_1" = "FDA-recognized (OncoKB Level 1)",
  "LEVEL_2" = "Standard care (OncoKB Level 2)",
  "LEVEL_3A" = "Compelling clinical evidence (OncoKB Level 3A)",
  "LEVEL_3B" = "Standard care or investigational (OncoKB Level 3B)",
  "LEVEL_4" = "Compelling biological evidence (OncoKB Level 4)",
  "LEVEL_Dx1" = "FDA-recognized (OncoKB Level Dx1)",
  "LEVEL_Dx2" = "Professional guideline-recognized (OncoKB Level Dx2)",
  "LEVEL_Dx3" = "Clinical evidence (OncoKB Level Dx3)",
  "LEVEL_Px1" = "FDA-recognized (OncoKB Level Px1)",
  "LEVEL_Px2" = "Professional guideline-recognized (OncoKB Level Px2)",
  "LEVEL_Px3" = "Clinical evidence (OncoKB Level Px3)",
  "LEVEL_R1" = "Standard of care (OncoKB Level R1)",
  "LEVEL_R2" = "Compelling clinical evidence (OncoKB Level R2)"
)
