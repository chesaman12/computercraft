--- User input utilities
-- @module input

local M = {}

--- Read a positive number from user
-- @param prompt string Prompt to display
-- @param defaultValue number Default value if enter is pressed (optional)
-- @return number The entered number
function M.readNumber(prompt, defaultValue)
    while true do
        write(prompt)
        local input = read()
        if input == "" and defaultValue ~= nil then
            return defaultValue
        end
        local value = tonumber(input)
        if value and value > 0 then
            return value
        end
        print("Please enter a positive number.")
    end
end

--- Read yes/no from user
-- @param prompt string Prompt to display
-- @param defaultValue boolean Default value if enter is pressed (optional)
-- @return boolean True for yes, false for no
function M.readYesNo(prompt, defaultValue)
    while true do
        write(prompt)
        local input = read():lower()
        if input == "" and defaultValue ~= nil then
            return defaultValue
        end
        if input == "y" or input == "yes" then
            return true
        end
        if input == "n" or input == "no" then
            return false
        end
        print("Please enter y or n.")
    end
end

--- Read a choice from a range of numbers
-- @param prompt string Prompt to display
-- @param minValue number Minimum valid choice
-- @param maxValue number Maximum valid choice
-- @param defaultValue number Default value if enter is pressed (optional)
-- @return number The selected choice
function M.readChoice(prompt, minValue, maxValue, defaultValue)
    while true do
        write(prompt)
        local input = read()
        if input == "" and defaultValue ~= nil then
            return defaultValue
        end
        local value = tonumber(input)
        if value and value >= minValue and value <= maxValue then
            return value
        end
        print("Please enter a number from " .. minValue .. " to " .. maxValue .. ".")
    end
end

--- Normalize direction input to standard form
-- @param input string User input (l, left, r, right)
-- @return string "left" or "right"
function M.normalizeLeftRight(input)
    input = input:lower()
    if input == "l" or input == "left" then
        return "left"
    elseif input == "r" or input == "right" then
        return "right"
    end
    return input
end

--- Normalize up/down input to standard form
-- @param input string User input (u, up, d, down)
-- @return string "up" or "down"
function M.normalizeUpDown(input)
    input = input:lower()
    if input == "u" or input == "up" then
        return "up"
    elseif input == "d" or input == "down" then
        return "down"
    end
    return input
end

return M
