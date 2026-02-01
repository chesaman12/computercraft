--- Tomfoolery Installer Script
-- Downloads all required files from GitHub to the turtle
--
-- Usage:
--   1. First time: wget https://raw.githubusercontent.com/chesaman12/computercraft/main/scripts/tomfoolery/installer.lua installer
--   2. Or: pastebin get XXXXXX installer
--   3. Run: installer
--
-- @script installer

-- ============================================
-- CONFIGURATION - Update this URL to match your GitHub repo
-- ============================================
local GITHUB_USER = "chesaman12"  -- Change this to your GitHub username
local GITHUB_REPO = "computercraft"   -- Change this to your repo name
local GITHUB_BRANCH = "main"          -- Change if using different branch

-- Base URL for raw GitHub content
local baseUrl = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/scripts/tomfoolery/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

-- ============================================
-- FILES TO DOWNLOAD
-- ============================================
local files = {
    -- Common libraries (required)
    { path = "common/init.lua",      required = true },
    { path = "common/movement.lua",  required = true },
    { path = "common/inventory.lua", required = true },
    { path = "common/mining.lua",    required = true },
    { path = "common/fuel.lua",      required = true },
    { path = "common/config.lua",    required = true },
    { path = "common/turtle_actions.lua", required = false },

    -- Miner modules (smart_miner dependencies)
    { path = "miner/core.lua",       required = true },
    { path = "miner/home.lua",       required = true },
    { path = "miner/tunnel.lua",     required = true },
    { path = "miner/patterns.lua",   required = true },
    
    -- Configuration files
    { path = "config/ores.cfg",      required = true },
    { path = "config/junk.cfg",      required = true },
    
    -- Mining scripts
    { path = "mining/smart_miner.lua", required = true },
}

-- Directories to create
local directories = {
    "common",
    "miner",
    "config", 
    "mining",
}

-- ============================================
-- INSTALLER LOGIC
-- ============================================

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    print("========================================")
    print("   Tomfoolery Installer")
    print("========================================")
    print("")
end

local function checkHttp()
    if not http then
        printError("HTTP API is not available!")
        printError("")
        printError("Ask your server admin to enable HTTP:")
        printError("  1. Edit config/computercraft-server.toml")
        printError("  2. Set http.enabled = true")
        printError("  3. Restart the server")
        return false
    end
    return true
end

local function createDirectories()
    print("Creating directories...")
    for _, dir in ipairs(directories) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
            print("  Created: " .. dir)
        else
            print("  Exists:  " .. dir)
        end
    end
    print("")
end

local function downloadFile(remotePath, localPath)
    local url = baseUrl .. remotePath
    
    local response, err = http.get(url)
    if not response then
        return false, err or "Unknown error"
    end
    
    local content = response.readAll()
    response.close()
    
    if not content or content == "" then
        return false, "Empty response"
    end
    
    -- Check for GitHub 404 page
    if content:match("^<!DOCTYPE html>") or content:match("^404:") then
        return false, "File not found (404)"
    end
    
    local file = fs.open(localPath, "w")
    if not file then
        return false, "Cannot write file"
    end
    
    file.write(content)
    file.close()
    
    return true
end

local function install()
    printHeader()
    
    -- Check HTTP
    if not checkHttp() then
        return false
    end
    
    print("Downloading from: " .. GITHUB_USER .. "/" .. GITHUB_REPO)
    print("Base URL: " .. baseUrl)
    print("")
    
    -- Create directories
    createDirectories()
    
    -- Download files
    print("Downloading files...")
    local succeeded = 0
    local failed = 0
    local skipped = 0
    local errors = {}  -- Collect errors for display at end
    
    for _, file in ipairs(files) do
        local path = file.path
        write("  " .. path .. " ")
        
        local ok, err = downloadFile(path, path)
        if ok then
            print("[OK]")
            succeeded = succeeded + 1
        else
            if file.required then
                print("[FAILED]")
                failed = failed + 1
                table.insert(errors, {
                    path = path,
                    error = tostring(err),
                    url = baseUrl .. path
                })
            else
                print("[SKIPPED]")
                skipped = skipped + 1
            end
        end
        
        -- Small delay to avoid rate limiting
        sleep(0.1)
    end
    
    -- Summary
    print("")
    print("========================================")
    print("Installation Summary:")
    print("  Downloaded: " .. succeeded)
    print("  Failed:     " .. failed)
    print("  Skipped:    " .. skipped)
    print("========================================")
    
    if failed > 0 then
        print("")
        printError("=== ERRORS ===")
        for _, e in ipairs(errors) do
            print("")
            printError("File: " .. e.path)
            printError("URL:  " .. e.url)
            printError("Error: " .. e.error)
        end
        print("")
        printError("Troubleshooting:")
        printError("1. Check the URL in a browser - does it exist?")
        printError("2. Verify GITHUB_USER is correct: " .. GITHUB_USER)
        printError("3. Verify repo is public and branch exists")
        printError("4. Check server HTTP whitelist settings")
        return false
    end
    
    print("")
    print("Installation complete!")
    print("")
    print("To run the smart miner:")
    print("  cd mining")
    print("  smart_miner 50")
    print("")
    print("Edit config/ores.cfg to add modded ores.")
    
    return true
end

local function update()
    printHeader()
    print("Updating existing installation...")
    print("")
    
    if not checkHttp() then
        return false
    end
    
    -- Just redownload all files
    return install()
end

local function uninstall()
    printHeader()
    print("This will delete all Tomfoolery files.")
    write("Are you sure? (y/n): ")
    local answer = read():lower()
    
    if answer ~= "y" and answer ~= "yes" then
        print("Cancelled.")
        return
    end
    
    print("")
    print("Removing files...")
    
    for _, dir in ipairs(directories) do
        if fs.exists(dir) then
            fs.delete(dir)
            print("  Deleted: " .. dir)
        end
    end
    
    print("")
    print("Uninstall complete.")
end

local function showHelp()
    printHeader()
    print("Commands:")
    print("  installer         - Install all files")
    print("  installer update  - Update existing files")
    print("  installer remove  - Uninstall all files")
    print("  installer help    - Show this help")
    print("")
    print("Before first use, update GITHUB_USER in")
    print("this script to match your repository.")
end

-- ============================================
-- MAIN
-- ============================================

local args = { ... }
local command = args[1] or "install"

if command == "help" or command == "-h" or command == "--help" then
    showHelp()
elseif command == "update" then
    update()
elseif command == "remove" or command == "uninstall" then
    uninstall()
else
    install()
end
