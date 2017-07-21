-- Read the SavedVariables file that ZZCraftExtractor creates  and convert
-- that to a spreadsheet-compabitle CSV (comma-separated value) file.

IN_FILE_PATH  = "../../SavedVariables/ZZCraftExtractor.lua"
OUT_FILE_PATH = "../../SavedVariables/ZZCraftExtractor.csv"
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
    for set_id, station_list in pairs(item_id_table) do
        set_ct = set_ct + 1
        for station_id, line_list in pairs(station_list) do
            for _, line in ipairs(line_list) do
                OUT_FILE:write(tostring(set_id)..","..tostring(station_id)..",")
                cells = split(line, "\t")
                for i = 1, (#cells - 1) do
                    c = ltrim(cells[i])
                    OUT_FILE:write(c..",")
                end
                OUT_FILE:write(enquote(cells[#cells]))
                OUT_FILE:write("\n")
            end
        end
    end
    print("set_ct:"..tostring(set_ct))
end

OUT_FILE:write('"#set","station","no trait","powered","charged","precise","infused","defending","training","sharpened","decisive","nirnhoned","item name"\n')
OUT_FILE:write('"#","","","sturdy","impenetrable","reinforced","well-fitted","training","infused","prosperous","divines","nirnhoned",""\n')
-- For each account
for k, v in pairs(ZZCraftExtractorVars["Default"]) do
    if (    ZZCraftExtractorVars["Default"][k]["$AccountWide"]
        and ZZCraftExtractorVars["Default"][k]["$AccountWide"]["item_id"]) then
        TableItemId(ZZCraftExtractorVars["Default"][k]["$AccountWide"]["item_id"])
    end
end
OUT_FILE:close()

