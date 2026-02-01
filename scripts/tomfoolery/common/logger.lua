--- Logger module with Pastebin cloud upload
-- Provides local file logging and cloud upload via Pastebin
--
-- Config: /config/logger.cfg (key=value)
--   min_level = error|warn|info|debug (default: info)
--   echo = true|false (default: true)
--   log_path = path (default: /logs/<program>.log)
--   pastebin_key = your_api_key (optional, for uploads)
--
-- Usage:
--   local logger = require("common.logger")
--   logger.info("Started mining")
--   logger.warn("Fuel low: %d", fuelLevel)
--   logger.error("Cannot move: %s", err)
--   logger.debug("Position: x=%d, y=%d, z=%d", x, y, z)
--
--   -- Upload log to Pastebin (returns URL or nil)
--   local url = logger.upload("Mining Run 1")
--
-- @module logger

local M = {}

-- ============================================
-- LOG LEVELS
-- ============================================

local LEVELS = {
    error = 1,
    warn  = 2,
    info  = 3,
    debug = 4,
}

-- ============================================
-- CONFIGURATION
-- ============================================

local config = {
    min_level = "info",
    echo = true,
    log_path = nil,  -- auto-detect from program name
    pastebin_key = nil,  -- optional API key for uploads
    discord_webhook = nil,  -- Discord webhook URL for notifications
}

local configLoaded = false

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
        if line ~= "" and not line:match("^[#-]") then
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

--- Load config from file
local function loadConfig()
    if configLoaded then return end
    configLoaded = true

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
    if fileConfig.pastebin_key and fileConfig.pastebin_key ~= "" then
        config.pastebin_key = fileConfig.pastebin_key
    end
    if fileConfig.discord_webhook and fileConfig.discord_webhook ~= "" then
        config.discord_webhook = fileConfig.discord_webhook
    end

    -- Auto-detect log path from program name if not set
    if not config.log_path then
        local prog = shell and shell.getRunningProgram() or "program"
        local name = prog:match("([^/]+)%.lua$") or prog:match("([^/]+)$") or "program"
        config.log_path = "/logs/" .. name .. ".log"
    end
end

-- ============================================
-- FILE OPERATIONS
-- ============================================

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

    local levelNum = LEVELS[level] or 3
    local minNum = LEVELS[config.min_level] or 3
    if levelNum > minNum then
        return
    end

    -- Format message
    local msg
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, fmt, ...)
        msg = ok and formatted or tostring(fmt)
    else
        msg = tostring(fmt)
    end

    local line = string.format("[%s] [%5s] %s", timestamp(), level:upper(), msg)

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

-- ============================================
-- PUBLIC LOGGING FUNCTIONS
-- ============================================

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

-- ============================================
-- CONFIGURATION FUNCTIONS
-- ============================================

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

--- Set Pastebin API key at runtime
function M.setPastebinKey(key)
    config.pastebin_key = key
end

--- Clear the log file
function M.clear()
    loadConfig()
    if fs.exists(config.log_path) then
        fs.delete(config.log_path)
    end
end

-- ============================================
-- SCRIPT STARTUP LOGGING
-- ============================================

--- Log script startup with parameters
-- @param scriptName Name of the script
-- @param params Table of parameter name/value pairs
function M.logParams(scriptName, params)
    local parts = { "=== " .. scriptName .. " ===" }
    log("info", parts[1])
    
    if params and next(params) then
        for name, value in pairs(params) do
            log("info", "  %s = %s", name, tostring(value))
        end
    end
    
    -- Log system info
    log("info", "Computer ID: %d", os.getComputerID())
    log("info", "Computer Label: %s", os.getComputerLabel() or "unlabeled")
    
    if turtle then
        local fuel = turtle.getFuelLevel()
        local limit = turtle.getFuelLimit()
        if fuel == "unlimited" then
            log("info", "Fuel: unlimited")
        else
            log("info", "Fuel: %d / %d", fuel, limit)
        end
    end
