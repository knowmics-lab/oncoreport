
---
title: <a id="Mutation Report"></a> <center> <h1>Mutation Report</h1> </center>
output:
  html_document:
    toc: true
    toc_float: true
---


 Patient information
=====================================================

```{r Patient_Information, echo=FALSE, message=FALSE, warning=FALSE, cache=FALSE}
##Patient information
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
pat<-data.frame(Name=args[1],Surname= args[2], ID=args[3],Gender=args[4], Age=args[5], Sample="Tumor and Blood Biopsy", Tumor=args[6] )
kable(pat) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive"))
```

## Detected variant therapeutic benefit  {.tabset}

### Variant Mutation

```{r Variant_Mutation, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
##Mutations information
library(knitr)
library(kableExtra)
library(dplyr)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({x<-read.csv(paste0("/definitive/",args[7], ".txt"), sep= "\t")
#farm <- read.csv("/Users/Grete/Documents/Farmaci/classe_a_c_h.txt", sep="\t")
#colnames(farm)[1] <- "Drug"
#x <- merge(farm, x, by= "Drug", all.y=TRUE)
dis<-read.csv("./Disease.txt", sep= "\t")
attach(x)
x<- merge(dis, x, by= "Disease")
x$Disease <- NULL
colnames(x)[1] <- "Disease"
x$Var_base <- as.character(x$Var_base)
x$Ref_base<-as.character(x$Ref_base)
  for(k in 1:length(x$Var_base)){
    if (is.na(x$Var_base[k])){
      x$Var_base[k] <- "T"
    }
  }
  for(q in 1:length(x$Ref_base)){
    if (is.na(x$Ref_base[q])){
      x$Ref_base[k] <- "T"
    }
  }
x <- sapply(x, as.character)
x[is.na(x)] <- " "
x <- as.data.frame(x)
x<-subset.data.frame(x,subset = x$Evidence_direction=="Supports")
x <- subset.data.frame(x,subset = x$Disease==args[6])
x$Drug <- as.character(x$Drug , levels=(x$Drug))
x<-x[order(x$Drug), ]
x$Evidence_type  <- factor(x$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
x<-x[order(x$Evidence_type), ]
x$Evidence_level  <- factor(x$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
x<-x[order(x$Evidence_level), ]
x$Disease <- as.character(x$Disease , levels=(x$Disease))
x<-x[order(x$Disease), ]
x<-data.frame(x, Reference=1:length(x$Disease))
row.names(x)<-NULL
hgx<-split(x, paste(x$Gene, x$Variant, x$Disease==args[6]))
  xa<-hgx[1:length(hgx)]
for (n in xa){
    n<-subset.data.frame(n,subset = n$Evidence_direction=="Supports")
    if (dim(n)[1]!=0){
      cat("  \n#### Gene",  as.character(n$Gene)[1],as.character(n$Disease[1]), " \n")
      n$Drug  <- as.character(n$Drug , levels =(n$Drug))
n<-n[order(n$Drug), ]
      n$Evidence_type  <- factor(n$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
n<-n[order(n$Evidence_type), ]
      n$Evidence_level  <- factor(n$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
n<-n[order(n$Evidence_level), ]
s<- gsub(",([A-Za-z])", " ,\\1", n$Drug)
n["Drug"]<-s
s1<- gsub(" ", "", n$Drug)
n["Drug"]<-s1
s2<- gsub(" ", "", n$Drug_interaction_type)
n["Drug_interaction_type"]<-s2
n<-subset(n, select= c(Variant, Drug, Drug_interaction_type, Evidence_type, Clinical_significance, Evidence_level, Reference)) #Clinical_trial
row.names(n)<-NULL
for(i in 1:(length(n$Drug)-1)){
if (n$Drug[i]==n$Drug[i+1] & n$Drug_interaction_type[i]==n$Drug_interaction_type[i+1] &
    n$Clinical_significance[i]==n$Clinical_significance[i+1]& n$Evidence_type[i]==n$Evidence_type[i+1]
    & n$Evidence_level[i]==n$Evidence_level[i+1]){
    n$Reference[i]<- paste0(n$Reference[i],",",n$Reference[i+1])
    n$Reference[i+1]<-gsub(n$Reference[i+1],pattern="[0-9]",replace=" ")
    n$Reference[i+1]<- (n$Reference[i])
    i <- i+1
}}
for(p in length(n$Drug):2){
  if (n$Drug[p]==n$Drug[p-1] & n$Drug_interaction_type[p]==n$Drug_interaction_type[p-1] &
      n$Clinical_significance[p]==n$Clinical_significance[p-1]& n$Evidence_type[p]==n$Evidence_type[p-1]
      & n$Evidence_level[p]==n$Evidence_level[p-1]){
    n$Reference[p-1]<-gsub(n$Reference[p-1],pattern="[0-9]",replace=" ")
    n$Reference[p-1]<- (n$Reference[p])
    p <- p-1
  }}
n <- unique(n)
row.names(n) <- NULL
print(kable(n) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))
}else next()
  }
  }, silent = TRUE)
```

