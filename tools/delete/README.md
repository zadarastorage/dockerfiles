## Delete Container

### Purpose

The purpose of this container is to recursively find and delete files in specified root directories, that match a given filename pattern, and are over a given retention age in days.

### Config File
The path to the config file is set by the CONFIG_PATH environment variable.  Config file must be a .csv file containing 3 columns with the headings "root", "pattern", and "retention_days".  If the CONFIG_PATH variable is not set, the path provided is not found on the container, or the file is not a csv, the container will stop.
 
| | | | 
|:---  |:---  |:---  |
| **Field**   | **Example Value**   | **Purpose**   |
| root | /export/data/logs/	| Root directory to recursively scan for files matching pattern
| pattern | *.log | Pattern to test file names against, supports wildcards.  See https://docs.python.org/3.7/library/fnmatch.html for more info.
| retention_days | 30 | Number of days to retain files matching the pattern

#### Example

```
root,pattern,retention_days
/export/data/logs,*.log,30
/export/data/logs,*.txt,45
/export/data/share,*.csv,180
```


### Environment Variables
| | | | | |
| --- | --- | --- | --- | --- |
| **Name** | **Acceptable Values** | **Default Value** | **Required** | **Purpose** |
| CONFIG_PATH | valid path to config csv file | None | Yes | Determines which config file to use | 
| LOG_BASE_DIR | valid path to base log directory | None | Yes | Determines where to store logs | 
| CASE_SENSITIVE_PATTERNS | true, false, enabled, disabled | disabled | No | Determines if pattern matching is case sensitive or not | 
| CRON | true, false, enabled, disabled | enabled | No | Determines if cron service is enabled | 
| CRON_TIMING | valid crontab timing | 0 0 * * * | No | If cron service enabled, determines the timing of the cron job |
| DRY_RUN | true, false, enabled, disabled | enabled | No | Determines if data will be deleted or not |
| KEEP_ALIVE | true, false, enabled, disabled | disabled | No | Determines if container will sleep indefinitely, useful when combined with SSH | 
| SSH | true, false, enabled, disabled | disabled | No | Determines if ssh service is enabled | 
| STARTUP_RUN | true, false, enabled, disabled | enabled | No | Determines if delete script gets run on startup |