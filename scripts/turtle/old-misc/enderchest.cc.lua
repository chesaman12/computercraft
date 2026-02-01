local chests = {};

function add (name, slot) 
    chests[name] = slot
    return true
end

function getChests ()
    return chests
end

function clear () 
    chests = {}
    return true
end

function remove (name)
    addChest(name, nil)
    return true
end

function place (name)
    name = name or 'bob'
    local slot = chests[name]
    if slot == nil then return false end
    
    turtle.select(slot)
    turtle.digUp()
    turtle.placeUp()
    return true
end

function pickUp (name)
    name = name or 'bob'
    local slot = chests[name]
    if slot == nil then return false end
    
    turtle.select(slot)
    turtle.digUp()
    return true    
end