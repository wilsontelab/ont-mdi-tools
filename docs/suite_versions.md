---
title: Semantic Versioning
has_children: false
nav_order: 60
published: true # set to false to remove this tab from your suite's doc site
---

## {{page.title}}

### Suite versions

You are encouraged (but not required) to use Git tags, via the 
[GitHub releases feature](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository), 
to maintain a proper version history of your tool suite.
The MDI uses the semantic versioning pattern, 'v0.0.0', described here:

- <https://semver.org/>

Only you can decide how to implement a versioning scheme
for your tool suite, but here are some guidelines:

- advance the patch (3rd) version number for bug fixes and small feature additions
- advance the minor (2nd) version number whenever:
    - new program dependencies are introduced, e.g., via conda
    - new pipelines, apps, or other major code features are introduced
- advance the major (1st) version whenever breaking changes are introduced that
would prevent job files written for previous versions from working with the current version

Please note that Git version/release tags apply to the entire tool suite,
not to individual pipelines or apps. Thus, you 
should advance the tool suite version whenever a matching code change
occurs in any of the tools carried in the suite repository. 

If you choose not to use version/release tags for your tool suite,
users will always be placed onto the tip of the main branch, i.e., the most
recent code commit on `main`.  If you do use versions, the tip of the main
branch can be accessed with the version directive **pre-release**, whereas
the most recent release tag can be accessed with the directive **latest**.
These last examples show the value of having release tags, as they help ensure
that `latest` (the default) always points to stable code.

### Pipeline and app versions

Distinct from the tool suite git version tags discussed above, you may also
declare versions of specific pipelines and apps within their YAML configuration files, e.g.:

```yml
# pipeline.yml
pipeline:
    name: myPipeline
    description: "Description of myPipeline"
    version: v0.0.0
```

Such tool versions should _not_ be placed into git version tags unless prefixed with the
name of the tool, e.g., 'myPipeline-v0.0.0', but this is usually not necessary. 
All git tags of format 'v0.0.0' are assumed to be tool suite versions. Thus, to communicate
the version of a tool it is best to simply provide the version of the tool suite that
carries it, which always has an unambiguous mapping to a tool version.

Tool versions are also optional except for pipelines that
offer pipeline-level Singularity containers, which are tagged with the major and minor
versions of the pipeline, e.g. 'myPipeline:v0.0'. Note that the patch version is _not_
included in container labels, so either the minor or major pipeline
version must be advanced whenever a new system or program dependency is introduced for a 
given pipeline for any of its actions. 
