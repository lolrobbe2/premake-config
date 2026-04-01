---
-- KConfig premake5 - Component-Based UI
-- Copyright (c) 2026 Robbe Beernaert
---

local view = {}
view.__index = view

function view.new()
    local self = setmetatable({}, view)

    -- UI Style Configuration
    self.style = {
        cursor      = " > ",
        indent      = "   ",
        bool_on     = "[*]",
        bool_off    = "[ ]",
        subdir      = "-->",
        label_width = 30
    }

    return self
end

--- Component: Renders a menu_container line with dynamic width
-- @param menu table (The menu_container object)
-- @param is_selected boolean
-- @param width number (The terminal width)
function view:menu_item(menu, is_selected, width)
    local w = width or 80
    -- Gutter is exactly 3 chars
    local gutter = is_selected and ">  " or "   "

    -- Note: Space after '[' to separate from text
    local title = "[ " .. menu.title .. " ]"
    local arrow = "-->"

    local current_len = #gutter + #title + #arrow
    local gap = string.rep(" ", math.max(w - current_len, 0))

    local line = string.format("%s%s%s%s", gutter, title, gap, arrow)
    if is_selected then
        return "\27[7;1m" .. line .. "\27[0m"
    end

    return line
end

--- Component: Renders a config_definition line
-- @param config table (The config_definition object)
-- @param is_selected boolean
function view:definition_item(config, is_selected, width)
    local w = width or 80
    -- Gutter is exactly 3 chars (Matches menu exactly)
    local gutter = is_selected and ">  " or "   "

    local status = ""
    if config.datatype == "bool" then
        -- No space before '[' so it aligns with the menu's '['
        status = config.value and "[*]" or "[ ]"
    elseif config.datatype == "enum" then
        status = "<" .. tostring(config.value or "") .. ">"
    else
        status = "(" .. tostring(config.value or "") .. ")"
    end

    local name = config.name or "UNKNOWN"

    -- Calculation: gutter(3) + status(3) + space(1) + name
    local current_len = #gutter + #status + 1 + #name
    local gap = string.rep(" ", math.max(w - current_len, 0))

    local line = string.format("%s%s %s%s", gutter, status, name, gap)
    if is_selected then
        return "\27[7;1m" .. line .. "\27[0m"
    end

    return line
end

--- Master Render: Assembles the components
-- @param items table (List of objects from a menu_container)
-- @param selected_index number
function view:assemble(items, selected_index, width)
    -- Fallback to 80 if width is nil to prevent arithmetic errors
    local w = width or 80
    local buffer = {}

    for i, item in ipairs(items) do
        local line = ""
        if item.is_menu then
            line = self:menu_item(item, i == selected_index, w)
        else
            line = self:definition_item(item, i == selected_index, w)
        end
        table.insert(buffer, line)
    end

    return buffer
end

--- Renders an ASCII box centered on the screen
-- @param lines table (Array of strings to display inside)
-- @param width number (Current terminal width)
function view:centered_box(lines, width)
    local w = width or 80
    local box_w = 60
    local left_margin = math.floor((w - box_w) / 2)
    local pad = string.rep(" ", left_margin)

    local h_line = pad .. "+" .. string.rep("-", box_w - 2) .. "+"
    local buffer = {}

    table.insert(buffer, h_line)

    for _, text in ipairs(lines) do
        local content = " " .. text
        local inner_width = box_w - 2
        -- Ensure text doesn't break the border
        local truncated = content:sub(1, inner_width)
        local space = string.rep(" ", inner_width - #truncated)
        table.insert(buffer, pad .. "|" .. truncated .. space .. "|")
    end

    table.insert(buffer, h_line)
    return buffer
end

return view