### Details
```{r Lead_disease_details, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
##Mutations information
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({x<-read.csv(paste0("/definitive/",args[7], ".txt"), sep= "\t")
dis<-read.csv("./Disease.txt", sep= "\t")
attach(x)
x<- merge(dis, x, by= "Disease")
x$Disease <- NULL
colnames(x)[1] <- "Disease"
x$Var_base <- as.character(x$Var_base)
x$Ref_base<-as.character(x$Ref_base)
  for(k in 1:length(x$Var_base)){
    if (is.na(x$Var_base[k])){
      x$Var_base[k] <- "T"
    }
  }
  for(q in 1:length(x$Ref_base)){
    if (is.na(x$Ref_base[q])){
      x$Ref_base[k] <- "T"
    }
  }
x <- sapply(x, as.character)
x[is.na(x)] <- " "
x <- as.data.frame(x)
x<-subset.data.frame(x,subset = x$Evidence_direction=="Supports")
x <- subset.data.frame(x,subset = x$Disease==args[6])
x$Drug <- as.character(x$Drug , levels=(x$Drug))
x<-x[order(x$Drug), ]
x$Evidence_type  <- factor(x$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
x<-x[order(x$Evidence_type), ]
x$Evidence_level  <- factor(x$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
x<-x[order(x$Evidence_level), ]
x$Disease <- as.character(x$Disease , levels=(x$Disease))
x<-x[order(x$Disease), ]
x<-data.frame(x, Reference=1:length(x$Disease))
row.names(x)<-NULL
hgx<-split(x, paste(x$Gene, x$Variant, x$Disease==args[6]))
  xa<-hgx[1:length(hgx)]
  for (n in xa){
    n<-subset.data.frame(n,subset = n$Evidence_direction=="Supports")
    if (dim(n)[1]!=0){
      row.names(n)<-NULL
      cat("  \n#### Gene",  as.character(n$Gene)[1], " \n")
      n$Drug <- as.character(n$Drug , levels=(n$Drug))
n<-n[order(n$Drug), ]
      n$Evidence_type  <- factor(n$Evidence_type , levels = c("Diagnostic", "Prognostic","Predictive"))
n<-n[order(n$Evidence_type), ]
n$Evidence_level  <- factor(n$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
n<-n[order(n$Evidence_level), ]
ya<-subset(n, select= c(Variant, Chromosome, Ref_base, Var_base, Start, Stop))
row.names(ya)<-NULL
print(kable(ya[1,]) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))
if(!is.na(n$Evidence_statement)[1]){
  yb<-subset(n, select= c(Evidence_statement, Reference))
  yb<-yb[complete.cases(yb),]
  yb<- yb[!(yb$Evidence_statement == " "), ]
  row.names(yb)<-NULL
     print(kable(yb) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive", align="justify")))}
if(!is.na(n$Variant_summary)[1]){
  yc<-subset(n, select= c(Variant_summary))
  yc <- data.frame(yc[1,])
  colnames(yc)[1]<-"Variant_summary"
    print(kable(yc) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))}
    }}
   }, silent = TRUE)
```


