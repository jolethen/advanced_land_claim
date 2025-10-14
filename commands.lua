-- commands.lua
-- Claiming commands and token purchase

local temp_positions = {}

-- Helper safe get player
local function get_player(name)
    return minetest.get_player_by_name(name)
end

-- claim_1
minetest.register_chatcommand("claim_1", {
    description = "Set first corner of claim area",
    func = function(name)
        local player = get_player(name)
        if not player then return false, "Player not found." end
        local pos = vector.round(player:get_pos())
        temp_positions[name] = temp_positions[name] or {}
        temp_positions[name].pos1 = pos
        return true, "✅ First position set at " .. minetest.pos_to_string(pos)
    end
})

-- claim_2
minetest.register_chatcommand("claim_2", {
    description = "Set second corner of claim area",
    func = function(name)
        local player = get_player(name)
        if not player then return false, "Player not found." end
        local pos = vector.round(player:get_pos())
        temp_positions[name] = temp_positions[name] or {}
        temp_positions[name].pos2 = pos
        return true, "✅ Second position set at " .. minetest.pos_to_string(pos)
    end
})

-- claim_confirm: /claim_confirm <item> <personal|empire>
minetest.register_chatcommand("claim_confirm", {
    params = "<item> <personal|empire>",
    description = "Confirm claim between previously set positions (pay with item)",
    func = function(name, param)
        local player = get_player(name)
        if not player then return false, "Player not found." end

        local t = temp_positions[name]
        if not t or not t.pos1 or not t.pos2 then
            return false, "You must set /claim_1 and /claim_2 first."
        end

        local item, typ = param:match("^(%S+)%s*(%S*)$")
        if not item then return false, "Usage: /claim_confirm <item> <personal|empire>" end
        typ = (typ == "" and "personal") or typ
        if typ ~= "personal" and typ ~= "empire" then
            return false, "Type must be 'personal' or 'empire'."
        end

        local price_info = find_price_item(item)
        if not price_info then return false, "That item cannot be used for claiming." end

        local pos1 = { x = math.min(t.pos1.x, t.pos2.x), y = HEIGHT_MIN, z = math.min(t.pos1.z, t.pos2.z) }
        local pos2 = { x = math.max(t.pos1.x, t.pos2.x), y = HEIGHT_MAX, z = math.max(t.pos1.z, t.pos2.z) }

        local size_x = pos2.x - pos1.x + 1
        local size_z = pos2.z - pos1.z + 1
        local area = size_x * size_z

        if area <= 0 or size_x < MIN_CLAIM_SIZE or size_z < MIN_CLAIM_SIZE or size_x > MAX_CLAIM_SIZE or size_z > MAX_CLAIM_SIZE then
            return false, "Invalid claim size or exceeds limits."
        end

        -- overlap check
        for owner, list in pairs(CLAIMS or {}) do
            if type(list) == "table" then
                for _, claim in ipairs(list) do
                    -- bounding box overlap check
                    if not (pos2.x < claim.pos1.x or pos1.x > claim.pos2.x or pos2.z < claim.pos1.z or pos1.z > claim.pos2.z) then
                        return false, "Overlaps with another claim (ID:"..tostring(claim.id)..")"
                    end
                end
            end
        end

        local needed = math.ceil(area * price_info.rate)
        local inv = player:get_inventory()
        if not inv or not inv:contains_item("main", ItemStack(item .. " " .. needed)) then
            return false, "You need " .. needed .. "x " .. item .. " to create this claim."
        end

        -- If empire claim, ensure player is in an empire
        if typ == "empire" then
            local empire_name = PLAYER_TO_EMPIRE[name]
            if not empire_name or not EMPIRES[empire_name] then
                return false, "You are not in an empire."
            end
        end

        -- Deduct items
        inv:remove_item("main", ItemStack(item .. " " .. needed))

        -- Create claim
        local id = next_claim_id()
        local claim = {
            id = id,
            owner = name,
            pos1 = pos1,
            pos2 = pos2,
            shared = {}, -- map of playername -> true
            type = typ,
        }
        if typ == "empire" then
            claim.empire = PLAYER_TO_EMPIRE[name]
            EMPIRES[claim.empire] = EMPIRES[claim.empire] or {}
            EMPIRES[claim.empire].claims = EMPIRES[claim.empire].claims or {}
            table.insert(EMPIRES[claim.empire].claims, id)
        end

        CLAIMS[name] = CLAIMS[name] or {}
        table.insert(CLAIMS[name], claim)
        save_claims()
        temp_positions[name] = nil

        return true, ("✅ Land claimed (ID #%d) — %dx%d blocks — paid %dx %s"):format(id, size_x, size_z, needed, item)
    end
})

