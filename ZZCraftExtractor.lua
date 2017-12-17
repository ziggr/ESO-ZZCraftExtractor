-- ZZCraftExtractor: Extract itemId values for every single craftable
--                   equipment item within the game.
--
-- When this add-on is loaded, each time you interact with a BS/CL/WW crafting
-- station, the add-on scans all ~14 items craftable at this station and
-- records the itemId numbers for each item, each trait, into a SavedVariables
-- file.
--
-- If you visit EVERY single crafting station in Tamriel (3 stations x ~40 set
-- bonuses), you'll have a complete list of every single craftable itemID.
--
-- Uses a couple library functions from LibLazyCrafter. Does not actually
-- craft anything with LibLazyCrafter.
--

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
if not set_index then
    d("No set_index")
    return
end

    -- d("Hello, Station! station:"..tostring(station)
    --   .." set:"..tostring(set_index))

    local item_id_list = self:BuildItemIdList(station, set_index)
    if not item_id_list then
        d("nope")
        return
    end

    if not self.savedVariables.item_id then self.savedVariables.item_id = {} end
    local iid = self.savedVariables.item_id
    if not iid[set_index] then iid[set_index] = {} end
    iid[set_index][station] = item_id_list
    d("Done with station:"..tostring(station)
        .." set:"..tostring(set_index)
        .." got:"..tostring(#item_id_list))

                        -- Special case for Armor Master: also build the non-
                        -- set-bonus table when you visit an Armor Master
                        -- table, just because the BBC crafting boardwalk lacks
                        -- a plain table.
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
    local motif_id       = 1    -- Breton
    local link_style    = LINK_STYLE_DEFAULT

                        -- For each of the up to 15 different items you can
                        -- craft at this station, generate a single tab-
                        -- delimited line. Line contains each of that item's
                        -- itemId numbers, one for each possible trait,
                        -- starting with no trait. Just to make the file easier
                        -- to read, line ends  with the item's name.
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
            table.insert(fmt_cells, string.format("%d", c))
        end
        table.insert(fmt_cells, row_name)
        local row_string = table.concat(fmt_cells, "\t")
        item_id_list[pattern_index] = row_string
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

function ZZCraftExtractor_LLCCompleted()
    -- NOP never used
end

-- This function COULD become public in the LibLazyCrafting API, but today
-- it is not, so time for some copy-and-paste "editor inheritance".
function GetItemIDFromLink(itemLink) return tonumber(string.match(itemLink,"|H%d:item:(%d+)")) end

-- API Proposal --------------------------------------------------------------

ZZCraftExtractor.TRAITS_WEAPON_TO_INDEX = {
    [ITEM_TRAIT_TYPE_WEAPON_POWERED    ] = 1
,   [ITEM_TRAIT_TYPE_WEAPON_CHARGED    ] = 2
,   [ITEM_TRAIT_TYPE_WEAPON_PRECISE    ] = 3
,   [ITEM_TRAIT_TYPE_WEAPON_INFUSED    ] = 4
,   [ITEM_TRAIT_TYPE_WEAPON_DEFENDING  ] = 5
,   [ITEM_TRAIT_TYPE_WEAPON_TRAINING   ] = 6
,   [ITEM_TRAIT_TYPE_WEAPON_SHARPENED  ] = 7
,   [ITEM_TRAIT_TYPE_WEAPON_DECISIVE   ] = 8   -- nee weighted
,   [ITEM_TRAIT_TYPE_WEAPON_NIRNHONED  ] = 9
}

ZZCraftExtractor.TRAITS_ARMOR_TO_INDEX    = {
    [ITEM_TRAIT_TYPE_ARMOR_STURDY      ] = 1
,   [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = 2
,   [ITEM_TRAIT_TYPE_ARMOR_REINFORCED  ] = 3
,   [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED ] = 4
,   [ITEM_TRAIT_TYPE_ARMOR_TRAINING    ] = 5
,   [ITEM_TRAIT_TYPE_ARMOR_INFUSED     ] = 6
,   [ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS  ] = 7  -- nee exploration
,   [ITEM_TRAIT_TYPE_ARMOR_DIVINES     ] = 8
,   [ITEM_TRAIT_TYPE_ARMOR_NIRNHONED   ] = 9
}

-- Expected values for pattern_index
ZZCraftExtractor.PATTERN_INDEX_1H_AXE           =  1
ZZCraftExtractor.PATTERN_INDEX_1H_MACE          =  2
ZZCraftExtractor.PATTERN_INDEX_1H_SWORD         =  3
ZZCraftExtractor.PATTERN_INDEX_2H_BATTLEAXE     =  4
ZZCraftExtractor.PATTERN_INDEX_2H_GREATSWORD    =  6
ZZCraftExtractor.PATTERN_INDEX_2H_MAUL          =  5
ZZCraftExtractor.PATTERN_INDEX_DAGGER           =  7

ZZCraftExtractor.PATTERN_INDEX_HEAVY_CUIRASS    =  8
ZZCraftExtractor.PATTERN_INDEX_HEAVY_SABATONS   =  9
ZZCraftExtractor.PATTERN_INDEX_HEAVY_GAUNTLETS  = 10
ZZCraftExtractor.PATTERN_INDEX_HEAVY_HELM       = 11
ZZCraftExtractor.PATTERN_INDEX_HEAVY_GREAVES    = 12
ZZCraftExtractor.PATTERN_INDEX_HEAVY_PAULDRON   = 13
ZZCraftExtractor.PATTERN_INDEX_HEAVY_GIRDLE     = 14

ZZCraftExtractor.PATTERN_INDEX_LIGHT_ROBE       =  1
ZZCraftExtractor.PATTERN_INDEX_LIGHT_JERKIN     =  2
ZZCraftExtractor.PATTERN_INDEX_LIGHT_SHOES      =  3
ZZCraftExtractor.PATTERN_INDEX_LIGHT_GLOVES     =  4
ZZCraftExtractor.PATTERN_INDEX_LIGHT_HAT        =  5
ZZCraftExtractor.PATTERN_INDEX_LIGHT_BREECHES   =  6
ZZCraftExtractor.PATTERN_INDEX_LIGHT_EPAULETS   =  7
ZZCraftExtractor.PATTERN_INDEX_LIGHT_SASH       =  8

ZZCraftExtractor.PATTERN_INDEX_MEDIUM_JACK      =  9
ZZCraftExtractor.PATTERN_INDEX_MEDIUM_BOOTS     = 10
ZZCraftExtractor.PATTERN_INDEX_MEDIUM_BRACERS   = 11
ZZCraftExtractor.PATTERN_INDEX_MEDIUM_HELMET    = 12
ZZCraftExtractor.PATTERN_INDEX_MEDIUM_GUARDS    = 13
ZZCraftExtractor.PATTERN_INDEX_MEDIUM_ARM_COPS  = 14
ZZCraftExtractor.PATTERN_INDEX_MEDIUM_BELT      = 15

ZZCraftExtractor.PATTERN_INDEX_BOW              =  1
ZZCraftExtractor.PATTERN_INDEX_INFERNO_STAFF    =  3
ZZCraftExtractor.PATTERN_INDEX_FROST_STAFF      =  4
ZZCraftExtractor.PATTERN_INDEX_LIGHTNING_STAFF  =  5
ZZCraftExtractor.PATTERN_INDEX_RESTO_STAFF      =  6

ZZCraftExtractor.PATTERN_INDEX_SHIELD           =  2

-- Expected values for set_index
ZZCraftExtractor.SET_INDEX_NONE                      =  1
ZZCraftExtractor.SET_INDEX_DEATHS_WIND               =  2
ZZCraftExtractor.SET_INDEX_NIGHTS_SILENCE            =  3
ZZCraftExtractor.SET_INDEX_ASHEN_GRIP                =  4
ZZCraftExtractor.SET_INDEX_TORUGS_PACT               =  5
ZZCraftExtractor.SET_INDEX_TWILIGHTS_EMBRACE         =  6
ZZCraftExtractor.SET_INDEX_ARMOR_OF_THE_SEDUCER      =  7
ZZCraftExtractor.SET_INDEX_MAGNUS_GIFT               =  8
ZZCraftExtractor.SET_INDEX_HIST_BARK                 =  9
ZZCraftExtractor.SET_INDEX_WHITESTRAKES_RETRIBUTION  = 10
ZZCraftExtractor.SET_INDEX_VAMPIRES_KISS             = 11
ZZCraftExtractor.SET_INDEX_SONG_OF_LAMAE             = 12
ZZCraftExtractor.SET_INDEX_ALESSIAS_BULWARK          = 13
ZZCraftExtractor.SET_INDEX_NIGHT_MOTHERS_GAZE        = 14
ZZCraftExtractor.SET_INDEX_WILLOWS_PATH              = 15
ZZCraftExtractor.SET_INDEX_HUNDINGS_RAGE             = 16
ZZCraftExtractor.SET_INDEX_KAGRENACS_HOPE            = 17
ZZCraftExtractor.SET_INDEX_ORGNUMS_SCALES            = 18
ZZCraftExtractor.SET_INDEX_EYES_OF_MARA              = 19
ZZCraftExtractor.SET_INDEX_SHALIDORS_CURSE           = 20
ZZCraftExtractor.SET_INDEX_OBLIVIONS_FOE             = 21
ZZCraftExtractor.SET_INDEX_SPECTRES_EYE              = 22
ZZCraftExtractor.SET_INDEX_WAY_OF_THE_ARENA          = 23
ZZCraftExtractor.SET_INDEX_TWICE_BORN_STAR           = 24
ZZCraftExtractor.SET_INDEX_NOBLES_CONQUEST           = 25
ZZCraftExtractor.SET_INDEX_REDISTRIBUTOR             = 26
ZZCraftExtractor.SET_INDEX_ARMOR_MASTER              = 27
ZZCraftExtractor.SET_INDEX_TRIAL_BY_FIRE             = 28
ZZCraftExtractor.SET_INDEX_LAW_OF_JULIANOS           = 29
ZZCraftExtractor.SET_INDEX_MORKULDIN                 = 30
ZZCraftExtractor.SET_INDEX_TAVAS_FAVOR               = 31
ZZCraftExtractor.SET_INDEX_CLEVER_ALCHEMIST          = 32
ZZCraftExtractor.SET_INDEX_ETERNAL_HUNT              = 33
ZZCraftExtractor.SET_INDEX_KVATCH_GLADIATOR          = 34
ZZCraftExtractor.SET_INDEX_VARENS_LEGACY             = 35
ZZCraftExtractor.SET_INDEX_PELINALS_APTITUDE         = 36
ZZCraftExtractor.SET_INDEX_ASSASSINS_GUILE           = 37
ZZCraftExtractor.SET_INDEX_SHACKLEBREAKER            = 38
ZZCraftExtractor.SET_INDEX_DAEDRIC_TRICKERY          = 39
ZZCraftExtractor.SET_INDEX_MECHANICAL_ACUITY         = 40
ZZCraftExtractor.SET_INDEX_INNATE_AXIOM              = 41
ZZCraftExtractor.SET_INDEX_FORTIFIED_BRASS           = 42

function ZZCraftExtractor.ReportError(s)
    d("ZZCraftExtractor:" .. s)
    return nil
end

-- Return the itemId of a craftable item.
--
-- crafting_type: one of CRAFTING_TYPE_BLACKSMITHING
--                       CRAFTING_TYPE_CLOTHIER
--                       CRAFTING_TYPE_WOODWORKING
--
-- set_index: nil/0/1 for no set bonus
--            2..39
--            one of SET_INDEX_XXX above
--
-- pattern_index: 1..15
--            one of PATTERN_INDEX_XXX above
--
-- trait_id:  nil/0 for no trait
--            one of ITEM_TRAIT_TYPE_XXX
--
function ZZCraftExtractor.ToItemId(crafting_type, set_index, pattern_index, trait_id)
    self = ZZCraftExtractor

                        -- Be pointlessly permissive in what we accept.
    local trait_index = 0
    if trait_id and trait_id > 0 then
        trait_index = self.TRAITS_WEAPON_TO_INDEX[trait_id]
        if not trait_index then
            trait_index = self.TRAITS_ARMOR_TO_INDEX[trait_id]
        end
        if not trait_index then trait_index = 0 end
    end

    local set_indexx = "none"
    if set_index and set_index > 2 then
        set_indexx = set_index
    end

    local item_id_table = self.savedVariables["item_id"]
    local set_to_stations = item_id_table[set_indexx]
    if not set_to_stations then
        return self.ReportError("unknown set_index:"..tostring(set_index))
    end

    local station_to_patterns = set_to_stations[crafting_type]
    if not station_to_patterns then
        return self.ReportError("unknown station:"..tostring(crafting_type)
                 .."  for set_index:"..tostring(set_index))
    end

    local row_string = station_to_patterns[pattern_index]
    if not row_string then
        return self.ReportError("unknown pattern_index:"..tostring(pattern_index)
                 .."  for station:"..tostring(crafting_type)
                 .."  set_index:"..tostring(set_index))
    end

    local cells = { zo_strsplit("\t", row_string) }
    local item_id_str = cells[trait_index + 1]
    return tonumber(item_id_str)
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


