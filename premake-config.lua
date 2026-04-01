local m = {}
local parser_module = nil
local formatter_module = nil
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
     if has_kconfig() then
            parser_module = require("kconfig_parser")
            local parser = parser_module.new("Kconfig");
            local success, tokens = parser:parse();
            print(success)
            if success then
                local formatter = require("kconfig_formatter").new(tokens)
                local app = formatter:format()
                app:save()
            end
        end
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

return m