-- unclaim
minetest.register_chatcommand("unclaim", {
    params = "<id>",
    description = "Remove a claim you own (admins may remove any)",
    func = function(name, param)
        local id = tonumber(param)
        if not id then return false, "Usage: /unclaim <id>" end
        local claim, owner = get_claim_by_id(id)
        if not claim then return false, "Claim not found." end
        if owner ~= name and not player_is_admin(name) then return false, "You don't own this claim." end
        for i,c in ipairs(CLAIMS[owner] or {}) do
            if c.id == id then table.remove(CLAIMS[owner], i); break end
        end
        if claim.type == "empire" and claim.empire and EMPIRES[claim.empire] and EMPIRES[claim.empire].claims then
            for i,v in ipairs(EMPIRES[claim.empire].claims) do if v == id then table.remove(EMPIRES[claim.empire].claims, i); break end end
        end
        save_claims()
        return true, "❌ Claim #" .. tostring(id) .. " removed."
    end
})

-- addplayer (owner or admin)
minetest.register_chatcommand("addplayer", {
    params = "<claimid> <player1> [player2 ...]",
    description = "Add players to a claim's allowed list",
    func = function(name, param)
        local idstr, rest = param:match("^(%d+)%s*(.*)$")
        local id = tonumber(idstr)
        if not id or not rest or rest:match("^%s*$") then return false, "Usage: /addplayer <claimid> <player1> [player2 ...]" end
        local claim, owner = get_claim_by_id(id)
        if not claim then return false, "Claim not found." end
        if owner ~= name and not player_is_admin(name) then return false, "You must own the claim or be admin." end
        claim.shared = claim.shared or {}
        local added = {}
        for pname in rest:gmatch("(%S+)") do
            claim.shared[pname] = true
            table.insert(added, pname)
        end
        save_claims()
        return true, "Added to claim #"..id..": "..table.concat(added, ", ")
    end
})

-- removeplayer (owner or admin)
minetest.register_chatcommand("removeplayer", {
    params = "<claimid> <player1> [player2 ...]",
    description = "Remove players from a claim's allowed list",
    func = function(name, param)
        local idstr, rest = param:match("^(%d+)%s*(.*)$")
        local id = tonumber(idstr)
        if not id or not rest or rest:match("^%s*$") then return false, "Usage: /removeplayer <claimid> <player1> [player2 ...]" end
        local claim, owner = get_claim_by_id(id)
        if not claim then return false, "Claim not found." end
        if owner ~= name and not player_is_admin(name) then return false, "You must own the claim or be admin." end
        claim.shared = claim.shared or {}
        local removed = {}
        for pname in rest:gmatch("(%S+)") do
            if claim.shared[pname] then
                claim.shared[pname] = nil
                table.insert(removed, pname)
            end
        end
        save_claims()
        if #removed == 0 then return true, "No matching players were found in the allowed list." end
        return true, "Removed from claim #"..id..": "..table.concat(removed, ", ")
    end
})