end

--- Log a section header for better log organization
function M.section(name)
    log("info", "--- %s ---", name)
end

--- Log mining statistics
function M.logStats(stats)
    M.section("Statistics")
    for key, value in pairs(stats) do
        log("info", "  %s: %s", key, tostring(value))
    end
end

-- ============================================
-- PASTEBIN UPLOAD
-- ============================================

--- URL encode a string for form data
local function urlEncode(str)
    if not str then return "" end
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w%-%_%.])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return str
end

--- Upload current log file to Pastebin
-- @param title string Optional title for the paste
-- @return string|nil URL of the paste, or nil on failure
-- @return string|nil Error message on failure
function M.upload(title)
    loadConfig()
    
    -- Check if HTTP is available
    if not http then
        return nil, "HTTP API not available"
    end
    
    -- Read log file
    if not fs.exists(config.log_path) then
        return nil, "Log file does not exist: " .. config.log_path
    end
    
    local file = fs.open(config.log_path, "r")
    if not file then
        return nil, "Cannot read log file"
    end
    
    local content = file.readAll()
    file.close()
    
    if not content or content == "" then
        return nil, "Log file is empty"
    end
    
    -- Build title
    title = title or string.format("Turtle Log - ID %d - Day %d", 
        os.getComputerID(), os.day())
    
    -- Add metadata header to paste
    local header = string.format([[
=== CC:Tweaked Turtle Log ===
Computer ID: %d
Computer Label: %s
Upload Time: Day %d, %s
Log File: %s
=============================

]], 
        os.getComputerID(),
        os.getComputerLabel() or "unlabeled",
        os.day(),
        textutils.formatTime(os.time(), true),
        config.log_path
    )
    
    local fullContent = header .. content
    
    -- Upload to Pastebin
    -- Note: Without an API key, we use the public paste endpoint
    -- which has more restrictions but works for basic uploads
    local postData
    
    if config.pastebin_key then
        -- Authenticated upload (more features, higher limits)
        postData = string.format(
            "api_dev_key=%s&api_option=paste&api_paste_code=%s&api_paste_name=%s&api_paste_expire_date=1W",
            urlEncode(config.pastebin_key),
            urlEncode(fullContent),
            urlEncode(title)
        )
    else
        -- Use CC:Tweaked's built-in pastebin command approach
        -- This leverages the pastebin API without needing a key
        -- by using the same endpoint the pastebin program uses
        postData = "text=" .. urlEncode(fullContent)
    end
    
    local url = config.pastebin_key 
        and "https://pastebin.com/api/api_post.php"
        or "https://pastebin.com/api/api_post.php"
    
    -- For keyless uploads, try the simpler approach
    if not config.pastebin_key then
        -- Use the approach from CC:Tweaked's built-in pastebin program
        local response, err = http.post(
            "https://pastebin.com/api/api_post.php",
            "api_dev_key=&api_option=paste&api_paste_code=" .. urlEncode(fullContent) ..
            "&api_paste_name=" .. urlEncode(title)
        )
        
        if not response then
            return nil, "Upload failed: " .. (err or "unknown error")
        end
        
        local result = response.readAll()
        response.close()
        
        if result:match("^https?://pastebin.com/") then
            return result, nil
        else
            return nil, "Pastebin error: " .. result
        end
    end
    
    local response, err = http.post(url, postData)
    
    if not response then
        return nil, "Upload failed: " .. (err or "unknown error")
    end
    
    local result = response.readAll()
    response.close()
    
    -- Check for success (Pastebin returns the URL on success)
    if result:match("^https?://pastebin.com/") then
        return result, nil
    else
        return nil, "Pastebin error: " .. result
    end
end

-- ============================================
-- DISCORD WEBHOOK
-- ============================================

