---
title: Benchmarking example
parent: Standalone scripts
has_children: false
nav_order: 30
published: true
---

## {{page.title}}

We provide details on a run of a single Promethion flow cell used
to sequence a rapid-kit whole-genomic library to exhaustion. This is a  smaller data set as compared to the deepest ligation kit libraries,
but sufficiently large to provide a reference.

### The objective

Our structural variant pipeline demands proper duplex
calling to avoid taking complementary strands as falsely independent SV evidence. Thus, our goal was to perform batched basecalling using
`dorado duplex`.

Importantly, duplex basecalling:
- occurs by nanopore channel (different channels cannot sequence two duplex strands)
- requires access to all reads from a given channel

Batching MinKnow-generated POD5 files creates a problem, since reads from all channels
are found in all files. Therefore, a preparative step is needed to ensure that all reads from a given channel are found in 
a single file.  In ont-mdi-tools, this is the sequence:

- `MinKnow` >> `repack` >> `basecall`

### The data

MinKnow generated >2K POD5 files of 570G net size from our flowcell.

```sh
$ du -h pod5_pass
570G    pod5_pass

$ ls -l pod5_pass | wc -l
2178
```

### Repacking the POD5 files

We use `repack` to refer to the parsing of reads such that:
- there are many fewer total POD5 files once done
- each resulting POD5 file has all reads from a predetermined group of nanopore channels

We pointed 'repack.sh' at 'pod5_pass' and sourced the script
using:
- /dev/shm/ as `POD5_BUFFER_DIR`
- `POD5_BATCH_SIZE` and `CHANNEL_GROUP_SIZE` of 50

The job completed in 3h 1min, generating the following output:

```sh
$ du -h pod5_pass_by_channel_group/
570G    pod5_pass_by_channel_group/

$ ls -l pod5_pass_by_channel_group/ | wc -l
61

$ ls -lh pod5_pass_by_channel_group/ | head -n5
total 570G
-rw-r--r-- 1 xx xx 6.3G Feb 16 16:04 channel_group-0.pod5
-rw-r--r-- 1 xx xx  11G Feb 16 16:13 channel_group-10.pod5
-rw-r--r-- 1 xx xx  12G Feb 16 16:14 channel_group-11.pod5
-rw-r--r-- 1 xx xx  11G Feb 16 16:16 channel_group-12.pod5
```

Note the preservation of net file size in many fewer repacked files.

Each file batch completed processing by `pod5 subset` in ~2min:

```
Parsed 8669416 targets
Calculated 200000 transfers
Subsetting: 100%|##########| 60/60 [02:06<00:00,  2.10s/Files]
Done    
```

### Duplex basecalling

We next pointed 'basecall.sh' at 'pod5_pass_by_channel_group' and sourced the script
using:
- /dev/shm/ as `POD5_BUFFER_DIR`
- `POD5_BATCH_SIZE` of 2 (files are now much larger)
- 8 CPU
- 4 A40 GPU
- 96 GB requested RAM

The job completed in 9h 49min, generating the following output (we 
use downstream read alignment):

```
$ ls -lh ubam/ | head -n 5
total 42G
-rwxrwxr-- 1 xx xx  1.1G Feb 16 19:30 batch_1_0.unaligned.bam
-rwxrwxr-- 1 xx xx  979M Feb 16 21:13 batch_1_10.unaligned.bam
-rwxrwxr-- 1 xx xx  1.6G Feb 16 21:37 batch_1_12.unaligned.bam
-rwxrwxr-- 1 xx xx  1.7G Feb 16 22:03 batch_1_14.unaligned.bam
```

Each file batch completed processing by `dorado duplex` in ~20min.
Critically, monitoring during the run using `nvidia-smi` and `top` verified
that basecalling was nearly continuously active with all four GPUs activated
at 100% load. The batch size provided an excellent balance between short load time and much longer processing time.

```
[2024-02-16 19:13:01.172] [info] > No duplex pairs file provided, pairing will be performed automatically
[2024-02-16 19:13:37.758] [info]  - set batch size for cuda:0 to 640
[2024-02-16 19:13:37.821] [info]  - set batch size for cuda:1 to 640
[2024-02-16 19:13:37.885] [info]  - set batch size for cuda:2 to 640
[2024-02-16 19:13:37.949] [info]  - set batch size for cuda:3 to 640
[2024-02-16 19:13:48.532] [info]  - set batch size for cuda:0 to 1792
[2024-02-16 19:13:49.053] [info]  - set batch size for cuda:1 to 1792
[2024-02-16 19:13:49.545] [info]  - set batch size for cuda:2 to 1792
[2024-02-16 19:13:50.037] [info]  - set batch size for cuda:3 to 1792
[2024-02-16 19:13:50.038] [info] > Starting Stereo Duplex pipeline
[2024-02-16 19:13:50.067] [info] > Reading read channel info
[2024-02-16 19:13:50.474] [info] > Processed read channel info
[2024-02-16 19:30:20.844] [info] > Simplex reads basecalled: 254046
[2024-02-16 19:30:20.845] [info] > Simplex reads filtered: 65
[2024-02-16 19:30:20.845] [info] > Duplex reads basecalled: 2684
[2024-02-16 19:30:20.846] [info] > Duplex rate: 2.444646%
[2024-02-16 19:30:20.846] [info] > Basecalled @ Bases/s: 1.215756e+06
```
