local LibLazyCrafting = LibStub("LibLazyCrafting")
local sortCraftQueue = LibLazyCrafting.sortCraftQueue

local function dbug(...)
    if not DolgubonGlobalDebugOutput then return end
    DolgubonGlobalDebugOutput(...)
end

local function toRecipeLink(recipeId)
    return string.format("|H1:item:%s:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", tostring(recipeId))
end

local function LLC_CraftProvisioningItemByRecipeIndex(self, recipeListIndex, recipeIndex, timesToMake, autocraft, reference)
    table.insert(craftingQueue[self.addonName][CRAFTING_TYPE_PROVISIONING],
    {
        ["recipeListIndex"] = recipeListIndex,
        ["recipeIndex"] = recipeIndex,
        ["timestamp"] = GetTimeStamp(),
        ["autocraft"] = autocraft,
        ["Requester"] = self.addonName,
        ["reference"] = reference,
        ["station"] = CRAFTING_TYPE_PROVISIONING,
        ["timesToMake"] = timesToMake or 1
    }
    )

    sortCraftQueue()
    if GetCraftingInteractionType()==CRAFTING_TYPE_PROVISIONING then
        LibLazyCrafting.craftInteract(event, CRAFTING_TYPE_PROVISIONING)
    end
end

local function LLC_CraftProvisioningItemByRecipeId(self, recipeId, timesToMake, autocraft, reference)
    dbug('FUNCTION:LLCCraftProvisioning')
    if reference == nil then reference = "" end
    if not self then d("Please call with colon notation") end
    if autocraft==nil then autocraft = self.autocraft end
    if not recipeId then return end

    local recipeLink = toRecipeLink(recipeId)
    local recipeListIndex, recipeIndex = GetItemLinkGrantedRecipeIndices(recipeLink)
    if not (recipeListIndex and recipeIndex) then
        d("Unable to find recipeListIndex for recipeId:"..tostring(recipeId))
        return
    end
    LLC_CraftProvisioningItemByRecipeIndex(self, recipeListIndex, recipeIndex, timesToMake, autocraft, reference)
end

local function LLC_ProvisioningCraftInteraction(event, station)
    dbug("FUNCTION:LLCProvisioningCraft")
    local earliest, addon , position = LibLazyCrafting.findEarliestRequest(CRAFTING_TYPE_PROVISIONING)
    if (not earliest) or IsPerformingCraftProcess() then return end

    dbug("CALL:ZOProvisioningCraft")
    local recipeArgs = { earliest.recipeListIndex, earliest.recipeIndex }
    CraftProvisionerItem(unpack(recipeArgs))

    currentCraftAttempt = LibLazyCrafting.tableShallowCopy(earliest)
    currentCraftAttempt.callback = LibLazyCrafting.craftResultFunctions[addon]
    currentCraftAttempt.slot = nil
    currentCraftAttempt.link = GetRecipeResultItemLink(unpack(recipeArgs))
    currentCraftAttempt.position = position
    currentCraftAttempt.timestamp = GetTimeStamp()
    currentCraftAttempt.addon = addon
    currentCraftAttempt.prevSlots = LibLazyCrafting.findSlotsContaining(currentCraftAttempt.link)
end

local function LLC_ProvisioningCraftingComplete(event, station, lastCheck)
    LibLazyCrafting.stackableCraftingComplete(event, station, lastCheck, CRAFTING_TYPE_PROVISIONING, currentCraftAttempt)
end

LibLazyCrafting.craftInteractionTables[CRAFTING_TYPE_PROVISIONING] =
{
    ["check"] = function(station) return station == CRAFTING_TYPE_PROVISIONING end,
    ['function'] = LLC_ProvisioningCraftInteraction,
    ["complete"] = LLC_ProvisioningCraftingComplete,
    ["endInteraction"] = function(station) --[[endInteraction()]] end,
    ["isItemCraftable"] = function(station) if station == CRAFTING_TYPE_PROVISIONING then return true else return false end end,
}

LibLazyCrafting.functionTable.CraftProvisioningItemByRecipeId = LLC_CraftProvisioningItemByRecipeId
LibLazyCrafting.functionTable.CraftProvisioningItemByRecipeIndex = LLC_CraftProvisioningItemByRecipeIndex
