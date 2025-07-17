# GC4miRNA
## Overview
MicroRNAs (miRNAs) are small RNA molecules that play a crucial role in regulating gene expression by binding to and degrading targeted mRNAs. Alterations in the binding site between miRNAs and mRNAs can lead to the dysregulation of genes, and a variety of diseases, including cancers. GC content is an important factor in miRNA binding, since high GC content miRNAs are often more stable and may have a stronger affinity for their targets. To reveal the GC content signature for cancer-associated miRNAs, we developed a R Shiny app called GC4miRNA, which calculates GC enrichment and performs statistical analysis for targeting miRNAs and their seed sequences using customized BASH and R scripts.

## Module 1 Instructions
In order to generate calculations of the GC Content for multiple miRNAs at once, run the module GC_Calculation_App.R in RStudio,
and input a fasta file containing your miRNAs. We have an example file called example-2.fa, which generates GC 
Content for miRNAs found in our dataset. gccontent_fixed.sh is the bash script that our R Shiny program uses for its calculation.
We would like to credit "Abbys-Amazing-GC-Calculator" for the original code, which we only modified a little bit. It can be found
in this directory: https://github.com/abbykatb/Abbys-Amazing-GC-Calculator/blob/master/README.md


## Workflow
<p align="center">
<img src="GC4miRNA_Figure.png">
</p>
