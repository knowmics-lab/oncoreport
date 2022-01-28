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
