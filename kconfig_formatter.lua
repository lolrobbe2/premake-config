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

        local entry   = {
            raw_tokens = tokens,
            keyword    = keyword,
            value      = value,
            type       = "unknown"
        }

        -- Mapping Keywords to Semantic Types
        if keyword == "menu" or keyword == "mainmenu" or keyword == "choice" then
            -- 'choice' acts as a block header just like 'menu'
            entry.type = "header"
        elseif keyword == "config" or keyword == "menuconfig" then
            entry.type = "definition"
        elseif keyword == "bool" or keyword == "tristate" or keyword == "string" or keyword == "hex" or keyword == "int" then
            entry.type = "attribute_type"
        elseif keyword == "default" or keyword == "range" or keyword == "prompt" then
            -- 'prompt' is often used inside 'choice' blocks to give the enum a name
            entry.type = "attribute_value"
        elseif keyword == "depends" then
            entry.type = "dependency"
        elseif keyword == "select" then
            entry.type = "reverse_dependency"
        elseif keyword == "help" then
            entry.type = "help_text"
        elseif keyword == "endmenu" or keyword == "endif" or keyword == "endchoice" then
            -- 'endchoice' is the required closer for a 'choice' block
            entry.type = "closer"
        else
            entry.type = "text"
            entry.keyword = ""
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
    local in_choice_block = false  -- Track if we are inside a choice

    local MainMenu = require("/types/main_menu")
    local MenuContainer = require("/types/menu_container")
    local ConfigDef = require("/types/definition")

    for _, entry in ipairs(tree) do
        -- 1. Initialize Main Menu (Same as before)
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
            if entry.keyword == "mainmenu" then
                main_menu_entry.title = entry.value:gsub('"', '')
            elseif entry.keyword == "choice" then
                -- CREATE AN ENUM ITEM
                local enum_cfg = ConfigDef.new("CHOICE_BLOCK")
                enum_cfg.datatype = "enum"
                enum_cfg.choices = {} -- Initialize the options list
                
                current_scope:add_item(enum_cfg)
                main_menu_entry:register(enum_cfg)
                
                last_config = enum_cfg
                in_choice_block = true -- Sub-configs now belong to this enum
            else
                -- Standard Menu
                local sub = MenuContainer.new(entry.value:gsub('"', ''))
                current_scope:add_item(sub)
                current_scope = sub 
                in_choice_block = false
            end

        elseif entry.type == "closer" then
            -- Handle endchoice/endmenu/endif
            if entry.keyword == "endchoice" then
                in_choice_block = false
            elseif current_scope and current_scope.parent then
                current_scope = current_scope.parent
            end

        elseif entry.type == "definition" then
            if in_choice_block and last_config and last_config.datatype == "enum" then
                -- Inside a choice, 'config' entries are just strings for the choice list
                -- We don't create new ConfigDef objects, we add to the last_config.choices
                table.insert(last_config.choices, entry.value)
            else
                -- Standard Definition
                local cfg = ConfigDef.new(entry.value)
                current_scope:add_item(cfg)
                main_menu_entry:register(cfg)
                last_config = cfg
            end

        elseif entry.type == "attribute_type" and last_config then
            -- If it's a prompt inside a choice, it names the enum
            if entry.keyword == "bool" and in_choice_block then
                -- Choice sub-items are bools, but the parent is an enum
            else
                last_config:set_prompt(entry.value:gsub('"', ''), entry.keyword)
            end

        elseif entry.type == "attribute_value" and last_config then
            if entry.keyword == "prompt" then
                last_config.name = entry.value:gsub('"', '')
            elseif entry.keyword == "default" then
                last_config.default = entry.value:gsub('"', '')
                last_config.value = last_config.default
            end
        
        -- ... handle help text etc ...
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
