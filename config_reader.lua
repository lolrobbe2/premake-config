local ConfigReader = {}
ConfigReader.__index = ConfigReader

function ConfigReader.new()
    local self = setmetatable({}, ConfigReader)
    self.settings = {} 
    return self
end

function ConfigReader:load(filename)
    filename = filename or ".config"
    local file = io.open(filename, "r")
    if not file then return false, "File not found" end

    for line in file:lines() do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            -- 1. Handle Kconfig "is not set" (bool false)
            local unset_key = line:match("^# CONFIG_([^%s]+) is not set")
            if unset_key then
                self.settings[unset_key] = false
            
            -- 2. Handle standard CONFIG_KEY=VALUE
            elseif not line:match("^#") then
                local key, value = line:match("^CONFIG_([^=]+)=(.*)$")
                if key and value then
                    -- Clean quotes
                    value = value:gsub('^"', ''):gsub('"$', '')
                    
                    -- Cast types
                    if value == "y" then value = true
                    elseif value == "n" then value = false
                    elseif tonumber(value) then value = tonumber(value)
                    end
                    
                    self.settings[key] = value
                end
            end
        end
    end

    file:close()
    return true
end

--- Returns a flat table of all loaded settings
-- Example output: { SHADER_COMPILER = true, MAX_THREADS = 8 }
function ConfigReader:get_key_values()
    local kv_table = {}
    
    -- self.settings already stores them as ["KEY"] = value
    for key, value in pairs(self.settings) do
        kv_table[key] = value
    end
    
    return kv_table
end

function ConfigReader:get(key, default)
    if self.settings[key] ~= nil then
        return self.settings[key]
    end
    return default
end

return ConfigReader