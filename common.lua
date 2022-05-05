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

function doom_hud.render_text(text, x, y, right_align)
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

function doom_hud.get_wielditem_pos(i)
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
function doom_hud.percent(n)
    return math.floor(n * 100 + 1e-10) .. "%"
end