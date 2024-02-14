# MDI Tools Suite Template

The [Michigan Data Interface](https://midataint.github.io/) (MDI) 
is a framework for developing, installing and running 
Stage 1 HPC **pipelines** and Stage 2 interactive web applications 
(i.e., **apps**) in a standardized design interface.

This is a **repository template** you can use to
create a new **MDI tools suite**. Follow the instructions
below to copy this repository, then fill your copy with code to define 
a suite of your own data analysis pipelines and/or apps.

The steps below were performed and provided as a separate working 
tool suite repository you can use to validate your MDI installation 
with a simple demo pipeline and app.

- <https://github.com/MiDataInt/demo-mdi-tools.git>

## Template usage

### Create a new repository from this template

**To get started quickly**, 
[click here to create a new suite repository from this template](https://github.com/MiDataInt/mdi-suite-template/generate).

You will be prompted for the user and name of the repository you would like 
to create. We recommend **NAME-mdi-tools**, replacing 'NAME' with a specific, 
informative name of your choosing, e.g., 'johndoelab'.

### Copy and use the _template pipeline or app

The easiest way to start a new tool is to copy and modify the _\_template_
pipeline or app, which provides a working boilerplate for all required code. 
Copy/paste, change the folder name, and start coding. Along the way,
write documentation files for your tools.

### Additional instructions

Please see the following documentation pages for detailed information
on using the features of your new tool suite and the MDI frameworks
to quickly develop pipelines and apps:

- [Tool suite template documentation](https://midataint.github.io/mdi-suite-template)
- [MDI pipelines framework documentation](https://midataint.github.io/mdi-pipelines-framework)
- [MDI apps framework documentation](https://midataint.github.io/mdi-apps-framework)

---
## Quick Start Method 1: multi-suite installation (recommended)

You can install MDI tool suites in one of two ways: as a **multi-suite installation** that carries one or more distinct tool suites (recommended), or as a more contained **single-suite installation** dedicated to just one tool suite.

In the recommended multi-suite mode, you will:
- clone and install the MDI framework
- add this tool suite (and potentially others) to your MDI installation
- call the _mdi_ utility to use tools from any installed suite

### Install the MDI framework

Please read the _install.sh_ menu options and the 
[MDI installer instructions](https://github.com/MiDataInt/mdi.git) to decide
which installation option is best for you. Briefly, choose option 1
if you will only run Stage 1 HPC pipelines from your installation.

```bash
git clone https://github.com/MiDataInt/mdi.git
cd mdi
./install.sh
```

### OPTIONAL: Add an _mdi_ alias to _.bashrc_

These commands will create a permanent named alias to the _mdi_
target script in your new installation.

```bash
./mdi alias --help
./mdi alias --alias mdi # change the alias name if you'd like 
`./mdi alias --alias mdi --get` # activate the alias in the current shell (or log out and back in)
mdi
```

Alternatively, you can add the MDI installation directory to your PATH variable,
or always change into the directory prior to calling _./mdi_.

### Add this tool suite to your MDI installation

```bash
./mdi add --help
./mdi add -p -s GIT_USER/NAME-mdi-tools 
```

Alternatively, you can perform the required suite addition steps one at a time:

```sh
nano config/suites.yml # or use any other text editor to edit suites.yml
```

```yml
# mdi/config/suites.yml
suites:
    - GIT_USER/NAME-mdi-tools # add this tools suite to the config file
```

```sh
./install.sh # re-install to add the new tool suite
```



### Execute a Stage 1 pipeline from the command line

For help, call the _mdi_ utility with no arguments, which describes the format for pipeline calls. 

```bash
./mdi  # call the mdi utility directly without an alias, OR
mdi    # if you created an alias as described above
```

### Launch the Stage 2 web apps server

To launch the MDI web server, we recommend using the 
[MDI Desktop app](https://midataint.github.io/mdi-desktop-app),
which allows you to control both local and remote MDI web servers.

---
## Quick Start Method 2: single-suite installation

In the alternative single-suite mode, you will install just this tool suite by:
- cloning this tool suite repository
- running _install.sh_ to create a suite-specific MDI installation
- OPTIONAL: calling _alias.pl_ to create an alias to the suite's _run_ utility
- calling the _run_ utility to use a tool from the suite

### Install this tool suite

```bash
git clone https://github.com/GIT_USER/NAME-mdi-tools.git
cd NAME-mdi-tools
./install.sh
```

### OPTIONAL: Create an alias to the suite's _run_ utility

```bash
perl alias.pl NAME # you can use a different alias name if you'd like
```

Alternatively, you can add the installation directory to your PATH variable,
or always change into the directory prior to calling _./run_.

### Execute a Stage 1 pipeline from the command line

For help, call the _run_ utility with no arguments, which describes the format for pipeline calls. 

```bash
./run  # call the run utility directly without an alias, OR
NAME # use the alias, if you created it as described above
```

### Launch the Stage 2 web apps server

To launch the MDI web server, we recommend using the 
[MDI Desktop app](https://midataint.github.io/mdi-desktop-app),
which allows you to control both local and remote MDI web servers.

