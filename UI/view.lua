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
        cursor     = " > ",
        indent     = "   ",
        bool_on    = "[*]",
        bool_off   = "[ ]",
        subdir     = "-->",
        label_width = 30
    }
    
    return self
end

--- Component: Renders a menu_container line with dynamic width
-- @param menu table (The menu_container object)
-- @param is_selected boolean
-- @param width number (The terminal width)
function view:menu_item(menu, is_selected, width)
    local w = width or 80 -- Fallback safety
    local icon = is_selected and self.style.cursor or self.style.indent
    local title = menu.title or "Unnamed Menu"
    local dir_icon = self.style.subdir or "-->"

    -- Calculate available space for the title
    -- We subtract the icon (3), brackets/spaces (4), and subdir icon (3)
    local reserved = 12
    local available_space = w - reserved

    -- Truncate title if it's too long for the current window
    if #title > available_space then
        title = title:sub(1, math.max(available_space - 3, 1)) .. "..."
    end

    -- Create a dynamic format string
    -- %-s will left-align the title, then we manually pad the middle
    local padding_count = math.max(available_space - #title, 0)
    local padding = string.rep(" ", padding_count)

    return string.format("%s [ %s ] %s%s", 
        icon, 
        title, 
        padding,
        dir_icon)
end
--- Component: Renders a config_definition line
-- @param config table (The config_definition object)
-- @param is_selected boolean
function view:definition_item(config, is_selected, width)
    local icon = is_selected and " > " or "   "
    local status = config.datatype == "bool" and (config.value and "[*]" or "[ ]") or "("..tostring(config.value)..")"
    
    -- Calculate how much space we have for the name
    -- icon (3) + space (1) + status (3+) + space (1)
    local reserved = 10 
    local max_name_len = width - reserved
    
    local name = config.name
    if #name > max_name_len then
        name = name:sub(1, max_name_len - 3) .. "..."
    end

    return string.format("%s %s %s", icon, status, name)
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