# GC4miRNA
## Overview
MicroRNAs (miRNAs) are small RNA molecules that play a crucial role in regulating gene expression by binding to and degrading targeted mRNAs. Alterations in the binding site between miRNAs and mRNAs can lead to the dysregulation of genes, and a variety of diseases, including cancers. GC content is an important factor in miRNA binding, since high GC content miRNAs are often more stable and may have a stronger affinity for their targets. To reveal the GC content signature for cancer-associated miRNAs, we developed a R Shiny app called GC4miRNA, which calculates GC enrichment and performs statistical analysis for targeting miRNAs and their seed sequences using customized BASH and R scripts.

## Module 1: GC Calculation Instructions
In order to generate calculations of the GC Content for multiple miRNAs at once, run the module GC_Calculation_App.R in RStudio, and input a fasta file containing your miRNAs. We have an example file called example-2.fa, which generates GC 
Content for miRNAs found in our dataset. gccontent_fixed.sh is the bash script that our R Shiny program uses for its calculation. We would like to credit "Abbys-Amazing-GC-Calculator" for the original code, which we only modified a little bit. It can be found in this directory: https://github.com/abbykatb/Abbys-Amazing-GC-Calculator/blob/master/README.md

## Module 2: Identifying Differential Expression in miRNA Instructions
This module comes with one R shiny script "Identifying_Differential_Expression.R" which takes in an input list of miRNA names as well as miRNA expression data and finds information about the differential expression of each miRNA between tumor and normal samples based on TCGA data, as well as the experiments where the data was taken. The miRNA list consists of mature miRNA sequences that are in seperate lines, as can be seen in the example file "BLCA_miRNA_list.txt". This program uses data from dbDEMC that can be used to find differential expression information, which is in the 28.5 MB file "miRExpAll.txt.zip". After inputting the miRNA list as well as the expression data, the program should display the desired information.

## Module 3: Statistical Analysis
The input file for this module is a csv file containing columns for GC content for consensus and 5p sequences of miRNA, as well as differential expression information that can be found in Module 2. An example file "LIHC-T-test_Sample.csv" is directly from a dataset we used for our research, and it contains many different columns alongside the ones that are used in the program. Our code searches for columns with very specific names, so it is important for the function of this program to modify the code so that it searches for the same column names in your dataset. After pressing "Run T-tests", there should be two Student's T-test that are generated, which are seperated based on whether or not they use data from miRNAs that are upregulated("UP") in tumor samples or downregulated("DOWN"). The T-tests compare the GC content of your consensus sequences with the GC content of your 5p sequences. There should also be a p-value that is generated which tells you how statistically significant the difference between the two sequences' GC content is. 

## Module 4: FASTA generator
The input file for this module can just be any data table with the columns specified within the program. Our code searches for columns with very specific names, so it is important for the function of this program to modify the code so that it searches for the same column names in your dataset. After inputting the name of the cancer you are analyzing the miRNA sequences for, it should give you the optionn to download a zip file, which should expand to give you a folder with four files, which are the consensus and 5p miRNAs with differing differential expression. The FASTA files can easily be inputted into MEME to find motifs, but be aware that the consensus sequences may be too short to find motifs with. 

## Workflow
<p align="center">
<img src="GC4miRNA_Figure.png">
</p>

## License
MIT
Authors: Braydon Lu and Ian Hou
