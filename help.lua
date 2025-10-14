-- help.lua
local storage = minetest.get_mod_storage()
local KEY_CLAIMS = "help_claims_text"
local KEY_EMPIRE = "help_empire_text"

local default_claims = [[
Claim Help:
- /claim_1 : mark first corner
- /claim_2 : mark second corner
- /claim_confirm <item> <personal|empire> : buy and create claim
- /addplayer <id> <players...> : allow players in your claim
- /removeplayer <id> <players...> : remove players
- /listallowed <id> : list allowed players
]]

local default_empire = [[
Empire Help:
- /empire_create <name> : create empire
- /invite_em <player> : invite player
- /accept_em <name> : accept invite
- /empire_color <hex> : set empire color (owner only)
- /empire_disband <name> : disband (owner only)
]]

local function get_help(key, def)
    local s = storage:get_string(key)
    if s == "" then storage:set_string(key, def); return def end
    return s
end

local function set_help(key, text)
    storage:set_string(key, text or "")
end

minetest.register_chatcommand("emchelp", {
    params = "<topic>",
    description = "Show help topics (claims, empire)",
    func = function(name, param)
        local topic = (param or ""):match("^(%S+)") or ""
        if topic ~= "claims" and topic ~= "empire" then
            return false, "Available topics: claims, empire"
        end
        local key = (topic == "claims") and KEY_CLAIMS or KEY_EMPIRE
        local txt = get_help(key, (topic == "claims") and default_claims or default_empire)

        local formspec = "formspec_version[6]size[10,10]textarea[0.25,0.5;9.5,8;help_text;;" .. minetest.formspec_escape(txt) .. "]button_exit[3,8.6;4,1;close;Close]"

        local privs = minetest.get_player_privs(name) or {}
        if privs.ceds then
            formspec = "formspec_version[6]size[10,10]textarea[0.25,0.5;9.5,7.2;help_text;" .. minetest.formspec_escape(txt) .. ";]button[3,7.6;4,0.8;save;Save]button_exit[3,8.6;4,1;close;Close]"
        end

        minetest.show_formspec(name, "advanced_land_claim:help_" .. topic, formspec)
        return true
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not formname then return end
    if formname:sub(1,23) ~= "advanced_land_claim:help_" then return end
    local name = player:get_player_name()
    local privs = minetest.get_player_privs(name) or {}
    if fields.save and privs.ceds and fields.help_text then
        local topic = formname:sub(24)
        local key = (topic == "claims") and KEY_CLAIMS or KEY_EMPIRE
        set_help(key, fields.help_text)
        minetest.chat_send_player(name, "✅ Help text saved.")
    end
end)
