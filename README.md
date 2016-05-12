# Boundary Microsoft SQL Server Plugin

Collects metrics from Microsoft SQL Server instance using a subset of the SQL Server Performance Counters. 

### Prerequisites

- SQL Server 2008, 2012 or 2014.

Multiple instances of SQL Server running on the same machine are supported: each instance will show up as a separate source on your Boundary dashboard.

#### Supported OS

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   -   |    v    |    -    |   -  |

#### Boundary Meter versions v4.2 or later

- To install new meter go to Settings->Installation or [see instructions](https://help.boundary.com/hc/en-us/sections/200634331-Installation).
- To upgrade the meter to the latest version - [see instructions](https://help.boundary.com/hc/en-us/articles/201573102-Upgrading-the-Boundary-Meter).

### Plugin Setup

None

### Plugin Configuration Fields

|Field Name     |Description                                                                       |
|:--------------|:---------------------------------------------------------------------------------|
|Source         |The source to display in the legend for the data                       |
|Poll Interval (ms)|The Poll Interval in milliseconds to poll for metrics |

### Metrics Collected

|Metric Name             |Description                                                   |
|:-----------------------|:-------------------------------------------------------------|
| MSSQL_ACTIVE_TEMP_TABLES | |
| MSSQL_USER_CONNECTIONS | |
| MSSQL_LOGICAL_CONNECTIONS | |
| MSSQL_TRANSACTIONS | |
| MSSQL_PROCESSES_BLOCKED | |
| MSSQL_LOCK_TIMEOUTS | |
| MSSQL_LOCK_WAITS | |
| MSSQL_LOCK_WAIT_TIME_MS | |
| MSSQL_LOCK_AVERAGE_WAIT_TIME_MS | |
| MSSQL_LOCK_TIMEOUTS_GT0 | |
| MSSQL_PERCENT_LOG_USED | |
| MSSQL_REPL_PENDING_XACTS | |
| MSSQL_COMPILATIONS | |
| MSSQL_PAGE_IO_LATCH_WAITS | |

### Dashboards

|Dashboard Name|Metrics Displayed       |
|:-------------|:-----------------------|
|MSSQL       | All |

### References

None
