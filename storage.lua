local storage = minetest.get_mod_storage()

function load_claims()
    local raw = storage:get_string("claims")
    if raw == "" then return {}, 0 end
    local ok, data = pcall(minetest.deserialize, raw)
    if not ok or type(data) ~= "table" or not data.claims then
        return {}, 0
    end
    return data.claims, data.last_id or 0
end

function save_claims()
    local ok, serialized = pcall(minetest.serialize, {claims = CLAIMS, last_id = LAST_ID})
    if ok then storage:set_string("claims", serialized) end
end

CLAIMS, LAST_ID = load_claims()
