---
title: "Wrapper pipeline: ont"
has_children: false
nav_order: 40
published: true
---

## {{page.title}}

The `ont` pipeline has no larger purpose, it is a simple
wrapper around some of the core actions provided by the 
ont-mdi-tools repository, namely:

- `download` ONT software and models
- `convert` FAST5 to POD5 files
- `repack` time-series POD5 files from MinKnow by channel group for duplex analysis
- `basecall` POD5 signal data in simplex or duplex mode

Most actions are wrappers that
help you run ONT software such as `pod5` and `dorado`
correctly and efficiently. They are not separate implementations
of these program functions. 

Developers of more complex MDI pipelines with bigger downstream goals
can use `ont` as a template to get started, since many of these
same steps will start most ONT pipelines.

### Usage

See our [general installation and usage help](https://wilsontelab.github.io/ont-mdi-tools/docs/30_installation/00_installation.html) and:

```sh
mdi --help
mdi ont --help
mdi ont basecall --help # etc.
```
