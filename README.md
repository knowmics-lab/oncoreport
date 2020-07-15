# Oncoreport

## Installation

Install docker through 
https://docs.docker.com/get-docker/
Pull the pipeline image using the command

```
   docker pull grete/oncoreport:latest
```
The first thing to do after the installation of docker and the download of the pipeline is to download the cosmic file that the pipeline need. 
You will need to download both the GRCh37 version and the GRCh38 version if you want to work with both the genome version, or only one if you plan to work always with the same version.Steps:
1.	Create a folder where to put the Cosmic files
2.	Go to https://cancer.sanger.ac.uk/cosmic/download
3.	If you don’t have an account create it, otherwise log in
4.	Choose the genome version GRCh37 
5.	Download CosmicCodingMuts.vcf.gz
6.	Download CosmicResistenceMutation.tsv.gz
7.	Leave the name of the cosmic file GRCh37 as you see them above
8.	Choose the genome version GRCh38, remember when you download the file to change the name of them as I did below
9.	Download CosmicCodingMuts_hg38.vcf.gz
10.	Download CosmicResistanceMutation_hg38.tsv.gz

 

 

 
 

When you download The Cosmic file for the GRCh38 version remember to change the files name
 

## Usage example
### File extension
Your fastq file need to have one of the following extension:
1.	for the liquid biopsy/only tumor analysis
-	_R1_001.fastq.gz _R2_001.fastq.gz 
-	_R1_001.fastq _R2_001.fastq 
-	.bam
-	.sam
-	.vcf
-	.varianttable.txt (This one is specific from vcf produced with illumina sequencer)
2.	for the tumour/normal analysis
-	.fastq.gz 
-	.bam
-	.sam
-	.vcf
The Pipeline is built to be used with three different types of data, liquid biopsy sample, a tumour only sample or a tumour-normal sample. 
When you first start the docker container you need to indicate three/four path, the path where the inputs are saved, the path were you have downloaded the cosmic files, and the path where you want to save your report. You must pay attention to leave the name of the docker folder (the names written in bold) as are written down in the examples and to change the other part with your computer path.
Remember If you need to do an analysis with both the tumour and the normal samples you have to set two fastq folder, one where you have your normal sample and one where you have your tumour sample. If your analysis of tumor and normal sample starts from the vcf you need to set up only the input_tumor folder where the vcf is saved.


##### FOR LIQUID BIOPSY OR ONLY TUMOR SAMPLES
Example for linux
```
docker run -v /home/yourusername/output:/output -v /home/yourusername/input:/input -v /home/yourusername/cosmic_downloads:/Cosmic_downloads  -it grete/oncoreport:latest
```
Example for windows
```
docker run -v C:\Users\yourusername\Documents\output:/output -v  C:\Users\yourusername\Documents\input:/input -v C:\Users\yourusername\Documents\cosmic_downloads:/Cosmic_downloads  -it grete/oncoreport:latest
```
##### FOR TUMOUR-NORMAL SAMPLES
Example for linux
```
docker run -v /home/yourusername/output:/output -v /home/ yourusername /fastq_blood:/input_blood -v /home/ yourusername /fastq_tumor:/input_tumor -v /home/ yourusername /cosmic_downloads:/Cosmic_downloads  -it grete/oncoreport:latest
```
Example for windows
```
docker run -v C:\Users\ yourusername \Documents\output:/output -v C:\Users\ yourusername \Documents\input_blood:/input_blood -v C:\Users\ yourusername \Documents\input_tumor:/input_tumor -v C:\Users\ yourusername \Documents\cosmic_downloads:/Cosmic_downloads  -it grete/oncoreport:latest
```
After you have built the container you will se your terminal change a bit, you are going to see root@ followed by a number an not anymore your username. 
At this point, when the container is started you need to choose the right script for your sample type, if you have a liquid biopsy sample or a tumour only sample choose the pipeline called pipeline_liquid_biopsy.bash, but if you have a tumour-normal sample choose pipeline_tumVSnormal_docker.bash pipeline. 
For both pipeline you have to set the parameters : 
-n <- the name of the patient
-s <- the surname of the patient
-i <- the code of the patients, or its ID, as the user prefer
-t <-the tumour type, it has to be chosen depending on a list given by us to reassure the compatibility between the database and the information given by the user. You can find the list of tumour name at the end of this document. Remember is your string is formed by two words to put the backslash near the first one (ex. Thyroid\ Cancer)
-a <- the age of the patient
-p <- the creation of the database you will need for the analysis, if is the first time you use your container write yes so you will create the databases, otherwise write no
-b <- the number of threads for the sample alignment, if you are not sure write 1
-c <- the version of the genome you want to use, the available option are hg19 or hg38
For the pipeline_liquid_biopsy.bash you need to set other two parameters before launching the analysis.
 -d <- is fundamental for the depth of the analysis is the number of time that a nucleotide is read, so it’s the number of reads generated by the ngs analysis. It depends on the NGS run, it can vary between different type of analysis, panels and tools. If you don’t know what to do set it to “DP<0 “
