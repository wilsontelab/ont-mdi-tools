---
title: Pipeline Config Files
parent: Stage 1 Pipelines
has_children: false
nav_order: 20
---

## {{page.title}}

Each pipeline must have a configuration file named
_pipelines/\<pipeline\>/pipeline.yml_
with metadata about the pipeline.  

Please see the comments in the _\_template/pipeline.yml_ in addition 
to the guidance below. Only non-obvious sections not covered 
well elsewhere are described here.

The best way to get started is simply to copy and modify a current,
working pipeline.yml file.

## Pipeline action declarations

```yml
# pipeline.yml
actions: 
    actionName: # change this to the name of your action
        order: 1
        thread: threadName
        environment: environmentName
        condaFamilies:
        optionFamilies:
        resources:
            required:
                total-ram: 2G
            recommended: 
                n-cpu: 1
                ram-per-cpu: 2G
        job-manager:
            recommended:
                time-limit: 1:00:00
        description: "short descriptive text"   
```

All action tags are optional except `description`. 

### Execution threads

When work is submitted to the job scheduler, the default behavior
is for all jobs to run in series. Sometimes you may want different 
actions to run in parallel. This is achieved using the `thread` key,
by giving parallel actions different thread names. The `submit` action
will make a job dependent on a job before it if, and only if, it
has the same thread name. 

Most often, the `thread` key can be omitted.

### condaFamilies

All pipelines use conda to construct an appropriate execution
environment with proper versions of all required program
dependencies, for explicit version control, reproducibility,
and portability. 

List software dependencies as follows - 
see <https://anaconda.org/> to search for available software.
The format is essentially the same as a conda 
[environment.yml](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#sharing-an-environment)
file.

```yml
# pipeline.yml
actions: 
    actionName: # change this to the name of your action
        environment: environmentName
        condaFamilies:
            - familyName
condaFamilies:
    familyName:
        channels: # optional, can often be omitted
            - abc
        dependencies: # load specific programs or versions
            - xyz=1.16.3
```

The name of the family to associate with the action is listed under 
`actions`. The family is defined under `condaFamilies` at root level
in _pipeline.yml_, or in a shared environment file. Indeed, the point
of calling families by name is that they can be shared easily.

If the `environment` key is not null, it is used as the name of 
the environment directory, otherwise a unique name is derived 
from a hash of the environment contents.

### optionFamilies

You expose options settable by the user via the `optionFamilies` key,
in a format that directly mirrors  `condaFamilies`, except that now
the family lists options with the obvious set of keys below:

```yml
# pipeline.yml
actions: 
    actionName: # change this to the name of your action
        optionFamilies:
            - familyName
optionFamilies:
    familyName:
        options:
            optionName: 
                order: 1
                short: i
                type: string
                required: true
                default: null
                directory: # optional content for directories only
                    must-exist: true
                    bind-mount: true # options 'directory' are bind-mounted to containers by default
                description: "short descriptive text"  
```

### Server environment suggestions

The `resources` and `job-manager` keys may be used to indicate
the required and/or recommended system resources for an action,
according to the format indicated. RAM value require a single-letter suffix.

### Sharing family declarations between actions

Sometimes different pipeline actions share common family declarations.
You may be able to simplify your pipeline.yml file by using the `_global`
key as follows:

```yml
# pipeline.yml
actions:
    _global:   
        environment: environmentName
        condaFamilies: 
        optionFamilies:
```

Any entry in `_global` is applied equally to all pipeline actions.
If present, the `_global` key must come before `condaFamilies` and `optionFamilies`.

Providing an environment name in `_global`
allows you to create, and update (rather than replace), a single conda
environment for all actions, which sometimes speeds development. 

## Data package declaration

Many MDI Stage 1 Pipelines are designed to create smaller data files suitable
for loading into a Stage 2 App. Such files are zipped into a single 
data package file associated with one or more pipeline actions, as follows:

```yml
# pipeline.yml
package:
    actionName1: # the pipeline action after which a data package should assembled
        uploadType: typeName # a signal to the Stage 2 framework regarding the package contents
        files:
            fileType:  # a contentFileType of any name you choose; 'manifestFile' has special meaning
                type: abc # additional information as to the file type
                file: $DATA_FILE_PREFIX.xxx.txt    
    actionName2: 
        uploadType: typeName
        extends: actionName1 # the new package will add files to the package from a previous step
        files: # continue as above
```

The example above would create two data packages after `actionName1`
and `actionName2`, where the `actionName2` file includes all files from `actionName1` 
plus any new ones it added. Most pipelines require zero or one packages.
