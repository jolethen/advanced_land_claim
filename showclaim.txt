-- Show claim borders temporarily
minetest.register_chatcommand("showclaim", {
    params = "<id>",
    description = "Show your claim or any claim by ID",
    func = function(name, param)
        local id = tonumber(param)
        if not id then return false, "Usage: /showclaim <id>" end
        local claim, owner = get_claim_by_id(id)
        if not claim then return false, "Claim not found." end
        if owner ~= name and not player_is_admin(name) then
            return false, "You cannot view this claim."
        end

        local nodes = {}
        for x = claim.pos1.x, claim.pos2.x do
            for z = claim.pos1.z, claim.pos2.z do
                for y = claim.pos1.y, claim.pos2.y do
                    if x == claim.pos1.x or x == claim.pos2.x
                    or z == claim.pos1.z or z == claim.pos2.z then
                        local pos = {x=x,y=y,z=z}
                        local node = minetest.get_node(pos)
                        table.insert(nodes, {pos=pos,node=node})
                        minetest.set_node(pos, {name=SHOWCLAIM_NODE})
                    end
                end
            end
        end

        minetest.after(SHOWCLAIM_DURATION, function()
            for _, n in ipairs(nodes) do
                minetest.set_node(n.pos, n.node)
            end
        end)

        return true, "Showing claim #" .. id .. " for " .. SHOWCLAIM_DURATION .. "s."
    end
})
