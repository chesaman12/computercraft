--- Turtle Scripts Startup Menu
-- Interactive menu to launch turtle scripts
-- @script startup

-- Menu pages for pagination (turtle terminal is 13 lines)
local pages = {
    {
        title = "Building",
        items = {
            { key = "1", name = "Block Builder",  script = "building/block.lua" },
            { key = "2", name = "Wall Builder",   script = "building/wall.lua" },
            { key = "3", name = "House Builder",  script = "building/house.lua" },
        }
    },
    {
        title = "Mining",
        items = {
            { key = "4", name = "Area Digger",    script = "mining/dig.lua" },
            { key = "5", name = "Simple Miner",   script = "mining/simple_miner.lua" },
            { key = "6", name = "Stair Miner",    script = "mining/stair_miner.lua" },
            { key = "7", name = "Strip Miner",    script = "mining/strip_miner.lua" },
        }
    },
    {
        title = "Utility",
        items = {
            { key = "8", name = "Move",           script = "utility/move.lua" },
            { key = "9", name = "Refuel",         script = "utility/refuel.lua" },
            { key = "0", name = "Lava Refuel",    script = "utility/lava_refuel.lua" },
        }
    },
}

local currentPage = 1

local function showMenu()
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Fuel status (compact)
    local fuel = turtle.getFuelLevel()
    local fuelStr = (fuel == "unlimited") and "Unlim" or tostring(fuel)
    print("Fuel:" .. fuelStr .. " [" .. currentPage .. "/" .. #pages .. "]")
    
    -- Current page
    local page = pages[currentPage]
    print("== " .. page.title .. " ==")
    for _, item in ipairs(page.items) do
        print(" " .. item.key .. ": " .. item.name)
    end
    
    -- Navigation
    print("")
    print("</>: Prev/Next page")
    print("r: Reboot  q: Exit")
    write("--> ")
end

local function runScript(scriptPath)
    if fs.exists(scriptPath) then
        term.clear()
        term.setCursorPos(1, 1)
        shell.run(scriptPath)
    else
        printError("Script not found: " .. scriptPath)
        printError("Run 'installer' to download scripts")
        print("")
        print("Press any key...")
        os.pullEvent("key")
    end
end

-- Build lookup table from pages
local scripts = {}
for _, page in ipairs(pages) do
    for _, item in ipairs(page.items) do
        scripts[item.key] = item.script
    end
end

local function main()
    while true do
        showMenu()
        local choice = read():lower()
        
        if choice == "r" or choice == "reboot" then
            os.reboot()
        elseif choice == "q" or choice == "quit" or choice == "exit" then
            term.clear()
            term.setCursorPos(1, 1)
            print("Type 'startup' to return to menu")
            return
        elseif choice == ">" or choice == "." or choice == "n" then
            currentPage = currentPage % #pages + 1
        elseif choice == "<" or choice == "," or choice == "p" then
            currentPage = (currentPage - 2) % #pages + 1
        elseif scripts[choice] then
            runScript(scripts[choice])
            print("")
            print("Press any key...")
            os.pullEvent("key")
        elseif choice ~= "" then
            print("Unknown: " .. choice)
            sleep(1)
        end
    end
end

main()

