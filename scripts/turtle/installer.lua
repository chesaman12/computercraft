--- Turtle Scripts Installer
-- Downloads all required files from GitHub to the turtle
--
-- Usage:
--   wget https://raw.githubusercontent.com/chesaman12/computercraft/turtle-overhaul/scripts/turtle/installer.lua installer
--   installer
--
-- Commands:
--   installer          Install all files
--   installer update   Re-download all files
--   installer remove   Uninstall everything
--
-- @script installer

-- ============================================
-- CONFIGURATION
-- ============================================
local GITHUB_USER = "chesaman12"
local GITHUB_REPO = "computercraft"
-- NOTE: Change this to "main" after merging turtle-overhaul branch
local GITHUB_BRANCH = "turtle-overhaul"
local PROJECT_FOLDER = "turtle"

-- Base URL for raw GitHub content
local baseUrl = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/scripts/%s/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH, PROJECT_FOLDER
)

-- ============================================
-- FILES TO DOWNLOAD
-- ============================================
local files = {
    -- Common libraries
    { path = "common/init.lua",       required = true },
    { path = "common/fuel.lua",       required = true },
    { path = "common/movement.lua",   required = true },
    { path = "common/inventory.lua",  required = true },
    { path = "common/input.lua",      required = true },

    -- Building scripts
    { path = "building/block.lua",    required = true },
    { path = "building/wall.lua",     required = true },
    { path = "building/house.lua",    required = true },

    -- Mining scripts
    { path = "mining/dig.lua",          required = true },
    { path = "mining/simple_miner.lua", required = true },
    { path = "mining/stair_miner.lua",  required = true },
    { path = "mining/strip_miner.lua",  required = true },

    -- Utility scripts
    { path = "utility/move.lua",        required = true },
    { path = "utility/refuel.lua",      required = true },
    { path = "utility/lava_refuel.lua", required = true },

    -- Startup menu
    { path = "startup.lua",           required = true },
}

-- Directories to create
local directories = {
    "common",
    "building",
    "mining",
    "utility",
}

-- ============================================
-- INSTALLER LOGIC
-- ============================================

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    print("========================================")
    print("   Turtle Scripts Installer")
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
            print("  Created: " .. dir .. "/")
        else
            print("  Exists:  " .. dir .. "/")
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

    local file = fs.open(localPath, "w")
    if not file then
        return false, "Could not write to " .. localPath
    end

    file.write(content)
    file.close()

    return true
end

local function downloadFiles()
    print("Downloading files...")
    local success = true
    local failed = {}

    for _, fileInfo in ipairs(files) do
        local path = fileInfo.path
        local isRequired = fileInfo.required

        write("  " .. path .. "... ")
        local ok, err = downloadFile(path, path)

        if ok then
            print("OK")
        else
            if isRequired then
                print("FAILED")
                table.insert(failed, {path = path, url = baseUrl .. path, error = err})
                success = false
            else
                print("skipped (optional)")
            end
        end
    end

    print("")

    if #failed > 0 then
        printError("========================================")
        printError("DOWNLOAD FAILURES:")
        printError("========================================")
        for _, f in ipairs(failed) do
            printError("")
            printError("File: " .. f.path)
            printError("URL:  " .. f.url)
            printError("Error: " .. tostring(f.error))
        end
        printError("========================================")
        print("")
    end

    return success
end

local function removeFiles()
    print("Removing installed files...")

    for _, fileInfo in ipairs(files) do
        if fs.exists(fileInfo.path) then
            fs.delete(fileInfo.path)
            print("  Deleted: " .. fileInfo.path)
        end
    end

    -- Remove directories (in reverse order)
    for i = #directories, 1, -1 do
        local dir = directories[i]
        if fs.exists(dir) and fs.isDir(dir) then
            local contents = fs.list(dir)
            if #contents == 0 then
                fs.delete(dir)
                print("  Removed: " .. dir .. "/")
            else
                print("  Kept:    " .. dir .. "/ (not empty)")
            end
        end
    end

    print("")
    print("Uninstall complete!")
end

local function showUsage()
    print("Usage:")
    print("  installer          Install all files")
    print("  installer update   Re-download all files")
    print("  installer remove   Uninstall everything")
    print("")
    print("After installing, run 'startup' to see the menu")
    print("Or run scripts directly:")
    print("  mining/strip_miner")
    print("  building/block")
    print("  utility/move")
    print("")
end

local function main(args)
    printHeader()

    local command = args[1] or "install"

    if command == "help" or command == "-h" or command == "--help" then
        showUsage()
        return
    end

    if command == "remove" or command == "uninstall" then
        removeFiles()
        return
    end

    if not checkHttp() then
        return
    end

    if command == "update" then
        print("Updating turtle scripts...")
        print("")
    else
        print("Installing turtle scripts...")
        print("")
    end

    createDirectories()

    if downloadFiles() then
        print("========================================")
        print("Installation complete!")
        print("========================================")
        print("")
        print("Run 'startup' for the interactive menu")
        print("Or run scripts directly:")
        print("  mining/strip_miner")
        print("  building/block")
        print("")
    else
        printError("Installation failed!")
        printError("Check error messages above.")
    end
end

local tArgs = { ... }
main(tArgs)
