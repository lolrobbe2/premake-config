local m = {}
local parser_module = nil
local formatter_module = nil
newaction {
    trigger     = "kconfig",
    description = "Open the interactive configuration menu",
    execute     = function()
        -- 2. Once the user saves and exits, force a project regeneration
        if  has_kconfig() then
            parser_module = require("kconfig_parser")
            local parser = parser_module.new("Kconfig");
            local  success, tokens = parser:parse();
            print(success)
            if success then
                --we can init formatter_module$
                formatter_module = require("kconfig_formatter")
                local formatter = formatter_module.new(tokens)
                local app = formatter:format()
                app.root:dump()
            end
        end
    end
}

newaction {
    trigger     = "kconfig-dump",
    description = "Dump the parser debug info",
    execute     = function()
        -- 2. Once the user saves and exits, force a project regeneration
        if  has_kconfig() then
            parser_module = require("kconfig_parser")
            local parser = parser_module.new("Kconfig");
            parser:token_dump();
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
