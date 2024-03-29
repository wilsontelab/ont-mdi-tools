---
title: Install code
parent: Installation and usage
has_children: false
nav_order: 10
published: true
---

## {{page.title}}

You can install MDI tool suites, including ont-mdi-tools, in one of two ways: 
- as a **multi-suite installation** that carries one or more distinct tool suites (recommended), 
- as a dedicated **single-suite installation**.

Choose one of the methods to install the code,
then continue on to build your runtime environments.

---
## Installation Method 1: multi-suite installation (recommended)

In the recommended multi-suite mode, you will:
- clone and install the MDI framework
- add ont-mdi-tools (and potentially other suites) to your MDI installation
- call the _mdi_ utility to use tools from any installed suite

### Install the MDI framework

Please read the _install.sh_ menu options and the 
[MDI utility instructions](https://github.com/MiDataInt/mdi.git) to decide
which installation option is best for you. Choose option 1
if you will only run Stage 1 HPC pipelines from your installation.

```bash
git clone https://github.com/MiDataInt/mdi.git
cd mdi
./install.sh
```

### OPTIONAL: Add an _mdi_ alias to _.bashrc_

The following commands will create a permanent named alias to the _mdi_
target script in your new installation.

```bash
./mdi alias --help
./mdi alias --alias mdi # change the alias name if you'd like 
`./mdi alias --alias mdi --get` # activate the alias in the current shell (or log out and back in)
```

Alternatively, you can add the MDI installation directory to your PATH variable,
or change into the directory prior to calling _./mdi_.

### Add the ont-mdi-tools suite to your MDI installation

```bash
./mdi add --help
./mdi add -s wilsontelab/ont-mdi-tools 
```

Alternatively, you can manually edit 'config/suites.yml' to include 
wilsontelab/ont-mdi-tools and re-run `./install.sh` to install it.

### Execute a Stage 1 pipeline from the command line

For help, call the _mdi_ utility with no arguments, which describes the format for pipeline calls. 

```bash
./mdi  # call the mdi utility directly without an alias, OR
mdi    # if you created an alias as described above
mdi ont # or change to one of the other pipelines...
# etc.
```


---
## Installation Method 2: single-suite installation

In the alternative single-suite mode, you will install just the ont-mdi-tools suite by:
- cloning this tool suite repository
- running _install.sh_ to create a suite-specific MDI installation
- OPTIONAL: calling _alias.pl_ to create an alias to the suite's _run_ utility
- calling the _run_ utility to use a tool from the suite

### Install this tool suite

```bash
git clone https://github.com/wilsontelab/ont-mdi-tools.git
cd ont-mdi-tools
./install.sh
```

### OPTIONAL: Create an alias to the suite's _run_ utility

```bash
perl alias.pl ont # you can use a different alias name if you'd like
```

Alternatively, you can add the installation directory to your PATH variable,
or change into the directory prior to calling _./run_.

### Execute a Stage 1 pipeline from the command line

For help, call the _run_ utility with no arguments, which describes the format for pipeline calls. 

```bash
./run  # call the run utility directly without an alias, OR
ont    # use the alias, if you created it as described above
```
