---
title: General usage
parent: Installation and usage
has_children: false
nav_order: 40
published: true
---

## {{page.title}}

As [described here](https://midataint.github.io/docs/analysis-flow/),
data analysis in MDI tool suites is divided into two stages called
**pipelines**, which perform high-performance computing on Linux servers,
and **apps**, which support interactive data visualization in R Shiny.

At present ont-mdi-tools only offers pipelines.

### Methods and help for calling MDI pipelines

Please see the [detailed documentation](https://midataint.github.io/mdi) 
and MDI command help:

```sh
mdi --help
```

for information about the ways you can execute an MDI pipeline on your server. Briefly,
you can run a pipeline action as a program from the command line, e.g.:

```sh
mdi <pipeline> <action> [options] # e.g., mdi ont basecall
```

However, rather than specifying options at the command line, 
we recommend creating a job configuration file and then either calling it directly:

```sh
mdi <pipeline> <data.yml> # e.g., mdi ont mydata.yml
```

or, better yet, submitting it to the job scheduler on your HPC cluster:

```sh
mdi submit <data.yml> # e.g., mdi submit mydata.yml
```

### Help for assembling job configuration files

Complete instructions for constructing MDI job files are found here -
there are many additional helpful features.
- <https://midataint.github.io/mdi/docs/job_config_files.html>

The following command will print a template you can use to 
quickly construct a new job file from scratch.

```sh
mdi <pipeline> template --help
mdi <pipeline> template > mydata.yml # e.g., mdi ont template
nano mydata.yml
```

Finally, the following commands will show help for a pipeline
or one of its actions to understand how options are organized and what they do:

```sh
mdi <pipeline> --help          # e.g., mdi ont --help
mdi <pipeline> <action> --help # e.g., mdi ont basecall --help
```

### Using ont-mdi-tools code outside of our pipelines

You may use whatever code you'd like from this repository
in your own pipelines subject to the MIT license. 

In particular, shared modules `repack` and `basecall` offer 
[standalone scripts](https://wilsontelab.github.io/ont-mdi-tools/docs/20_standalone_scripts/00_standalones.html)
for performing IO-intensive actions
on POD5 files on shared HPC resource servers. 
