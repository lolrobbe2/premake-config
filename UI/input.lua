---
-- KConfig premake5 - Cross-Platform Input & Terminal Control
-- Copyright (c) 2026 Robbe Beernaert
---

local input = {}

-- Detect Platform once
local is_windows = (package.config:sub(1,1) == "\\")
local cached_width = nil

--- Queries the OS for the current terminal width
-- @return number
function input.get_width()
    if cached_width then return cached_width end

    local width = 80 -- Default fallback
    local handle

    if is_windows then
        -- PowerShell query for window width
        handle = io.popen('powershell -Command "$Host.UI.RawUI.WindowSize.Width"')
    else
        -- Unix standard command
        handle = io.popen('tput cols 2>/dev/null')
    end

    if handle then
        local result = handle:read("*a")
        handle:close()
        width = tonumber(result:match("%d+")) or 80
    end

    cached_width = width
    return width
end

--- Forces a re-query of the width (call this if you detect a window resize)
function input.refresh_width()
    cached_width = nil
    return input.get_width()
end

function input.clear()
    io.write("\27[H")
    io.flush()
end

function input.full_clear()
    io.write("\27[2J\27[H")
    io.flush()
end

function input.get_char()
    local char = ""
   if is_windows then
        -- Updated PS command to handle all 4 arrows + Escape
        local cmd = 'powershell -Command "$st=[Console]::ReadKey($true); ' ..
                    'if($st.Key -eq \'UpArrow\'){write-host \'up\'} ' ..
                    'elseif($st.Key -eq \'DownArrow\'){write-host \'down\'} ' ..
                    'elseif($st.Key -eq \'LeftArrow\'){write-host \'left\'} ' ..
                    'elseif($st.Key -eq \'RightArrow\'){write-host \'right\'} ' ..
                    'elseif($st.Key -eq \'Escape\'){write-host \'esc\'} ' ..
                    'else {write-host $st.KeyChar}"'
        local handle = io.popen(cmd)
        char = (handle:read("*a") or ""):gsub("%s+", "")
        handle:close()
    else
        os.execute("stty -icanon min 1 -echo")
        char = io.read(1)
        if char == "\27" then
            local n1 = io.read(1)
            local n2 = io.read(1)
            char = char .. n1 .. n2
        end
        os.execute("stty cooked echo")
    end
    return char:lower()
end
function input.detect_layout()
    input.full_clear()
    print("Keyboard Calibration")
    print("--------------------")
    print("Press the 'A' key on your keyboard:")
    
    local char = input.get_char()
    
    -- On QWERTY, 'A' is 'a'
    -- On AZERTY, 'A' is 'q' (The physical 'A' key sends 'q')
    -- On some layouts, it might be different, but this covers the main two.
    
    if char == "q" then
        return "AZERTY"
    else
        return "QWERTY"
    end
end
return input