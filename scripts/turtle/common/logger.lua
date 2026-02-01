--- Logger module for turtle scripts
-- Provides file and terminal logging with configurable levels
--
-- Config: /config/logger.cfg (key=value)
--   min_level = error|warn|info|debug (default: info)
--   echo = true|false (default: true)
--   log_path = path (default: /logs/<program>.log)
--
-- Override at runtime via _G.LOG_LEVEL, _G.LOG_ECHO, _G.LOG_PATH
--
-- Usage:
--   local logger = require("common.logger")
--   logger.info("Started mining")
--   logger.warn("Fuel low")
--   logger.error("Cannot move")
--   logger.debug("Position: x=%d", x)
--
-- @module logger

local M = {}

-- Log levels (lower = more severe)
local LEVELS = {
    error = 1,
    warn  = 2,
    info  = 3,
    debug = 4,
}

-- Default config
local config = {
    min_level = "info",
    echo = true,
    log_path = nil,  -- nil means auto-detect from program name
}

local configLoaded = false
local logFile = nil

--- Parse a config file with key=value lines
local function parseConfigFile(path)
    local result = {}
    if not fs.exists(path) then
        return result
    end
    local file = fs.open(path, "r")
    if not file then
        return result
    end
    local line = file.readLine()
    while line do
        line = line:match("^%s*(.-)%s*$")  -- trim
        if line ~= "" and not line:match("^#") then
            local key, value = line:match("^([^=]+)%s*=%s*(.*)$")
            if key and value then
                key = key:match("^%s*(.-)%s*$")
                value = value:match("^%s*(.-)%s*$")
                result[key] = value
            end
        end
        line = file.readLine()
    end
    file.close()
    return result
end

--- Load config from file and apply overrides
local function loadConfig()
    if configLoaded then return end
    configLoaded = true

    -- Load from file
    local fileConfig = parseConfigFile("/config/logger.cfg")
    if fileConfig.min_level and LEVELS[fileConfig.min_level] then
        config.min_level = fileConfig.min_level
    end
    if fileConfig.echo ~= nil then
        config.echo = (fileConfig.echo == "true")
    end
    if fileConfig.log_path and fileConfig.log_path ~= "" then
        config.log_path = fileConfig.log_path
    end

    -- Apply runtime overrides
    if _G.LOG_LEVEL and LEVELS[_G.LOG_LEVEL] then
        config.min_level = _G.LOG_LEVEL
    end
    if _G.LOG_ECHO ~= nil then
        config.echo = _G.LOG_ECHO
    end
    if _G.LOG_PATH then
        config.log_path = _G.LOG_PATH
    end

    -- Auto-detect log path from program name if not set
    if not config.log_path then
        local prog = shell and shell.getRunningProgram() or "program"
        local name = prog:match("([^/]+)%.lua$") or prog:match("([^/]+)$") or "program"
        config.log_path = "/logs/" .. name .. ".log"
    end
end

--- Ensure log directory exists
local function ensureLogDir()
    local dir = config.log_path:match("(.+)/[^/]+$")
    if dir and not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

--- Get a timestamp string
local function timestamp()
    local time = os.time()
    local day = os.day()
    return string.format("D%d %s", day, textutils.formatTime(time, true))
end

--- Write a log entry
-- @param level Log level string
-- @param fmt Format string
-- @param ... Format arguments
local function log(level, fmt, ...)
    loadConfig()

    -- Check if this level should be logged
    local levelNum = LEVELS[level] or 3
    local minNum = LEVELS[config.min_level] or 3
    if levelNum > minNum then
        return
    end

    -- Format message
    local msg
    if select("#", ...) > 0 then
        msg = string.format(fmt, ...)
    else
        msg = tostring(fmt)
    end

    local line = string.format("[%s] [%s] %s", timestamp(), level:upper(), msg)

    -- Echo to terminal if enabled
    if config.echo then
        if level == "error" then
            printError(line)
        else
            print(line)
        end
    end

    -- Write to file
    ensureLogDir()
    local file = fs.open(config.log_path, "a")
    if file then
        file.writeLine(line)
        file.close()
    end
end

--- Log an error message
function M.error(fmt, ...)
    log("error", fmt, ...)
end

--- Log a warning message
function M.warn(fmt, ...)
    log("warn", fmt, ...)
end

--- Log an info message
function M.info(fmt, ...)
    log("info", fmt, ...)
end

--- Log a debug message
function M.debug(fmt, ...)
    log("debug", fmt, ...)
end

--- Get current log file path
function M.getLogPath()
    loadConfig()
    return config.log_path
end

--- Set log level at runtime
function M.setLevel(level)
    if LEVELS[level] then
        config.min_level = level
    end
end

--- Set echo mode at runtime
function M.setEcho(enabled)
    config.echo = enabled
end

--- Clear the log file
function M.clear()
    loadConfig()
    if fs.exists(config.log_path) then
        fs.delete(config.log_path)
    end
end

return M
