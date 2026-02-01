--- Upload Log Utility
-- Uploads the most recent log file to Pastebin
--
-- Usage:
--   upload_log              -- Upload default log
--   upload_log <logfile>    -- Upload specific log file
--   upload_log --list       -- List available log files
--
-- @script upload_log

-- ============================================
-- PATH SETUP
-- ============================================

local function setupPaths()
    local scriptPath = shell.getRunningProgram()
    local absPath = "/" .. shell.resolve(scriptPath)
    local scriptDir = absPath:match("(.+/)") or "/"
    local rootDir
    if scriptDir == "/" then
        rootDir = "/"
    else
        local withoutTrailing = scriptDir:sub(1, -2)
        rootDir = withoutTrailing:match("(.*/)" ) or "/"
    end
    package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path
    return rootDir
end

setupPaths()

-- ============================================
-- MAIN
-- ============================================

local logger = require("common.logger")

local args = { ... }
local command = args[1]

-- List available logs
if command == "--list" or command == "-l" then
    print("=== Available Log Files ===")
    if fs.exists("/logs") then
        local logs = fs.list("/logs")
        if #logs == 0 then
            print("  No log files found.")
        else
            for _, log in ipairs(logs) do
                local path = "/logs/" .. log
                local size = fs.getSize(path)
                print(string.format("  %s (%d bytes)", log, size))
            end
        end
    else
        print("  No /logs directory found.")
    end
    return
end

-- Determine log file to upload
local logPath
if command and command ~= "" then
    if fs.exists(command) then
        logPath = command
    elseif fs.exists("/logs/" .. command) then
        logPath = "/logs/" .. command
    elseif fs.exists("/logs/" .. command .. ".log") then
        logPath = "/logs/" .. command .. ".log"
    else
        printError("Log file not found: " .. command)
        print("Use 'upload_log --list' to see available logs.")
        return
    end
else
    -- Find most recent log in /logs
    logPath = logger.getLogPath()
    
    if not fs.exists(logPath) then
        -- Try to find any log
        if fs.exists("/logs") then
            local logs = fs.list("/logs")
            if #logs > 0 then
                logPath = "/logs/" .. logs[#logs]
            end
        end
    end
end

if not logPath or not fs.exists(logPath) then
    printError("No log file found to upload.")
    print("")
    print("Run a script with logging first, or specify a file:")
    print("  upload_log /path/to/file.log")
    return
end

print("Uploading: " .. logPath)

-- Read and upload
local file = fs.open(logPath, "r")
if not file then
    printError("Cannot read log file.")
    return
end

local content = file.readAll()
file.close()

-- Build title from filename
local filename = logPath:match("([^/]+)$") or "log"
local title = string.format("Turtle %d - %s", os.getComputerID(), filename)

-- Add header
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
    logPath
)

local fullContent = header .. content

-- Upload
print("Connecting to Pastebin...")

local function urlEncode(str)
    if not str then return "" end
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w%-%_%.])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return str
end

local response, err = http.post(
    "https://pastebin.com/api/api_post.php",
    "api_dev_key=&api_option=paste&api_paste_code=" .. urlEncode(fullContent) ..
    "&api_paste_name=" .. urlEncode(title)
)

if not response then
    printError("Upload failed: " .. (err or "unknown error"))
    return
end

local result = response.readAll()
response.close()

if result:match("^https?://pastebin.com/") then
    print("")
    print("============================")
    print("  LOG UPLOADED SUCCESSFULLY")
    print("============================")
    print("")
    print(result)
    print("")
    print("Copy this URL to share your log!")
else
    printError("Pastebin error: " .. result)
end
