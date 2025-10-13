local storage = minetest.get_mod_storage()

local function safe_deserialize(s)
    local ok, res = pcall(minetest.deserialize, s)
    if ok and type(res) == "table" then return res end
    return nil
end

function load_all()
    local raw = storage:get_string("data")
    if raw == "" then
        return {claims = {}, last_id = 0, empires = {}, players = {}, allowed_em = {}, players_tokens = {}}
    end
    local t = safe_deserialize(raw)
    if not t then
        return {claims = {}, last_id = 0, empires = {}, players = {}, allowed_em = {}, players_tokens = {}}
    end
    t.claims = t.claims or {}
    t.last_id = t.last_id or 0
    t.empires = t.empires or {}
    t.players = t.players or {}
    t.allowed_em = t.allowed_em or {}
    t.players_tokens = t.players_tokens or {}
    return t
end

DATA = load_all()

function save_all()
    local ok, s = pcall(minetest.serialize, DATA)
    if ok then
        storage:set_string("data", s)
    else
        minetest.log("error", "[advanced_land_claim] Failed to serialize data")
    end
end

CLAIMS = DATA.claims
LAST_ID = DATA.last_id
EMPIRES = DATA.empires
PLAYER_TO_EMPIRE = DATA.players
ALLOWED_EM = DATA.allowed_em
PLAYERS_TOKENS = DATA.players_tokens