### Clinical Trials
```{r leading_disease_clinical_trials, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
args=commandArgs(trailingOnly = TRUE)
library(dplyr)
library(knitr)
library(kableExtra)
try({xurls<-read.csv(paste0("/Trial/", args[7],".txt"), sep= "\t")
  if(!is.na(xurls$Drug)){
xurls <- xurls[!(xurls$Drug == ""), ]
xurls <- xurls[!(xurls$Drug == " "), ]

cat("  \n####",  as.character(xurls$Gene)[1], as.character(xurls$Variant)[1], " \n")
urls1 <- subset(xurls, select=c(Clinical_trial, Reference))

print(urls1 %>%
  mutate(Clinical_trial = cell_spec(xurls$Drug, "html", link = Clinical_trial)) %>%
  kable("html", escape = FALSE) %>%
  kable_styling(bootstrap_options = c("hover", "condensed")))
  }else {
 cat("  \n####",  as.character(xurls$Gene)[1], as.character(xurls$Variant)[1], " \n")
urls1 <- subset(xurls, select=c(Clinical_trial, Reference))
print(urls1 %>%
  mutate(Clinical_trial = cell_spec(xurls$Gene, "html", link = Clinical_trial)) %>%
  kable("html", escape = FALSE) %>%
  kable_styling(bootstrap_options = c("hover", "condensed"))) 
}
}, silent = TRUE)
```

## PharmGKB variant {.tabset}

### Variant Mutation
```{r pharm_variant, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
##Mutations information
library(knitr)
library(kableExtra)
library(dplyr)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({x<-read.csv(paste0("/txt_pharm/results/",args[7],"/", args[7],".txt"), sep= "\t")
#farm <- read.csv("/Users/Grete/Documents/Farmaci/classe_a_c_h.txt", sep="\t")
#colnames(farm)[1] <- "Drug"
#x <- merge(farm, x, by= "Drug", all.y=TRUE)
x <- sapply(x, as.character)
x[is.na(x)] <- " "
x <- as.data.frame(x)
x$Drug <- as.character(x$Drug , levels=(x$Drug))
x<-x[order(x$Drug), ]
x$Gene <- as.character(x$Gene , levels=(x$Gene))
x<-x[order(x$Gene), ]
x<-data.frame(x, Reference=1:length(x$Drug))
row.names(x)<-NULL
hgx<-split(x, paste(x$Gene))
  xa<-hgx[1:length(hgx)]
  x$Clinical_significance<-gsub(pattern=" ", replace="",x$Clinical_significance)
for (n in xa){
    if (dim(n)[1]!=0){
      cat("  \n#### Gene",  as.character(n$Gene)[1], " \n")
      n$Drug  <- as.character(n$Drug , levels =(n$Drug))
n<-subset(n, select= c(Variant, Drug, Clinical_significance, Reference))
row.names(n)<-NULL
if(length(n$Drug)>1){
for(i in 1:(length(n$Drug)-1)){
if (n$Drug[i]==n$Drug[i+1] &
    n$Clinical_significance[i]==n$Clinical_significance[i+1]
    & n$Variant[i]==n$Variant[i+1]){
    n$Reference[i]<- paste0(n$Reference[i],",",n$Reference[i+1])
    n$Reference[i+1]<-gsub(n$Reference[i+1],pattern="[0-9]",replace=" ")
    n$Reference[i+1]<- (n$Reference[i])
    i <- i+1
}}
for(p in length(n$Drug):2){
  if (n$Drug[p]==n$Drug[p-1] &
    n$Clinical_significance[p]==n$Clinical_significance[p-1]
    & n$Variant[p]==n$Variant[p-1]){
    n$Reference[p-1]<-gsub(n$Reference[p-1],pattern="[0-9]",replace=" ")
    n$Reference[p-1]<- (n$Reference[p])
    p <- p-1
  }}}
n <- unique(n)
row.names(n) <- NULL
print(kable(n) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))
} else next()
}
  }, silent = TRUE)
```

### Details

