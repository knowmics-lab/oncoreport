# Manual WORK IN PROGRESS
# Oncoreport

## System Requirements

Docker need to be installed on your computer to run OncoReport
Docker can be installed through one of these two links

```
https://www.docker.com/products/docker-desktop

https://docs.docker.com/get-docker/
```

First of all to use OncoReport you need to regist yourself on https://cancer.sanger.ac.uk/cosmic
To use OncoReport it is necessary to have Cosmic functional credentials.

## Installation


Download the OncoReport app from.....
After the download it will be ask to you to add the Cosmic credential.
The download will start
 

## Usage 
### Inputs
The pipeline takes several inputs:
-	fastq  
-	bam (sam??)
-	ubam
-	vcf (it also possible to upload a varianttable sample in this section)

### Patients creation

After installing the app it is possible to start immediately the analysis.
First of all the user should create a new patient using the "+" in the patients screen.
You can see from the image the specific of the patients  page.


![immagine](https://user-images.githubusercontent.com/57007795/151526164-a1d0842f-474f-47f1-a13d-0ac3ca3f3a0f.png)


The information necessary to add a new patient are:
- The Patient Code*
- The Patient First and Last Name*
- Patient Age*
- Patient Gender*
- Fiscal Number
- Email*
- Telephone
- City
- Primary Disease* The disease for which we want to do the analysis
- Disease type
- Diagnosis Date
- T, the tumor stage of the patient
- N, the lymph node number
- M, the presence or absence of the metastasis


The information indicated with the asterisk must be added!

![immagine](https://user-images.githubusercontent.com/57007795/151539525-c646d215-331a-4c0a-a682-f529a2b7a03c.png)


After the patient creation it is possible to add also information about other disease of the patient and the drug already taken. 
In this way we permit to OncoReport to discover possible drug-drug interaction.

![immagine](https://user-images.githubusercontent.com/57007795/151528305-9143aa13-792c-4ca7-8285-539f54bef7ff.png)


### Analysis creation

For each patient it is possible to add more than one analysis. 
At the end of each analysis we will have as output the logs and the report.

![immagine](https://user-images.githubusercontent.com/57007795/151528763-78ee9838-b172-4e22-b13d-cb5ef015f184.png)


The user need to provide analysis sample code, the analysis name, the type of analysis, the input type and the number of threads that are gonna be used by the machine. It is possible to upload fatsq or bam or ubam or vcf files. The used have also the possibility to choose between two human reference genome: GRCh37 (hg19) and GRCh38 (hg38). It is needed to specify if the samples are paired end. 

It is possible to make two types of analysis:

1. The Tumor vs Normal analysis. It takes two input, a tumor sample and a normal sample. This analysis compare the tumor sample with the normal sample to remove all the germline mutation of the tumor sample. In this way the report will annotate only the somatic mutations. 


![immagine](https://user-images.githubusercontent.com/57007795/151537926-0c81f8b3-a467-478e-ab77-f789aee4cf60.png)

2. The Tumor only analysis. It takes only the tumor sample. This tumor sample can originate both from a solid biopsy or a liquid biopsy. Here is necessary to speicify both the "Dept filter" for the variant calling and the "Allele Fraction Filter". The latter it is needed to split the somatic mutations from the germline ones since we do not have the normal sample. We suggest to use Less and equal to 0.3 for liquid biopsy and Less and equal to 0.4 for solid biopsy.

![immagine](https://user-images.githubusercontent.com/57007795/151538534-f52ed764-bd03-4d1e-b4f9-ee0b69348ca9.png)


Now you need to choose the right script for your sample type, if you have a liquid biopsy sample or a tumour only sample choose the pipeline called pipeline_liquid_biopsy.bash, but if you have a tumour-normal sample choose pipeline_tumVSnormal.bash pipeline. 
For both pipeline you have to set the parameters : 
- n/-name <- the name of the patient
- s/-surname <- the surname of the patient
- i/-id <- the code of the patients, or its ID, as the user prefer
- t/-tumor <-the tumour type, it has to be chosen depending on a list given by us to reassure the compatibility between the database and the information given by the user. You can find the list of tumour name at the end of this document. Remember is your string is formed by two words to put the backslash near the first one (ex. Thyroid\ Cancer)
- a/-age <- the age of the patient
- ip/-idx_path <- the path of the folder of the index 
- idx/-index <- the genome versione you want to use (hg19 or hg38)
- pp/-project_path <- the path of the project where you can find the input folder and you will create the output one
- th/-threas <- the number of threads for the sample alignment, if you are not sure write 1
- dp/-depth <- is fundamental for the depth of the analysis is the number of time that a nucleotide is read, so it’s the number of reads generated by the ngs analysis. It depends on the NGS run, it can vary between different type of analysis, panels and tools. If you don’t know what to do set it to “DP<0 “
- af/-allfreq <- set the Allele fraction filter, that is the percentage of the mutate alleles in that reads, it is helpful to understand if a mutation is probably germline or somatic, in a liquid biopsy analysis is usually set to “AF>0.3” (30%), in a solid biopsy analysis to “AF<0.4” (40%).
- fq1/-fastq1 <- the analysis can start from fastq, bam, ubam or vcf, insert this parameter with the fastq1 path if you have the fastq sample
- fq2/-fastq2 <- the second fastq sample if the analysis is a paired-end analysis
- b/-bam <- the analysis can start from fastq, bam, ubam or vcf, insert this parameter with the bam path if you have the bam sample 
- ub/-ubam <-  the analysis can start from fastq, bam, ubam or vcf, insert this parameter with the ubam path if you have the ubam sample
- pr/-paired <-  if you have inserted the ubam you need to specify if the ubam originate from a paired-end analysis or not, using yes in the former case or no in the latter 
- v/-vcf <-  the analysis can start from fastq, bam, ubam or vcf, insert this parameter with the vcf path if you have the vcf sample
- db/-database <- the path of the databases folder

Examples
```
bash pipeline_liquid_biopsy.bash -n Mario -s Rossi -g M -i AX6754R -a 45 -dp "DP<0" -af "AF>=0.4"  -t Colon\ Cancer -ip index/ -idx hg19 -th 4 -pp input -fq1 input/fastq/OGT_S2_R1_001.fastq -fq2 input/fastq/OGT_S2_R2_001.fastq -db Databases
```
```
bash  pipeline_tumVSnormal_docker.bash bash pipeline_liquid_biopsy.bash -g M -s Rossi -n Mario -i AX6754R -a 45 -t Colon\ Cancer -ip index/ -th 4 -pp input -idx hg19 -fq1 input/fastq/fastq_sample.fastq -nm1 input/normal/normal_sample.fastq -db Databases
```

