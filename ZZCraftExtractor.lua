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

local STATION_WORK =
{ [CRAFTING_TYPE_BLACKSMITHING] = true
, [CRAFTING_TYPE_CLOTHIER     ] = true
, [CRAFTING_TYPE_WOODWORKING  ] = true
}
function ZZCraftExtractor.OnStationInteract(event, station)
    local station_work = STATION_WORK[station]
    if not station_work then return end

    local llc = ZZCraftExtractor:GetLLC()
    local set_index = llc:GetCurrentSetInteractionIndex()
    d("Hello, Station! station:"..tostring(station).." set:"..tostring(set_index))
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


