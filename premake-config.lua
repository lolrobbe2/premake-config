local m = {}
local parser_module = nil
local formatter_module = nil
local ConfigReader = nil
newaction {
    trigger     = "kconfig",
    description = "Open the interactive configuration menu",
    execute     = function()
        -- 2. Once the user saves and exits, force a project regeneration
        if has_kconfig() then
            parser_module = require("kconfig_parser")
            local parser = parser_module.new("Kconfig");
            local success, tokens = parser:parse();
            print(success)
            if success then
                local formatter = require("kconfig_formatter").new(tokens)
                local app = formatter:format()

                -- Prepare the Bare Metal UI
                local renderer = require("UI.view").new()

                -- Start the engine
                app:run(renderer)

                print("Configuration complete.")
            end
        end
    end
}

newaction {
    trigger     = "configure",
    description = "generate default configuration",
    execute     = function()
        -- 2. Once the user saves and exits, force a project regeneration
        configure()
    end
}

---checks for Kconfig file in root
---@return boolean
function has_kconfig()
    if not os.isfile("Kconfig") then
        print("Error: No 'Kconfig' file found in the root directory.")
        print("Please ensure your project has a Kconfig definition file.")
        return false
    end
    return true
end

function configure()
    if has_kconfig() then
        parser_module = require("kconfig_parser")
        local parser = parser_module.new("Kconfig");
        local success, tokens = parser:parse();
        if success then
            local formatter = require("kconfig_formatter").new(tokens)
            local app = formatter:format()
            app:save()
        end
    end
end

function set_configuration_global()
    local ConfigReader = require("config_reader")
    local reader = ConfigReader.new()

    -- Try to load existing config
    if reader:load(".config") then
        _G.configuration = reader:get_key_values()
    else
        -- If no config, generate defaults
        print("No .config found. Generating defaults...")
        configure() 
        
        -- Try loading again after generation
        if reader:load(".config") then
            _G.configuration = reader:get_key_values()
        else
            -- Last resort fallback to prevent dump crash
            _G.configuration = {} 
        end
    end
end

set_configuration_global()

return m
