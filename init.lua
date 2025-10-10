local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local function safe_dofile(fname)
    local ok, err = pcall(dofile, modpath.."/"..fname)
    if not ok then
        minetest.log("error", "[advanced_land_claim] Failed to load "..fname..": "..tostring(err))
    else
        minetest.log("action", "[advanced_land_claim] Loaded "..fname)
    end
end

safe_dofile("config.lua")
safe_dofile("storage.lua")
safe_dofile("utils.lua")
safe_dofile("protection.lua")
safe_dofile("commands.lua")
safe_dofile("showclaim.lua")

minetest.log("action", "[advanced_land_claim] Mod fully initialized.")
