---
-- KConfig premake5.
-- Copyright (c) 2026 Robbe Beernaert
---

local config_lang_parser = {}
config_lang_parser.__index = config_lang_parser

-- Constructor: Initialize with a file path or string buffer
function config_lang_parser.new(source_path)
    local self = setmetatable({}, config_lang_parser)
    self.source_path = source_path
    self.config_tree = {} -- Stores the hierarchical structure (menus, configs)
    self.symbols = {}     -- Flat lookup for CONFIG_ values
    return self
end

-- Loads the file into memory
function config_lang_parser:load()
    if not self.source_path then
        return nil, "No source path provided"
    end

    local f, err = io.open(self.source_path, "r")
    if not f then
        return nil, "Could not open file: " .. err
    end

    local content = f:read("*all")
    f:close()
    return content
end

--- Cleans a block of text line-by-line
-- @param content string (The raw file content)
-- @return string (The cleaned content)
function config_lang_parser:clean(content)
    if not content then return "" end
    
    local clean_lines = {}
    
    -- Iterate through each line in the content string
    for line in content:gmatch("([^\r\n]*)") do
        -- Strip leading and trailing whitespace/tabs
        local cleaned = line:match("^%s*(.-)%s*$")
        
        -- Only add to our table if it's not an empty string or a comment
        if cleaned and cleaned ~= "" and not cleaned:find("^#") then
            table.insert(clean_lines, cleaned)
        end
    end
    
    -- Join the table back into a single string separated by newlines
    return table.concat(clean_lines, "\n")
end

--- Converts raw content into a table of tokenized lines
-- Each line becomes a sub-table of words/tokens.
-- @param cleaned_content string
-- @return table
function config_lang_parser:tokenize(cleaned_content)
    if not cleaned_content then print("Error: could not tokenize") return {} end


    local tokenized_data = {}

    -- Iterate through the already cleaned lines
    for line in cleaned_content:gmatch("([^\r\n]+)") do
        local line_tokens = {}
        
        -- Pattern: 
        -- ^(%S+)     -> Capture the first non-space sequence (the keyword)
        -- %s+        -> Match the space(s) in between
        -- (.*)$      -> Capture everything else until the end of the line
        local keyword, rest = line:match("^(%S+)%s+(.*)$")
        
        if keyword and rest then
            table.insert(line_tokens, keyword)
            table.insert(line_tokens, rest)
        else
            -- If there is no space (like the word 'endmenu'), 
            -- just insert the whole line as one token.
            table.insert(line_tokens, line)
        end
        
        if #line_tokens > 0 then
            table.insert(tokenized_data, line_tokens)
        end
    end
    
    return tokenized_data
end

function config_lang_parser:parse()
    local content, err = self:load()
    if not content then 
        print("Error: " .. err)
        return false 
    end

    print("KConfig: Parsing " .. self.source_path)
    -- Transform raw content into clean contentn (NO front tabs/spaces)
    local clean_content = self:clean(content)
    local tokens = self:tokenize(clean_content)
    return true, tokens;
end

function config_lang_parser:token_dump()
    local err, tokens = self:parse()
    
    print("--- Starting Token Dump ---")
    
    -- Iterate through each line in the tokenized table
    for line_idx, line_tokens in ipairs(tokens) do
        local line_output = "Line " .. line_idx .. ": "
        
        -- Iterate through each individual token in this specific line
        for token_idx, token_val in ipairs(line_tokens) do
            -- We wrap in brackets to clearly see where a token starts/ends
            line_output = line_output .. "[" .. token_val .. "] "
        end
        
        print(line_output)
    end

    print("--- End of Token Dump ---")
  
end

return config_lang_parser;