```{r pharm_variant_details, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
##Mutations information
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({x<-read.csv(paste0("/txt_pharm/results/",args[7],"/", args[7],".txt"), sep= "\t")
x <- sapply(x, as.character)
x[is.na(x)] <- " "
x <- as.data.frame(x)
x$Drug <- as.character(x$Drug , levels=(x$Drug))
x<-x[order(x$Drug), ]
x$Gene <- as.character(x$Gene , levels=(x$Gene))
x<-x[order(x$Gene), ]
x<-data.frame(x, Reference=1:length(x$Drug))
x$Var_base<-as.character(x$Var_base)
x$Ref_base<-as.character(x$Ref_base)
  for(k in 1:length(x$Var_base)){
    if (is.na(x$Var_base[k])){
      x$Var_base[k] <- "T"
    }
  }
  for(q in 1:length(x$Ref_base)){
    if (is.na(x$Ref_base[q])){
      x$Ref_base[k] <- "T"
    }
  }
row.names(x)<-NULL
hgx<-split(x, paste(x$Gene))
  xa<-hgx[1:length(hgx)]
  #i=1
for (n in xa){
    if (dim(n)[1]!=0){
      row.names(n)<-NULL
      cat("  \n#### Gene",  as.character(n$Gene)[1], " \n")
      n$Drug <- as.character(n$Drug , levels=(n$Drug))
n<-n[order(n$Drug), ]
ya<-subset(n, select= c(Variant, Chromosome, Ref_base, Var_base, Start, Stop))
row.names(ya)<-NULL
print(kable(ya[1,]) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))
if((is.na(n$Evidence_statement))==FALSE){
  yb<-subset(n, select= c(Evidence_statement, Reference))
  yb<-yb[complete.cases(yb),]
  yb<- yb[!(yb$Evidence_statement == " "), ]
  row.names(yb)<-NULL
     print(kable(yb) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive", align="justify")))}
if((is.na(n$Variant_summary))==FALSE){
  yc<-subset(n, select= c(Variant_summary))
  yc <- data.frame(yc[1,])
  colnames(yc)[1]<-"Variant_summary"
    print(kable(yc) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))}
    }}
  }, silent = TRUE)
```


## Mutations' annotations
```{r mut_annotations, echo=FALSE, message=FALSE, warning=FALSE}
library(knitr)
library(kableExtra)
args=commandArgs(trailingOnly = TRUE)
try({xref<-read.csv(paste0("/txt_refgene/",args[7],".txt"), sep= "\t")
xclin<-read.csv(paste0("/txt_clinvar/",args[7],".txt"), sep="\t")
xcr<-merge(xref,xclin, all.x=TRUE)
xcr <- format.data.frame(xcr, digits = NULL, na.encode = FALSE)
xcr[is.na(xcr)] <- " "
names(xcr)[5]<- "Gene"
names(xcr)[6]<- "Change Type"
names(xcr)[7]<- "Clinical significance"
rownames(xcr)<-NULL
kable(xcr) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive"), font_size=10)%>%
column_spec(1, bold = T, border_right = T)
}, silent = TRUE)
```

## Off labels Drug  {.tabset}

