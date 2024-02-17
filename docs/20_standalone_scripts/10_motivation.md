---
title: Motivation and design
parent: Standalone scripts
has_children: false
nav_order: 10
published: true
---

## Use case for standalone scripts

People needing to perform HPC actions on POD5 files
on shared resource servers, e.g., on a Slurm work node on a university cluster, 
will benefit from scripts that optimize file IO. 
Poor attention to these critical issues can make programs MUCH slower
than they might otherwise be. 

If you are struggling with slow POD5 processing, these scripts might help you. 
Our goal is to keep your cluster CPUs and/or GPUs working as close to 100% as possible.

### Problems and solutions

The common approach used by the standalone scripts is to support
batched analysis of a portion of your total POD5 files at a time, which
solves many problems.

| Problem | Solution / Strategy |
|-----------|------------|
| File IO to/from nodes is slow | Batched analysis and parallel processing allow file transfers to/from nodes and ONT commands to run largely concurrently |
| POD5 file actions are IO limited, HDD drives are very slow | Batched analysis allows use of shared memory drives, i.e., /dev/shm (or small SSD drives) for maximial processing speed |
| ONT data sets are very large | Batched analysis makes it unnecessary for all of your run data files to reside on your fastest drives at the same time |
| Basecalling sometime crashes | Batched writing of bam files allows jobs to be restarted from where they failed |
