--- Configuration loader module
-- Loads and saves configuration files for turtle scripts
-- @module config

local M = {}

--- Default config directory
M.CONFIG_DIR = "config"

--- Ensure config directory exists
local function ensureConfigDir()
    if not fs.exists(M.CONFIG_DIR) then
        fs.makeDir(M.CONFIG_DIR)
    end
end

--- Load a list from a config file (one item per line)
-- Lines starting with -- are comments
-- Empty lines are ignored
-- @param filename string Config file name (without path)
-- @return table Array of items
function M.loadList(filename)
    local path = M.CONFIG_DIR .. "/" .. filename
    local items = {}
    
    if not fs.exists(path) then
        return items
    end
    
    local file = fs.open(path, "r")
    if not file then
        return items
    end
    
    local line = file.readLine()
    while line do
        -- Trim whitespace
        line = line:match("^%s*(.-)%s*$")
        
        -- Skip empty lines and comments
        if line ~= "" and not line:match("^%-%-") then
            table.insert(items, line)
        end
        
        line = file.readLine()
    end
    
    file.close()
    return items
end

--- Load a list as a set (table with values as keys)
-- @param filename string Config file name (without path)
-- @return table Set (keys are items, values are true)
function M.loadSet(filename)
    local list = M.loadList(filename)
    local set = {}
    for _, item in ipairs(list) do
        set[item] = true
    end
    return set
end

--- Save a list to a config file
-- @param filename string Config file name (without path)
-- @param items table Array of items to save
-- @param header string|nil Optional header comment
-- @return boolean Success
function M.saveList(filename, items, header)
    ensureConfigDir()
    
    local path = M.CONFIG_DIR .. "/" .. filename
    local file = fs.open(path, "w")
    if not file then
        return false
    end
    
    if header then
        file.writeLine("-- " .. header)
        file.writeLine("")
    end
    
    for _, item in ipairs(items) do
        file.writeLine(item)
    end
    
    file.close()
    return true
end

--- Load a key-value config file
-- Format: key = value (one per line)
-- @param filename string Config file name (without path)
-- @return table Key-value pairs
function M.loadConfig(filename)
    local path = M.CONFIG_DIR .. "/" .. filename
    local config = {}
    
    if not fs.exists(path) then
        return config
    end
    
    local file = fs.open(path, "r")
    if not file then
        return config
    end
    
    local line = file.readLine()
    while line do
        -- Skip comments and empty lines
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^%-%-") then
            -- Parse key = value
            local key, value = line:match("^([%w_]+)%s*=%s*(.+)$")
            if key and value then
                -- Try to convert to number or boolean
                if value == "true" then
                    config[key] = true
                elseif value == "false" then
                    config[key] = false
                elseif tonumber(value) then
                    config[key] = tonumber(value)
                else
                    -- Remove quotes if present
                    value = value:match('^"(.-)"$') or value:match("^'(.-)'$") or value
                    config[key] = value
                end
            end
        end
        
        line = file.readLine()
    end
    
    file.close()
    return config
end

--- Save a key-value config file
-- @param filename string Config file name (without path)
-- @param config table Key-value pairs to save
-- @param header string|nil Optional header comment
-- @return boolean Success
function M.saveConfig(filename, config, header)
    ensureConfigDir()
    
    local path = M.CONFIG_DIR .. "/" .. filename
    local file = fs.open(path, "w")
    if not file then
        return false
    end
    
    if header then
        file.writeLine("-- " .. header)
        file.writeLine("")
    end
    
    -- Sort keys for consistent output
    local keys = {}
    for k in pairs(config) do
        table.insert(keys, k)
    end
    table.sort(keys)
    
    for _, key in ipairs(keys) do
        local value = config[key]
        if type(value) == "string" then
            file.writeLine(string.format('%s = "%s"', key, value))
        else
            file.writeLine(string.format("%s = %s", key, tostring(value)))
        end
    end
    
    file.close()
    return true
end

--- Check if a config file exists
-- @param filename string Config file name (without path)
-- @return boolean Exists
function M.exists(filename)
    return fs.exists(M.CONFIG_DIR .. "/" .. filename)
end

--- Delete a config file
-- @param filename string Config file name (without path)
-- @return boolean Success
function M.delete(filename)
    local path = M.CONFIG_DIR .. "/" .. filename
    if fs.exists(path) then
        fs.delete(path)
        return true
    end
    return false
end

return M
