---
title: "Tool Suite Template"
has_children: false
nav_order: 0
---
<!--- edit the title above with the short name of your repository, 
      e.g, "My Tools", which will appear on the menu tab item -->

<!-- please do not alter the next line -->
{% include mdi-project-overview.md %}


<!-- replace this section with markdown content describing your tool suite -->
<!-- https://www.markdownguide.org/basic-syntax/ -->

These pages provide a detailed description of the **MDI tool suite template**, 
which you can use to create your own suite of Stage 1 Pipelines and Stage 2 Apps. 

- <https://github.com/MiDataInt/mdi-suite-template>

### Quick start

[**Click here**](https://github.com/MiDataInt/mdi-suite-template/generate) 
to create a new tool suite repository from the template.

>We recommend **NAME-mdi-tools** as the name of your 
repository, replacing 'NAME' with an informative name of your choosing, 
e.g., 'johndoelab'.

Open and edit the following files, using the instructions in comments
to find lines to edit to match your needs:

- _config.yml
- overview.md
- LICENSE (adjust the type, year, and licensee)
- README.md (delete the developer instructions, if desired)

Then copy and modify the '_template' pipeline or app, which provides a working 
boilerplate for all required code. 

### Further documentation

The rest of these pages walk you through
the basic structure of pipeline and app assemblies and 
provide a working reference as you write code.

In addition, you will want to explore the documentation for the
pipelines and apps frameworks that provide support functions
for writing tools:

- [Stage 1 pipelines framework](/mdi-pipelines-framework)
- [Stage 2 apps framework](/mdi-apps-framework)

<!-- please do not alter the next line -->
{% include mdi-project-documentation.md %}
