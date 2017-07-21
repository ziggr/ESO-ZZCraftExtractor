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
                     {  1, WEAPON_TRAITS } -- 1h axe
                   , {  2, WEAPON_TRAITS } -- 1h mace
                   , {  3, WEAPON_TRAITS } -- 1h sword
                   , {  4, WEAPON_TRAITS } -- 2h battleaxe
                   , {  6, WEAPON_TRAITS } -- 2h greatsword
                   , {  5, WEAPON_TRAITS } -- 2h maul
                   , {  7, WEAPON_TRAITS } -- dagger
                   , {  8, ARMOR_TRAITS  } -- heavy cuirass
                   , {  9, ARMOR_TRAITS  } -- heavy sabatons
                   , { 10, ARMOR_TRAITS  } -- heavy gauntlets
                   , { 11, ARMOR_TRAITS  } -- heavy hHelm
                   , { 12, ARMOR_TRAITS  } -- heavy greaves
                   , { 13, ARMOR_TRAITS  } -- heavy pauldron
                   , { 14, ARMOR_TRAITS  } -- heavy girdle
                   }
, set_bonus_pattern_offset = 14
}
, [CRAFTING_TYPE_CLOTHIER     ] = {
    station_work = {
                     {  1, ARMOR_TRAITS  } -- light robe
                   , {  2, ARMOR_TRAITS  } -- light jerkin
                   , {  3, ARMOR_TRAITS  } -- light shoes
                   , {  4, ARMOR_TRAITS  } -- light gloves
                   , {  5, ARMOR_TRAITS  } -- light hat
                   , {  6, ARMOR_TRAITS  } -- light breeches
                   , {  7, ARMOR_TRAITS  } -- light epaulets
                   , {  8, ARMOR_TRAITS  } -- light sash
                   , {  9, ARMOR_TRAITS  } -- medium jack
                   , { 10, ARMOR_TRAITS  } -- medium boots
                   , { 11, ARMOR_TRAITS  } -- medium bracers
                   , { 12, ARMOR_TRAITS  } -- medium helmet
                   , { 13, ARMOR_TRAITS  } -- medium guards
                   , { 14, ARMOR_TRAITS  } -- medium arm cops
                   , { 15, ARMOR_TRAITS  } -- medium belt
                   }
, set_bonus_pattern_offset = 15
}

, [CRAFTING_TYPE_WOODWORKING  ] = {
    station_work = {
                     {  1, WEAPON_TRAITS } -- bow
                   , {  3, WEAPON_TRAITS } -- inferno staff
                   , {  4, WEAPON_TRAITS } -- frost staff
                   , {  5, WEAPON_TRAITS } -- lightning staff
                   , {  6, WEAPON_TRAITS } -- healing staff
                   , {  2, ARMOR_TRAITS  } -- shield
                   }
, set_bonus_pattern_offset = 6
}
}


function ZZCraftExtractor.OnStationInteract(event, station)
    local self = ZZCraftExtractor
    local llc = self:GetLLC()
    local set_index = llc:GetCurrentSetInteractionIndex()
    d("Hello, Station! station:"..tostring(station).." set:"..tostring(set_index))

    local item_id_list = self:BuildItemIdList(station)
    if not item_id_list then
        d("nope")
        return
    end

    if not self.savedVariables.item_id then self.savedVariables.item_id = {} end
    local iid = self.savedVariables.item_id
    if not iid[set_index] then iid[set_index] = {} end
    iid[set_index][station] = item_id_list
    d("Done with station:"..tostring(station).." set:"..tostring(set_index) .. " got:"..tostring(#item_id_list))
end

function ZZCraftExtractor:BuildItemIdList(station)
    if not STATION_WORK[station] then
        d("no STATION_WORK["..tostring(station).."]")
        return nil
    end
    local station_work   = STATION_WORK[station].station_work
                        -- A plain "Iron Axe" is pattern_index=1, an "Axe of
                        -- the Armor Master" is pattern_index=1+14=15
    local pattern_offset = STATION_WORK[station].set_bonus_pattern_offset
                        -- Traits and motifs must be offset by 1, dunno why.
    local trait_offset   = 1
    local motif_offset   = 1

    local item_id_list = {}
    local material_index = 1    -- iron/jute/maple
    local motif_id       = 1     -- Breton
    local link_style    = LINK_STYLE_DEFAULT
    local list_name     = nil

    for i,sw in ipairs(station_work) do
        local pattern_index = sw[1]
        local traits        = sw[2]
        local material_ct   = 3     -- 3 for level 1 weapons
        if traits == ARMOR_TRAITS then
            material_ct = 7         -- 7 for level 1 armor
        end

        for ti, trait_index in ipairs(traits) do
            local item_link = GetSmithingPatternResultLink(
                    pattern_index + pattern_offset
                  , material_index
                  , material_ct
                  , motif_id    + motif_offset
                  , trait_index + trait_offset
                  , link_style
                  )
-- d("GetSmithingPatternResultLink("
--   ..tostring(pattern_index + pattern_offset)..", "
--   ..tostring(material_index)..", "
--   ..tostring(material_ct)..", "
--   ..tostring(motif_id + motif_offset)..", "
--   ..tostring(trait_index + trait_offset)..", "
--   ..tostring(link_style)..
--     ")")
d(item_link)
            local item_id = GetItemIDFromLink(item_link)
            table.insert(item_id_list, item_id)

                        -- Insert the first item's name as sort of
                        -- documentation within the saved data.
            if not list_name then
                list_name = GetItemLinkName(item_link)
                item_id_list.name = list_name
d(list_name)
            end
        end
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