--- Send a message to Discord via webhook
-- @param message string The message to send
-- @param pastebinUrl string|nil Optional Pastebin URL to include
-- @param stats table|nil Optional stats to include in embed
-- @return boolean Success
function M.sendToDiscord(message, pastebinUrl, stats)
    loadConfig()
    
    if not config.discord_webhook then
        return false, "No Discord webhook configured"
    end
    
    if not http then
        return false, "HTTP API not available"
    end
    
    -- Build embed for rich formatting
    local embed = {
        title = "🐢 Turtle Log",
        color = 5814783,  -- Teal color
        fields = {},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
    
    -- Add computer info
    table.insert(embed.fields, {
        name = "Computer",
        value = string.format("ID: %d\nLabel: %s", 
            os.getComputerID(), 
            os.getComputerLabel() or "unlabeled"),
        inline = true,
    })
    
    -- Add fuel info if turtle
    if turtle then
        local fuel = turtle.getFuelLevel()
        local fuelStr = fuel == "unlimited" and "Unlimited" or tostring(fuel)
        table.insert(embed.fields, {
            name = "Fuel",
            value = fuelStr,
            inline = true,
        })
    end
    
    -- Add stats if provided
    if stats then
        local statsLines = {}
        for key, value in pairs(stats) do
            table.insert(statsLines, string.format("%s: %s", key, tostring(value)))
        end
        if #statsLines > 0 then
            table.insert(embed.fields, {
                name = "Statistics",
                value = table.concat(statsLines, "\n"),
                inline = false,
            })
        end
    end
    
    -- Add Pastebin link if provided
    if pastebinUrl then
        table.insert(embed.fields, {
            name = "📋 Full Log",
            value = pastebinUrl,
            inline = false,
        })
    end
    
    -- Build payload
    local payload = {
        username = "Turtle Bot",
        content = message,
        embeds = { embed },
    }
    
    local body = textutils.serializeJSON(payload)
    
    local response, err = http.post(
        config.discord_webhook,
        body,
        { ["Content-Type"] = "application/json" }
    )
    
    if response then
        response.close()
        return true
    else
        return false, err or "Unknown error"
    end
end

--- Upload log and print the URL
-- @param title string Optional title for the paste
-- @param stats table Optional stats to include in Discord message
function M.uploadAndPrint(title, stats)
    print("Uploading log to Pastebin...")
    local url, err = M.upload(title)
    
    if url then
        print("=== LOG UPLOADED ===")
        print(url)
        print("====================")
        log("info", "Log uploaded: %s", url)
        
        -- Send to Discord if configured
        if config.discord_webhook then
            print("Sending to Discord...")
            local discordOk, discordErr = M.sendToDiscord(
                "📋 **" .. (title or "Turtle Log") .. "**",
                url,
                stats
            )
            if discordOk then
                print("✓ Sent to Discord!")
                log("info", "Log URL sent to Discord")
            else
                print("Discord failed: " .. (discordErr or "unknown"))
                log("warn", "Discord send failed: %s", discordErr or "unknown")
            end
        end
        
        return url
    else
        printError("Upload failed: " .. (err or "unknown"))
        log("error", "Log upload failed: %s", err or "unknown")
        
        -- Try to send error to Discord anyway
        if config.discord_webhook then
            M.sendToDiscord("❌ **Log upload failed**: " .. (err or "unknown"), nil, stats)
        end
        
        return nil
    end
end

-- ============================================
-- CONVENIENCE FUNCTION FOR END OF RUN
-- ============================================

--- Finalize logging: log completion, upload, and return URL
-- @param stats table Optional statistics to log
-- @param title string Optional paste title
-- @return string|nil Pastebin URL
function M.finalize(stats, title)
    if stats then
        M.logStats(stats)
    end
    M.section("Run Complete")
    log("info", "End time: Day %d, %s", os.day(), textutils.formatTime(os.time(), true))
    
    return M.uploadAndPrint(title, stats)
end

return M
