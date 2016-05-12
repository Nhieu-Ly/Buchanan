-- Copyright 2015 Boundary, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the 'License');
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an 'AS IS' BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local framework = require('framework')
local CommandOutputDataSource = framework.CommandOutputDataSource
local Plugin = framework.Plugin
local CachedDataSource = framework.CachedDataSource
local gsplit = framework.string.gsplit
local split = framework.string.split
local ipack = framework.util.ipack

local params = framework.params

local metrics_map = {
  ['general statistics\\active temp tables'] = {'MSSQL_ACTIVE_TEMP_TABLES', 1},
  ['general statistics\\user connections'] = {'MSSQL_USER_CONNECTIONS', 1},
  ['general statistics\\logical connections'] = {'MSSQL_LOGICAL_CONNECTIONS', 1},
  ['general statistics\\transactions'] = {'MSSQL_TRANSACTIONS', 1},
  ['general statistics\\processes blocked'] = {'MSSQL_PROCESSES_BLOCKED', 1},
  ['locks(_total)\\lock timeouts/sec'] = {'MSSQL_LOCK_TIMEOUTS', 1},
  ['locks(_total)\\lock waits/sec'] = {'MSSQL_LOCK_WAITS', 1},
  ['locks(_total)\\lock wait time (ms)'] = {'MSSQL_LOCK_WAIT_TIME_MS', 1},
  ['locks(_total)\\average wait time (ms)'] = {'MSSQL_LOCK_AVERAGE_WAIT_TIME_MS', 1},
  ['locks(_total)\\lock timeouts (timeout > 0)/sec'] = {'MSSQL_LOCK_TIMEOUTS_GT0', 1},
  ['databases(_total)\\percent log used'] = {'MSSQL_PERCENT_LOG_USED', 0.01},
  ['databases(_total)\\repl. pending xacts'] = {'MSSQL_REPL_PENDING_XACTS', 1},
  ['sql statistics\\sql compilations/sec'] = {'MSSQL_COMPILATIONS', 1},
  ['wait statistics(_total)\\page io latch waits'] = {'MSSQL_PAGE_IO_LATCH_WAITS', 1}
}

local cmd_instances = {
  path = "powershell.exe",
  args = {'-NoLogo -NonInteractive -NoProfile -Command Set-ExecutionPolicy UnRestricted; .\\mssql_instances.ps1'},
  use_popen = true
}

local ds_instances = CommandOutputDataSource:new(cmd_instances)

local cmd_metrics = {
  path = 'get_metrics_native.exe',
  args = {}, -- to be completed on chain transformation function.
  use_popen = false 
}

local ds_metrics = CommandOutputDataSource:new(cmd_metrics)
local INSTANCE_REFRESH_SECONDS = 60 

local ds_cached = CachedDataSource:new(ds_instances, INSTANCE_REFRESH_SECONDS)
ds_cached:chain(ds_metrics, function (data)
  local instances = split((data.output):sub(1,-2), ' ')
  ds_metrics.args = instances 
end)

local plugin = Plugin:new(params, ds_cached)

function plugin:onParseValues(data)
  local result = {}
  local output = data.output
  if output then
    for v in gsplit(output, '\r\n') do
      local source, metric, value = string.match(v, '(.+):(.+):([%d.?]+)')
      if metric and value and source then
        local boundary_metric = metrics_map[metric][1]
        local factor = metrics_map[metric][2]
        value = factor * tonumber(value)
        source = self.source .. '.' .. source
        ipack(result, boundary_metric, value, nil, source)
      end
    end
  end
  return result
end

plugin:run()
