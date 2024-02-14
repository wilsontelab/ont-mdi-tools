---
title: Suite Sharing
has_children: false
nav_order: 40
published: true # set to false to remove this tab from your suite's doc site
---

## {{page.title}}

All tool suites can be used in either a **single-suite** or **multi-suite** pattern, 
depending on whether the tool suite or the MDI is the first installation target.

You might want to adjust your documentation if you prefer one pattern, 
but both are available to users.

### Single-suite installation

In a single-suite installation, the user installs just your tool suite.
The _install.sh_ script in the suite template clones the MDI and configures
the installation for use. A renamable _run_ script in the template executes 
pipelines and launches a web server specific to the tool suite.

In this way, developers and users can think of the tool suite as the 
primary unit of installation and use.

### Multi-suite installation

In a multi-suite installation, the user instead first clones the MDI installation utility:

- [mdi git repository](https://github.com/MiDataInt/mdi) /
  [documentation](/mdi)

and executes its _install.sh_ script to set up an empty MDI installation. 
They must then make one or more tool suites known to the MDI installation by editing file 
_mdi/config/suites.yml_ as follows:

```yml
# mdi/config/suites.yml
suites:
    - GIT_USER/NAME-mdi-tools # either format works
    - https://github.com/GIT_USER/NAME-mdi-tools.git
```

and repeating the MDI installation.
Alternatively, they can install new suites from within the Stage 2 web server, 
or run the following from the command line:

```bash
mdi add -p -s GIT_USER/NAME-mdi-tools # either format works
mdi add -p -s https://github.com/GIT_USER/NAME-mdi-tools.git
```

In this way, users can maintain an extended MDI installation that carries
many tool suites in a one place, called from a single 'mdi' command target.

### Public vs. private distributions

If your repository is public (recommended), anyone will be able to perform the steps
above to use your tools. 

If your repository is private, you will need to provide a 
[GithHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
to clone and use your tool suite. Pass the token to MDI commands by creating file 
_~/gitCredentials.R_ (or, alternatively, _mdi/gitCredentials.R_):

```r
# ~/gitCredentials.R
gitCredentials <- list(
    USER_NAME  = "First Name",
    USER_EMAIL = "namef@umich.edu",
    GIT_USER   = "xxx",
    GITHUB_PAT = "xxx"
)
```

### Add your public tools to the MDI suite registry

For maximum visibility within the MDI, you may list your tool suite
in the registry on the 
[main MDI documentation page](https://midataint.github.io/docs/registry/00_index/). 

Only public suites that offer substantive, purposeful, non-malicious tools 
will be listed in the registry. All code used by your tools must be open source. 
Otherwise, we place no restrictions on the kind of suites you list. 

The steps for listing your suite are:
- fork the docs repo: <https://github.com/MiDataInt/midataint.github.io>
- make a copy of file _/_data/registry/_template.yml_ and edit as needed
- make a pull request to the parent repo

Any developer capable of writing a tool suite should have no problem
executing these steps by following the comments in _\_template.yml_.

When we receive your pull request, we will do a basic level of code review
to ensure that your suite appears appropriate, identifiable, and not nefarious. 
We will then either accept your pull request or reply with needed changes.

> **IMPORTANT** - the MDI team never takes responsibility for your code. You are
> responsible for all outcomes and queries related to the use of your tool suite by any user.
