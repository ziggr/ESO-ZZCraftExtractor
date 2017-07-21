-- ZZCraftExtractor: Is this Maaster Writ worth doing?
--
-- In a master writ's tooltip, include the material cost for that writ
-- as both a gold total, and a gold per writ voucher reward.

ZZCraftExtractor = {}

ZZCraftExtractor.name            = "ZZCraftExtractor"
ZZCraftExtractor.version         = "3.0.1"
ZZCraftExtractor.savedVarVersion = 1
ZZCraftExtractor.default = {

}

local WEAPON_TRAITS = {
    ITEM_TRAIT_TYPE_NONE
,   ITEM_TRAIT_TYPE_WEAPON_POWERED
,   ITEM_TRAIT_TYPE_WEAPON_CHARGED
,   ITEM_TRAIT_TYPE_WEAPON_PRECISE
,   ITEM_TRAIT_TYPE_WEAPON_INFUSED
,   ITEM_TRAIT_TYPE_WEAPON_DEFENDING
,   ITEM_TRAIT_TYPE_WEAPON_TRAINING
,   ITEM_TRAIT_TYPE_WEAPON_SHARPENED
,   ITEM_TRAIT_TYPE_WEAPON_DECISIVE     -- nee weighted
,   ITEM_TRAIT_TYPE_WEAPON_NIRNHONED
}
local ARMOR_TRAITS    = {
    ITEM_TRAIT_TYPE_NONE
,   ITEM_TRAIT_TYPE_ARMOR_STURDY
,   ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE
,   ITEM_TRAIT_TYPE_ARMOR_REINFORCED
,   ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED
,   ITEM_TRAIT_TYPE_ARMOR_TRAINING
,   ITEM_TRAIT_TYPE_ARMOR_INFUSED
,   ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS   -- nee exploration
,   ITEM_TRAIT_TYPE_ARMOR_DIVINES
,   ITEM_TRAIT_TYPE_ARMOR_NIRNHONED
}

