$METRICS = @(
    @("\{0}:General Statistics\Active Temp Tables", "MSSQL_ACTIVE_TEMP_TABLES", 1),
    @("\{0}:General Statistics\User Connections", "MSSQL_USER_CONNECTIONS", 1),
    @("\{0}:General Statistics\Logical Connections", "MSSQL_LOGICAL_CONNECTIONS", 1),
    @("\{0}:General Statistics\Transactions", "MSSQL_TRANSACTIONS", 1),
    @("\{0}:General Statistics\Processes blocked", "MSSQL_PROCESSES_BLOCKED", 1),
    @("\{0}:Locks(_total)\Lock Timeouts/sec", "MSSQL_LOCK_TIMEOUTS", 1),
    @("\{0}:Locks(_total)\Lock Waits/sec", "MSSQL_LOCK_WAITS", 1),
    @("\{0}:Locks(_total)\Lock Wait Time (ms)", "MSSQL_LOCK_WAIT_TIME_MS", 1),
    @("\{0}:Locks(_total)\Average Wait Time (ms)", "MSSQL_LOCK_AVERAGE_WAIT_TIME_MS", 1),
    @("\{0}:Locks(_total)\Lock Timeouts (timeout > 0)/sec", "MSSQL_LOCK_TIMEOUTS_GT0", 1),
    @("\{0}:Databases(_total)\Percent Log Used", "MSSQL_PERCENT_LOG_USED", 0.01),
    @("\{0}:Databases(_total)\Repl. Pending Xacts", "MSSQL_REPL_PENDING_XACTS", 1),
    @("\{0}:SQL Statistics\SQL Compilations/sec", "MSSQL_COMPILATIONS", 1),
    @("\{0}:Wait Statistics(_total)\Page IO latch waits", "MSSQL_PAGE_IO_LATCH_WAITS", 1)
)

function getInstances
{
    $services = Get-WmiObject win32_service | where {$_.name -like "MSSQL*"}
    $instances = @()
    foreach ($service in $services)
    {
        if (($service.name -eq "MSSQLSERVER") -or ($service.name -like "MSSQL$*"))
        {
            $instances += $service.name
        }
    }
    return $instances
}

$METRIC_COUNTERS = @()
$BOUNDARY_NAME_MAP = @{}

# Get a list of instances on the local machine
$instances = getInstances
foreach ($instance in $instances)
{
    # Determine the source name to pass to Boundary and the counter prefix
    if ($instance -eq "MSSQLSERVER")
    {
        $source = ""
        $counter_prefix = "SQLServer"
    }
    else
    {
        $source = "{0}_{1}" -f $env:COMPUTERNAME, ($instance -split '\$')[1]
        $counter_prefix = $instance
    }

    # Get the local server's name for each counter (the names are sometimes different
    # than what we pass in, e.g. prepended with a server name).
    foreach ($metric_info in $METRICS)
    {
        $counter_name = $metric_info[0] -f $counter_prefix
        $boundary_name = $metric_info[1]
        $scale = $metric_info[2]
    
        try
        {
	       $data = Get-Counter $counter_name -ErrorAction Stop
           # Write-Host ("{0} -> {1}" -f $data.CounterSamples[0].Path, $boundary_name)
           $METRIC_COUNTERS += $counter_name
           $BOUNDARY_NAME_MAP[$data.CounterSamples[0].Path] = $boundary_name, $scale, $source
        }
        catch
        {
            # If a counter is unavailable, ignore it and don't add it to the list so we never
            # try it to request it again.
        }
    }
}

function outputMetrics
{
    $data = Get-Counter -Counter $METRIC_COUNTERS -EA SilentlyContinue
    
    foreach ($item in $data.counterSamples)
    {
        $counter_info = $BOUNDARY_NAME_MAP[$item.Path]
        $boundary_name = $counter_info[0]
        $value = $item.CookedValue * $counter_info[1]
        Write-Host ("{0} {1} {2}" -f $boundary_name, $value, $counter_info[2])
    }
}

while (1)
{
    # Note: outputMetrics samples the counters over a one-second interval, so
    # there's no need to sleep between calls.
    outputMetrics
}