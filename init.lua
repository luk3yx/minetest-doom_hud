local SCALE = 4
hud_fs.set_scale("doom_hud:hud", SCALE)

local nums = {}
for i = 0, 9 do
    nums[tostring(i)] = true
end

local function get_lg_texture(char)
    if nums[char] then
        return "doom_hud_sttnum" .. char .. ".png"
    end
    return "doom_hud_sttprcnt.png"
end

local function render_text(text, x, y, right_align)
    local x_scale = right_align and -13 or 13
    local res = {type = "container", x = x + 1, y = y}
    for i = 1, #text do
        res[i] = {
            type = "image",
            x = i * x_scale,
            y = 0,
            w = 13,
            h = 16,
            texture_name = get_lg_texture(text:sub(-i, -i))
        }
    end
    return res
end

local function get_wielditem_pos(i)
    if i >= 8 then
        return {
            x = 239,
            y = 10 * i - 77,
            w = 7,
            h = 7,
        }
    end
    return {
        x = 108 + (i % 4) * 8,
        y = i >= 4 and 11.2 or 3.2,
        w = 7.2,
        h = 7.2,
    }
end

-- Add a tiny value to try and fix floating-point weirdness
local function percent(n)
    return math.floor(n * 100 + 1e-10) .. "%"
end

local old_hotbar = {}
local old_wield_index = {}
local old_breath = {}
local sam_e = ""
local function update_hud(player)
    local props = player:get_properties()
    local health_frac = player:get_hp() / props.hp_max * 2
    local tree = {
        {type = "size", w = 320, h = 32},
        {type = "position", x = 0.5, y = 1},
        {type = "anchor", x = 0.5, y = 1},
        {type = "image", x = 0, y = 0, w = 320, h = 32,
            texture_name = "doom_hud_stbar.png"},
        {type = "image", x = 150, y = 7, w = 20, h = 20,
            texture_name = "doom_hud_sam" .. sam_e .. ".png^[opacity:" ..
            math.floor(math.min(health_frac + 0.1, 1) * 255)}
    }

    local name = player:get_player_name()
    local wield_index = player:get_wield_index()
    local elem = get_wielditem_pos(wield_index - 1)
    old_wield_index[name] = wield_index
    elem.type = "box"
    elem.color = "darkgrey"
    tree[#tree + 1] = elem

    local inv = player:get_inventory()
    local stacks = {}
    for i = 0, 10 do
        local stack = inv:get_stack("main", i + 1)
        local item_name = stack:get_name()
        stacks[i + 1] = stack:to_string()
        elem = get_wielditem_pos(i)
        if item_name == "" then
            elem.type = "image"
            elem.texture_name = "blank.png"
        else
            elem.type = "item_image"
            elem.item_name = item_name
        end
        tree[#tree + 1] = elem
    end
    old_hotbar[name] = stacks

    local breath_val = player:get_breath()
    old_breath[name] = breath_val
    tree[#tree + 1] = render_text(
        percent(breath_val / props.breath_max), 232, 3, true
    )
    tree[#tree + 1] = render_text(percent(health_frac), 101, 3, true)

    local stack = player:get_wielded_item()
    local ammo
    if stack:get_definition().type == "tool" then
        -- ammo = math.floor(100 - (stack:get_wear() / 65536 * 100))
        local uses = stack:get_tool_capabilities().punch_attack_uses
        ammo = math.floor((65536 - stack:get_wear()) / 65536 * uses) + 1
    else
        ammo = stack:get_count()
    end
    tree[#tree + 1] = render_text(tostring(ammo), 42, 3, true)

    hud_fs.show_hud(player, "doom_hud:hud", tree)
end

local function update_hud_pname(name)
    local player = minetest.get_player_by_name(name)
    if player then
        update_hud(player)
    end
end

local t = 0
minetest.register_globalstep(function(dtime)
    t = t + dtime
    if t >= 3 then
        t = 0
        if sam_e == "" then
            sam_e = "_l"
        elseif sam_e == "_l" then
            sam_e = "_r"
        else
            sam_e = ""
        end
        for _, player in ipairs(minetest.get_connected_players()) do
            if player:get_hp() > 0 then
                update_hud(player)
            end
        end
        return
    end
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        if player:get_wield_index() ~= old_wield_index[name] or
                player:get_breath() ~= old_breath[name] then
            update_hud(player)
        else
            local hb = old_hotbar[name] or {}
            local inv = player:get_inventory()
            for i = 1, 11 do
                if hb[i] ~= inv:get_stack("main", i):to_string() then
                    update_hud(player)
                    break
                end
            end
        end
    end
end)

minetest.register_on_joinplayer(function(player)
    t = 0
    local hud_flags = player:hud_get_flags()
    hud_flags.hotbar = false
    hud_flags.healthbar = false
    hud_flags.breathbar = false
    player:hud_set_flags(hud_flags)
    player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.5, y = 1},
        scale = {x = -100, y = SCALE},
        offset = {x = 0, y = -SCALE * 16},
        text = "doom_hud_stbar_side.png",
    })
    update_hud(player)
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    old_hotbar[name] = nil
    old_wield_index[name] = nil
    old_breath[name] = nil
end)

minetest.register_on_player_hpchange(function(player, _, _)
    minetest.after(0, update_hud_pname, player:get_player_name())
end, false)
