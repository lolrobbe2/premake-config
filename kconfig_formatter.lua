---
-- KConfig premake5.
-- Copyright (c) 2026 Robbe Beernaert
---

local config_lang_formatter = {}
config_lang_formatter.__index = config_lang_formatter

function config_lang_formatter.new(tokenized_data)
    local self = setmetatable({}, config_lang_formatter)
    self.data = tokenized_data or {}
    self.classified_tree = {}
    return self
end

--- Classifies tokens into KConfig semantic types
-- @return table (List of classified objects)
function config_lang_formatter:classify()
    self.classified_tree = {}
    for _, tokens in ipairs(self.data) do
        local keyword = tokens[1]
        local value   = tokens[2] or ""

        local entry = {
            raw_tokens = tokens,
            keyword    = keyword,
            value      = value,
            type       = "unknown"
        }

        -- Mapping Keywords to Semantic Types
        if keyword == "menu" or keyword == "mainmenu" then
            entry.type = "header"
        elseif keyword == "config" or keyword == "menuconfig" then
            entry.type = "definition"
        elseif keyword == "bool" or keyword == "tristate" or keyword == "string" or keyword == "hex" or keyword == "int" then
            entry.type = "attribute_type"
        elseif keyword == "default" or keyword == "range" then
            entry.type = "attribute_value"
        elseif keyword == "depends" then -- Matches 'depends on'
            entry.type = "dependency"
        elseif keyword == "select" then
            entry.type = "reverse_dependency"
        elseif keyword == "help" then
            entry.type = "help_text"
        elseif keyword == "endmenu" or keyword == "endif" then
            entry.type = "closer"
        else
            entry.type = "text"
            entry.keyword = "";
            entry.value = table.concat(tokens, " ")
        end

        table.insert(self.classified_tree, entry)
    end

    return self.classified_tree
end

function config_lang_formatter:format()
    local tree = self:classify()

    local main_menu_entry = nil
    local current_scope = nil
    local last_config = nil

    local MainMenu = require("/types/main_menu")
    local MenuContainer = require("/types/menu_container")
    local ConfigDef = require("/types/definition")

    for _, entry in ipairs(tree) do
        
        -- 1. Initialize Main Menu on the first available opportunity
        -- We use 'mainmenu' if it exists, otherwise fallback to a generic title
        -- until a top-level 'menu' is found.
        if not main_menu_entry then
            local initial_title = "Project Configuration"
            if entry.keyword == "mainmenu" then
                initial_title = entry.value:gsub('"', '')
            end
            main_menu_entry = MainMenu.new(initial_title)
            current_scope = main_menu_entry.root
        end

        -- 2. Handle the Semantic Tree
        if entry.type == "header" then
            -- Update main title if we hit 'mainmenu', otherwise create sub-menu
            if entry.keyword == "mainmenu" then
                local t = entry.value:gsub('"', '')
                main_menu_entry.title = t
                main_menu_entry.root.title = t
            else
                local sub = MenuContainer.new(entry.value:gsub('"', ''))
                current_scope:add_item(sub)
                current_scope = sub -- Step into sub-menu
            end

        elseif entry.type == "closer" then
            -- Step out to parent menu
            if current_scope and current_scope.parent then
                current_scope = current_scope.parent
            end

        elseif entry.type == "definition" then
            -- Create a new config symbol
            local cfg = ConfigDef.new(entry.value)
            current_scope:add_item(cfg)
            
            -- Register globally for the .config saver
            main_menu_entry:register(cfg)
            last_config = cfg

        elseif entry.type == "attribute_type" and last_config then
            -- Assign type and prompt (stripping quotes)
            last_config:set_prompt(entry.value:gsub('"', ''), entry.keyword)

        elseif entry.type == "text" and last_config then
            -- This captures help text or multi-line descriptions
            last_config:append_help(entry.value)
            
        elseif entry.type == "attribute_value" and last_config then
            -- Handle 'default' or 'range'
            if entry.keyword == "default" then
                last_config.default = entry.value:gsub('"', '')
                -- Initialize the live value to the default
                last_config.value = last_config.default
            end
        end
    end

    return main_menu_entry
end

--- Formatted Dump for Debugging
function config_lang_formatter:dump_classification()
    print("\n--- Semantic Classification Dump ---")
    for i, entry in ipairs(self.classified_tree) do
        print(string.format("[%02d] TYPE: %-18s | KEY: %-10s | VAL: %s", 
            i, 
            entry.type:upper(), 
            entry.keyword, 
            entry.value))
    end
end

return config_lang_formatter