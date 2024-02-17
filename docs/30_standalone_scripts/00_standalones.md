---
title: Standalone scripts
has_children: true
nav_order: 30
published: true
---

## {{page.title}}

Shared modules `repack` and `basecall`
offer standalone scripts for performing IO-intensive actions
on POD5 files on shared HPC resource servers. These same
scripts are used in our pipelines but designed to be easily
portable for incorporation into other pipelines.

### Use case for standalone scripts

People who wish to perform HPC actions on POD5 files
on shared resource servers, e.g., on a Slurm work node on a university cluster, 
will benefit from scripts that manage file transfers
and other IO issues in an optimized fashion. Poor attention
to these critical issues can make certain steps MUCH slower
than they might otherwise be. 

If you are shocked at how long your POD5 processing steps are taking,
these scripts might help you. Our goal is to keep your CPUs and/or GPUs
working as close to 100% as possible.

### Problems and solutions

The common approach used by the standalone scripts is to support
batched analysis of a portion of your total POD5 files at a time, which
solves many problems.

| Problem | Solution / Strategy |
|-----------|------------|
| File IO to/from nodes is slow | Batched analysis and parallel processing allow file transfers and ONT commands to run largely concurrently |
| POD5 file actions are IO limited, HDD drives are very slow | Batched analysis allows use of shared memory drives, i.e., /dev/shm (or smaller SSD drives) for maximial processing speed |
| ONT data sets are very large | Batched analysis makes it unnecessary for all of your run data files to reside on your fastest drives at the same time |
| Basecalling sometime crashes | Batched writing of bam files allows jobs to be restarted from where they failed |


### General usage

As stated, thesea are standalone scripts that do not require
any specific integration with MDI pipelines. To use them, you simply 
set a couple of environment variables by whatever methods makes sense
for you use case, then source the bash scripts.

```sh
XXX=xxx
source repack.sh

XXX=xxx
source basecall.sh
```

Full details about the required and available environment variables
are provided at the top of the standalone scripts.

### Benchmarking and validation

Pending.