local STATION_WORK = {
  [CRAFTING_TYPE_BLACKSMITHING] = {
    station_work = {
                     { pattern_index =  1, mat_ct = 3, traits = WEAPON_TRAITS } -- 1h axe
                   , { pattern_index =  2, mat_ct = 3, traits = WEAPON_TRAITS } -- 1h mace
                   , { pattern_index =  3, mat_ct = 3, traits = WEAPON_TRAITS } -- 1h sword
                   , { pattern_index =  4, mat_ct = 5, traits = WEAPON_TRAITS } -- 2h battleaxe
                   , { pattern_index =  6, mat_ct = 5, traits = WEAPON_TRAITS } -- 2h greatsword
                   , { pattern_index =  5, mat_ct = 5, traits = WEAPON_TRAITS } -- 2h maul
                   , { pattern_index =  7, mat_ct = 2, traits = WEAPON_TRAITS } -- dagger
                   , { pattern_index =  8, mat_ct = 7, traits = ARMOR_TRAITS  } -- heavy cuirass
                   , { pattern_index =  9, mat_ct = 5, traits = ARMOR_TRAITS  } -- heavy sabatons
                   , { pattern_index = 10, mat_ct = 5, traits = ARMOR_TRAITS  } -- heavy gauntlets
                   , { pattern_index = 11, mat_ct = 5, traits = ARMOR_TRAITS  } -- heavy helm
                   , { pattern_index = 12, mat_ct = 6, traits = ARMOR_TRAITS  } -- heavy greaves
                   , { pattern_index = 13, mat_ct = 5, traits = ARMOR_TRAITS  } -- heavy pauldron
                   , { pattern_index = 14, mat_ct = 5, traits = ARMOR_TRAITS  } -- heavy girdle
                   }
, set_bonus_pattern_offset = 14
}
, [CRAFTING_TYPE_CLOTHIER     ] = {
    station_work = {
                     { pattern_index =  1, mat_ct = 7, traits = ARMOR_TRAITS  } -- light robe
                   , { pattern_index =  2, mat_ct = 7, traits = ARMOR_TRAITS  } -- light jerkin
                   , { pattern_index =  3, mat_ct = 5, traits = ARMOR_TRAITS  } -- light shoes
                   , { pattern_index =  4, mat_ct = 5, traits = ARMOR_TRAITS  } -- light gloves
                   , { pattern_index =  5, mat_ct = 5, traits = ARMOR_TRAITS  } -- light hat
                   , { pattern_index =  6, mat_ct = 6, traits = ARMOR_TRAITS  } -- light breeches
                   , { pattern_index =  7, mat_ct = 5, traits = ARMOR_TRAITS  } -- light epaulets
                   , { pattern_index =  8, mat_ct = 5, traits = ARMOR_TRAITS  } -- light sash
                   , { pattern_index =  9, mat_ct = 7, traits = ARMOR_TRAITS  } -- medium jack
                   , { pattern_index = 10, mat_ct = 5, traits = ARMOR_TRAITS  } -- medium boots
                   , { pattern_index = 11, mat_ct = 5, traits = ARMOR_TRAITS  } -- medium bracers
                   , { pattern_index = 12, mat_ct = 5, traits = ARMOR_TRAITS  } -- medium helmet
                   , { pattern_index = 13, mat_ct = 6, traits = ARMOR_TRAITS  } -- medium guards
                   , { pattern_index = 14, mat_ct = 5, traits = ARMOR_TRAITS  } -- medium arm cops
                   , { pattern_index = 15, mat_ct = 5, traits = ARMOR_TRAITS  } -- medium belt
                   }
, set_bonus_pattern_offset = 15
}

, [CRAFTING_TYPE_WOODWORKING  ] = {
    station_work = {
                     { pattern_index =  1, mat_ct = 3, traits = WEAPON_TRAITS } -- bow
                   , { pattern_index =  3, mat_ct = 3, traits = WEAPON_TRAITS } -- inferno staff
                   , { pattern_index =  4, mat_ct = 3, traits = WEAPON_TRAITS } -- frost staff
                   , { pattern_index =  5, mat_ct = 3, traits = WEAPON_TRAITS } -- lightning staff
                   , { pattern_index =  6, mat_ct = 3, traits = WEAPON_TRAITS } -- healing staff
                   , { pattern_index =  2, mat_ct = 6, traits = ARMOR_TRAITS  } -- shield
                   }
, set_bonus_pattern_offset = 6
}
}


