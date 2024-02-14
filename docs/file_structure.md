---
title: Folder Structure
has_children: false
nav_order: 10
published: true # set to false to remove this tab from your suite's doc site
---

## {{page.title}}

The following is a high-level outline of a tool suite repository's folders:

| Folder          | Subfolder       | Description |  
| --------------- | --------------- | ------------|  
| **docs**        |                 | optional markdown files for your documentation web site |
| **pipelines**   |                 | subfolders carry scripts that define individual **Pipelines** |
| **shared**      |                 | subfolders carry scripts with code shared by multiple pipelines | 
| \|--------      | **environments**| yml files that create reusable conda environments for job execution | 
| \|--------      | **modules**     | scripts with reusable code accessible by running pipelines | 
| \|--------      | **options**     | yml files that expose reusable option families for job configuration | 
| **shiny**       |                 | carries scripts that define **R Shiny Apps** | 
| \|--------      | **apps**        | subfolders carry scripts that define individual apps | 
| \|--------      | **shared**      | subfolders carry scripts with code shared by potentially multiple apps | 

Thus, you should create one subfolder in `pipelines` or `shiny/apps` for each distinct
tool in your suite. Those tools can draw on the common code elements that you 
populate into the `shared` folders. We encourage the use of shared components, 
which is one reason the MDI uses suite repositories carrying multiple related tools.