### Variant Mutation
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
##Mutations information
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({x<-read.csv(paste0("/definitive/",args[7],".txt"), sep= "\t")
dis<-read.csv("./Disease.txt", sep= "\t")
attach(x)
x<- merge(dis, x, by= "Disease")
x$Disease <- NULL
colnames(x)[1] <- "Disease"
x$Var_base <- as.character(x$Var_base)
x$Ref_base <- as.character(x$Ref_base)
for(k in 1:length(x$Var_base)){
    if (is.na(x$Var_base[k])){
      x$Var_base[k] <- "T"
    }
  }
  for(q in 1:length(x$Ref_base)){
    if (is.na(x$Ref_base[q])){
      x$Ref_base[k] <- "T"
    }
  }
x <- sapply(x, as.character)
x[is.na(x)] <- " "
x <- as.data.frame(x)
x<-subset.data.frame(x,subset = x$Evidence_direction=="Supports")
   x <- subset.data.frame(x,subset = x$Disease!=args[6])
      row.names(x)<-NULL
x$Drug <- as.character(x$Drug , levels=(x$Drug))
x<-x[order(x$Drug), ]
x$Evidence_type  <- factor(x$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
x<-x[order(x$Evidence_type), ]
x$Evidence_level  <- factor(x$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
x<-x[order(x$Evidence_level), ]
x$Disease <- as.character(x$Disease , levels=(x$Disease))
x<-x[order(x$Disease), ]
x<-data.frame(x, Reference=1:length(x$Disease))
hgx<-split(x, paste(x$Gene, x$Variant, x$Disease!=args[6]))
  xa<-hgx[1:length(hgx)]
  df_total = data.frame()
for (n in xa){
    if (dim(n)[1]!=0){
s<- gsub(",([A-Za-z])", ", \\1", n$Drug)
n["Drug"]<-s
n<-subset(n, select= c(Gene,Variant, Drug, Drug_interaction_type, Evidence_type, Clinical_significance, Evidence_level, Disease, Reference))
df <- data.frame(n)
row.names(df)<-NULL
    df_total <- rbind(df_total,df)
}else next()
  }
df_total$Drug <- as.character(df_total$Drug , levels=(df_total$Drug))
df_total<-df_total[order(df_total$Drug), ]
df_total$Evidence_level  <- factor(df_total$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
df_total<-df_total[order(df_total$Evidence_level), ]
df_total$Evidence_type  <- factor(df_total$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
df_total<-df_total[order(df_total$Evidence_type), ]
df_total$Disease <- as.character(df_total$Disease , levels=(df_total$Disease))
df_total<-df_total[order(df_total$Disease), ]
#df_total<-data.frame(df_total, Reference=1:length(df_total$Gene))
for(i in 1:(length(df_total$Drug)-1)){
if (df_total$Drug[i]==df_total$Drug[i+1] & df_total$Drug_interaction_type[i]==df_total$Drug_interaction_type[i+1] &
    df_total$Clinical_significance[i]==df_total$Clinical_significance[i+1]& df_total$Disease[i]==df_total$Disease[i+1]
    & df_total$Evidence_level[i]==df_total$Evidence_level[i+1]){
    df_total$Reference[i]<- paste0(df_total$Reference[i],",",df_total$Reference[i+1])
    df_total$Reference[i+1]<-gsub(df_total$Reference[i+1],pattern="[0-9]",replace=" ")
    df_total$Reference[i+1]<- (df_total$Reference[i])
    #df_total <-df_total[-c(i+1),]
    i <- i+1
}}
for(i in length(df_total$Drug):2){
  if (df_total$Drug[i]==df_total$Drug[i-1] & df_total$Drug_interaction_type[i]==df_total$Drug_interaction_type[i-1] &
      df_total$Clinical_significance[i]==df_total$Clinical_significance[i-1]& df_total$Disease[i]==df_total$Disease[i-1]
      & df_total$Evidence_level[i]==df_total$Evidence_level[i-1]){
    df_total$Reference[i-1]<-gsub(df_total$Reference[i-1],pattern="[0-9]",replace=" ")
    df_total$Reference[i-1]<- (df_total$Reference[i])
    i <- i-1
  }}
df_total <- unique(df_total)
row.names(df_total)<-NULL
df_total$Reference <- paste0(df_total$Reference,"a")
df_total1<-subset(df_total, select= c(Gene,Variant, Drug, Evidence_type, Clinical_significance, Evidence_level, Reference))
t <- kable(df_total1) %>%
kable_styling(bootstrap_options = c("striped","hover","responsive"))
df_total$Disease <- as.factor(df_total$Disease)
lvl <- levels(df_total$Disease)
for (l in lvl) {
  a <- which(df_total$Disease == l)
  if (length(a) == 0) next()
  t <- t %>% pack_rows(l, min(a), max(a), indent=FALSE)
}
print(t)
}, silent = TRUE)
```

### Details
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
##Mutations information
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({x<-read.csv(paste0("/definitive/", args[7],".txt"), sep= "\t")
dis<-read.csv("./Disease.txt", sep= "\t")
attach(x)
x<- merge(dis, x, by= "Disease")
x$Disease <- NULL
colnames(x)[1] <- "Disease"
x$Var_base <- as.character(x$Var_base)
x$Ref_base<-as.character(x$Ref_base)
  for(k in 1:length(x$Var_base)){
    if (is.na(x$Var_base[k])){
      x$Var_base[k] <- "T"
    }
  }
  for(q in 1:length(x$Ref_base)){
    if (is.na(x$Ref_base[q])){
      x$Ref_base[k] <- "T"
    }
  }
x <- sapply(x, as.character)
x[is.na(x)] <- " "
x <- as.data.frame(x)
   x<-subset.data.frame(x,subset = x$Evidence_direction=="Supports")
   x <- subset.data.frame(x,subset = x$Disease!=args[6])
      row.names(x)<-NULL
      x$Drug <- as.character(x$Drug , levels=(x$Drug))
x<-x[order(x$Drug), ]
      x$Evidence_type  <- factor(x$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
x<-x[order(x$Evidence_type), ]
x$Evidence_level  <- factor(x$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
x<-x[order(x$Evidence_level), ]
x$Disease <- as.character(x$Disease , levels=(x$Disease))
x<-x[order(x$Disease), ]
x<-data.frame(x, paste0(Reference=1:length(x$Disease),"a"))
colnames(x)[20] <- "Reference"
hgx<-split(x, paste(x$Gene, x$Variant))
  xa<-hgx[1:length(hgx)]
  #i=1
d1 <- data.frame()
d2 <- data.frame()
d4 <- data.frame()
for (n in xa){
    n<-subset.data.frame(n,subset = n$Evidence_direction=="Supports")
    if (dim(n)[1]!=0){
      row.names(n)<-NULL
n$Evidence_type  <- factor(n$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
n<-n[order(n$Evidence_type), ]
n$Evidence_level  <- factor(n$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
n<-n[order(n$Evidence_level), ]
n$Disease <- as.character(n$Disease , levels=(n$Disease))
n<-n[order(n$Disease), ]
ya<-subset(n, select= c(Gene,Variant, Chromosome, Ref_base, Var_base, Start, Stop))
row.names(ya)<-NULL
df1 <- data.frame(ya)
d1 <- rbind(df1,d1)

for (i in 1:length(n$Evidence_statement)){
if(!is.na(n$Evidence_statement)[i]){
  yb<-data.frame("Evidence_statement"=n$Evidence_statement[i], "Disease"=n$Disease[i], "Reference"=n$Reference[i])
  yb<-yb[complete.cases(yb),]
  yb <- yb[!(yb$Evidence_statement == " "), ]
  yb <- yb[!(yb$Evidence_statement == ""), ]
  row.names(yb)<-NULL
  #df2 <- data.frame(yb)
  d2 <- rbind(d2,yb)
}else next()
}
yd <- data.frame()
for (i in length(n$Variant_summary)){
if(n$Variant_summary[i]== " "){ next()
}else{ df <- data.frame(n$Variant_summary[i], n$Gene[i])
yc <- rbind(yd,df)
}
  df4 <- data.frame(yc)
  d4 <- rbind(d4,yc)
}}}
d1<- unique(d1)
row.names(d1)<- NULL
print(kable(d1) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))

d2$Disease <- as.character(d2$Disease , levels=(d2$Disease))
d2<-d2[order(d2$Disease), ]
d3<-subset(d2, select= c(Evidence_statement, Reference))
row.names(d3) <- NULL
t <- kable(d3) %>%
kable_styling(bootstrap_options = c("striped","hover","responsive"))
d2$Disease <- as.factor(d2$Disease)
lvl <- levels(d2$Disease)
for (l in lvl) {
  a <- which(d2$Disease == l)
  if (length(a) == 0) next()
  t <- t %>% pack_rows(l, min(a), max(a), indent=FALSE)
}
print(t)

colnames(d4)[1]<-"Variant_summary"
colnames(d4)[2]<-"Gene"
d5<-subset(d4, select= "Variant_summary")
u <- kable(d5) %>%
kable_styling(bootstrap_options = c("striped","hover","responsive"))
d4$Gene <- as.factor(d4$Gene)
lvl <- levels(d4$Gene)
for (l in lvl) {
  a <- which(d4$Gene == l)
  if (length(a) == 0) next()
  u <- u %>% pack_rows(l, min(a), max(a), indent=FALSE)
}
print(u)
}, silent = TRUE)
```

### Clinical Trials off labels
```{r Clinical Trials off labels, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
args=commandArgs(trailingOnly = TRUE)
library(dplyr)
library(knitr)
library(kableExtra)
try({urls<-read.csv(paste0("/Trial/", args[7],"_off.txt"), sep= "\t")
  if(!is.na(urls$Drug)){
urls <- urls[!(urls$Drug == ""), ]
urls <- urls[!(urls$Drug == " "), ]

cat("  \n####",  as.character(urls$Gene)[1], as.character(urls$Variant)[1], " \n")
urls1 <- subset(urls, select=c(Clinical_trial, Reference))

print(urls1 %>%
  mutate(Clinical_trial = cell_spec(urls$Drug, "html", link = Clinical_trial)) %>%
  kable("html", escape = FALSE) %>%
  kable_styling(bootstrap_options = c("hover", "condensed")))
  }else {
 cat("  \n####",  as.character(urls$Gene)[1], as.character(urls$Variant)[1], " \n")
urls1 <- subset(urls, select=c(Clinical_trial, Reference))
print(urls1 %>%
  mutate(Clinical_trial = cell_spec(urls$Gene, "html", link = Clinical_trial)) %>%
  kable("html", escape = FALSE) %>%
  kable_styling(bootstrap_options = c("hover", "condensed"))) 
}
}, silent = TRUE)
```


## Cosmic {.tabset}
### Drug resistant mutations
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
##Mutations information
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({cosm<-read.csv(paste0("/txt_cosmic/results/",args[7],"/",args[7],".txt"), sep= "\t")
attach(cosm)
hgx<-split(cosm, paste(cosm$Gene, cosm$Variant))
  xa<-hgx[1:length(hgx)]
  i=1
for (n in xa){
    if (dim(n)[1]!=0){
      cat("  \n#### Gene",  as.character(n$Gene)[1], " \n")
n<-data.frame(n, Reference=1:length(n$Gene))
n<-subset(n, select= c(Variant, Drug, Primary.Tissue, Reference))
for(i in 1:(length(n$Drug)-1)){
if (n$Drug[i]==n$Drug[i+1] & n$Primary.Tissue[i]==n$Primary.Tissue[i+1] &
    n$Variant[i]==n$Variant[i+1]){
    n$Reference[i]<- paste0(n$Reference[i],",",n$Reference[i+1])
    n$Reference[i+1]<-gsub(n$Reference[i+1],pattern="[0-9]",replace=" ")
    n$Reference[i+1]<- (n$Reference[i])
    i <- i+1
}}
for(p in length(n$Drug):2){
  if (n$Drug[p]==n$Drug[p-1] & n$Primary.Tissue[p]==n$Primary.Tissue[p-1] &
      n$Variant[p]==n$Variant[p-1]){
    n$Reference[p-1]<-gsub(n$Reference[p-1],pattern="[0-9]",replace=" ")
    n$Reference[p-1]<- (n$Reference[p])
    p <- p-1
  }}
n <- unique(n)
row.names(n)<-NULL
print(kable(n) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))
i<-i+1
    }}
  }, silent = TRUE)

```


### Details
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
##Mutations information
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({x<-read.csv(paste0("/txt_cosmic/results/",args[7],"/", args[7],".txt"), sep= "\t")
x$Var_base <- as.character(x$Var_base)
x$Ref_base<-as.character(x$Ref_base)
  for(k in 1:length(x$Var_base)){
    if (is.na(x$Var_base[k])){
      x$Var_base[k] <- "T"
    }
  }
  for(q in 1:length(x$Ref_base)){
    if (is.na(x$Ref_base[q])){
      x$Ref_base[k] <- "T"
    }
  }
attach(x)
hgx<-split(x, paste(x$Gene, x$Variant))
  xa<-hgx[1:length(hgx)]
  i=1
for (n in xa){
    if (dim(n)[1]!=0){
       cat("  \n#### Gene",  as.character(n$Gene)[1], "Dettaglio", " \n")
ya<-subset(n, select= c(Variant, Chromosome, Ref_base, Var_base, Start, Stop))
ya <- unique(ya)
row.names(ya)<-NULL
print(kable(ya) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))
    }}
  }, silent = TRUE)
```



## Drug-Food Interactions
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
#Food interactions
args=commandArgs(trailingOnly = TRUE)
try({k<-read.csv(paste0("/Food/",args[7],".txt"), sep="\t")
colnames(k)[1] <- "Drug"
k <- subset(k, select=c(Drug, food_interaction))
print(kable(k) %>%
kable_styling(bootstrap_options = c("striped", "hover","responsive")))
}, silent = TRUE)
```

## Reference {.tabset}

### Mutation
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
try({x_url<-read.csv(paste0("/Reference/",args[7],".txt"), sep= "\t")
library(dplyr)
library(knitr)
library(kableExtra)
link1<-subset(x_url, select= c(Citation, PMID, Reference))
t <- link1 %>%
  mutate(PMID = cell_spec(x_url$Cod, "html", link = PMID)) %>%
  kable("html", escape = FALSE) %>%
kable_styling(bootstrap_options = c("hover", "condensed"))
x_url$Gene <- as.factor(x_url$Gene)
lvl <- levels(x_url$Gene)
for (l in lvl) {
  a <- which(x_url$Gene == l)
  if (length(a) == 0) next()
  t <- t %>% pack_rows(l, min(a), max(a), indent=FALSE)
}
print(t)
}, silent = TRUE)
```

### pharm
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
#pharm
try({x_url_p<-read.csv(paste0("/Reference/",args[7],"_pharm.txt"), sep= "\t")
library(dplyr)
library(knitr)
library(kableExtra)
x_url_p<-data.frame(x_url_p, paste0(x_url_p$Reference,"a"))
x_url_p$Reference <- NULL
colnames(x_url_p)[4] <- "Reference"
#x_url <- x_url[order(x_url[,3]),]
link1<-subset(x_url_p, select= c(PMID, Reference))
t <- link1 %>%
  mutate(PMID = cell_spec(x_url_p$Cod, "html", link = PMID)) %>%
  kable("html", escape = FALSE) %>%
kable_styling(bootstrap_options = c("hover", "condensed"))
x_url_p$Gene <- as.factor(x_url_p$Gene)
lvl <- levels(x_url_p$Gene)
for (l in lvl) {
  a <- which(x_url_p$Gene == l)
  if (length(a) == 0) next()
  t <- t %>% pack_rows(l, min(a), max(a), indent=FALSE)
}
#cat("  \n#### pharm", " \n")
print(t)
}, silent = TRUE)

```
### Off label Drug
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
#Off label
try({x_url<-read.csv(paste0("/Reference/",args[7],"_off.txt"), sep= "\t")
library(dplyr)
library(knitr)
library(kableExtra)
x_url <- x_url[order(x_url[,5]),]
x_url<-data.frame(x_url, paste0(x_url$Reference,"a"))
x_url$Reference <- NULL
colnames(x_url)[5] <- "Reference"
#x_url <- x_url[order(x_url[,3]),]
link1<-subset(x_url, select= c(Citation, PMID, Reference))
t <- link1 %>%
  mutate(PMID = cell_spec(x_url$Cod, "html", link = PMID)) %>%
  kable("html", escape = FALSE) %>%
kable_styling(bootstrap_options = c("hover", "condensed"))
x_url$Disease <- as.factor(x_url$Disease)
lvl <- levels(x_url$Disease)
for (l in lvl) {
  a <- which(x_url$Disease == l)
  if (length(a) == 0) next()
  t <- t %>% pack_rows(l, min(a), max(a), indent=FALSE)
}
#cat("  \n#### Off label", " \n")
print(t)
}, silent = TRUE)
```
### Cosmic
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
library(knitr)
library(kableExtra)
library(dplyr)
options(knitr.table.format = "html")
args=commandArgs(trailingOnly = TRUE)
#Cosmic
try({cosm<-read.csv(paste0("/Reference/",args[7],"_cosmic.txt"), sep= "\t")
attach(cosm)
for(i in 1:(length(cosm$Cod)-1)){
if (cosm$Cod[i]==cosm$Cod[i+1]){
    cosm$Reference[i]<- paste0(cosm$Reference[i],",",cosm$Reference[i+1])
    cosm$Reference[i+1]<-gsub(cosm$Reference[i+1],pattern="[0-9]",replace=" ")
    cosm$Reference[i+1]<- (cosm$Reference[i])
    i <- i+1
}}
for(p in length(cosm$Cod):2){
  if (cosm$Cod[p]==cosm$Cod[p-1]){
    cosm$Reference[p-1]<-gsub(cosm$Reference[p-1],pattern="[0-9]",replace=" ")
    cosm$Reference[p-1]<- (cosm$Reference[p])
    p <- p-1
  }}
cosm <- unique(cosm)
link1<-subset(cosm, select= c(PMID, Reference))
t <- link1 %>%
  mutate(PMID = cell_spec(cosm$Cod, "html", link = PMID)) %>%
  kable("html", escape = FALSE) %>%
kable_styling(bootstrap_options = c("hover", "condensed"))
cosm$Gene <- as.factor(cosm$Gene)
lvl <- levels(cosm$Gene)
for (l in lvl) {
  a <- which(cosm$Gene == l)
  if (length(a) == 0) next()
  t <- t %>% pack_rows(l, min(a), max(a), indent=FALSE)
}
#cat("  \n#### Cosmic", " \n")
print(t)
}, silent = TRUE)
```



## Appendix
### Disease list
```{r echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
library(knitr)
library(kableExtra)
options(knitr.table.format = "html")
try({x<-read.csv("./Disease.txt", sep= "\t")
x$Disease <- gsub(x$Disease, pattern="��", replace="�") #trova una soluzione
x$Disease1 <- gsub(x$Disease1, pattern="��", replace="�")
x <- x[order(x[,2]),]
x <- x[,c(2,1)]
colnames(x)[1]<- "Disease group"
row.names(x) <- NULL
kable(x, align = "c") %>%
  kable_styling(full_width = F) %>%
  column_spec(1, bold = T,border_right = T) %>%
  collapse_rows(columns = 1, valign = "middle")
}, silent = TRUE)
```



