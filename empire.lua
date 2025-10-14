-- empire.lua
-- Empire creation & management

-- create empire
minetest.register_chatcommand("empire_create", {
    params = "<name>",
    description = "Create a new empire. You become the owner.",
    func = function(name, param)
        local ename = (param or ""):match("^(%S.+)$")
        if not ename then return false, "Usage: /empire_create <name>" end
        if PLAYER_TO_EMPIRE[name] and EMPIRES[PLAYER_TO_EMPIRE[name]] then return false, "You are already in an empire." end
        if EMPIRES[ename] then return false, "An empire with that name already exists." end
        EMPIRES[ename] = {
            name = ename,
            owner = name,
            color = "#ffffff",
            members = { [name] = true },
            staff = {},
            claims = {},
            invited = {}
        }
        PLAYER_TO_EMPIRE[name] = ename
        save_claims()
        return true, "✅ Empire '"..ename.."' created. You are the owner."
    end
})

-- set empire color (owner only)
minetest.register_chatcommand("empire_color", {
    params = "<#hex>",
    description = "Set empire color (owner only). Accepts hex like ff0000 or #ff0000",
    func = function(name, param)
        local hex = (param or ""):match("^%s*(#?%x%x%x%x%x%x)$")
        if not hex then return false, "Usage: /empire_color <hex> (e.g. ff0000)" end
        if hex:sub(1,1) ~= "#" then hex = "#" .. hex end
        local ename = PLAYER_TO_EMPIRE[name]
        if not ename or not EMPIRES[ename] then return false, "You are not in an empire." end
        local E = EMPIRES[ename]
        if E.owner ~= name then return false, "Only the owner can change color." end
        E.color = hex
        save_claims()
        return true, "✅ Empire color set to " .. hex
    end
})

-- disband empire (owner only)
minetest.register_chatcommand("empire_disband", {
    params = "<name>",
    description = "Disband an empire (owner only).",
    func = function(name, param)
        local ename = (param or ""):match("^(%S.+)$")
        if not ename then return false, "Usage: /empire_disband <name>" end
        local E = EMPIRES[ename]
        if not E then return false, "Empire not found." end
        if E.owner ~= name then return false, "Only the owner can disband the empire." end
        -- remove empire claims
        for _, cid in ipairs(E.claims or {}) do
            local claim, owner = get_claim_by_id(cid)
            if claim and owner and CLAIMS[owner] then
                for i,c in ipairs(CLAIMS[owner]) do if c.id == cid then table.remove(CLAIMS[owner], i); break end end
            end
        end
        for member,_ in pairs(E.members or {}) do PLAYER_TO_EMPIRE[member] = nil end
        EMPIRES[ename] = nil
        ALLOWED_EM[ename] = nil
        save_claims()
        return true, "✅ Empire '"..ename.."' disbanded."
    end
})

-- leave empire
minetest.register_chatcommand("empire_leave", {
    description = "Leave your empire.",
    func = function(name)
        local ename = PLAYER_TO_EMPIRE[name]
        if not ename then return false, "You are not in an empire." end
        local E = EMPIRES[ename]
        if not E then PLAYER_TO_EMPIRE[name] = nil; save_claims(); return true, "Left empire." end
        E.members[name] = nil
        if E.staff then E.staff[name] = nil end
        PLAYER_TO_EMPIRE[name] = nil
        save_claims()
        return true, "✅ You left empire '"..ename.."'." 
    end
})

-- invite player (owner or staff)
minetest.register_chatcommand("invite_em", {
    params = "<player>",
    description = "Invite a player to your empire (owner or staff).",
    func = function(name, param)
        local target = (param or ""):match("^(%S+)$")
        if not target then return false, "Usage: /invite_em <player>" end
        local ename = PLAYER_TO_EMPIRE[name]
        if not ename or not EMPIRES[ename] then return false, "You are not in an empire." end
        local E = EMPIRES[ename]
        if not (E.owner == name or (E.staff and E.staff[name])) then return false, "Only owner or staff can invite." end
        E.invited = E.invited or {}
        E.invited[target] = true
        save_claims()
        return true, "✅ "..target.." invited to empire "..ename
    end
})

-- accept invite
minetest.register_chatcommand("accept_em", {
    params = "<empire_name>",
    description = "Accept an invitation to an empire.",
    func = function(name, param)
        local ename = (param or ""):match("^(%S.+)$")
        if not ename then return false, "Usage: /accept_em <empire_name>" end
        local E = EMPIRES[ename]
        if not E then return false, "Empire not found." end
        if not (E.invited and E.invited[name]) then return false, "You are not invited to this empire." end
        E.invited[name] = nil
        E.members = E.members or {}
        E.members[name] = true
        PLAYER_TO_EMPIRE[name] = ename
        save_claims()
        return true, "✅ You joined "..ename
    end
})

-- promote / demote staff (owner only)
minetest.register_chatcommand("empire_promote", {
    params = "<player>",
    description = "Promote a member to staff (owner only).",
    func = function(name, param)
        local target = (param or ""):match("^(%S+)$")
        if not target then return false, "Usage: /empire_promote <player>" end
        local ename = PLAYER_TO_EMPIRE[name]
        if not ename or not EMPIRES[ename] then return false, "You are not in an empire." end
        local E = EMPIRES[ename]
        if E.owner ~= name then return false, "Only owner can promote." end
        E.staff = E.staff or {}
        E.staff[target] = true
        save_claims()
        return true, "✅ "..target.." promoted to staff."
    end
})

minetest.register_chatcommand("empire_demote", {
    params = "<player>",
    description = "Demote a staff member (owner only).",
    func = function(name, param)
        local target = (param or ""):match("^(%S+)$")
        if not target then return false, "Usage: /empire_demote <player>" end
        local ename = PLAYER_TO_EMPIRE[name]
        if not ename or not EMPIRES[ename] then return false, "You are not in an empire." end
        local E = EMPIRES[ename]
        if E.owner ~= name then return false, "Only owner can demote." end
        if E.staff then E.staff[target] = nil end
        save_claims()
        return true, "✅ "..target.." demoted."
    end
})
