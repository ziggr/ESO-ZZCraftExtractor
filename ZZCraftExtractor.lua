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


