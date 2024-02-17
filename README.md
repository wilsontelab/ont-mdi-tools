# Wilson lab tools for Oxford Nanopore data processing

The [Michigan Data Interface](https://midataint.github.io/) (MDI) 
is a framework for developing, installing and running 
Stage 1 HPC **pipelines** and Stage 2 interactive web applications 
(i.e., **apps**) in a standardized design interface.

This **ont-mdi-tools** repository contains pipelines and apps
from the 
[Thomas Wilson laboratory](https://wilsonte-umich.github.io)
at the University of Michigan
for general processing of Oxford Nanopore read data, 
including activities like basecalling, POD5 file manipulation, 
modification modeling, etc.

In general, these tools implement publicly
distributed ONT software and act upstream of genome-specific
actions like alignment and variant calling.

### Available tools

Pipelines and apps in stable release, based on established modules:
- **ont** = a simple pipeline wrapper around download, convert, repack, and basecall actions

Pipelines and apps in alpha, with exploratory code that is not considered stable:
- **modmod** = train a base modification model (modmod) using concatemerized oligos

Shared action modules for use by other pipelines include:
- **download** = downlad ONT software and basecalling models
- **convert** = convert FAST5 files to POD5 format
- **repack** = sort a set of POD5 files from a single ONT run to one POD5 file per channel group prior to duplex analysis
- **basecall** = perform efficient basecalling (and optionally alignment) on POD5 reads on a shared compute cluster

# Installation and usage

Please see the [ont-mdi-tools documentation site](https://wilsontelab.github.io/ont-mdi-tools)
for detailed information on suite installation and the usage of specific pipeline and apps.

Otherwise, code from several shared modules is written as 
[standalone scripts](https://wilsontelab.github.io/ont-mdi-tools/docs/20_standalone_scripts/00_standalones.html)
available for use under the MIT license. 
