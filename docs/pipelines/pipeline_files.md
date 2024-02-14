---
title: Pipeline-Specific Files
parent: Stage 1 Pipelines
has_children: false
nav_order: 10
---

## {{page.title}}

Each folder in **pipelines** has files that define 
the behavior of a single pipeline, a.ka. workflow.

### Pipeline actions

Each MDI pipeline must have one or more **actions** defined
in _pipeline.yml_ and organized into pipeline subfolders.
Actions are entered by users at the command line or in
_data.yml_ job configuration files.

```yml
# pipeline.yml (the pipeline's configuration file)
actions:
    actionName:
        ...
```

```bash
# command line
mdi <pipeline> <actionName> ...
mdi myPipeline do ...
```

```yml
# data.yml (a job configuration file)
pipeline: myPipeline
options: 
    ... 
execute:  # the list of actions to execute
    - do  # 'do' is the standardized name for a single-action pipeline
```

## Pipeline construction

Create one folder in _\<suite\>/pipelines_ for each distinct data 
analysis pipeline carried in your suite. Each pipeline 
might define its own specific code and/or use code elements 
in the _\<suite\>/shared_ folder.

Only one file is essential and must be present, called _pipeline.yml_.

Optional files include (see the _template pipeline for usage):
- _README.md_, to document the pipeline 
- _pipeline.pl_, which can be used to set custom environment variables 
- _singularity.def_, if your pipeline will offer or require a container to run

### Pipeline configuration file

Begin by editing file _pipeline.yml_, which is the configuration file that 
establishes your pipeline's identity, options, actions, etc. 
It dictates how users will provide information to your pipeline and 
where the pipeline will look for supporting scripts and definitions.

### Pipeline actions

Next, create a subfolder in your pipeline directory for each discrete **action**
defined in _pipeline.yml_. Many pipelines only require one action, which by convention is called 'do'. 
Alternatively, you might need multiple actions executed independently, e.g., a first action 'analyze' 
applied to individual samples followed by a second action 'compare' that integrates information from multiple samples.

By convention, the target script in an action folder is called **Workflow.sh** - 
it is the script that performs the work of the pipeline action.
There are no restrictions on how _Workflow.sh_ does its work. You may incorporate 
other code, make calls to programs, including calls to nested workflow managers such as snakemake, etc. 
One common pattern might be:

```bash
# pipelines/<pipeline>/<action>/Worflow.sh
TARGET_FILE=$DATA_NAME.XYZ
snakemake $SN_DRY_RUN $SN_FORCEALL \
    --cores $N_CPU \
    --snakefile $ACTION_DIR/Snakefile \
    --directory $TASK_DIR \
    $TARGET_FILE
checkPipe
```

### Output conventions

Data files written by a pipeline must always be placed into a folder the user specifies using 
options `--output-dir` and `--data-name`. File names should always be prefixed with the value of option
`--data-name`, such that pipeline output files follow the pattern:

```
<output-dir>/<data-name>/<data-name>.XXX
```

`--output-dir` and `--data-name` are thus universally required options, 
as enforced by the MDI pipelines framework, i.e., you do not need to list them.

By the
[MDI Code of Conduct](https://midataint.github.io/docs/registry/00_index/#mdi-developer-code-of-conduct),
pipelines are only allowed to write output files to `--output-dir`.

## Stage 1 versioning

### Pipeline versions

Individual pipeline versioning is optional but recommended as it will
help users to confidently access legacy versions of your code to analyze 
their data according to some previous standard.

Declaring pipeline versions is simple: just add a proper semantic version
declaration to pipeline.yml and update it prior to committing new code. 
It is not necessary to create Git tags for pipeline versions.

```yml
# pipelines/<pipeline>/pipeline.yml
pipeline:
    name: myPipeline
    description: "Description of myPipeline"
    version: v0.0.0
```

### External suite versions

If your pipeline uses code modules from external tool suites, you may
wish to specify the required versions of those external suites.
This is useful if you don't wish to adjust your pipeline to account for a
breaking change made in an external tool suite.  Declare such version
requirements as follows, replacing `suiteName` with the name of the
external tool suite.

```yml
# pipelines/<pipeline>/pipeline.yml
suiteVersions:
    suiteName: v0.0.0
```

If you do not provide a version for an external tool suite,
the latest version of that suite will be used.

If you only use pipeline code from within your own tool suite, the 
suiteVersions dictionary can be omitted from _pipeline.yml_.
