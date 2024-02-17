---
title: Build environments
parent: Installation and usage
has_children: false
nav_order: 20
published: true
---

## {{page.title}}

Most MDI pipelines, including those in ont-mdi-tools, depend
on third-party programs installed into an appropriate runtime
environment.

### Conda environments

All pipeline environments can be set up using [conda](https://docs.conda.io/en/latest/),
which must be installed and available on your system. You then call
the following MDI command(s) to create/build the required environment(s).

```sh
mdi ont conda --help 
mdi ont conda --create 
mdi ont conda --list 

mdi modmod conda --create  # etc.
```
