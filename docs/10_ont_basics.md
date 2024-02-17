---
title: ONT basics
has_children: false
nav_order: 10
published: true
---

## {{page.title}}

A high-level overview of nanopore sequencing is provided by many reviews, 
including our structural variant (SV) review:

- <https://pubmed.ncbi.nlm.nih.gov/37931775/>

Key features exploited by functions in ont-mdi-tools include:

- (very) long reads support improved structural assembly and SV detection
- duplex sequencing of both DNA strands supports high accuracy basecalling
- direct sequencing of genomic DNA molecules supports modification analysis

### ONT support software

Detailed descriptions of Oxford Nanopore Technologies (ONT) methods and
data types is beyond our scope here, but well documented by ONT:

- ONT on GitHub: <https://github.com/nanoporetech>
- POD5 files and utility: <https://github.com/nanoporetech/pod5-file-format>
- Dorado basecaller: <https://github.com/nanoporetech/dorado>
- Remora modification modeleing: <https://github.com/nanoporetech/remora>

ont-mdi-tools provides wrappers that make it easier to install and use these programs.

### POD5 files are IO intensive

ONT flowcells generate electrical signal data as "traces", or "squiggles",
one DNA molecule at a time, in each of up to a few thousand nanopore "channels". 
That data are stored in POD5 files for basecalling and modification analysis.

It is critical to understand that:
- POD5 files can easily grow to 1T or more in net size
- programs that use POD5 files are often IO-bound

Thus, disk speed is a main limit on program performance.
ont-mdi-tools implements strategies to maximize file IO to keep processing speed high.
Large files are moved _en bloc_ to fast drives for iterative access by ONT software.
