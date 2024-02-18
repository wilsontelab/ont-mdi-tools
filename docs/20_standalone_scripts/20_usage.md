---
title: General usage
parent: Standalone scripts
has_children: false
nav_order: 20
published: true
---

## {{page.title}}

As the name implies, the standalone scripts do not require
any specific integration with MDI pipelines. To use them, simply 
set a few environment variables by whatever methods makes sense
for your use case, then source the bash scripts.

```sh
EXPANDED_INPUT_DIR=/path/to/pod5s
READ_IDS_FILES=/path/to/read_ids.txt
POD5_OUTPUT_FILES=/path/to/out.pod5
POD5_BATCH_SIZE=50
# etc.
source filter.sh
```

```sh
EXPANDED_INPUT_DIR=/path/to/pod5s
POD5_BATCH_SIZE=50
CHANNEL_GROUP_SIZE=50
# etc.
source repack.sh
```

```sh
ONT_MODEL_DIR=/path/to/ont/model
EXPANDED_INPUT_DIR=/path/to/pod5s
BAM_DIR=/path/to/bams
POD5_BATCH_SIZE=50
# etc.
source basecall.sh
```

Full details about the required and available environment variables
are provided at the top of the standalone scripts.

- filter: <https://github.com/wilsontelab/ont-mdi-tools/blob/main/shared/modules/filter/filter.sh>
- repack: <https://github.com/wilsontelab/ont-mdi-tools/blob/main/shared/modules/repack/repack.sh>
- bacecall: <https://github.com/wilsontelab/ont-mdi-tools/blob/main/shared/modules/basecall/basecall.sh>
- condense: <https://github.com/wilsontelab/ont-mdi-tools/blob/main/shared/modules/condense/condense.sh>

### Tuning script usage

The environment variables will first, and obviously, 
point to the files and directories you need to analyze.

Others, notably `POD5_BATCH_SIZE` and `CHANNEL_GROUP_SIZE`, 
tune the batched analyses to your system and needs.

The key factor in deciding how large a batch to use is matching
the size of your files to the size of the fast local drive you
will use on the node during active processing. We often
use /dev/shm (shared memory virtual file system), so set the batch
size to ensure that we won't overrun the node's RAM,
including the memory required for the programs to run, etc.

Comments in the scripts provide detailed example calculations and guidelines.

Even if you have a large local /tmp SSD available,
don't set the batch size too high. With a large
batch size, you may wait too long for the initial file transfer before the ONT software can begin - 
one goal of batching is to allow file transfers and data processing to run concurrently.

However, too small a batch size is also non-productive, because you 
will incur excessive overhead from repeating the startup actions of
programs like `dorado` too many times. Let experience be your guide,
but we have good success running up to 50G file batches. 

Finally, some ONT runs with short reads generate massive numbers
of POD5 files with current versions of MinKnow. The sheer number of file
transfers to work nodes can become a bottleneck. In such a case, consider
running the `condense` script or pipeline action to reduce the file
number before running `repack` or `basecall`.

### Running batches in parallel

The `repack` action cannot benefit from further parallelization,
since the action must integrate data from all POD5 files
in a single data set.

In contrast, `basecall` batches could be executed in parallel on different nodes.
The script does not explicitly support this. 
You could do it yourself by how you set the directories, however, we find that:
- basecalling is sufficiently fast with serial batching (measured in hours)
- GPU nodes are more precious and subject to usage limits and competition

Thus, we recommend running a single multi-GPU node at maximum for basecalling
one flowcell data set. If you can run more nodes, put different data set(s) on the other node(s).
