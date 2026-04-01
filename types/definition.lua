---
-- KConfig premake5.
-- Copyright (c) 2026 Robbe Beernaert
---

local config_definition = {}
config_definition.__index = config_definition

--- Constructor
-- @param name string (e.g., "ENABLE_VULKAN")
function config_definition.new(name)
    local self = setmetatable({}, config_definition)
    
    self.name = name           -- The CONFIG_ symbol name
    self.label = ""            -- The human-readable prompt string
    self.datatype = "unknown"  -- bool, tristate, string, int, hex
    self.default = nil         -- The default value
    self.help = ""             -- Help text description
    self.value = nil           -- The current active value
    self.dependencies = {}     -- List of "depends on" symbols
    
    return self
end

--- Sets the prompt label (e.g. bool "Enable Feature")
-- @param label string
-- @param datatype string
function config_definition:set_prompt(label, datatype)
    self.label = label
    self.datatype = datatype
end

--- Appends a line of help text
-- @param text string
function config_definition:append_help(text)
    if self.help == "" then
        self.help = text
    else
        self.help = self.help .. "\n" .. text
    end
end

--- Returns the value formatted for a .config file or C header
-- @return string
function config_definition:serialize()
    if self.datatype == "bool" then
        return self.name .. "=" .. (self.value and "y" or "n")
    elseif self.datatype == "string" then
        return self.name .. '="' .. tostring(self.value) .. '"'
    end
    return self.name .. "=" .. tostring(self.value)
end

return config_definition