---
title: Suite Documentation
has_children: false
nav_order: 70
published: true # set to false to remove this tab from your suite's doc site
---

## {{page.title}}

The suite template carries the configuration files needed to easily launch a documentation
web site for your new tools suite using a permanent, customized fork 
of the open source Jekyll theme 
[Just the Docs](https://github.com/just-the-docs/just-the-docs), called
[just-the-docs-mdi](https://github.com/MiDataInt/just-the-docs-mdi).

### Configure your suite's basic information

Open and edit the following files, following the instructions in the comments
to find specific lines you need to edit to match your needs:

- _config.yml
- overview.md
- LICENSE (adjust the license type, year, and licensee as needed)
- aws-mdi.md (specify the resources needed for a public server, if relevant)
- README.md (delete these developer instructions, if desired)
  
### Activate your documentation web page on github.io
  
Activate your new documentation site for loading via github.io as follows:

- navigate to your new repository on GitHub
- click "Settings"
- click the "Pages" tab on the left
- edit the "Source" to be branch 'main' and folder '/root'
- click 'Save'
  
After about a minute, your site will be live at the link indicated on
Settings / Pages.  It will track your repository to keep your site up
to date whenever you push or merge changes into the 'main' branch.

Please note that this only works if your repository is public. 
  
### Write your documentation files

Finally, create documentation page files within any folder.
The easy way is to create [markdown](https://www.google.com/search?q=markdown+bascis) 
files similar to the _overview.md_ file you edited above.
By placing these as README.md files into the appropriate folders in your file tree,
users will be able to see them both on GitHub and in your
documentation web site. 

### Just the Docs usage

Please see the 
[Just the Docs](https://just-the-docs/just-the-docs/) 
documentation for guidance on how to use the Jekyll front matter
at the top of each markdown file to create the nested 
menu items typical of MDI documentation sites. 
Examples here will get you going:

<https://github.com/MiDataInt/mdi-documentation-template/tree/main/_docs>