-e <- set the Allele fraction filter, that is the percentage of the mutate alleles in that reads, it is helpful to understand if a mutation is probably germline or somatic, in a liquid biopsy analysis is usually set to “AF>0.3” (30%), in a solid biopsy analysis to “AF<0.4” (40%).

Examples
```
bash  pipeline_liquid_biopsy.bash -n Mario -s Rossi -i AF6575P -g M -t Colon\ Cancer -a 89 -d "DP<0" -e "AF>0.3" -p yes -b 1 -c hg19
```
```
bash  pipeline_tumVSnormal_docker.bash -n Mario -s Rossi -i AF6575P -g M -t Colon\ Cancer -a 89 -p yes -b 1 -c hg19
```

### Disease
- Acoustic Neuroma
- Adenoid cystic carcinoma
- Adrenal adenoma
- Adrenal Gland Pheochromocytoma
- Adrenocortical Carcinoma
- Alveolar Rhabdomyosarcoma
- Anaplastic Large Cell Lymphoma
- Anaplastic Oligodendroglioma
- Angiosarcoma
- Any cancer type
- Astrocytoma
- B cell lymphoma
- Barrett's Adenocarcinoma
- Basal Cell Carcinoma
- Bile Duct Adenocarcinoma
- Biliary Tract Cancer
- Billiary tract
- Bladder Cancer
- Bone Cancer
- Brain Cancer
- Breast Cancer
- Bronchiolo-alveolar Adenocarcinoma
- Cervical Cancer
- Cervix Cancer
- Cholangiocarcinoma
- Chordoma
- Chuvash Polycythemia
- Colon Cancer
- Congenital Fibrosarcoma
- Dermatofibrosarcoma
- Dermatofibrosarcoma Protuberans
- Desmoid Fibromatosis
- Diffuse Intrinsic Pontine Glioma
- Diffuse Large B-cell Lymphoma
- Endometrial Cancer
- Epithelioid Hemangioendothelioma
- Epithelioid Inflammatory Myofibroblastic Sarcoma
- Erdheim-Chester histiocytosis
- Esophageal Cancer
- Essential Thrombocythemia
- Ewing Sarcoma
- Female germ cell tumor
- Female Reproductive Organ Cancer
- Fibrous histiocytoma
- Follicular Lymphoma
- Ganglioglioma
- Gastric Cancer
- Giant cell astrocytoma
- Glioblastoma
- Glioblastoma Multiforme
- Glioma
- Head And Neck Cancer
- Hematologic Cancer
- Hematologic malignancies
- Hepatic carcinoma
- Hepatocellular Cancer
- Hyper eosinophilic advanced snydrome
- Inflammatory myofibroblastic
- Inflammatory Myofibroblastic Tumor
- Intrahepatic Cholangiocarcinoma
- Langerhans-Cell Histiocytosis
- Laryngeal Cancer
- Leukemia
- Liposarcoma
- Lung Cancer
- Lymphangioleiomyomatosis
- Lymphoma
- Lynch Syndrome
- Male germ cell tumor
- Malignant astrocytoma
- Malignant Glioma
- Malignant Mesothelioma
- Malignant Peripheral Nerve Sheath Tumor
- Malignant Pleural Mesothelioma
- Malignant rhabdoid tumor
- Malignant Sertoli-Leydig Cell Tumor
- Mantle Cell Lymphoma
- Medulloblastoma
- Melanoma
- Meningioma
- Merkel Cell Carcinoma
- Mesenchymal Chondrosarcoma
- Mesothelioma
- Myeloma
- Myxoid Liposarcoma
- Neuroblastoma
- Neuroendocrine
- Neuroendocrine Tumor
- Neurofibroma
- Non-small cell lung
- NUT Midline Carcinoma
- Oligodendroglioma
- Oral Squamous Cell Carcinoma
- Oropharynx Cancer
- Osteosarcoma
- Ovarian Cancer
- Pancreatic Cancer
- Papillary Adenocarcinoma
- Paraganglioma
- Parietal Lobe Ependymoma
- Pediatric Fibrosarcoma
- Pediatric glioma
- Pericytoma
- Peripheral T-cell Lymphoma
- Peritoneal Mesothelioma
- Peutz-Jeghers Syndrome
- Pilocytic Astrocytoma
- Plexiform Neurofibroma
- Polycythemia Vera
- Prostate Cancer
- Pseudomyxoma Peritonei
- PTEN Hamartoma Tumor Syndrome
- Rectum Cancer
- Renal Cancer
- Retinoblastoma
- Rhabdoid Cancer
- Rhabdomyosarcoma
- Salivary Cancer
- Sarcoma
- Schwannoma
- Scrotum Paget's Disease
- Sezary's Disease
- Skin Squamous Cell Carcinoma
- Solid Tumor
- Stomach Cancer
- Supratentorial Glioblastoma Multiforme
- Synovial Sarcoma
- Systemic Mastocytosis
- Thymic
- Thymic Carcinoma
- Thyroid Cancer
- Tuberous Sclerosis
- Ureter Small Cell Carcinoma
- Urinary tract carcinoma
- Urothelial Carcinoma
- Uterine Cancer
- Vagina Sarcoma
- Von Hippel-Lindau Disease
- Waldenström macro globulinemia
- Waldenström's Macroglobulinemia