-- listallowed
minetest.register_chatcommand("listallowed", {
    params = "<claimid>",
    description = "List players allowed to build in a claim",
    func = function(name, param)
        local id = tonumber(param)
        if not id then return false, "Usage: /listallowed <claimid>" end
        local claim, owner = get_claim_by_id(id)
        if not claim then return false, "Claim not found." end
        if owner ~= name and not player_is_admin(name) then return false, "You don't have permission." end
        claim.shared = claim.shared or {}
        local list = {}
        for ply, v in pairs(claim.shared) do if v then table.insert(list, ply) end end
        local s = (#list > 0) and table.concat(list, ", ") or "<no players allowed>"
        return true, "Allowed players for claim #" .. id .. ": " .. s
    end
})

-- allow_em and revoke_em (empire owner/staff only)
minetest.register_chatcommand("allow_em", {
    params = "<player|all> <claimid|all>",
    description = "Allow empire member(s) for empire-owned claim(s). Usage: /allow_em <player|all> <claimid|all>",
    func = function(name, param)
        local who, cid = param:match("^(%S+)%s*(%S+)$")
        if not who or not cid then return false, "Usage: /allow_em <player|all> <claimid|all>" end

        local empire_name = PLAYER_TO_EMPIRE[name]
        if not empire_name or not EMPIRES[empire_name] then return false, "You are not in an empire." end
        local E = EMPIRES[empire_name]

        if E.owner ~= name and not (E.staff and E.staff[name]) then
            return false, "Only the empire owner or staff can manage access."
        end

        ALLOWED_EM[empire_name] = ALLOWED_EM[empire_name] or {}

        if cid == "all" then
            -- allow who for all empire claims
            ALLOWED_EM[empire_name][who] = ALLOWED_EM[empire_name][who] or {}
            ALLOWED_EM[empire_name][who].claims = "all"
            save_claims()
            return true, "Allowed " .. who .. " for all empire claims."
        end

        local claimid = tonumber(cid)
        if not claimid then return false, "Invalid claim id." end

        -- ensure empire owns this claimid
        local owns = false
        for _, id in ipairs(E.claims or {}) do if id == claimid then owns = true; break end end
        if not owns then return false, "Your empire does not own claim #" .. tostring(claimid) end

        ALLOWED_EM[empire_name][who] = ALLOWED_EM[empire_name][who] or { claims = {} }
        if ALLOWED_EM[empire_name][who].claims == "all" then
            return true, who .. " is already allowed for all empire claims."
        end

        -- avoid duplicates
        local claims_list = ALLOWED_EM[empire_name][who].claims
        local exists = false
        for _, id in ipairs(claims_list) do if id == claimid then exists = true; break end end
        if not exists then table.insert(claims_list, claimid) end
        save_claims()
        return true, "Allowed " .. who .. " for claim #" .. tostring(claimid)
    end
})

minetest.register_chatcommand("revoke_em", {
    params = "<player|all> <claimid|all>",
    description = "Revoke empire access. Usage: /revoke_em <player|all> <claimid|all>",
    func = function(name, param)
        local who, cid = param:match("^(%S+)%s*(%S+)$")
        if not who or not cid then return false, "Usage: /revoke_em <player|all> <claimid|all>" end

        local empire_name = PLAYER_TO_EMPIRE[name]
        if not empire_name or not EMPIRES[empire_name] then return false, "You are not in an empire." end
        local E = EMPIRES[empire_name]
        if E.owner ~= name and not (E.staff and E.staff[name]) then return false, "Only owner or staff can manage access." end

        ALLOWED_EM[empire_name] = ALLOWED_EM[empire_name] or {}

        if cid == "all" then
            ALLOWED_EM[empire_name][who] = nil
            save_claims()
            return true, "Revoked " .. who .. " from all empire claims."
        end

        local claimid = tonumber(cid)
        if not claimid then return false, "Invalid claim id." end

        local entry = ALLOWED_EM[empire_name][who]
        if not entry then return true, "Nothing to revoke." end
        if entry.claims == "all" then
            ALLOWED_EM[empire_name][who] = nil
            save_claims()
            return true, "Revoked " .. who .. " from all empire claims."
        end
        if type(entry.claims) == "table" then
            for i,v in ipairs(entry.claims) do
                if v == claimid then table.remove(entry.claims, i); break end
            end
        end
        save_claims()
        return true, "Revoked " .. who .. " for claim #" .. tostring(claimid)
    end
})

-- buy claim tokens /tokens
minetest.register_chatcommand("buy_claimtoken", {
    params = "<amount> <item>",
    description = "Buy claim tokens. Usage: /buy_claimtoken <amount> <item>",
    func = function(name, param)
        local amt, item = param:match("^(%d+)%s*(%S+)$")
        amt = tonumber(amt)
        if not amt or not item then return false, "Usage: /buy_claimtoken <amount> <item>" end
        local player = get_player(name)
        if not player then return false, "Player not found." end
        local inv = player:get_inventory()
        if not inv then return false, "Inventory unavailable." end

        local cost_entry = nil
        for _, e in ipairs(TOKEN_COSTS or {}) do if e.item == item then cost_entry = e; break end end
        if not cost_entry then return false, "That item cannot be used to buy tokens." end
        local need = cost_entry.amount * amt
        if not inv:contains_item("main", ItemStack(item .. " " .. need)) then
            return false, "You need " .. need .. "x " .. item
        end

        inv:remove_item("main", ItemStack(item .. " " .. need))
        DATA.players_tokens = DATA.players_tokens or {}
        DATA.players_tokens[name] = (DATA.players_tokens[name] or 0) + amt
        save_claims()
        return true, "✅ You bought " .. tostring(amt) .. " claim tokens."
    end
})

minetest.register_chatcommand("tokens", {
    description = "Check your claim tokens.",
    func = function(name)
        DATA.players_tokens = DATA.players_tokens or {}
        local n = DATA.players_tokens[name] or 0
        return true, "You have " .. tostring(n) .. " claim tokens."
    end
})
