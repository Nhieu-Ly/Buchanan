$instances = (Get-WmiObject win32_service | Where-Object { (($_.Name -like "MSSQL`$*") -or ($_.Name -eq "MSSQLSERVER")) -and ($_.State -eq "Running") }).Name

$metrics_map = @{
    "general statistics\active temp tables" = @("MSSQL_ACTIVE_TEMP_TABLES", 1);
    "general statistics\user connections" = @("MSSQL_USER_CONNECTIONS", 1);
    "general statistics\logical connections" = @("MSSQL_LOGICAL_CONNECTIONS", 1);
    "general statistics\transactions" = @("MSSQL_TRANSACTIONS", 1);
    "general statistics\processes blocked" = @("MSSQL_PROCESSES_BLOCKED", 1);
    "locks(_total)\lock timeouts/sec" = @("MSSQL_LOCK_TIMEOUTS", 1);
    "locks(_total)\lock waits/sec" = @("MSSQL_LOCK_WAITS", 1);
    "locks(_total)\lock wait time (ms)" = @("MSSQL_LOCK_WAIT_TIME_MS", 1);
    "locks(_total)\average wait time (ms)" = @("MSSQL_LOCK_AVERAGE_WAIT_TIME_MS", 1);
    "locks(_total)\lock timeouts (timeout > 0)/sec" = @("MSSQL_LOCK_TIMEOUTS_GT0", 1);
    "databases(_total)\percent log used" = @("MSSQL_PERCENT_LOG_USED", 0.01);
    "databases(_total)\repl. pending xacts" = @("MSSQL_REPL_PENDING_XACTS", 1);
    "sql statistics\sql compilations/sec" = @("MSSQL_COMPILATIONS", 1);
    "wait statistics(_total)\page io latch waits" = @("MSSQL_PAGE_IO_LATCH_WAITS", 1);
}

$counters = @()
foreach ($instance in $instances) {
    foreach ($m in $metrics_map.GetEnumerator())
    {
        $counter_name = "\$($instance):$($m.Key)"
        $counters += $counter_name
    }
}

function normalize ($counterPath) {
    $counterPath.Split("{:}")[1]    
}

function metricInfo($counterPath) {
    $key = normalize($counterPath)
    $metrics_map[$key]
}

function metric($counterPath) {
    (metricInfo($counterPath))[0]
}

function multiplier($counterPath, $counterValue) {
    $m = metricInfo($counterPath)
    $m[1]
}

function source($counterPath) {
    $instance_part = $counterPath.Split("{:}")[0]
    $from = $instance_part.LastIndexOf("\")
    $from = $from + 1
    $instance_part.Substring($from)
}

$samples = (Get-Counter -Counter $counters -ErrorAction SilentlyContinue).CounterSamples | ForEach-Object {Join-String -Strings (metric $_.Path), ((multiplier $_.Path) * $_.CookedValue), (source $_.Path) -Separator " "}
$samples