---
title: Pipeline Shared Files
parent: Stage 1 Pipelines
has_children: true
nav_order: 30
---

## {{page.title}}

MDI Stage 1 Pipelines suites support three types of reusable code 
components that can be shared between all pipelines in the suite,
which are defined in the _\<suite\>/shared_ folder.

- **environments** = yml config files that create conda environments for job execution
- **modules** = script libraries that provide code for use by running pipelines
- **options** = yml config files that expose option families for job configuration

In all cases, the components are effectively placed inline into the 
_pipeline.yml_ file that configures a specific pipeline.

### Private vs. shared components

Environments and options can be defined privately for a 
pipeline within its _pipeline.yml_ file, used from the shared folder, or both.
The framework first looks to see if a component is present in the shared
folder and loads that configuration first. It then further looks to see 
if there are pipeline-specific definitions for the named component in 
_pipeline.yml_. If no shared component was found, the definition must 
exist in its entirety in _pipeline.yml_. If a shared component was found,
any further definitions in _pipeline.yml_ override the shared configuration.

Modules, by their nature, are encapsulated components that are 
always loaded from the 'shared' folder.

### External components

Component sharing can extend beyond a single tool suite, such that
_pipeline.yml_ may also attempt to load an environment, module, or option 
family from a different tool suite, which must also be installed into 
the working MDI directory by setting `suite_dependencies` in the calling suite's
_\_config.yml_ file.

```yml
# _config.yml
suite_dependencies:
    - <git_user>/<suite>
```

To use external components in pipeline.yml, prefix the component path
with '\<suite\>//', where \<suite\> is the name of the external suite from
which to load the component.

```yml
# pipeline.yml
actions:
    actionName:
        condaFamilies:
            - <suite>//shared-conda  
        module: <suite>//example/shared-module
        optionFamilies:
            - <suite>//shared-options
```

If running in developer mode, the MDI pipelines framework looks for external component files
in a forked repository first, if it exists. Otherwise, it falls back to using
files from definitive suite repositories.

## Shared component versioning

Similar to pipelines, the version of a shared component is implicitly
derived from the version of its parent suite, i.e., setting the
version of a tool suite always yields the same, specific version of the component. 

If your pipeline requires a specific version of an external tool suite
(and therefore of its components), you may override the default version of 
`latest` at the pipeline level:

```yml
# pipeline.yml
pipeline: ...
suiteVersions: # must come before 'actions'
    suiteName: v0.0.0 # use this version of a suite invoked as 'suite//module', etc. [latest]
actions: ...
```