function ZZCraftExtractor.OnStationInteract(event, station)
    local self = ZZCraftExtractor
    local llc = self:GetLLC()
    local set_index = llc:GetCurrentSetInteractionIndex()
    d("Hello, Station! station:"..tostring(station).." set:"..tostring(set_index))

    local item_id_list = self:BuildItemIdList(station, set_index)
    if not item_id_list then
        d("nope")
        return
    end

    if not self.savedVariables.item_id then self.savedVariables.item_id = {} end
    local iid = self.savedVariables.item_id
    if not iid[set_index] then iid[set_index] = {} end
    iid[set_index][station] = item_id_list
    d("Done with station:"..tostring(station).." set:"..tostring(set_index) .. " got:"..tostring(#item_id_list))

                        -- Special case for Armor Master: also build
                        -- the non-set-bonus table when you visit an
                        -- Armor Master table, just because the BBC crafting
                        -- boardwalk lacks a plain table.
    if set_index == 27 then
        local item_id_list = self:BuildItemIdList(station, 0)
        if not iid["none"] then iid["none"] = {} end
        iid["none"][station] = item_id_list
        d("Done with station:none got:"..tostring(#item_id_list))
    end
end

function ZZCraftExtractor:BuildItemIdList(station, set_index)
    if not STATION_WORK[station] then
        d("no STATION_WORK["..tostring(station).."]")
        return nil
    end
    local station_work   = STATION_WORK[station].station_work
                        -- A plain "Iron Axe" is pattern_index=1, an "Axe of
                        -- the Armor Master" is pattern_index=1+14=15
    local pattern_offset = 0
    if 0 < set_index then
        pattern_offset = STATION_WORK[station].set_bonus_pattern_offset
    end
                        -- Traits and motifs must be offset by 1, dunno why.
    local trait_offset   = 1
    local motif_offset   = 1

    local item_id_list = {}
    local material_index = 1    -- iron/jute/maple
    local motif_id       = 1     -- Breton
    local link_style    = LINK_STYLE_DEFAULT

                        -- For each of the up to 15 different items
                        -- you can craft at this station, generate a single
                        -- tab-delimited
                        -- line with all of that item's itemId numbers,
                        -- one for each possible trait, starting with no trait.
                        -- Just to make the file easier to read, also append
                        -- the item's name.
    for i,sw in ipairs(station_work) do
        local pattern_index = sw.pattern_index
        local traits        = sw.traits
        local mat_ct        = sw.mat_ct
        local cells = {}
        local row_name = nil
        for ti, trait_index in ipairs(traits) do
            local item_link = GetSmithingPatternResultLink(
                    pattern_index + pattern_offset
                  , material_index
                  , mat_ct
                  , motif_id    + motif_offset
                  , trait_index + trait_offset
                  , link_style
                  )
-- if pattern_index == 4 then
-- d("GetSmithingPatternResultLink("
--   ..tostring(pattern_index + pattern_offset)..", "
--   ..tostring(material_index)..", "
--   ..tostring(mat_ct)..", "
--   ..tostring(motif_id    + motif_offset)..", "
--   ..tostring(trait_index + trait_offset)..", "
--   ..tostring(link_style)..
--     ")")
-- d(item_link)
-- end
            local item_id = GetItemIDFromLink(item_link)
            table.insert(cells, item_id)

                        -- Insert the first item's name as sort of
                        -- documentation within the saved data.
            if not row_name then
                row_name = GetItemLinkName(item_link)
            end
        end

        local fmt_cells = {}
        for _, c in ipairs(cells) do
            table.insert(fmt_cells, string.format("%7d", c))
        end
        table.insert(fmt_cells, row_name)
        local row_string = table.concat(fmt_cells, "\t")
        table.insert(item_id_list, row_string)
    end
    return item_id_list
end


function ZZCraftExtractor:GetLLC()
    if self.LibLazyCrafting then
        return self.LibLazyCrafting
    end


    local lib = LibStub:GetLibrary("LibLazyCrafting", 0.4)
    self.LibLazyCrafting = lib:AddRequestingAddon(
         ZZCraftExtractor.name           -- name
       , true                            -- autocraft
       , ZZCraftExtractor_LLCCompleted   -- functionCallback
       )

    return self.LibLazyCrafting
end

-- This function COULD become public in the LibLazyCrafting API, but today
-- it is not, so time for some copy-and-paste "editor inheritance".
function GetItemIDFromLink(itemLink) return tonumber(string.match(itemLink,"|H%d:item:(%d+)")) end

function ZZCraftExtractor_LLCCompleted()
    -- NOP never used
end


-- Init ----------------------------------------------------------------------

function ZZCraftExtractor.OnAddOnLoaded(event, addonName)
    if addonName ~= ZZCraftExtractor.name then return end
    if not ZZCraftExtractor.version then return end
    ZZCraftExtractor:Initialize()
end

function ZZCraftExtractor:Initialize()
                        -- Account-wide for most things
    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "ZZCraftExtractorVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )

    --EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end


-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( ZZCraftExtractor.name
                              , EVENT_ADD_ON_LOADED
                              , ZZCraftExtractor.OnAddOnLoaded
                              )

EVENT_MANAGER:RegisterForEvent( ZZCraftExtractor.name
                              , EVENT_CRAFTING_STATION_INTERACT
                              , ZZCraftExtractor.OnStationInteract
                              )


