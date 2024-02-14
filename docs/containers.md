---
title: Singularity Containers
has_children: false
nav_order: 50
published: true # set to false to remove this tab from your suite's doc site
---

## {{page.title}}

Developers can help users enjoy the fastest and most controlled 
pipeline execution by supporting Singularity containers.
You can choose to wrap your entire tool suite, or just individual pipelines, in 
container images that you distribute in a registry, such as the GitHub Container Registry.

- Singularity: <https://sylabs.io/guides/latest/user-guide/>
- GitHub Container Registry: <https://docs.github.com/en/packages/>

In all cases, the user's system must support Singularity containers. If it does not,
the mdi utility will revert to conda-based execution.

### Suite-level containers

The simplest approach is to enable your entire tool suite for container support
by editing files (please see comments within for more information):

- _config.yml
- singularity.def

The advantage of this approach is simplicity. 
A potential disadvantage is the larger size of the resulting container.

An example of the relevant section of _\_config.yml_ activated for suite-level containers is:

```yml
# _config.yml
container:
    supported:  true 
    registry:   ghcr.io 
    owner:      GIT_USER 
    installer:  apt-get
    stages:
        pipelines: true 
        apps:      false # OBSOLETE: no longer used
```

### Pipeline-level containers

Alternatively, you may place individual pipelines into their own containers.
This is accomplished by appropriate edits to:

- pipeline.yml
- pipelines/\<pipeline\>/singularity.def

An example of the relevant section of pipeline.yml activated for pipeline-level containers is:

```yml
# pipeline.yml
container:
    supported: true 
    registry:  ghcr.io 
    owner:     GIT_USER 
    installer: apt-get  
```

Note that suite-level containers take precedence, so set `containers:supported` to false
in _\_config.yml_ if you intend to support pipeline-level containers.

### Container configuration via singularity.def

The operating system and system libraries to be made available in 
your container are specified in _singularity.def_, while program dependencies are 
provided by conda environments pre-installed into the container. In other words,
containers still rely on proper `condaFamilies` declarations - what differs is where
the conda environments are built and by whom.

A complete description of Singularity definition files is beyond our scope 
(see link above), but most developers can simply use _singularity.def_
as it is provided in the suite template.  Otherwise, you might think about changing:

```yml
# singularity.def

# declare the operating system
Bootstrap: docker
From: ubuntu:20.04

# add to the %post scriptlet to prepare your container in ways beyond conda
%post
```
