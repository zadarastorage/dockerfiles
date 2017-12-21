## Disk Usage Report Container

### Introduction

This container will give produce disk usage reports on a target directory and output the results to an output directory.
The container will output either `tree -du` in JSON, XML, or TXT or `du` in TXT. The report will run repeatedly at a given cron interval.

This is early alpha quality, and does not cover all use cases.  It is offered without warranty.

### Parameters

1. **TARGET_DIRECTORY="string"**  
  Directory to run report on  
2. **OUTPUT_DIRECTORY="string"**  
  Directory to output results  
3. **DIRECTORY_DEPTH="integer"**   
  Number of directories deep to traverse file system  
4. **TREE="true|false"**  
  if "true" will use `tree --du` command  
  if "false" will use `du` command
5. **TREE_OUTPUT_FORMAT="JSON|XML|TXT"**  
  if TREE="true" allows changing of output format to JSON, XML, or TXT
6. **CRON_STRING="string"**  
  example: "0 0 * * *"  
  cron timing string to run report at desired time
7. **SIZES_HUMAN_READABLE="true|false"**  
  if output format is TXT will print sizes in human readable format (kb, m, g) instead of bytes
