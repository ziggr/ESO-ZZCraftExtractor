-- Read the SavedVariables file that ZZCraftExtractor creates  and convert
-- that to a spreadsheet-compabitle CSV (comma-separated value) file.

IN_FILE_PATH  = "../../SavedVariables/ZZCraftExtractor.lua"
OUT_FILE_PATH = "./data/SetIndex.lua"
dofile(IN_FILE_PATH)
OUT_FILE = assert(io.open(OUT_FILE_PATH, "w"))


-- Lua lacks a split() function. Here's a cheesy one that works
-- for our specific need.
function split(str, delim)
    local l = {}
    local delim_index = 0
    while true do
        end_index = string.find(str, delim, delim_index + 1)
        if end_index == nil then
            local word = string.sub(str, delim_index + 1)
            table.insert(l, word)
            break
        end
        local word = string.sub(str, delim_index + 1, end_index - 1)
        table.insert(l, word)
        delim_index = end_index
    end
    return l
end

function enquote(s)
    return '"' .. s .. '"'
end

function tonum(s)
    if not s or s == "" or s == "nil" then return "" end
    local n = tonumber(s)
    if not n then return "" end
    return n
end

function tostr(s)
    if not s or s == "" or s == "nil" then return "" end
    return enquote(s)
end

function ltrim(s)
    return s:gsub("^ *", "")
end


function TableItemId(item_id_table)
    set_ct = 0
    sort_table = {}
    keys = {}
    for set_id, station_list in pairs(item_id_table) do
        set_ct = set_ct + 1
        for station_id, line_list in pairs(station_list) do
            pattern_index = 1 -- 1h axe, light robe, or bow
            line = line_list[pattern_index]
            cells = split(line, "\t")
            item_id = cells[1]
            if item_id and item_id ~= ""then
                if set_id == "none" then set_id = "1" end
                item_name = cells[#cells]
                s = string.format(", [%6d] = %2d -- %s\n"
                        , tonumber(item_id)
                        , tonumber(set_id)
                        , item_name
                        )
                k = string.format("%02d.%1d"
                        , tonumber(set_id)
                        , tonumber(station_id)
                        )
                sort_table[k] = s
                table.insert(keys, k)
            end
        end
    end
    table.sort(keys)
    for _,k in ipairs(keys) do
        OUT_FILE:write(sort_table[k])
    end
end

-- For each account
for k, v in pairs(ZZCraftExtractorVars["Default"]) do
    if (    ZZCraftExtractorVars["Default"][k]["$AccountWide"]
        and ZZCraftExtractorVars["Default"][k]["$AccountWide"]["item_id"]) then
        TableItemId(ZZCraftExtractorVars["Default"][k]["$AccountWide"]["item_id"])
    end
end
OUT_FILE:close()

