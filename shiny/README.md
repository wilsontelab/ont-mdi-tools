---
title: Stage 2 Apps
has_children: true
nav_order: 30
published: true # set to false to remove this tab from your suite's doc site
---

## {{page.title}}

An **app** is a single, coordinated set
of R Shiny interactive data visualization tools. 

Two kinds of files define a Stage 2 App,
listed here in the order in which they are loaded.

- files loaded by all apps in a suite, in _shiny/shared_
- app-specific files, in _shiny/apps/\<appName\>_

Thus, R functions in app-specific scripts supersede functions 
of the same name in shared scripts or in the apps framework. 
