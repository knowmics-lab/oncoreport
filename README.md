# Oncoreport

![immagine](https://user-images.githubusercontent.com/57007795/163539998-1be36952-2e90-4023-bb21-1e8fee0e6dd2.png)

**OncoReport** is a user-friendly software system for the analysis of DNA-seq data coming either from solid or liquid biopsy samples. The aim of **OncoReport** to identify the patients' tumor mutations allowing the help in the definition of the most suitable therapy.

![immagine](https://user-images.githubusercontent.com/57007795/151794368-902242bd-e6ca-48cf-8108-b794fa6497c1.png)

The software performs two types of analysis:
* Tumor vs Normal 
* Tumor only 

The user can choose the human reference genome to use between **GRCh37** (hg19) and **GRCh38** (hg38).

## System Requirements

**OncoReport** is a cross-platform application backed by a customized docker image to minimize the dependencies. The supported operating systems are:

* Windows Professional
* macOS
* Linux


# System Requirements 

**Internet Connection**: internet connection is needed only for the setup process and the download of cosmic database and reference genomes. After the installation has been completed no connection is required.

For WGS analysis:
* Processor 8 core processor
* RAM 64GB 
* Hard Drive 1Tb


For WES analysis:
* Processor ?
* RAM 32GB 
* Hard Drive 500GB

For custom panel?

## Installation

# Installation on Windows Professional

* Install Docker Desktop in your computer by downloading the installer at this link [Docker Desktop](https://hub.docker.com/editions/community/docker-ce-desktop-windows/). When prompted, ensure to enable the Hyper-V Windows Features or WSL2 (available only for Windows 10 2004 or later). For Windows 10, WSL2 option is suggested.
* Now that Docker Desktop is running, you can install OncoReport by downloading...

# Installation on macOS

* First check [Docker Desktop system requirements](https://docs.docker.com/desktop/mac/install/).
* Install Docker Desktop in your computer by downloading the installer at this link [Docker Desktop for mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac/) and following the instructions.
* Now that Docker Desktop is running, download OncoReport...

# Installation on Linux

* First install Docker in your computer by following the procedure for your linux distribution.
* Add your user account to the docker group. In most distribution you can get your username with the whoami command, and add it to the docker group using the following command:

`foo@bar:~$ sudo usermod -aG docker YOUR_USER_NAME`

* After adding your user account to docker group, you will need to log out and log in to activate the changes.
* Download the OncoReport package most suited for your distribution from ...
 

## Usage 
### Inputs
The pipeline takes several inputs:
-	fastq  
-	bam
-	sam
-	ubam
-	vcf (it also possible to upload a varianttable sample in this section)
**OncoReport** allows users to easily generate rich reports to support clinical interpretation of variants and their association to prognosis and therapy. 

### Patients creation

After installing the app, it is possible to start immediately the analysis.
First of all, the user has to create a new patient using the "+" in the patients screen.
You can see from the image the specific of the patients page.


![immagine](https://user-images.githubusercontent.com/57007795/151526164-a1d0842f-474f-47f1-a13d-0ac3ca3f3a0f.png)


The information needed to add a new patient are:
- The Patient's Code*
- Patient's First and Last Name*
- Patient's Age*
- Patient's Gender*
- Fiscal Number
- Email*
- Telephone
- City
- Primary Disease* The disease that the user wants to analyze
- Disease type
- Diagnosis Date
- T, the stage of the patient's tumor
- N, the lymph node number
- M, the presence or absence of metastasis


The information indicated with the asterisk are mandatory.

![immagine](https://user-images.githubusercontent.com/57007795/151539525-c646d215-331a-4c0a-a682-f529a2b7a03c.png)


After the patient creation, it is also possible to add information about other diseases of the patient and about the drugs already taken. 
In this way OncoReport is able to discover possible drug-drug interactions.

![immagine](https://user-images.githubusercontent.com/57007795/151528305-9143aa13-792c-4ca7-8285-539f54bef7ff.png)

### Analysis creation

For each patient it is possible to add more than one analysis. 
At the end of each analysis we will have as output the logs, the report and an archive of the raw annotated output.

![immagine](https://user-images.githubusercontent.com/57007795/163541322-cf0b1d97-ec07-4e7a-b2e7-12e239ef91f8.png)


The user needs to provide analysis sample code, analysis name, the type of analysis, the input type and the number of threads that are gonna be used by the machine. It is possible to upload fastq, bam, ubam or vcf files. The user has also the chance to choose between two human reference genomes: GRCh37 (hg19) and GRCh38 (hg38). The user has also to specify if the samples are paired end. 

It is possible to make two types of analysis:

1. **The Tumor vs Normal analysis**
It takes two inputs, a tumor sample and a normal sample. This analysis compare the two samples to remove all the germline mutation of the tumor sample. In this way the report will annotate only the somatic mutations. It is necessary to specify the "Depth filter" of the analysis.

![immagine](https://user-images.githubusercontent.com/57007795/163542443-6697a1a1-286b-4858-88bd-4857209059e8.png)

2. **The Tumor only analysis** 
It takes only the tumor sample. This tumor sample can originate both from a solid biopsy or a liquid biopsy. Here is necessary to specify both the "Depth filter" for variant calling and the "Allele Fraction Filter". The latter it is needed to split the somatic mutations from the germline ones since we do not have the normal samples. We suggest to use Less and equal to 0.3 for liquid biopsy and Less and equal to 0.4 for solid biopsy.

![immagine](https://user-images.githubusercontent.com/57007795/163542014-429af5aa-f23d-41ad-bfe5-3035976af255.png)

# The Report
OncoReport' goal is the automatic generation of a report describing all the possible annotations (both prognostic and therapeutic) associated to the patients' mutations.
To reach this purpose, it employees several databases which will allow to synthetize a **precision medicine therapy report** for the patient.

![immagine](https://user-images.githubusercontent.com/57007795/163543139-4829d077-320b-46d7-b2ed-eaa0ceaf1bfd.png)

When the analysis finish the user can both interactively consult the report from the app or download locally a compressed version of it. 
Once decompressed the report will be available within a folder and the user will be able to consult it by clicking on the "index" file.

The report is composed by four main sections. An additional section named "other details" provides further information on the mutation annotations.
![immagine](https://user-images.githubusercontent.com/57007795/163543515-19b9dd0e-055a-45f0-a57d-d58cc3e334e5.png)

## Therapeutic indications

![immagine](https://user-images.githubusercontent.com/57007795/163544477-8e6b3d1c-d7b1-4ff2-a0a6-ffb777da80b2.png)


This section contains two tables providing information on the mutations' clinical impact. The first table reports mutations yielding therapeutic evidence going from Validated association, to clinical evidence and FDA approved drugs. The second table is called ***other evidences*** which are not already used in the clinical context. It includes all the mutations that have been marked as "Case study" evidence level, "Preclinical evidence" and so on. 

In both tables the user will find the **name of the gene and the variants** which have been found mutated in the patient and the **drugs** associated with these specific mutations. The presence of more than one drug per row indicates the usage of such drugs in combination. 
The **evidence type**, can be:
* predictive and therefore associated with a drug that can bring a response;
* Diagnostic, this underlines the impact, positive (e.g. higer incidence of the disease) or negative (e.g. lower incidence of the disease), of the mutation on the patient;
* Prognostic, the impact of a variant on the patient's disease;
* Predisposing, the possibility that the variant predisposes the patient to the illness;
* Oncogenic, a somatic variant that it is involved in tumor pathogenesis;
* Functional, if the variant causes or not alteration of the function of the protein produced by the gene.
This information is taken from the two databases: CIViC and Cancer Genome Interpreter (CGI).
The **Clinical Significance** changes when the evidence type changes. For our purpose the most interesting are:
* Sensitivity/Response which is associated with the possible response of the patient, having that specific mutation, to the treatment with that drug;
* Resistance, which is associated with the possible resistance of the patient, having that specific mutation, to the treatment with that drug;
* Adverse Response to the drug treatment;
* Reduced Sensitivity when the patients respond to the treatment, but not in the best way possible.
**Type** of mutation which can be somatic or germline.
**Details**, when details about that evidence exists the user can click on the plus and reach to the subsection ***Clinical Evidence Details*** where it is possible to find information about the evidence and the study of that evidence. 
![immagine](https://user-images.githubusercontent.com/57007795/163546083-c46f0124-87f1-481c-941f-d2fed8197b32.png)

**Trials** Clicking on trials the users can reach the "ClinicalTrials.gov" page where they will find all the existing trials for the drug-variant combination.
**References** Clicking on reference the users reach the Reference Section. Here, they will be able to consult the pubmed paper from which the evidence was taken clicking on the PMID. 
![immagine](https://user-images.githubusercontent.com/57007795/167871106-e3b18b56-f007-4696-9ac5-4d0caf9e366f.png)

**Score**
The evidence score is calculated using variant's pathogenic information, the repetition of the drug for the same mutation and the evidence publication year.

**AIFA**, **EMA**, **FDA**
Information about the approval of drugs by the AIFA, EMA and FDA agencies. When there are three ticks it means that the drug or the combination of drugs has been approved by all the agency. 

![immagine](https://user-images.githubusercontent.com/57007795/167890613-14092357-2601-4faa-a535-c993d5c78511.png)

When the "x" is found, it means that at least one of the drug has not been approved by that specific agency.

![immagine](https://user-images.githubusercontent.com/57007795/167890395-af1d96c9-eb1c-4c20-84f1-d7ba5bbf76bd.png)

**Publication year**
The year of the evidence publication.
 
## Drug-Drug interactions
![immagine](https://user-images.githubusercontent.com/57007795/167891126-4de6c20f-9ddf-400d-a164-cde590bdd784.png)

Information, taken from drugbank, about the interactions between the drugs already taken by the patient and the drugs recommended by the system.

![immagine](https://user-images.githubusercontent.com/57007795/167891171-6ef750b3-fc76-4028-b074-f3a4ff81fc33.png)

Information, taken from drugbank, about the interactions between the drugs.

This section allows to prevent unpleasant side-effects to the patients, understanding the role of a combination of drugs to the organism.

## Drug-Food interactions
This section provides information about the interaction between drugs and food allowing to be aware about side-effects, as nausea, to the patients under a specific therapy.
![immagine](https://user-images.githubusercontent.com/57007795/167892488-ce805af4-95f2-49c6-8be5-351ff020b8cf.png)

##ESMO Guidelines
![immagine](https://user-images.githubusercontent.com/57007795/167892875-faef0dd3-5d10-47f1-abcc-71f1863c96db.png)

These guidelines, commonly consulted by the oncologists, have been added to the report to allow an easy and fast consultation. The guidelines will bring information about the primary disease inserted by the user at the beginning of the analysis.


## Drug response

![immagine](https://user-images.githubusercontent.com/57007795/167894604-d66652ea-db00-4382-a85e-3bf2c5432cdf.png)
Evidence taken from PharmGKB database. The user can found information about the gene with the variant indicated with rs code and the drug associated with its clinical significance (toxicity, efficacy). For each evidence also details are provided.

##Mutations Annotations
![immagine](https://user-images.githubusercontent.com/57007795/167895058-2480c923-db34-4f8e-b5c1-33a954d38e93.png)
Annotation for each mutation which have been found in the analysis. 
For each mutation the user will find:
* Gene name
* Chromosome 
* Position
* Ref Base
* Var Base
* The change that the mutation cause (e.g. Synonymous, Missense, intron, etc.)
* Clinical Significance by Clinvar (e.g. Benign, Pathogenic, etc.)
* Clinical Significance by Cosmic (e.g. Neutral, Pathogenic, etc.)
* Allele Frequency
* Depth of the mutation in variant calling step
* Genotype: 0/1 Heterozygote, 1/1 Homozygote
* Class: SNP or Indel
* Type of mutation (e.g. Somatic, Germline)

## Off-labels indications
![immagine](https://user-images.githubusercontent.com/57007795/167897266-7962cfd4-18a1-4315-82b8-610f84e560d6.png)
Therapeutic indication concerning a gene-variant couple in disease different from the one studied by the user.
These information can be essential when no evidence is found in therapeutic indication.

## Known-drug resistance
![immagine](https://user-images.githubusercontent.com/57007795/167897317-7e956b9d-3793-4511-a575-720941b9d7ac.png)
Information taken from the COSMIC database about the resistance to a drug in specific cancer with that variant mutation.
