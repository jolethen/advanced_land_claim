local modpath = minetest.get_modpath(minetest.get_current_modname())

local function safe_dofile(file)
    local path = modpath .. "/" .. file
    local ok, err = pcall(dofile, path)
    if not ok then
        minetest.log("error", "[advanced_land_claim] Failed loading " .. file .. ": " .. err)
    end
end

-- CONFIG FIRST
safe_dofile("config.lua")

-- STORAGE MUST BE FIRST (DATA, CLAIMS, EMPIRES)
safe_dofile("storage.lua")

-- UTILS NEXT (functions used everywhere)
safe_dofile("utils.lua")

-- CORE LOGIC
safe_dofile("empire.lua")
safe_dofile("protection.lua")
safe_dofile("enter_notify.lua")

-- COMMANDS LAST (they depend on everything above)
safe_dofile("commands.lua")
safe_dofile("help.lua")
