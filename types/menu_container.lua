---
-- KConfig premake5.
-- Copyright (c) 2026 Robbe Beernaert
---

local menu_container = {}
menu_container.__index = menu_container

--- Constructor
-- @param title string (The display name of the menu)
function menu_container.new(title)
    local self = setmetatable({}, menu_container)
    
    self.title = title or "Untitled Menu"
    self.items = {}      -- List of config_definition or menu_container objects
    self.parent = nil    -- Reference to parent menu for walking back up the tree
    self.is_menu = true  -- Helper flag to distinguish from definitions
    
    return self
end

--- Adds an item to this menu
-- @param item table (either a config_definition or another menu_container)
function menu_container:add_item(item)
    table.insert(self.items, item)
    -- If it's a sub-menu, tell it who its parent is
    if item.is_menu then
        item.parent = self
    end
end

--- Recursively finds a config by name within this menu and sub-menus
-- @param name string
-- @return table|nil
function menu_container:find_config(name)
    for _, item in ipairs(self.items) do
        if not item.is_menu and item.name == name then
            return item
        elseif item.is_menu then
            local found = item:find_config(name)
            if found then return found end
        end
    end
    return nil
end

--- Simple debug print of the menu structure
-- @param depth number (indentation level)
function menu_container:dump(depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    
    print(indent .. "== " .. self.title .. " ==")
    
    for _, item in ipairs(self.items) do
        if item.is_menu then
            item:dump(depth + 1)
        else
            print(indent .. "  [ ] " .. item.name .. " (" .. item.datatype .. ")")
        end
    end
end

return menu_container