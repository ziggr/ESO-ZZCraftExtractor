LibCraftId = {}

-- Return the itemId of a craftable item.
--
-- crafting_type: one of CRAFTING_TYPE_BLACKSMITHING
--                       CRAFTING_TYPE_CLOTHIER
--                       CRAFTING_TYPE_WOODWORKING
--
-- set_index: nil/0/1 for no set bonus
--            2..39
--            one of SET_INDEX_XXX below
--
-- pattern_index: 1..15
--            one of PATTERN_INDEX_XXX below
--
-- trait_id:  nil/0 for no trait
--            one of ITEM_TRAIT_TYPE_XXX
--
function LibCraftId.ToItemId(crafting_type, set_index, pattern_index, trait_id)
    self = LibCraftId

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
        return self.Report("unknown set_index:"..tostring(set_index))
    end

    local station_to_patterns = set_to_stations[crafting_type]
    if not station_to_patterns then
        return self.Report("unknown station:"..tostring(crafting_type)
                 .."  for set_index:"..tostring(set_index))
    end

    local row_string = station_to_patterns[pattern_index]
    if not row_string then
        return self.Report("unknown pattern_index:"..tostring(pattern_index)
                 .."  for station:"..tostring(crafting_type)
                 .."  set_index:"..tostring(set_index))
    end

    local cells = { zo_strsplit("\t", row_string) }
    local item_id_str = cells[trait_index + 1]
    return tonumber(item_id_str)
end


-- Convert an itemId to the same four parameters as ToItemId():
--
-- { set_index
-- , crafting_type
-- , pattern_index
-- , trait_id
-- }
function LibCraftId.FromItemId(item_id)
                        -- Inflate lookup table if necessary, NOP if not.
    local self = LibCraftId
    local tuples = self.UnpackTable()
    return tuples[item_id]
end

-- Internal function to report bad input or surprise bugs or status.
function LibCraftId.Report(s)
    d("LibCraftId:" .. s)
    return nil
end

-- First time FromItemId() needs to look up an itemId, inpack 200KB of
-- tables into itemId --> tuple
function LibCraftId.UnpackTable()
    self = LibCraftId
    if self.TUPLE then return self.TUPLE end
    self.Report("Building tables...")

                        -- Reverse the Trait/index tables.
    for trait_id, trait_index in pairs(self.TRAITS_WEAPON_TO_INDEX) do
        self.TRAITS_INDEX_TO_WEAPON[trait_index] = trait_id
    end
    for trait_id, trait_index in pairs(self.TRAITS_ARMOR_TO_INDEX) do
        self.TRAITS_INDEX_TO_ARMOR[trait_index] = trait_id
    end

                        -- Build GIANT table of item_id => tuple
    local tuples = {}
    for si, s in pairs(self.ITEM_ID) do
        local set_index = si
        if set_index == "none" or set_index < 2 then
            set_index = nil
        end
        for crafting_type, ctdata in pairs(s) do
            for pattern_index, row_string in pairs(ctdata) do
                cells = { zo_strsplit("\t", row_string) }
                for i = 1,#cells - 1 do
                    local item_id  = tonumber(cells[i])
    -- d("i:"..tostring(i).."  cell:"
    --     ..tostring(cells[i]).." item_id:"
    --     ..tostring(item_id).." row_string:"
    --     ..tostring(row_string))
                    local trait_index = i - 1
                    local trait_id = nil
                    if 0 < trait_index then
                        trait_id = self.TRAITS[crafting_type][pattern_index][trait_index]
                    end
                    tuple = { set_index     = set_index
                            , crafting_type = crafting_type
                            , pattern_index = pattern_index
                            , trait_id      = trait_id
                            }
                    tuples[item_id] = tuple
                end
            end
        end
    end
    self.TUPLE = tuples
    return self.TUPLE
end

-- Constants expected by ToItemId() and returned by FromItemId() -------------

LibCraftId.TRAITS_WEAPON_TO_INDEX = {
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
LibCraftId.TRAITS_ARMOR_TO_INDEX    = {
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
LibCraftId.TRAITS_INDEX_TO_WEAPON = {}
LibCraftId.TRAITS_INDEX_TO_ARMOR  = {}

-- Expected values for pattern_index
LibCraftId.PATTERN_INDEX_1H_AXE           =  1
LibCraftId.PATTERN_INDEX_1H_MACE          =  2
LibCraftId.PATTERN_INDEX_1H_SWORD         =  3
LibCraftId.PATTERN_INDEX_2H_BATTLEAXE     =  4
LibCraftId.PATTERN_INDEX_2H_GREATSWORD    =  6
LibCraftId.PATTERN_INDEX_2H_MAUL          =  5
LibCraftId.PATTERN_INDEX_DAGGER           =  7

LibCraftId.PATTERN_INDEX_HEAVY_CUIRASS    =  8
LibCraftId.PATTERN_INDEX_HEAVY_SABATONS   =  9
LibCraftId.PATTERN_INDEX_HEAVY_GAUNTLETS  = 10
LibCraftId.PATTERN_INDEX_HEAVY_HELM       = 11
LibCraftId.PATTERN_INDEX_HEAVY_GREAVES    = 12
LibCraftId.PATTERN_INDEX_HEAVY_PAULDRON   = 13
LibCraftId.PATTERN_INDEX_HEAVY_GIRDLE     = 14

LibCraftId.PATTERN_INDEX_LIGHT_ROBE       =  1
LibCraftId.PATTERN_INDEX_LIGHT_JERKIN     =  2
LibCraftId.PATTERN_INDEX_LIGHT_SHOES      =  3
LibCraftId.PATTERN_INDEX_LIGHT_GLOVES     =  4
LibCraftId.PATTERN_INDEX_LIGHT_HAT        =  5
LibCraftId.PATTERN_INDEX_LIGHT_BREECHES   =  6
LibCraftId.PATTERN_INDEX_LIGHT_EPAULETS   =  7
LibCraftId.PATTERN_INDEX_LIGHT_SASH       =  8

LibCraftId.PATTERN_INDEX_MEDIUM_JACK      =  9
LibCraftId.PATTERN_INDEX_MEDIUM_BOOTS     = 10
LibCraftId.PATTERN_INDEX_MEDIUM_BRACERS   = 11
LibCraftId.PATTERN_INDEX_MEDIUM_HELMET    = 12
LibCraftId.PATTERN_INDEX_MEDIUM_GUARDS    = 13
LibCraftId.PATTERN_INDEX_MEDIUM_ARM_COPS  = 14
LibCraftId.PATTERN_INDEX_MEDIUM_BELT      = 15

LibCraftId.PATTERN_INDEX_BOW              =  1
LibCraftId.PATTERN_INDEX_INFERNO_STAFF    =  3
LibCraftId.PATTERN_INDEX_FROST_STAFF      =  4
LibCraftId.PATTERN_INDEX_LIGHTNING_STAFF  =  5
LibCraftId.PATTERN_INDEX_RESTO_STAFF      =  6

LibCraftId.PATTERN_INDEX_SHIELD           =  2

-- Expected values for set_index
LibCraftId.SET_INDEX_NONE                      =  1
LibCraftId.SET_INDEX_DEATHS_WIND               =  2
LibCraftId.SET_INDEX_NIGHTS_SILENCE            =  3
LibCraftId.SET_INDEX_ASHEN_GRIP                =  4
LibCraftId.SET_INDEX_TORUGS_PACT               =  5
LibCraftId.SET_INDEX_TWILIGHTS_EMBRACE         =  6
LibCraftId.SET_INDEX_ARMOR_OF_THE_SEDUCER      =  7
LibCraftId.SET_INDEX_MAGNUS_GIFT               =  8
LibCraftId.SET_INDEX_HIST_BARK                 =  9
LibCraftId.SET_INDEX_WHITESTRAKES_RETRIBUTION  = 10
LibCraftId.SET_INDEX_VAMPIRES_KISS             = 11
LibCraftId.SET_INDEX_SONG_OF_LAMAE             = 12
LibCraftId.SET_INDEX_ALESSIAS_BULWARK          = 13
LibCraftId.SET_INDEX_NIGHT_MOTHERS_GAZE        = 14
LibCraftId.SET_INDEX_WILLOWS_PATH              = 15
LibCraftId.SET_INDEX_HUNDINGS_RAGE             = 16
LibCraftId.SET_INDEX_KAGRENACS_HOPE            = 17
LibCraftId.SET_INDEX_ORGNUMS_SCALES            = 18
LibCraftId.SET_INDEX_EYES_OF_MARA              = 19
LibCraftId.SET_INDEX_SHALIDORS_CURSE           = 20
LibCraftId.SET_INDEX_OBLIVIONS_FOE             = 21
LibCraftId.SET_INDEX_SPECTRES_EYE              = 22
LibCraftId.SET_INDEX_WAY_OF_THE_ARENA          = 23
LibCraftId.SET_INDEX_TWICE_BORN_STAR           = 24
LibCraftId.SET_INDEX_NOBLES_CONQUEST           = 25
LibCraftId.SET_INDEX_REDISTRIBUTOR             = 26
LibCraftId.SET_INDEX_ARMOR_MASTER              = 27
LibCraftId.SET_INDEX_TRIAL_BY_FIRE             = 28
LibCraftId.SET_INDEX_LAW_OF_JULIANOS           = 29
LibCraftId.SET_INDEX_MORKULDIN                 = 30
LibCraftId.SET_INDEX_TAVAS_FAVOR               = 31
LibCraftId.SET_INDEX_CLEVER_ALCHEMIST          = 32
LibCraftId.SET_INDEX_ETERNAL_HUNT              = 33
LibCraftId.SET_INDEX_KVATCH_GLADIATOR          = 34
LibCraftId.SET_INDEX_VARENS_LEGACY             = 35
LibCraftId.SET_INDEX_PELINALS_APTITUDE         = 36
LibCraftId.SET_INDEX_ASSASSINS_GUILE           = 37
LibCraftId.SET_INDEX_SHACKLEBREAKER            = 38
LibCraftId.SET_INDEX_DAEDRIC_TRICKERY          = 39
LibCraftId.SET_INDEX_MECHANICAL_ACUITY         = 40
LibCraftId.SET_INDEX_INNATE_AXIOM              = 41
LibCraftId.SET_INDEX_FORTIFIED_BRASS           = 42


-- Internal table of which trait set to use in FromItemId()
LibCraftId.TRAITS =
{
    [CRAFTING_TYPE_BLACKSMITHING] = {
        [LibCraftId.PATTERN_INDEX_1H_AXE          ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_1H_MACE         ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_1H_SWORD        ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_2H_BATTLEAXE    ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_2H_GREATSWORD   ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_2H_MAUL         ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_DAGGER          ] = LibCraftId.TRAITS_INDEX_TO_WEAPON

    ,   [LibCraftId.PATTERN_INDEX_HEAVY_CUIRASS   ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_HEAVY_SABATONS  ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_HEAVY_GAUNTLETS ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_HEAVY_HELM      ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_HEAVY_GREAVES   ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_HEAVY_PAULDRON  ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_HEAVY_GIRDLE    ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    }
,   [CRAFTING_TYPE_CLOTHIER] = {
        [LibCraftId.PATTERN_INDEX_LIGHT_ROBE      ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_LIGHT_JERKIN    ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_LIGHT_SHOES     ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_LIGHT_GLOVES    ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_LIGHT_HAT       ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_LIGHT_BREECHES  ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_LIGHT_EPAULETS  ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_LIGHT_SASH      ] = LibCraftId.TRAITS_INDEX_TO_ARMOR

    ,   [LibCraftId.PATTERN_INDEX_MEDIUM_JACK     ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_MEDIUM_BOOTS    ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_MEDIUM_BRACERS  ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_MEDIUM_HELMET   ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_MEDIUM_GUARDS   ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_MEDIUM_ARM_COPS ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    ,   [LibCraftId.PATTERN_INDEX_MEDIUM_BELT     ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    }
,   [CRAFTING_TYPE_WOODWORKING] = {
        [LibCraftId.PATTERN_INDEX_BOW             ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_INFERNO_STAFF   ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_FROST_STAFF     ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_LIGHTNING_STAFF ] = LibCraftId.TRAITS_INDEX_TO_WEAPON
    ,   [LibCraftId.PATTERN_INDEX_RESTO_STAFF     ] = LibCraftId.TRAITS_INDEX_TO_WEAPON

    ,   [LibCraftId.PATTERN_INDEX_SHIELD          ] = LibCraftId.TRAITS_INDEX_TO_ARMOR
    }
}

-- Begin giant itemId dump extracted from crafting stations ------------------
-- index order:
-- set_index
--      crafting_type  (always 1=BS, 2=CL, 6=WW)
--          pattern_index
--              10 tab-delimited item_id values, for no-trait and then the nine traits
--              string item name (not used here, just retained as documentation so that
--              humans can read the table).
LibCraftId.ITEM_ID =
{
    [2] =
    {
        [1] =
        {
            [1] = "46499\t46351\t46153\t46363\t46246\t46165\t46456\t46398\t46468\t56103\tAxe of Death's Wind",
            [2] = "46500\t46352\t46154\t46364\t46247\t46166\t46457\t46399\t46469\t56104\tHammer of Death's Wind",
            [3] = "46501\t46353\t46155\t46365\t46248\t46167\t46458\t46400\t46470\t56105\tSword of Death's Wind",
            [4] = "46502\t46354\t46156\t46366\t46249\t46168\t46459\t46401\t46471\t56106\tBattle Axe of Death's Wind",
            [5] = "46503\t46355\t46157\t46367\t46250\t46169\t46460\t46402\t46472\t56107\tMaul of Death's Wind",
            [6] = "46504\t46356\t46158\t46368\t46251\t46170\t46461\t46403\t46473\t56108\tGreatsword of Death's Wind",
            [7] = "46505\t46357\t46159\t46369\t46252\t46171\t46462\t46404\t46474\t56109\tDagger of Death's Wind",
            [8] = "46507\t46410\t46223\t46375\t46480\t46433\t46258\t46200\t46177\t56115\tCuirass of Death's Wind",
            [9] = "46508\t46411\t46224\t46376\t46481\t46434\t46259\t46201\t46178\t56116\tSabatons of Death's Wind",
            [10] = "46509\t46412\t46225\t46377\t46482\t46435\t46260\t46202\t46179\t56117\tGauntlets of Death's Wind",
            [11] = "46510\t46413\t46226\t46378\t46483\t46436\t46261\t46203\t46180\t56118\tHelm of Death's Wind",
            [12] = "46511\t46414\t46227\t46379\t46484\t46437\t46262\t46204\t46181\t56119\tGreaves of Death's Wind",
            [13] = "46512\t46415\t46228\t46380\t46485\t46438\t46263\t46205\t46182\t56120\tPauldron of Death's Wind",
            [14] = "46513\t46416\t46229\t46381\t46486\t46439\t46264\t46206\t46183\t56121\tGirdle of Death's Wind",
        },
        [2] =
        {
            [1] = "43805\t46417\t46230\t46382\t54629\t46440\t46265\t46207\t46184\t56122\tRobe of Death's Wind",
            [2] = "46516\t46422\t46235\t46387\t46489\t46445\t46270\t46212\t46189\t56127\tShirt of Death's Wind",
            [3] = "43806\t46418\t46231\t46383\t54630\t46441\t46266\t46208\t46185\t56123\tShoes of Death's Wind",
            [4] = "46514\t46419\t46232\t46384\t46487\t46442\t46267\t46209\t46186\t56124\tGloves of Death's Wind",
            [5] = "46515\t46420\t46233\t46385\t46488\t46443\t46268\t46210\t46187\t56125\tHat of Death's Wind",
            [6] = "43804\t46421\t46234\t46386\t54631\t46444\t46269\t46211\t46188\t56126\tBreeches of Death's Wind",
            [7] = "43803\t46423\t46236\t46388\t54632\t46446\t46271\t46213\t46190\t56128\tEpaulets of Death's Wind",
            [8] = "46517\t46424\t46237\t46389\t46490\t46447\t46272\t46214\t46191\t56129\tSash of Death's Wind",
            [9] = "46519\t46425\t46238\t46390\t46491\t46448\t46273\t46215\t46192\t56130\tJack of Death's Wind",
            [10] = "46520\t46426\t46239\t46391\t46492\t46449\t46274\t46216\t46193\t56131\tBoots of Death's Wind",
            [11] = "46521\t46427\t46240\t46392\t46493\t46450\t46275\t46217\t46194\t56132\tBracers of Death's Wind",
            [12] = "46522\t46428\t46241\t46393\t46494\t46451\t46276\t46218\t46195\t56133\tHelmet of Death's Wind",
            [13] = "46523\t46429\t46242\t46394\t46495\t46452\t46277\t46219\t46196\t56134\tGuards of Death's Wind",
            [14] = "46524\t46430\t46243\t46395\t46496\t46453\t46278\t46220\t46197\t56135\tArm Cops of Death's Wind",
            [15] = "46525\t46431\t46244\t46396\t46497\t46454\t46279\t46221\t46198\t56136\tBelt of Death's Wind",
        },
        [6] =
        {
            [1] = "46518\t46358\t46160\t46370\t46253\t46172\t46463\t46405\t46475\t56110\tBow of Death's Wind",
            [2] = "46527\t46432\t46245\t46397\t46498\t46455\t46280\t46222\t46199\t56137\tShield of Death's Wind",
            [3] = "46528\t46359\t46161\t46371\t46254\t46173\t46464\t46406\t46476\t56111\tInferno Staff of Death's Wind",
            [4] = "46529\t46360\t46162\t46372\t46255\t46174\t46465\t46407\t46477\t56112\tIce Staff of Death's Wind",
            [5] = "46530\t46361\t46163\t46373\t46256\t46175\t46466\t46408\t46478\t56113\tLightning Staff of Death's Wind",
            [6] = "46531\t46362\t46164\t46374\t46257\t46176\t46467\t46409\t46479\t56114\tRestoration Staff of Death's Wind",
        },
    },
    [3] =
    {
        [1] =
        {
            [1] = "47265\t47113\t46915\t47125\t47008\t46927\t47218\t47160\t47230\t56173\tAxe of Night's Silence",
            [2] = "47266\t47114\t46916\t47126\t47009\t46928\t47219\t47161\t47231\t56174\tHammer of Night's Silence",
            [3] = "47267\t47115\t46917\t47127\t47010\t46929\t47220\t47162\t47232\t56175\tSword of Night's Silence",
            [4] = "47268\t47116\t46918\t47128\t47011\t46930\t47221\t47163\t47233\t56176\tBattle Axe of Night's Silence",
            [5] = "47269\t47117\t46919\t47129\t47012\t46931\t47222\t47164\t47234\t56177\tMaul of Night's Silence",
            [6] = "47270\t47118\t46920\t47130\t47013\t46932\t47223\t47165\t47235\t56178\tGreatsword of Night's Silence",
            [7] = "43818\t47119\t46921\t47131\t47014\t46933\t47224\t47166\t47236\t56179\tDagger of Night's Silence",
            [8] = "47272\t47172\t46985\t47137\t47242\t47195\t47020\t46962\t46939\t56185\tCuirass of Night's Silence",
            [9] = "47273\t47173\t46986\t47138\t47243\t47196\t47021\t46963\t46940\t56186\tSabatons of Night's Silence",
            [10] = "47274\t47174\t46987\t47139\t47244\t47197\t47022\t46964\t46941\t56187\tGauntlets of Night's Silence",
            [11] = "47275\t47175\t46988\t47140\t47245\t47198\t47023\t46965\t46942\t56188\tHelm of Night's Silence",
            [12] = "47276\t47176\t46989\t47141\t47246\t47199\t47024\t46966\t46943\t56189\tGreaves of Night's Silence",
            [13] = "47277\t47177\t46990\t47142\t47247\t47200\t47025\t46967\t46944\t56190\tPauldron of Night's Silence",
            [14] = "47278\t47178\t46991\t47143\t47248\t47201\t47026\t46968\t46945\t56191\tGirdle of Night's Silence",
        },
        [2] =
        {
            [1] = "47279\t47179\t46992\t47144\t47249\t47202\t47027\t46969\t46946\t56192\tRobe of Night's Silence",
            [2] = "47284\t47184\t46997\t47149\t47254\t47207\t47032\t46974\t46951\t56197\tShirt of Night's Silence",
            [3] = "47280\t47180\t46993\t47145\t47250\t47203\t47028\t46970\t46947\t56193\tShoes of Night's Silence",
            [4] = "47281\t47181\t46994\t47146\t47251\t47204\t47029\t46971\t46948\t56194\tGloves of Night's Silence",
            [5] = "47282\t47182\t46995\t47147\t47252\t47205\t47030\t46972\t46949\t56195\tHat of Night's Silence",
            [6] = "47283\t47183\t46996\t47148\t47253\t47206\t47031\t46973\t46950\t56196\tBreeches of Night's Silence",
            [7] = "47285\t47185\t46998\t47150\t47255\t47208\t47033\t46975\t46952\t56198\tEpaulets of Night's Silence",
            [8] = "47286\t47186\t46999\t47151\t47256\t47209\t47034\t46976\t46953\t56199\tSash of Night's Silence",
            [9] = "43816\t47187\t47000\t47152\t47257\t47210\t47035\t46977\t46954\t56200\tJack of Night's Silence",
            [10] = "47288\t47188\t47001\t47153\t47258\t47211\t47036\t46978\t46955\t56201\tBoots of Night's Silence",
            [11] = "43815\t47189\t47002\t47154\t47259\t47212\t47037\t46979\t46956\t56202\tBracers of Night's Silence",
            [12] = "47289\t47190\t47003\t47155\t47260\t47213\t47038\t46980\t46957\t56203\tHelmet of Night's Silence",
            [13] = "47290\t47191\t47004\t47156\t47261\t47214\t47039\t46981\t46958\t56204\tGuards of Night's Silence",
            [14] = "47291\t47192\t47005\t47157\t47262\t47215\t47040\t46982\t46959\t56205\tArm Cops of Night's Silence",
            [15] = "47292\t47193\t47006\t47158\t47263\t47216\t47041\t46983\t46960\t56206\tBelt of Night's Silence",
        },
        [6] =
        {
            [1] = "47287\t47120\t46922\t47132\t47015\t46934\t47225\t47167\t47237\t56180\tBow of Night's Silence",
            [2] = "47293\t47194\t47007\t47159\t47264\t47217\t47042\t46984\t46961\t56207\tShield of Night's Silence",
            [3] = "47294\t47121\t46923\t47133\t47016\t46935\t47226\t47168\t47238\t56181\tInferno Staff of Night's Silence",
            [4] = "47295\t47122\t46924\t47134\t47017\t46936\t47227\t47169\t47239\t56182\tIce Staff of Night's Silence",
            [5] = "47296\t47123\t46925\t47135\t47018\t46937\t47228\t47170\t47240\t56183\tLightning Staff of Night's Silence",
            [6] = "47297\t47124\t46926\t47136\t47019\t46938\t47229\t47171\t47241\t56184\tRestoration Staff of Night's Silence",
        },
    },
    [4] =
    {
        [1] =
        {
            [1] = "49563\t49411\t49213\t49423\t49306\t49225\t49516\t49458\t49528\t56383\tAxe of Ashen Grip",
            [2] = "49564\t49412\t49214\t49424\t49307\t49226\t49517\t49459\t49529\t56384\tHammer of Ashen Grip",
            [3] = "49565\t49413\t49215\t49425\t49308\t49227\t49518\t49460\t49530\t56385\tSword of Ashen Grip",
            [4] = "49566\t49414\t49216\t49426\t49309\t49228\t49519\t49461\t49531\t56386\tBattle Axe of Ashen Grip",
            [5] = "49567\t49415\t49217\t49427\t49310\t49229\t49520\t49462\t49532\t56387\tMaul of Ashen Grip",
            [6] = "49568\t49416\t49218\t49428\t49311\t49230\t49521\t49463\t49533\t56388\tGreatsword of Ashen Grip",
            [7] = "49569\t49417\t49219\t49429\t49312\t49231\t49522\t49464\t49534\t56389\tDagger of Ashen Grip",
            [8] = "43873\t49470\t49283\t49435\t49540\t49493\t49318\t49260\t49237\t56395\tCuirass of Ashen Grip",
            [9] = "49571\t49471\t49284\t49436\t49541\t49494\t49319\t49261\t49238\t56396\tSabatons of Ashen Grip",
            [10] = "49572\t49472\t49285\t49437\t49542\t49495\t49320\t49262\t49239\t56397\tGauntlets of Ashen Grip",
            [11] = "49573\t49473\t49286\t49438\t49543\t49496\t49321\t49263\t49240\t56398\tHelm of Ashen Grip",
            [12] = "43872\t49474\t49287\t49439\t49544\t49497\t49322\t49264\t49241\t56399\tGreaves of Ashen Grip",
            [13] = "43871\t49475\t49288\t49440\t49545\t49498\t49323\t49265\t49242\t56400\tPauldron of Ashen Grip",
            [14] = "49574\t49476\t49289\t49441\t49546\t49499\t49324\t49266\t49243\t56401\tGirdle of Ashen Grip",
        },
        [2] =
        {
            [1] = "49575\t49477\t49290\t49442\t49547\t49500\t49325\t49267\t49244\t56402\tRobe of Ashen Grip",
            [2] = "49580\t49482\t49295\t49447\t49552\t49505\t49330\t49272\t49249\t56407\tShirt of Ashen Grip",
            [3] = "49576\t49478\t49291\t49443\t49548\t49501\t49326\t49268\t49245\t56403\tShoes of Ashen Grip",
            [4] = "49577\t49479\t49292\t49444\t49549\t49502\t49327\t49269\t49246\t56404\tGloves of Ashen Grip",
            [5] = "49578\t49480\t49293\t49445\t49550\t49503\t49328\t49270\t49247\t56405\tHat of Ashen Grip",
            [6] = "49579\t49481\t49294\t49446\t49551\t49504\t49329\t49271\t49248\t56406\tBreeches of Ashen Grip",
            [7] = "49581\t49483\t49296\t49448\t49553\t49506\t49331\t49273\t49250\t56408\tEpaulets of Ashen Grip",
            [8] = "49582\t49484\t49297\t49449\t49554\t49507\t49332\t49274\t49251\t56409\tSash of Ashen Grip",
            [9] = "49584\t49485\t49298\t49450\t49555\t49508\t49333\t49275\t49252\t56410\tJack of Ashen Grip",
            [10] = "49585\t49486\t49299\t49451\t49556\t49509\t49334\t49276\t49253\t56411\tBoots of Ashen Grip",
            [11] = "49586\t49487\t49300\t49452\t49557\t49510\t49335\t49277\t49254\t56412\tBracers of Ashen Grip",
            [12] = "49587\t49488\t49301\t49453\t49558\t49511\t49336\t49278\t49255\t56413\tHelmet of Ashen Grip",
            [13] = "49588\t49489\t49302\t49454\t49559\t49512\t49337\t49279\t49256\t56414\tGuards of Ashen Grip",
            [14] = "49589\t49490\t49303\t49455\t49560\t49513\t49338\t49280\t49257\t56415\tArm Cops of Ashen Grip",
            [15] = "49590\t49491\t49304\t49456\t49561\t49514\t49339\t49281\t49258\t56416\tBelt of Ashen Grip",
        },
        [6] =
        {
            [1] = "49583\t49418\t49220\t49430\t49313\t49232\t49523\t49465\t49535\t56390\tBow of Ashen Grip",
            [2] = "49591\t49492\t49305\t49457\t49562\t49515\t49340\t49282\t49259\t56417\tShield of Ashen Grip",
            [3] = "49592\t49419\t49221\t49431\t49314\t49233\t49524\t49466\t49536\t56391\tInferno Staff of Ashen Grip",
            [4] = "49593\t49420\t49222\t49432\t49315\t49234\t49525\t49467\t49537\t56392\tIce Staff of Ashen Grip",
            [5] = "49594\t49421\t49223\t49433\t49316\t49235\t49526\t49468\t49538\t56393\tLightning Staff of Ashen Grip",
            [6] = "49595\t49422\t49224\t49434\t49317\t49236\t49527\t49469\t49539\t56394\tRestoration Staff of Ashen Grip",
        },
    },
    [5] =
    {
        [1] =
        {
            [1] = "50708\t50556\t50358\t50568\t50451\t50370\t50661\t50603\t50673\t56488\tAxe of Torug's Pact",
            [2] = "50709\t50557\t50359\t50569\t50452\t50371\t50662\t50604\t50674\t56489\tHammer of Torug's Pact",
            [3] = "50710\t50558\t50360\t50570\t50453\t50372\t50663\t50605\t50675\t56490\tSword of Torug's Pact",
            [4] = "50711\t50559\t50361\t50571\t50454\t50373\t50664\t50606\t50676\t56491\tBattle Axe of Torug's Pact",
            [5] = "50712\t50560\t50362\t50572\t50455\t50374\t50665\t50607\t50677\t56492\tMaul of Torug's Pact",
            [6] = "50713\t50561\t50363\t50573\t50456\t50375\t50666\t50608\t50678\t56493\tGreatsword of Torug's Pact",
            [7] = "50714\t50562\t50364\t50574\t50457\t50376\t50667\t50609\t50679\t56494\tDagger of Torug's Pact",
            [8] = "50715\t50615\t50428\t50580\t50685\t50638\t50463\t50405\t50382\t56500\tCuirass of Torug's Pact",
            [9] = "50716\t50616\t50429\t50581\t50686\t50639\t50464\t50406\t50383\t56501\tSabatons of Torug's Pact",
            [10] = "50717\t50617\t50430\t50582\t50687\t50640\t50465\t50407\t50384\t56502\tGauntlets of Torug's Pact",
            [11] = "50718\t50618\t50431\t50583\t50688\t50641\t50466\t50408\t50385\t56503\tHelm of Torug's Pact",
            [12] = "50719\t50619\t50432\t50584\t50689\t50642\t50467\t50409\t50386\t56504\tGreaves of Torug's Pact",
            [13] = "50720\t50620\t50433\t50585\t50690\t50643\t50468\t50410\t50387\t56505\tPauldron of Torug's Pact",
            [14] = "50721\t50621\t50434\t50586\t50691\t50644\t50469\t50411\t50388\t56506\tGirdle of Torug's Pact",
        },
        [2] =
        {
            [1] = "43979\t50622\t50435\t50587\t50692\t50645\t50470\t50412\t50389\t56507\tRobe of Torug's Pact",
            [2] = "50725\t50627\t50440\t50592\t50697\t50650\t50475\t50417\t50394\t56512\tShirt of Torug's Pact",
            [3] = "50722\t50623\t50436\t50588\t50693\t50646\t50471\t50413\t50390\t56508\tShoes of Torug's Pact",
            [4] = "50723\t50624\t50437\t50589\t50694\t50647\t50472\t50414\t50391\t56509\tGloves of Torug's Pact",
            [5] = "50724\t50625\t50438\t50590\t50695\t50648\t50473\t50415\t50392\t56510\tHat of Torug's Pact",
            [6] = "43978\t50626\t50439\t50591\t50696\t50649\t50474\t50416\t50393\t56511\tBreeches of Torug's Pact",
            [7] = "43977\t50628\t50441\t50593\t50698\t50651\t50476\t50418\t50395\t56513\tEpaulets of Torug's Pact",
            [8] = "50726\t50629\t50442\t50594\t50699\t50652\t50477\t50419\t50396\t56514\tSash of Torug's Pact",
            [9] = "50728\t50630\t50443\t50595\t50700\t50653\t50478\t50420\t50397\t56515\tJack of Torug's Pact",
            [10] = "50729\t50631\t50444\t50596\t50701\t50654\t50479\t50421\t50398\t56516\tBoots of Torug's Pact",
            [11] = "50730\t50632\t50445\t50597\t50702\t50655\t50480\t50422\t50399\t56517\tBracers of Torug's Pact",
            [12] = "50731\t50633\t50446\t50598\t50703\t50656\t50481\t50423\t50400\t56518\tHelmet of Torug's Pact",
            [13] = "50732\t50634\t50447\t50599\t50704\t50657\t50482\t50424\t50401\t56519\tGuards of Torug's Pact",
            [14] = "50733\t50635\t50448\t50600\t50705\t50658\t50483\t50425\t50402\t56520\tArm Cops of Torug's Pact",
            [15] = "50734\t50636\t50449\t50601\t50706\t50659\t50484\t50426\t50403\t56521\tBelt of Torug's Pact",
        },
        [6] =
        {
            [1] = "50727\t50563\t50365\t50575\t50458\t50377\t50668\t50610\t50680\t56495\tBow of Torug's Pact",
            [2] = "50735\t50637\t50450\t50602\t50707\t50660\t50485\t50427\t50404\t56522\tShield of Torug's Pact",
            [3] = "50736\t50564\t50366\t50576\t50459\t50378\t50669\t50611\t50681\t56496\tInferno Staff of Torug's Pact",
            [4] = "50737\t50565\t50367\t50577\t50460\t50379\t50670\t50612\t50682\t56497\tIce Staff of Torug's Pact",
            [5] = "50738\t50566\t50368\t50578\t50461\t50380\t50671\t50613\t50683\t56498\tLightning Staff of Torug's Pact",
            [6] = "50739\t50567\t50369\t50579\t50462\t50381\t50672\t50614\t50684\t56499\tRestoration Staff of Torug's Pact",
        },
    },
    [6] =
    {
        [1] =
        {
            [1] = "46882\t46730\t46532\t46742\t46625\t46544\t46835\t46777\t46847\t56138\tAxe of Twilight's Embrace",
            [2] = "46883\t46731\t46533\t46743\t46626\t46545\t46836\t46778\t46848\t56139\tHammer of Twilight's Embrace",
            [3] = "46884\t46732\t46534\t46744\t46627\t46546\t46837\t46779\t46849\t56140\tSword of Twilight's Embrace",
            [4] = "46885\t46733\t46535\t46745\t46628\t46547\t46838\t46780\t46850\t56141\tBattle Axe of Twilight's Embrace",
            [5] = "46886\t46734\t46536\t46746\t46629\t46548\t46839\t46781\t46851\t56142\tMaul of Twilight's Embrace",
            [6] = "46887\t46735\t46537\t46747\t46630\t46549\t46840\t46782\t46852\t56143\tGreatsword of Twilight's Embrace",
            [7] = "46888\t46736\t46538\t46748\t46631\t46550\t46841\t46783\t46853\t56144\tDagger of Twilight's Embrace",
            [8] = "46890\t46789\t46602\t46754\t46859\t46812\t46637\t46579\t46556\t56150\tCuirass of Twilight's Embrace",
            [9] = "46891\t46790\t46603\t46755\t46860\t46813\t46638\t46580\t46557\t56151\tSabatons of Twilight's Embrace",
            [10] = "46892\t46791\t46604\t46756\t46861\t46814\t46639\t46581\t46558\t56152\tGauntlets of Twilight's Embrace",
            [11] = "46893\t46792\t46605\t46757\t46862\t46815\t46640\t46582\t46559\t56153\tHelm of Twilight's Embrace",
            [12] = "46894\t46793\t46606\t46758\t46863\t46816\t46641\t46583\t46560\t56154\tGreaves of Twilight's Embrace",
            [13] = "46895\t46794\t46607\t46759\t46864\t46817\t46642\t46584\t46561\t56155\tPauldron of Twilight's Embrace",
            [14] = "46896\t46795\t46608\t46760\t46865\t46818\t46643\t46585\t46562\t56156\tGirdle of Twilight's Embrace",
        },
        [2] =
        {
            [1] = "43808\t46796\t46609\t46761\t46866\t46819\t46644\t46586\t46563\t56157\tRobe of Twilight's Embrace",
            [2] = "46900\t46801\t46614\t46766\t46871\t46824\t46649\t46591\t46568\t56162\tShirt of Twilight's Embrace",
            [3] = "43810\t46797\t46610\t46762\t46867\t46820\t46645\t46587\t46564\t56158\tShoes of Twilight's Embrace",
            [4] = "46897\t46798\t46611\t46763\t46868\t46821\t46646\t46588\t46565\t56159\tGloves of Twilight's Embrace",
            [5] = "46898\t46799\t46612\t46764\t46869\t46822\t46647\t46589\t46566\t56160\tHat of Twilight's Embrace",
            [6] = "46899\t46800\t46613\t46765\t46870\t46823\t46648\t46590\t46567\t56161\tBreeches of Twilight's Embrace",
            [7] = "43807\t46802\t46615\t46767\t46872\t46825\t46650\t46592\t46569\t56163\tEpaulets of Twilight's Embrace",
            [8] = "43809\t46803\t46616\t46768\t46873\t46826\t46651\t46593\t46570\t56164\tSash of Twilight's Embrace",
            [9] = "46902\t46804\t46617\t46769\t46874\t46827\t46652\t46594\t46571\t56165\tJack of Twilight's Embrace",
            [10] = "46903\t46805\t46618\t46770\t46875\t46828\t46653\t46595\t46572\t56166\tBoots of Twilight's Embrace",
            [11] = "46904\t46806\t46619\t46771\t46876\t46829\t46654\t46596\t46573\t56167\tBracers of Twilight's Embrace",
            [12] = "46905\t46807\t46620\t46772\t46877\t46830\t46655\t46597\t46574\t56168\tHelmet of Twilight's Embrace",
            [13] = "46906\t46808\t46621\t46773\t46878\t46831\t46656\t46598\t46575\t56169\tGuards of Twilight's Embrace",
            [14] = "46907\t46809\t46622\t46774\t46879\t46832\t46657\t46599\t46576\t56170\tArm Cops of Twilight's Embrace",
            [15] = "46908\t46810\t46623\t46775\t46880\t46833\t46658\t46600\t46577\t56171\tBelt of Twilight's Embrace",
        },
        [6] =
        {
            [1] = "46901\t46737\t46539\t46749\t46632\t46551\t46842\t46784\t46854\t56145\tBow of Twilight's Embrace",
            [2] = "46910\t46811\t46624\t46776\t46881\t46834\t46659\t46601\t46578\t56172\tShield of Twilight's Embrace",
            [3] = "46911\t46738\t46540\t46750\t46633\t46552\t46843\t46785\t46855\t56146\tInferno Staff of Twilight's Embrace",
            [4] = "46912\t46739\t46541\t46751\t46634\t46553\t46844\t46786\t46856\t56147\tIce Staff of Twilight's Embrace",
            [5] = "46913\t46740\t46542\t46752\t46635\t46554\t46845\t46787\t46857\t56148\tLightning Staff of Twilight's Embrace",
            [6] = "46914\t46741\t46543\t46753\t46636\t46555\t46846\t46788\t46858\t56149\tRestoration Staff of Twilight's Embrace",
        },
    },
    [7] =
    {
        [1] =
        {
            [1] = "48031\t47879\t47681\t47891\t47774\t47693\t47984\t47926\t47996\t56243\tAxe of the Seducer",
            [2] = "48032\t47880\t47682\t47892\t47775\t47694\t47985\t47927\t47997\t56244\tHammer of the Seducer",
            [3] = "48033\t47881\t47683\t47893\t47776\t47695\t47986\t47928\t47998\t56245\tSword of the Seducer",
            [4] = "48034\t47882\t47684\t47894\t47777\t47696\t47987\t47929\t47999\t56246\tBattle Axe of the Seducer",
            [5] = "48035\t47883\t47685\t47895\t47778\t47697\t47988\t47930\t48000\t56247\tMaul of the Seducer",
            [6] = "48036\t47884\t47686\t47896\t47779\t47698\t47989\t47931\t48001\t56248\tGreatsword of the Seducer",
            [7] = "48037\t47885\t47687\t47897\t47780\t47699\t47990\t47932\t48002\t56249\tDagger of the Seducer",
            [8] = "43830\t47938\t47751\t47903\t48008\t47961\t47786\t47728\t47705\t56255\tCuirass of the Seducer",
            [9] = "48039\t47939\t47752\t47904\t48009\t47962\t47787\t47729\t47706\t56256\tSabatons of the Seducer",
            [10] = "48040\t47940\t47753\t47905\t48010\t47963\t47788\t47730\t47707\t56257\tGauntlets of the Seducer",
            [11] = "43827\t47941\t47754\t47906\t48011\t47964\t47789\t47731\t47708\t56258\tHelm of the Seducer",
            [12] = "43829\t47942\t47755\t47907\t48012\t47965\t47790\t47732\t47709\t56259\tGreaves of the Seducer",
            [13] = "43828\t47943\t47756\t47908\t48013\t47966\t47791\t47733\t47710\t56260\tPauldron of the Seducer",
            [14] = "48041\t47944\t47757\t47909\t48014\t47967\t47792\t47734\t47711\t56261\tGirdle of the Seducer",
        },
        [2] =
        {
            [1] = "48042\t47945\t47758\t47910\t48015\t47968\t47793\t47735\t47712\t56262\tRobe of the Seducer",
            [2] = "48047\t47950\t47763\t47915\t48020\t47973\t47798\t47740\t47717\t56267\tShirt of the Seducer",
            [3] = "48043\t47946\t47759\t47911\t48016\t47969\t47794\t47736\t47713\t56263\tShoes of the Seducer",
            [4] = "48044\t47947\t47760\t47912\t48017\t47970\t47795\t47737\t47714\t56264\tGloves of the Seducer",
            [5] = "48045\t47948\t47761\t47913\t48018\t47971\t47796\t47738\t47715\t56265\tHat of the Seducer",
            [6] = "48046\t47949\t47762\t47914\t48019\t47972\t47797\t47739\t47716\t56266\tBreeches of the Seducer",
            [7] = "48048\t47951\t47764\t47916\t48021\t47974\t47799\t47741\t47718\t56268\tEpaulets of the Seducer",
            [8] = "48049\t47952\t47765\t47917\t48022\t47975\t47800\t47742\t47719\t56269\tSash of the Seducer",
            [9] = "48051\t47953\t47766\t47918\t48023\t47976\t47801\t47743\t47720\t56270\tJack of the Seducer",
            [10] = "48052\t47954\t47767\t47919\t48024\t47977\t47802\t47744\t47721\t56271\tBoots of the Seducer",
            [11] = "48053\t47955\t47768\t47920\t48025\t47978\t47803\t47745\t47722\t56272\tBracers of the Seducer",
            [12] = "48054\t47956\t47769\t47921\t48026\t47979\t47804\t47746\t47723\t56273\tHelmet of the Seducer",
            [13] = "48055\t47957\t47770\t47922\t48027\t47980\t47805\t47747\t47724\t56274\tGuards of the Seducer",
            [14] = "48056\t47958\t47771\t47923\t48028\t47981\t47806\t47748\t47725\t56275\tArm Cops of the Seducer",
            [15] = "48057\t47959\t47772\t47924\t48029\t47982\t47807\t47749\t47726\t56276\tBelt of the Seducer",
        },
        [6] =
        {
            [1] = "48050\t47886\t47688\t47898\t47781\t47700\t47991\t47933\t48003\t56250\tBow of the Seducer",
            [2] = "48059\t47960\t47773\t47925\t48030\t47983\t47808\t47750\t47727\t56277\tShield of the Seducer",
            [3] = "48060\t47887\t47689\t47899\t47782\t47701\t47992\t47934\t48004\t56251\tInferno Staff of the Seducer",
            [4] = "48061\t47888\t47690\t47900\t47783\t47702\t47993\t47935\t48005\t56252\tIce Staff of the Seducer",
            [5] = "48062\t47889\t47691\t47901\t47784\t47703\t47994\t47936\t48006\t56253\tLightning Staff of the Seducer",
            [6] = "48063\t47890\t47692\t47902\t47785\t47704\t47995\t47937\t48007\t56254\tRestoration Staff of the Seducer",
        },
    },
    [8] =
    {
        [1] =
        {
            [1] = "48797\t48645\t48447\t48657\t48540\t48459\t48750\t48692\t48762\t56313\tMagnus' Axe",
            [2] = "48798\t48646\t48448\t48658\t48541\t48460\t48751\t48693\t48763\t56314\tMagnus' Hammer",
            [3] = "48799\t48647\t48449\t48659\t48542\t48461\t48752\t48694\t48764\t56315\tMagnus' Sword",
            [4] = "48800\t48648\t48450\t48660\t48543\t48462\t48753\t48695\t48765\t56316\tMagnus' Battle Axe",
            [5] = "48801\t48649\t48451\t48661\t48544\t48463\t48754\t48696\t48766\t56317\tMagnus' Maul",
            [6] = "48802\t48650\t48452\t48662\t48545\t48464\t48755\t48697\t48767\t56318\tMagnus' Greatsword",
            [7] = "48803\t48651\t48453\t48663\t48546\t48465\t48756\t48698\t48768\t56319\tMagnus' Dagger",
            [8] = "48805\t48704\t48517\t48669\t48774\t48727\t48552\t48494\t48471\t56325\tMagnus' Cuirass",
            [9] = "48806\t48705\t48518\t48670\t48775\t48728\t48553\t48495\t48472\t56326\tMagnus' Sabatons",
            [10] = "48807\t48706\t48519\t48671\t48776\t48729\t48554\t48496\t48473\t56327\tMagnus' Gauntlets",
            [11] = "48808\t48707\t48520\t48672\t48777\t48730\t48555\t48497\t48474\t56328\tMagnus' Helm",
            [12] = "48809\t48708\t48521\t48673\t48778\t48731\t48556\t48498\t48475\t56329\tMagnus' Greaves",
            [13] = "48810\t48709\t48522\t48674\t48779\t48732\t48557\t48499\t48476\t56330\tMagnus' Pauldron",
            [14] = "48811\t48710\t48523\t48675\t48780\t48733\t48558\t48500\t48477\t56331\tMagnus' Girdle",
        },
        [2] =
        {
            [1] = "43849\t48711\t48524\t48676\t48781\t48734\t48559\t48501\t48478\t56332\tMagnus' Robe",
            [2] = "48813\t48716\t48529\t48681\t48786\t48739\t48564\t48506\t48483\t56337\tMagnus' Shirt",
            [3] = "43850\t48712\t48525\t48677\t48782\t48735\t48560\t48502\t48479\t56333\tMagnus' Shoes",
            [4] = "43848\t48713\t48526\t48678\t48783\t48736\t48561\t48503\t48480\t56334\tMagnus' Gloves",
            [5] = "43847\t48714\t48527\t48679\t48784\t48737\t48562\t48504\t48481\t56335\tMagnus' Hat",
            [6] = "48812\t48715\t48528\t48680\t48785\t48738\t48563\t48505\t48482\t56336\tMagnus' Breeches",
            [7] = "48814\t48717\t48530\t48682\t48787\t48740\t48565\t48507\t48484\t56338\tMagnus' Epaulets",
            [8] = "48815\t48718\t48531\t48683\t48788\t48741\t48566\t48508\t48485\t56339\tMagnus' Sash",
            [9] = "48817\t48719\t48532\t48684\t48789\t48742\t48567\t48509\t48486\t56340\tMagnus' Jack",
            [10] = "48818\t48720\t48533\t48685\t48790\t48743\t48568\t48510\t48487\t56341\tMagnus' Boots",
            [11] = "48819\t48721\t48534\t48686\t48791\t48744\t48569\t48511\t48488\t56342\tMagnus' Bracers",
            [12] = "48820\t48722\t48535\t48687\t48792\t48745\t48570\t48512\t48489\t56343\tMagnus' Helmet",
            [13] = "48821\t48723\t48536\t48688\t48793\t48746\t48571\t48513\t48490\t56344\tMagnus' Guards",
            [14] = "48822\t48724\t48537\t48689\t48794\t48747\t48572\t48514\t48491\t56345\tMagnus' Arm Cops",
            [15] = "48823\t48725\t48538\t48690\t48795\t48748\t48573\t48515\t48492\t56346\tMagnus' Belt",
        },
        [6] =
        {
            [1] = "48816\t48652\t48454\t48664\t48547\t48466\t48757\t48699\t48769\t56320\tMagnus' Bow",
            [2] = "48825\t48726\t48539\t48691\t48796\t48749\t48574\t48516\t48493\t56347\tMagnus' Shield",
            [3] = "48826\t48653\t48455\t48665\t48548\t48467\t48758\t48700\t48770\t56321\tMagnus' Inferno Staff",
            [4] = "48827\t48654\t48456\t48666\t48549\t48468\t48759\t48701\t48771\t56322\tMagnus' Ice Staff",
            [5] = "48828\t48655\t48457\t48667\t48550\t48469\t48760\t48702\t48772\t56323\tMagnus' Lightning Staff",
            [6] = "48829\t48656\t48458\t48668\t48551\t48470\t48761\t48703\t48773\t56324\tMagnus' Restoration Staff",
        },
    },
    [9] =
    {
        [1] =
        {
            [1] = "51090\t50938\t50740\t50950\t50833\t50752\t51043\t50985\t51055\t56523\tAxe of Hist Bark",
            [2] = "51091\t50939\t50741\t50951\t50834\t50753\t51044\t50986\t51056\t56524\tHammer of Hist Bark",
            [3] = "51092\t50940\t50742\t50952\t50835\t50754\t51045\t50987\t51057\t56525\tSword of Hist Bark",
            [4] = "51093\t50941\t50743\t50953\t50836\t50755\t51046\t50988\t51058\t56526\tBattle Axe of Hist Bark",
            [5] = "51094\t50942\t50744\t50954\t50837\t50756\t51047\t50989\t51059\t56527\tMaul of Hist Bark",
            [6] = "51095\t50943\t50745\t50955\t50838\t50757\t51048\t50990\t51060\t56528\tGreatsword of Hist Bark",
            [7] = "51096\t50944\t50746\t50956\t50839\t50758\t51049\t50991\t51061\t56529\tDagger of Hist Bark",
            [8] = "51098\t50997\t50810\t50962\t51067\t51020\t50845\t50787\t50764\t56535\tCuirass of Hist Bark",
            [9] = "51099\t50998\t50811\t50963\t51068\t51021\t50846\t50788\t50765\t56536\tSabatons of Hist Bark",
            [10] = "51100\t50999\t50812\t50964\t51069\t51022\t50847\t50789\t50766\t56537\tGauntlets of Hist Bark",
            [11] = "51101\t51000\t50813\t50965\t51070\t51023\t50848\t50790\t50767\t56538\tHelm of Hist Bark",
            [12] = "51102\t51001\t50814\t50966\t51071\t51024\t50849\t50791\t50768\t56539\tGreaves of Hist Bark",
            [13] = "51103\t51002\t50815\t50967\t51072\t51025\t50850\t50792\t50769\t56540\tPauldron of Hist Bark",
            [14] = "51104\t51003\t50816\t50968\t51073\t51026\t50851\t50793\t50770\t56541\tGirdle of Hist Bark",
        },
        [2] =
        {
            [1] = "51105\t51004\t50817\t50969\t51074\t51027\t50852\t50794\t50771\t56542\tRobe of Hist Bark",
            [2] = "51110\t51009\t50822\t50974\t51079\t51032\t50857\t50799\t50776\t56547\tShirt of Hist Bark",
            [3] = "51106\t51005\t50818\t50970\t51075\t51028\t50853\t50795\t50772\t56543\tShoes of Hist Bark",
            [4] = "51107\t51006\t50819\t50971\t51076\t51029\t50854\t50796\t50773\t56544\tGloves of Hist Bark",
            [5] = "51108\t51007\t50820\t50972\t51077\t51030\t50855\t50797\t50774\t56545\tHat of Hist Bark",
            [6] = "51109\t51008\t50821\t50973\t51078\t51031\t50856\t50798\t50775\t56546\tBreeches of Hist Bark",
            [7] = "51111\t51010\t50823\t50975\t51080\t51033\t50858\t50800\t50777\t56548\tEpaulets of Hist Bark",
            [8] = "51112\t51011\t50824\t50976\t51081\t51034\t50859\t50801\t50778\t56549\tSash of Hist Bark",
            [9] = "43998\t51012\t50825\t50977\t51082\t51035\t50860\t50802\t50779\t56550\tJack of Hist Bark",
            [10] = "44000\t51013\t50826\t50978\t51083\t51036\t50861\t50803\t50780\t56551\tBoots of Hist Bark",
            [11] = "43996\t51014\t50827\t50979\t51084\t51037\t50862\t50804\t50781\t56552\tBracers of Hist Bark",
            [12] = "51114\t51015\t50828\t50980\t51085\t51038\t50863\t50805\t50782\t56553\tHelmet of Hist Bark",
            [13] = "43997\t51016\t50829\t50981\t51086\t51039\t50864\t50806\t50783\t56554\tGuards of Hist Bark",
            [14] = "43995\t51017\t50830\t50982\t51087\t51040\t50865\t50807\t50784\t56555\tArm Cops of Hist Bark",
            [15] = "43999\t51018\t50831\t50983\t51088\t51041\t50866\t50808\t50785\t56556\tBelt of Hist Bark",
        },
        [6] =
        {
            [1] = "51113\t50945\t50747\t50957\t50840\t50759\t51050\t50992\t51062\t56530\tBow of Hist Bark",
            [2] = "51116\t51019\t50832\t50984\t51089\t51042\t50867\t50809\t50786\t56557\tShield of Hist Bark",
            [3] = "51117\t50946\t50748\t50958\t50841\t50760\t51051\t50993\t51063\t56531\tInferno Staff of Hist Bark",
            [4] = "51118\t50947\t50749\t50959\t50842\t50761\t51052\t50994\t51064\t56532\tIce Staff of Hist Bark",
            [5] = "51119\t50948\t50750\t50960\t50843\t50762\t51053\t50995\t51065\t56533\tLightning Staff of Hist Bark",
            [6] = "51120\t50949\t50751\t50961\t50844\t50763\t51054\t50996\t51066\t56534\tRestoration Staff of Hist Bark",
        },
    },
    [10] =
    {
        [1] =
        {
            [1] = "47648\t47496\t47298\t47508\t47391\t47310\t47601\t47543\t47613\t56208\tWhitestrake's Axe",
            [2] = "47649\t47497\t47299\t47509\t47392\t47311\t47602\t47544\t47614\t56209\tWhitestrake's Hammer",
            [3] = "47650\t47498\t47300\t47510\t47393\t47312\t47603\t47545\t47615\t56210\tWhitestrake's Sword",
            [4] = "47651\t47499\t47301\t47511\t47394\t47313\t47604\t47546\t47616\t56211\tWhitestrake's Battle Axe",
            [5] = "47652\t47500\t47302\t47512\t47395\t47314\t47605\t47547\t47617\t56212\tWhitestrake's Maul",
            [6] = "47653\t47501\t47303\t47513\t47396\t47315\t47606\t47548\t47618\t56213\tWhitestrake's Greatsword",
            [7] = "47654\t47502\t47304\t47514\t47397\t47316\t47607\t47549\t47619\t56214\tWhitestrake's Dagger",
            [8] = "47656\t47555\t47368\t47520\t47625\t47578\t47403\t47345\t47322\t56220\tWhitestrake's Cuirass",
            [9] = "47657\t47556\t47369\t47521\t47626\t47579\t47404\t47346\t47323\t56221\tWhitestrake's Sabatons",
            [10] = "47658\t47557\t47370\t47522\t47627\t47580\t47405\t47347\t47324\t56222\tWhitestrake's Gauntlets",
            [11] = "47659\t47558\t47371\t47523\t47628\t47581\t47406\t47348\t47325\t56223\tWhitestrake's Helm",
            [12] = "47660\t47559\t47372\t47524\t47629\t47582\t47407\t47349\t47326\t56224\tWhitestrake's Greaves",
            [13] = "47661\t47560\t47373\t47525\t47630\t47583\t47408\t47350\t47327\t56225\tWhitestrake's Pauldron",
            [14] = "47662\t47561\t47374\t47526\t47631\t47584\t47409\t47351\t47328\t56226\tWhitestrake's Girdle",
        },
        [2] =
        {
            [1] = "47663\t47562\t47375\t47527\t47632\t47585\t47410\t47352\t47329\t56227\tWhitestrake's Robe",
            [2] = "47668\t47567\t47380\t47532\t47637\t47590\t47415\t47357\t47334\t56232\tWhitestrake's Shirt",
            [3] = "47664\t47563\t47376\t47528\t47633\t47586\t47411\t47353\t47330\t56228\tWhitestrake's Shoes",
            [4] = "47665\t47564\t47377\t47529\t47634\t47587\t47412\t47354\t47331\t56229\tWhitestrake's Gloves",
            [5] = "47666\t47565\t47378\t47530\t47635\t47588\t47413\t47355\t47332\t56230\tWhitestrake's Hat",
            [6] = "47667\t47566\t47379\t47531\t47636\t47589\t47414\t47356\t47333\t56231\tWhitestrake's Breeches",
            [7] = "47669\t47568\t47381\t47533\t47638\t47591\t47416\t47358\t47335\t56233\tWhitestrake's Epaulets",
            [8] = "47670\t47569\t47382\t47534\t47639\t47592\t47417\t47359\t47336\t56234\tWhitestrake's Sash",
            [9] = "47672\t47570\t47383\t47535\t47640\t47593\t47418\t47360\t47337\t56235\tWhitestrake's Jack",
            [10] = "47673\t47571\t47384\t47536\t47641\t47594\t47419\t47361\t47338\t56236\tWhitestrake's Boots",
            [11] = "47674\t47572\t47385\t47537\t47642\t47595\t47420\t47362\t47339\t56237\tWhitestrake's Bracers",
            [12] = "43819\t47573\t47386\t47538\t47643\t47596\t47421\t47363\t47340\t56238\tWhitestrake's Helmet",
            [13] = "43821\t47574\t47387\t47539\t47644\t47597\t47422\t47364\t47341\t56239\tWhitestrake's Guards",
            [14] = "43820\t47575\t47388\t47540\t47645\t47598\t47423\t47365\t47342\t56240\tWhitestrake's Arm Cops",
            [15] = "43822\t47576\t47389\t47541\t47646\t47599\t47424\t47366\t47343\t56241\tWhitestrake's Belt",
        },
        [6] =
        {
            [1] = "47671\t47503\t47305\t47515\t47398\t47317\t47608\t47550\t47620\t56215\tWhitestrake's Bow",
            [2] = "47676\t47577\t47390\t47542\t47647\t47600\t47425\t47367\t47344\t56242\tWhitestrake's Shield",
            [3] = "47677\t47504\t47306\t47516\t47399\t47318\t47609\t47551\t47621\t56216\tWhitestrake's Inferno Staff",
            [4] = "47678\t47505\t47307\t47517\t47400\t47319\t47610\t47552\t47622\t56217\tWhitestrake's Ice Staff",
            [5] = "47679\t47506\t47308\t47518\t47401\t47320\t47611\t47553\t47623\t56218\tWhitestrake's Lightning Staff",
            [6] = "47680\t47507\t47309\t47519\t47402\t47321\t47612\t47554\t47624\t56219\tWhitestrake's Restoration Staff",
        },
    },
    [11] =
    {
        [1] =
        {
            [1] = "48414\t48262\t48064\t48274\t48157\t48076\t48367\t48309\t48379\t56278\tAxe of Vampire's Kiss",
            [2] = "48415\t48263\t48065\t48275\t48158\t48077\t48368\t48310\t48380\t56279\tHammer of Vampire's Kiss",
            [3] = "48416\t48264\t48066\t48276\t48159\t48078\t48369\t48311\t48381\t56280\tSword of Vampire's Kiss",
            [4] = "48417\t48265\t48067\t48277\t48160\t48079\t48370\t48312\t48382\t56281\tBattle Axe of Vampire's Kiss",
            [5] = "48418\t48266\t48068\t48278\t48161\t48080\t48371\t48313\t48383\t56282\tMaul of Vampire's Kiss",
            [6] = "48419\t48267\t48069\t48279\t48162\t48081\t48372\t48314\t48384\t56283\tGreatsword of Vampire's Kiss",
            [7] = "48420\t48268\t48070\t48280\t48163\t48082\t48373\t48315\t48385\t56284\tDagger of Vampire's Kiss",
            [8] = "43834\t48321\t48134\t48286\t48391\t48344\t48169\t48111\t48088\t56290\tCuirass of Vampire's Kiss",
            [9] = "48422\t48322\t48135\t48287\t48392\t48345\t48170\t48112\t48089\t56291\tSabatons of Vampire's Kiss",
            [10] = "43832\t48323\t48136\t48288\t48393\t48346\t48171\t48113\t48090\t56292\tGauntlets of Vampire's Kiss",
            [11] = "48423\t48324\t48137\t48289\t48394\t48347\t48172\t48114\t48091\t56293\tHelm of Vampire's Kiss",
            [12] = "43833\t48325\t48138\t48290\t48395\t48348\t48173\t48115\t48092\t56294\tGreaves of Vampire's Kiss",
            [13] = "43831\t48326\t48139\t48291\t48396\t48349\t48174\t48116\t48093\t56295\tPauldron of Vampire's Kiss",
            [14] = "48424\t48327\t48140\t48292\t48397\t48350\t48175\t48117\t48094\t56296\tGirdle of Vampire's Kiss",
        },
        [2] =
        {
            [1] = "48425\t48328\t48141\t48293\t48398\t48351\t48176\t48118\t48095\t56297\tRobe of Vampire's Kiss",
            [2] = "48430\t48333\t48146\t48298\t48403\t48356\t48181\t48123\t48100\t56302\tShirt of Vampire's Kiss",
            [3] = "48426\t48329\t48142\t48294\t48399\t48352\t48177\t48119\t48096\t56298\tShoes of Vampire's Kiss",
            [4] = "48427\t48330\t48143\t48295\t48400\t48353\t48178\t48120\t48097\t56299\tGloves of Vampire's Kiss",
            [5] = "48428\t48331\t48144\t48296\t48401\t48354\t48179\t48121\t48098\t56300\tHat of Vampire's Kiss",
            [6] = "48429\t48332\t48145\t48297\t48402\t48355\t48180\t48122\t48099\t56301\tBreeches of Vampire's Kiss",
            [7] = "48431\t48334\t48147\t48299\t48404\t48357\t48182\t48124\t48101\t56303\tEpaulets of Vampire's Kiss",
            [8] = "48432\t48335\t48148\t48300\t48405\t48358\t48183\t48125\t48102\t56304\tSash of Vampire's Kiss",
            [9] = "48434\t48336\t48149\t48301\t48406\t48359\t48184\t48126\t48103\t56305\tJack of Vampire's Kiss",
            [10] = "48435\t48337\t48150\t48302\t48407\t48360\t48185\t48127\t48104\t56306\tBoots of Vampire's Kiss",
            [11] = "48436\t48338\t48151\t48303\t48408\t48361\t48186\t48128\t48105\t56307\tBracers of Vampire's Kiss",
            [12] = "48437\t48339\t48152\t48304\t48409\t48362\t48187\t48129\t48106\t56308\tHelmet of Vampire's Kiss",
            [13] = "48438\t48340\t48153\t48305\t48410\t48363\t48188\t48130\t48107\t56309\tGuards of Vampire's Kiss",
            [14] = "48439\t48341\t48154\t48306\t48411\t48364\t48189\t48131\t48108\t56310\tArm Cops of Vampire's Kiss",
            [15] = "48440\t48342\t48155\t48307\t48412\t48365\t48190\t48132\t48109\t56311\tBelt of Vampire's Kiss",
        },
        [6] =
        {
            [1] = "48433\t48269\t48071\t48281\t48164\t48083\t48374\t48316\t48386\t56285\tBow of Vampire's Kiss",
            [2] = "48442\t48343\t48156\t48308\t48413\t48366\t48191\t48133\t48110\t56312\tShield of Vampire's Kiss",
            [3] = "48443\t48270\t48072\t48282\t48165\t48084\t48375\t48317\t48387\t56286\tInferno Staff of Vampire's Kiss",
            [4] = "48444\t48271\t48073\t48283\t48166\t48085\t48376\t48318\t48388\t56287\tIce Staff of Vampire's Kiss",
            [5] = "48445\t48272\t48074\t48284\t48167\t48086\t48377\t48319\t48389\t56288\tLightning Staff of Vampire's Kiss",
            [6] = "48446\t48273\t48075\t48285\t48168\t48087\t48378\t48320\t48390\t56289\tRestoration Staff of Vampire's Kiss",
        },
    },
    [12] =
    {
        [1] =
        {
            [1] = "52233\t52081\t51883\t52093\t51976\t51895\t52186\t52128\t52198\t56628\tAxe of the Song of Lamae",
            [2] = "52234\t52082\t51884\t52094\t51977\t51896\t52187\t52129\t52199\t56629\tHammer of the Song of Lamae",
            [3] = "52235\t52083\t51885\t52095\t51978\t51897\t52188\t52130\t52200\t56630\tSword of the Song of Lamae",
            [4] = "52236\t52084\t51886\t52096\t51979\t51898\t52189\t52131\t52201\t56631\tBattle Axe of the Song of Lamae",
            [5] = "52237\t52085\t51887\t52097\t51980\t51899\t52190\t52132\t52202\t56632\tMaul of the Song of Lamae",
            [6] = "44018\t52086\t51888\t52098\t51981\t51900\t52191\t52133\t52203\t56633\tGreatsword of the Song of Lamae",
            [7] = "52238\t52087\t51889\t52099\t51982\t51901\t52192\t52134\t52204\t56634\tDagger of the Song of Lamae",
            [8] = "44016\t52140\t51953\t52105\t52210\t52163\t51988\t51930\t51907\t56640\tCuirass of the Song of Lamae",
            [9] = "52240\t52141\t51954\t52106\t52211\t52164\t51989\t51931\t51908\t56641\tSabatons of the Song of Lamae",
            [10] = "44014\t52142\t51955\t52107\t52212\t52165\t51990\t51932\t51909\t56642\tGauntlets of the Song of Lamae",
            [11] = "44013\t52143\t51956\t52108\t52213\t52166\t51991\t51933\t51910\t56643\tHelm of the Song of Lamae",
            [12] = "44015\t52144\t51957\t52109\t52214\t52167\t51992\t51934\t51911\t56644\tGreaves of the Song of Lamae",
            [13] = "52241\t52145\t51958\t52110\t52215\t52168\t51993\t51935\t51912\t56645\tPauldron of the Song of Lamae",
            [14] = "52242\t52146\t51959\t52111\t52216\t52169\t51994\t51936\t51913\t56646\tGirdle of the Song of Lamae",
        },
        [2] =
        {
            [1] = "52243\t52147\t51960\t52112\t52217\t52170\t51995\t51937\t51914\t56647\tRobe of the Song of Lamae",
            [2] = "52248\t52152\t51965\t52117\t52222\t52175\t52000\t51942\t51919\t56652\tShirt of the Song of Lamae",
            [3] = "52244\t52148\t51961\t52113\t52218\t52171\t51996\t51938\t51915\t56648\tShoes of the Song of Lamae",
            [4] = "52245\t52149\t51962\t52114\t52219\t52172\t51997\t51939\t51916\t56649\tGloves of the Song of Lamae",
            [5] = "52246\t52150\t51963\t52115\t52220\t52173\t51998\t51940\t51917\t56650\tHat of the Song of Lamae",
            [6] = "52247\t52151\t51964\t52116\t52221\t52174\t51999\t51941\t51918\t56651\tBreeches of the Song of Lamae",
            [7] = "52249\t52153\t51966\t52118\t52223\t52176\t52001\t51943\t51920\t56653\tEpaulets of the Song of Lamae",
            [8] = "52250\t52154\t51967\t52119\t52224\t52177\t52002\t51944\t51921\t56654\tSash of the Song of Lamae",
            [9] = "52252\t52155\t51968\t52120\t52225\t52178\t52003\t51945\t51922\t56655\tJack of the Song of Lamae",
            [10] = "52253\t52156\t51969\t52121\t52226\t52179\t52004\t51946\t51923\t56656\tBoots of the Song of Lamae",
            [11] = "52254\t52157\t51970\t52122\t52227\t52180\t52005\t51947\t51924\t56657\tBracers of the Song of Lamae",
            [12] = "52255\t52158\t51971\t52123\t52228\t52181\t52006\t51948\t51925\t56658\tHelmet of the Song of Lamae",
            [13] = "52256\t52159\t51972\t52124\t52229\t52182\t52007\t51949\t51926\t56659\tGuards of the Song of Lamae",
            [14] = "52257\t52160\t51973\t52125\t52230\t52183\t52008\t51950\t51927\t56660\tArm Cops of the Song of Lamae",
            [15] = "52258\t52161\t51974\t52126\t52231\t52184\t52009\t51951\t51928\t56661\tBelt of the Song of Lamae",
        },
        [6] =
        {
            [1] = "52251\t52088\t51890\t52100\t51983\t51902\t52193\t52135\t52205\t56635\tBow of the Song of Lamae",
            [2] = "52259\t52162\t51975\t52127\t52232\t52185\t52010\t51952\t51929\t56662\tShield of the Song of Lamae",
            [3] = "52260\t52089\t51891\t52101\t51984\t51903\t52194\t52136\t52206\t56636\tInferno Staff of the Song of Lamae",
            [4] = "52261\t52090\t51892\t52102\t51985\t51904\t52195\t52137\t52207\t56637\tIce Staff of the Song of Lamae",
            [5] = "52262\t52091\t51893\t52103\t51986\t51905\t52196\t52138\t52208\t56638\tLightning Staff of the Song of Lamae",
            [6] = "52263\t52092\t51894\t52104\t51987\t51906\t52197\t52139\t52209\t56639\tRestoration Staff of the Song of Lamae",
        },
    },
    [13] =
    {
        [1] =
        {
            [1] = "52614\t52462\t52264\t52474\t52357\t52276\t52567\t52509\t52579\t56663\tAxe of Alessia's Bulwark",
            [2] = "52615\t52463\t52265\t52475\t52358\t52277\t52568\t52510\t52580\t56664\tHammer of Alessia's Bulwark",
            [3] = "52616\t52464\t52266\t52476\t52359\t52278\t52569\t52511\t52581\t56665\tSword of Alessia's Bulwark",
            [4] = "52617\t52465\t52267\t52477\t52360\t52279\t52570\t52512\t52582\t56666\tBattle Axe of Alessia's Bulwark",
            [5] = "52618\t52466\t52268\t52478\t52361\t52280\t52571\t52513\t52583\t56667\tMaul of Alessia's Bulwark",
            [6] = "52619\t52467\t52269\t52479\t52362\t52281\t52572\t52514\t52584\t56668\tGreatsword of Alessia's Bulwark",
            [7] = "52620\t52468\t52270\t52480\t52363\t52282\t52573\t52515\t52585\t56669\tDagger of Alessia's Bulwark",
            [8] = "44022\t52521\t52334\t52486\t52591\t52544\t52369\t52311\t52288\t56675\tCuirass of Alessia's Bulwark",
            [9] = "52622\t52522\t52335\t52487\t52592\t52545\t52370\t52312\t52289\t56676\tSabatons of Alessia's Bulwark",
            [10] = "52623\t52523\t52336\t52488\t52593\t52546\t52371\t52313\t52290\t56677\tGauntlets of Alessia's Bulwark",
            [11] = "44019\t52524\t52337\t52489\t52594\t52547\t52372\t52314\t52291\t56678\tHelm of Alessia's Bulwark",
            [12] = "44021\t52525\t52338\t52490\t52595\t52548\t52373\t52315\t52292\t56679\tGreaves of Alessia's Bulwark",
            [13] = "44020\t52526\t52339\t52491\t52596\t52549\t52374\t52316\t52293\t56680\tPauldron of Alessia's Bulwark",
            [14] = "44023\t52527\t52340\t52492\t52597\t52550\t52375\t52317\t52294\t56681\tGirdle of Alessia's Bulwark",
        },
        [2] =
        {
            [1] = "52624\t52528\t52341\t52493\t52598\t52551\t52376\t52318\t52295\t56682\tRobe of Alessia's Bulwark",
            [2] = "52629\t52533\t52346\t52498\t52603\t52556\t52381\t52323\t52300\t56687\tShirt of Alessia's Bulwark",
            [3] = "52625\t52529\t52342\t52494\t52599\t52552\t52377\t52319\t52296\t56683\tShoes of Alessia's Bulwark",
            [4] = "52626\t52530\t52343\t52495\t52600\t52553\t52378\t52320\t52297\t56684\tGloves of Alessia's Bulwark",
            [5] = "52627\t52531\t52344\t52496\t52601\t52554\t52379\t52321\t52298\t56685\tHat of Alessia's Bulwark",
            [6] = "52628\t52532\t52345\t52497\t52602\t52555\t52380\t52322\t52299\t56686\tBreeches of Alessia's Bulwark",
            [7] = "52630\t52534\t52347\t52499\t52604\t52557\t52382\t52324\t52301\t56688\tEpaulets of Alessia's Bulwark",
            [8] = "52631\t52535\t52348\t52500\t52605\t52558\t52383\t52325\t52302\t56689\tSash of Alessia's Bulwark",
            [9] = "52633\t52536\t52349\t52501\t52606\t52559\t52384\t52326\t52303\t56690\tJack of Alessia's Bulwark",
            [10] = "52634\t52537\t52350\t52502\t52607\t52560\t52385\t52327\t52304\t56691\tBoots of Alessia's Bulwark",
            [11] = "52635\t52538\t52351\t52503\t52608\t52561\t52386\t52328\t52305\t56692\tBracers of Alessia's Bulwark",
            [12] = "52636\t52539\t52352\t52504\t52609\t52562\t52387\t52329\t52306\t56693\tHelmet of Alessia's Bulwark",
            [13] = "52637\t52540\t52353\t52505\t52610\t52563\t52388\t52330\t52307\t56694\tGuards of Alessia's Bulwark",
            [14] = "52638\t52541\t52354\t52506\t52611\t52564\t52389\t52331\t52308\t56695\tArm Cops of Alessia's Bulwark",
            [15] = "52639\t52542\t52355\t52507\t52612\t52565\t52390\t52332\t52309\t56696\tBelt of Alessia's Bulwark",
        },
        [6] =
        {
            [1] = "52632\t52469\t52271\t52481\t52364\t52283\t52574\t52516\t52586\t56670\tBow of Alessia's Bulwark",
            [2] = "44024\t52543\t52356\t52508\t52613\t52566\t52391\t52333\t52310\t56697\tShield of Alessia's Bulwark",
            [3] = "52641\t52470\t52272\t52482\t52365\t52284\t52575\t52517\t52587\t56671\tInferno Staff of Alessia's Bulwark",
            [4] = "52642\t52471\t52273\t52483\t52366\t52285\t52576\t52518\t52588\t56672\tIce Staff of Alessia's Bulwark",
            [5] = "52643\t52472\t52274\t52484\t52367\t52286\t52577\t52519\t52589\t56673\tLightning Staff of Alessia's Bulwark",
            [6] = "52644\t52473\t52275\t52485\t52368\t52287\t52578\t52520\t52590\t56674\tRestoration Staff of Alessia's Bulwark",
        },
    },
    [14] =
    {
        [1] =
        {
            [1] = "49180\t49028\t48830\t49040\t48923\t48842\t49133\t49075\t49145\t56348\tAxe of the Night Mother",
            [2] = "49181\t49029\t48831\t49041\t48924\t48843\t49134\t49076\t49146\t56349\tHammer of the Night Mother",
            [3] = "49182\t49030\t48832\t49042\t48925\t48844\t49135\t49077\t49147\t56350\tSword of the Night Mother",
            [4] = "49183\t49031\t48833\t49043\t48926\t48845\t49136\t49078\t49148\t56351\tBattle Axe of the Night Mother",
            [5] = "49184\t49032\t48834\t49044\t48927\t48846\t49137\t49079\t49149\t56352\tMaul of the Night Mother",
            [6] = "49185\t49033\t48835\t49045\t48928\t48847\t49138\t49080\t49150\t56353\tGreatsword of the Night Mother",
            [7] = "49186\t49034\t48836\t49046\t48929\t48848\t49139\t49081\t49151\t56354\tDagger of the Night Mother",
            [8] = "49188\t49087\t48900\t49052\t49157\t49110\t48935\t48877\t48854\t56360\tCuirass of the Night Mother",
            [9] = "49189\t49088\t48901\t49053\t49158\t49111\t48936\t48878\t48855\t56361\tSabatons of the Night Mother",
            [10] = "49190\t49089\t48902\t49054\t49159\t49112\t48937\t48879\t48856\t56362\tGauntlets of the Night Mother",
            [11] = "49191\t49090\t48903\t49055\t49160\t49113\t48938\t48880\t48857\t56363\tHelm of the Night Mother",
            [12] = "49192\t49091\t48904\t49056\t49161\t49114\t48939\t48881\t48858\t56364\tGreaves of the Night Mother",
            [13] = "49193\t49092\t48905\t49057\t49162\t49115\t48940\t48882\t48859\t56365\tPauldron of the Night Mother",
            [14] = "49194\t49093\t48906\t49058\t49163\t49116\t48941\t48883\t48860\t56366\tGirdle of the Night Mother",
        },
        [2] =
        {
            [1] = "49195\t49094\t48907\t49059\t49164\t49117\t48942\t48884\t48861\t56367\tRobe of the Night Mother",
            [2] = "49200\t49099\t48912\t49064\t49169\t49122\t48947\t48889\t48866\t56372\tShirt of the Night Mother",
            [3] = "49196\t49095\t48908\t49060\t49165\t49118\t48943\t48885\t48862\t56368\tShoes of the Night Mother",
            [4] = "49197\t49096\t48909\t49061\t49166\t49119\t48944\t48886\t48863\t56369\tGloves of the Night Mother",
            [5] = "49198\t49097\t48910\t49062\t49167\t49120\t48945\t48887\t48864\t56370\tHat of the Night Mother",
            [6] = "49199\t49098\t48911\t49063\t49168\t49121\t48946\t48888\t48865\t56371\tBreeches of the Night Mother",
            [7] = "49201\t49100\t48913\t49065\t49170\t49123\t48948\t48890\t48867\t56373\tEpaulets of the Night Mother",
            [8] = "49202\t49101\t48914\t49066\t49171\t49124\t48949\t48891\t48868\t56374\tSash of the Night Mother",
            [9] = "43861\t49102\t48915\t49067\t49172\t49125\t48950\t48892\t48869\t56375\tJack of the Night Mother",
            [10] = "49204\t49103\t48916\t49068\t49173\t49126\t48951\t48893\t48870\t56376\tBoots of the Night Mother",
            [11] = "43859\t49104\t48917\t49069\t49174\t49127\t48952\t48894\t48871\t56377\tBracers of the Night Mother",
            [12] = "49205\t49105\t48918\t49070\t49175\t49128\t48953\t48895\t48872\t56378\tHelmet of the Night Mother",
            [13] = "43860\t49106\t48919\t49071\t49176\t49129\t48954\t48896\t48873\t56379\tGuards of the Night Mother",
            [14] = "49206\t49107\t48920\t49072\t49177\t49130\t48955\t48897\t48874\t56380\tArm Cops of the Night Mother",
            [15] = "49207\t49108\t48921\t49073\t49178\t49131\t48956\t48898\t48875\t56381\tBelt of the Night Mother",
        },
        [6] =
        {
            [1] = "49203\t49035\t48837\t49047\t48930\t48849\t49140\t49082\t49152\t56355\tBow of the Night Mother",
            [2] = "49208\t49109\t48922\t49074\t49179\t49132\t48957\t48899\t48876\t56382\tShield of the Night Mother",
            [3] = "49209\t49036\t48838\t49048\t48931\t48850\t49141\t49083\t49153\t56356\tInferno Staff of the Night Mother",
            [4] = "49210\t49037\t48839\t49049\t48932\t48851\t49142\t49084\t49154\t56357\tIce Staff of the Night Mother",
            [5] = "49211\t49038\t48840\t49050\t48933\t48852\t49143\t49085\t49155\t56358\tLightning Staff of the Night Mother",
            [6] = "49212\t49039\t48841\t49051\t48934\t48853\t49144\t49086\t49156\t56359\tRestoration Staff of the Night Mother",
        },
    },
    [15] =
    {
        [1] =
        {
            [1] = "51471\t51319\t51121\t51331\t51214\t51133\t51424\t51366\t51436\t56558\tAxe of the Willow's Path",
            [2] = "51472\t51320\t51122\t51332\t51215\t51134\t51425\t51367\t51437\t56559\tHammer of the Willow's Path",
            [3] = "51473\t51321\t51123\t51333\t51216\t51135\t51426\t51368\t51438\t56560\tSword of the Willow's Path",
            [4] = "51474\t51322\t51124\t51334\t51217\t51136\t51427\t51369\t51439\t56561\tBattle Axe of the Willow's Path",
            [5] = "51475\t51323\t51125\t51335\t51218\t51137\t51428\t51370\t51440\t56562\tMaul of the Willow's Path",
            [6] = "51476\t51324\t51126\t51336\t51219\t51138\t51429\t51371\t51441\t56563\tGreatsword of the Willow's Path",
            [7] = "51477\t51325\t51127\t51337\t51220\t51139\t51430\t51372\t51442\t56564\tDagger of the Willow's Path",
            [8] = "51479\t51378\t51191\t51343\t51448\t51401\t51226\t51168\t51145\t56570\tCuirass of the Willow's Path",
            [9] = "51480\t51379\t51192\t51344\t51449\t51402\t51227\t51169\t51146\t56571\tSabatons of the Willow's Path",
            [10] = "51481\t51380\t51193\t54191\t51450\t51403\t51228\t51170\t51147\t56572\tGauntlets of the Willow's Path",
            [11] = "51482\t51381\t51194\t51346\t51451\t51404\t51229\t51171\t51148\t56573\tHelm of the Willow's Path",
            [12] = "51483\t51382\t51195\t51347\t51452\t51405\t51230\t51172\t51149\t56574\tGreaves of the Willow's Path",
            [13] = "51484\t51383\t51196\t51348\t51453\t51406\t51231\t51173\t51150\t56575\tPauldron of the Willow's Path",
            [14] = "51485\t51384\t51197\t51349\t51454\t51407\t51232\t51174\t51151\t56576\tGirdle of the Willow's Path",
        },
        [2] =
        {
            [1] = "51486\t51385\t51198\t51350\t51455\t51408\t51233\t51175\t51152\t56577\tRobe of the Willow's Path",
            [2] = "51491\t51390\t51203\t51355\t51460\t51413\t51238\t51180\t51157\t56582\tShirt of the Willow's Path",
            [3] = "51487\t51386\t51199\t51351\t51456\t51409\t51234\t51176\t51153\t56578\tShoes of the Willow's Path",
            [4] = "51488\t51387\t51200\t51352\t51457\t51410\t51235\t51177\t51154\t56579\tGloves of the Willow's Path",
            [5] = "51489\t51388\t51201\t51353\t51458\t51411\t51236\t51178\t51155\t56580\tHat of the Willow's Path",
            [6] = "51490\t51389\t51202\t51354\t51459\t51412\t51237\t51179\t51156\t56581\tBreeches of the Willow's Path",
            [7] = "51492\t51391\t51204\t51356\t51461\t51414\t51239\t51181\t51158\t56583\tEpaulets of the Willow's Path",
            [8] = "51493\t51392\t51205\t51357\t51462\t51415\t51240\t51182\t51159\t56584\tSash of the Willow's Path",
            [9] = "44005\t51393\t51206\t51358\t51463\t51416\t51241\t51183\t51160\t56585\tJack of the Willow's Path",
            [10] = "44006\t51394\t51207\t51359\t51464\t51417\t51242\t51184\t51161\t56586\tBoots of the Willow's Path",
            [11] = "44003\t51395\t51208\t51360\t51465\t51418\t51243\t51185\t51162\t56587\tBracers of the Willow's Path",
            [12] = "44001\t51396\t51209\t51361\t51466\t51419\t51244\t51186\t51163\t56588\tHelmet of the Willow's Path",
            [13] = "44004\t51397\t51210\t51362\t51467\t51420\t51245\t51187\t51164\t56589\tGuards of the Willow's Path",
            [14] = "44002\t51398\t51211\t51363\t51468\t51421\t51246\t51188\t51165\t56590\tArm Cops of the Willow's Path",
            [15] = "51495\t51399\t51212\t51364\t51469\t51422\t51247\t51189\t51166\t56591\tBelt of the Willow's Path",
        },
        [6] =
        {
            [1] = "51494\t51326\t51128\t51338\t51221\t51140\t51431\t51373\t51443\t56565\tBow of the Willow's Path",
            [2] = "51497\t51400\t51213\t51365\t51470\t51423\t51248\t51190\t51167\t56592\tShield of the Willow's Path",
            [3] = "51498\t51327\t51129\t51339\t51222\t51141\t51432\t51374\t51444\t56566\tInferno Staff of the Willow's Path",
            [4] = "51499\t51328\t51130\t51340\t51223\t51142\t51433\t51375\t51445\t56567\tIce Staff of the Willow's Path",
            [5] = "51500\t51329\t51131\t51341\t51224\t51143\t51434\t51376\t51446\t56568\tLightning Staff of the Willow's Path",
            [6] = "51501\t51330\t51132\t51342\t51225\t51144\t51435\t51377\t51447\t56569\tRestoration Staff of the Willow's Path",
        },
    },
    [16] =
    {
        [1] =
        {
            [1] = "51852\t51700\t51502\t51712\t51595\t51514\t51805\t51747\t51817\t56593\tAxe of Hunding's Rage",
            [2] = "51853\t51701\t51503\t51713\t51596\t51515\t51806\t51748\t51818\t56594\tHammer of Hunding's Rage",
            [3] = "44011\t51702\t51504\t51714\t51597\t51516\t51807\t51749\t51819\t56595\tSword of Hunding's Rage",
            [4] = "51854\t51703\t51505\t51715\t51598\t51517\t51808\t51750\t51820\t56596\tBattle Axe of Hunding's Rage",
            [5] = "51855\t51704\t51506\t51716\t51599\t51518\t51809\t51751\t51821\t56597\tMaul of Hunding's Rage",
            [6] = "51856\t51705\t51507\t51717\t51600\t51519\t51810\t51752\t51822\t56598\tGreatsword of Hunding's Rage",
            [7] = "44012\t51706\t51508\t51718\t51601\t51520\t51811\t51753\t51823\t56599\tDagger of Hunding's Rage",
            [8] = "51857\t51759\t51572\t51724\t51829\t51782\t51607\t51549\t51526\t56605\tCuirass of Hunding's Rage",
            [9] = "51858\t51760\t51573\t51725\t51830\t51783\t51608\t51550\t51527\t56606\tSabatons of Hunding's Rage",
            [10] = "51859\t51761\t51574\t51726\t51831\t51784\t51609\t51551\t51528\t56607\tGauntlets of Hunding's Rage",
            [11] = "51860\t51762\t51575\t51727\t51832\t51785\t51610\t51552\t51529\t56608\tHelm of Hunding's Rage",
            [12] = "51861\t51763\t51576\t51728\t51833\t51786\t51611\t51553\t51530\t56609\tGreaves of Hunding's Rage",
            [13] = "51862\t51764\t51577\t51729\t51834\t51787\t51612\t51554\t51531\t56610\tPauldron of Hunding's Rage",
            [14] = "51863\t51765\t51578\t51730\t51835\t51788\t51613\t51555\t51532\t56611\tGirdle of Hunding's Rage",
        },
        [2] =
        {
            [1] = "51864\t51766\t51579\t51731\t51836\t51789\t51614\t51556\t51533\t56612\tRobe of Hunding's Rage",
            [2] = "51869\t51771\t51584\t51736\t51841\t51794\t51619\t51561\t51538\t56617\tShirt of Hunding's Rage",
            [3] = "51865\t51767\t51580\t51732\t51837\t51790\t51615\t51557\t51534\t56613\tShoes of Hunding's Rage",
            [4] = "51866\t51768\t51581\t51733\t51838\t51791\t51616\t51558\t51535\t56614\tGloves of Hunding's Rage",
            [5] = "51867\t51769\t51582\t51734\t51839\t51792\t51617\t51559\t51536\t56615\tHat of Hunding's Rage",
            [6] = "51868\t51770\t51583\t51735\t51840\t51793\t51618\t51560\t51537\t56616\tBreeches of Hunding's Rage",
            [7] = "51870\t51772\t51585\t51737\t51842\t51795\t51620\t51562\t51539\t56618\tEpaulets of Hunding's Rage",
            [8] = "51871\t51773\t51586\t51738\t51843\t51796\t51621\t51563\t51540\t56619\tSash of Hunding's Rage",
            [9] = "51873\t51774\t51587\t51739\t51844\t51797\t51622\t51564\t51541\t56620\tJack of Hunding's Rage",
            [10] = "51874\t51775\t51588\t51740\t51845\t51798\t51623\t54192\t51542\t56621\tBoots of Hunding's Rage",
            [11] = "44008\t51776\t51589\t51741\t51846\t51799\t51624\t51566\t51543\t56622\tBracers of Hunding's Rage",
            [12] = "44007\t51777\t51590\t51742\t51847\t51800\t51625\t51567\t51544\t56623\tHelmet of Hunding's Rage",
            [13] = "44009\t51778\t51591\t51743\t51848\t51801\t51626\t51568\t51545\t56624\tGuards of Hunding's Rage",
            [14] = "51875\t51779\t51592\t51744\t51849\t51802\t51627\t51569\t51546\t56625\tArm Cops of Hunding's Rage",
            [15] = "51876\t51780\t51593\t51745\t51850\t51803\t51628\t51570\t51547\t56626\tBelt of Hunding's Rage",
        },
        [6] =
        {
            [1] = "51872\t51707\t51509\t51719\t51602\t51521\t51812\t51754\t51824\t56600\tBow of Hunding's Rage",
            [2] = "51878\t51781\t51594\t51746\t51851\t51804\t51629\t51571\t51548\t56627\tShield of Hunding's Rage",
            [3] = "51879\t51708\t51510\t51720\t51603\t51522\t51813\t51755\t51825\t56601\tInferno Staff of Hunding's Rage",
            [4] = "51880\t51709\t51511\t51721\t51604\t51523\t51814\t51756\t51826\t56602\tIce Staff of Hunding's Rage",
            [5] = "51881\t51710\t51512\t51722\t51605\t51524\t51815\t51757\t51827\t56603\tLightning Staff of Hunding's Rage",
            [6] = "51882\t51711\t51513\t51723\t51606\t51525\t51816\t51758\t51828\t56604\tRestoration Staff of Hunding's Rage",
        },
    },
    [17] =
    {
        [1] =
        {
            [1] = "53757\t53605\t53407\t53617\t53500\t53419\t53710\t53652\t53722\t56768\tAxe of Kagrenac's Hope",
            [2] = "53758\t53606\t53408\t53618\t53501\t53420\t53711\t53653\t53723\t56769\tHammer of Kagrenac's Hope",
            [3] = "53759\t53607\t53409\t53619\t53502\t53421\t53712\t53654\t53724\t56770\tSword of Kagrenac's Hope",
            [4] = "53760\t53608\t53410\t53620\t53503\t53422\t53713\t53655\t53725\t56771\tBattle Axe of Kagrenac's Hope",
            [5] = "53761\t53609\t53411\t53621\t53504\t53423\t53714\t53656\t53726\t56772\tMaul of Kagrenac's Hope",
            [6] = "53762\t53610\t53412\t53622\t53505\t53424\t53715\t53657\t53727\t56773\tGreatsword of Kagrenac's Hope",
            [7] = "53763\t53611\t53413\t53623\t53506\t53425\t53716\t53658\t53728\t56774\tDagger of Kagrenac's Hope",
            [8] = "53765\t53664\t53477\t53629\t53734\t53687\t53512\t53454\t53431\t56780\tCuirass of Kagrenac's Hope",
            [9] = "53766\t53665\t53478\t53630\t53735\t53688\t53513\t53455\t53432\t56781\tSabatons of Kagrenac's Hope",
            [10] = "53767\t53666\t53479\t53631\t53736\t53689\t53514\t53456\t53433\t56782\tGauntlets of Kagrenac's Hope",
            [11] = "53768\t53667\t53480\t53632\t53737\t53690\t53515\t53457\t53434\t56783\tHelm of Kagrenac's Hope",
            [12] = "53769\t53668\t53481\t53633\t53738\t53691\t53516\t53458\t53435\t56784\tGreaves of Kagrenac's Hope",
            [13] = "53770\t53669\t53482\t53634\t53739\t53692\t53517\t53459\t53436\t56785\tPauldron of Kagrenac's Hope",
            [14] = "53771\t53670\t53483\t53635\t53740\t53693\t53518\t53460\t53437\t56786\tGirdle of Kagrenac's Hope",
        },
        [2] =
        {
            [1] = "53772\t53671\t53484\t53636\t53741\t53694\t53519\t53461\t53438\t56787\tRobe of Kagrenac's Hope",
            [2] = "53777\t53676\t53489\t53641\t53746\t53699\t53524\t53466\t53443\t56792\tShirt of Kagrenac's Hope",
            [3] = "53773\t53672\t53485\t53637\t53742\t53695\t53520\t53462\t53439\t56788\tShoes of Kagrenac's Hope",
            [4] = "53774\t53673\t53486\t53638\t53743\t53696\t53521\t53463\t53440\t56789\tGloves of Kagrenac's Hope",
            [5] = "53775\t53674\t53487\t53639\t53744\t53697\t53522\t53464\t53441\t56790\tHat of Kagrenac's Hope",
            [6] = "53776\t53675\t53488\t53640\t53745\t53698\t53523\t53465\t53442\t56791\tBreeches of Kagrenac's Hope",
            [7] = "53778\t53677\t53490\t53642\t53747\t53700\t53525\t53467\t53444\t56793\tEpaulets of Kagrenac's Hope",
            [8] = "53779\t53678\t53491\t53643\t53748\t53701\t53526\t53468\t53445\t56794\tSash of Kagrenac's Hope",
            [9] = "44082\t53679\t53492\t53644\t53749\t53702\t53527\t53469\t53446\t56795\tJack of Kagrenac's Hope",
            [10] = "44084\t53680\t53493\t53645\t53750\t53703\t53528\t53470\t53447\t56796\tBoots of Kagrenac's Hope",
            [11] = "53781\t53681\t53494\t53646\t53751\t53704\t53529\t53471\t53448\t56797\tBracers of Kagrenac's Hope",
            [12] = "44079\t53682\t53495\t53647\t53752\t53705\t53530\t53472\t53449\t56798\tHelmet of Kagrenac's Hope",
            [13] = "44081\t53683\t53496\t53648\t53753\t53706\t53531\t53473\t53450\t56799\tGuards of Kagrenac's Hope",
            [14] = "44080\t53684\t53497\t53649\t53754\t53707\t53532\t53474\t53451\t56800\tArm Cops of Kagrenac's Hope",
            [15] = "44083\t53685\t53498\t53650\t53755\t53708\t53533\t53475\t53452\t56801\tBelt of Kagrenac's Hope",
        },
        [6] =
        {
            [1] = "53780\t53612\t53414\t53624\t53507\t53426\t53717\t53659\t53729\t56775\tBow of Kagrenac's Hope",
            [2] = "53783\t53686\t53499\t53651\t53756\t53709\t53534\t53476\t53453\t56802\tShield of Kagrenac's Hope",
            [3] = "53784\t53613\t53415\t53625\t53508\t53427\t53718\t53660\t53730\t56776\tInferno Staff of Kagrenac's Hope",
            [4] = "53785\t53614\t53416\t53626\t53509\t53428\t53719\t53661\t53731\t56777\tIce Staff of Kagrenac's Hope",
            [5] = "53786\t53615\t53417\t53627\t53510\t53429\t53720\t53662\t53732\t56778\tLightning Staff of Kagrenac's Hope",
            [6] = "53787\t53616\t53418\t53628\t53511\t53430\t53721\t53663\t53733\t56779\tRestoration Staff of Kagrenac's Hope",
        },
    },
    [18] =
    {
        [1] =
        {
            [1] = "52995\t52843\t52645\t52855\t52738\t52657\t52948\t52890\t52960\t56698\tAxe of Orgnum's Scales",
            [2] = "52996\t52844\t52646\t52856\t52739\t52658\t52949\t52891\t52961\t56699\tHammer of Orgnum's Scales",
            [3] = "52997\t52845\t52647\t52857\t52740\t52659\t52950\t52892\t52962\t56700\tSword of Orgnum's Scales",
            [4] = "52998\t52846\t52648\t52858\t52741\t52660\t52951\t52893\t52963\t56701\tBattle Axe of Orgnum's Scales",
            [5] = "52999\t52847\t52649\t52859\t52742\t52661\t52952\t52894\t52964\t56702\tMaul of Orgnum's Scales",
            [6] = "53000\t52848\t52650\t52860\t52743\t52662\t52953\t52895\t52965\t56703\tGreatsword of Orgnum's Scales",
            [7] = "53001\t52849\t52651\t52861\t52744\t52663\t52954\t52896\t52966\t56704\tDagger of Orgnum's Scales",
            [8] = "44033\t52902\t52715\t52867\t52972\t52925\t52750\t52692\t52669\t56710\tCuirass of Orgnum's Scales",
            [9] = "44034\t52903\t52716\t52868\t52973\t52926\t52751\t52693\t52670\t56711\tSabatons of Orgnum's Scales",
            [10] = "53003\t52904\t52717\t52869\t52974\t52927\t52752\t52694\t52671\t56712\tGauntlets of Orgnum's Scales",
            [11] = "44031\t52905\t52718\t52870\t52975\t52928\t52753\t52695\t52672\t56713\tHelm of Orgnum's Scales",
            [12] = "44032\t52906\t52719\t52871\t52976\t52929\t52754\t52696\t52673\t56714\tGreaves of Orgnum's Scales",
            [13] = "53004\t52907\t52720\t52872\t52977\t52930\t52755\t52697\t52674\t56715\tPauldron of Orgnum's Scales",
            [14] = "53005\t52908\t52721\t52873\t52978\t52931\t52756\t52698\t52675\t56716\tGirdle of Orgnum's Scales",
        },
        [2] =
        {
            [1] = "53006\t52909\t52722\t52874\t52979\t52932\t52757\t52699\t52676\t56717\tRobe of Orgnum's Scales",
            [2] = "53011\t52914\t52727\t52879\t52984\t52937\t52762\t52704\t52681\t56722\tShirt of Orgnum's Scales",
            [3] = "53007\t52910\t52723\t52875\t52980\t52933\t52758\t52700\t52677\t56718\tShoes of Orgnum's Scales",
            [4] = "53008\t52911\t52724\t52876\t52981\t52934\t52759\t52701\t52678\t56719\tGloves of Orgnum's Scales",
            [5] = "53009\t52912\t52725\t52877\t52982\t52935\t52760\t52702\t52679\t56720\tHat of Orgnum's Scales",
            [6] = "53010\t52913\t52726\t52878\t52983\t52936\t52761\t52703\t52680\t56721\tBreeches of Orgnum's Scales",
            [7] = "53012\t52915\t52728\t52880\t52985\t52938\t52763\t52705\t52682\t56723\tEpaulets of Orgnum's Scales",
            [8] = "53013\t52916\t52729\t52881\t52986\t52939\t52764\t52706\t52683\t56724\tSash of Orgnum's Scales",
            [9] = "53015\t52917\t52730\t52882\t52987\t52940\t52765\t52707\t52684\t56725\tJack of Orgnum's Scales",
            [10] = "53016\t52918\t52731\t52883\t52988\t52941\t52766\t52708\t52685\t56726\tBoots of Orgnum's Scales",
            [11] = "53017\t52919\t52732\t52884\t52989\t52942\t52767\t52709\t52686\t56727\tBracers of Orgnum's Scales",
            [12] = "53018\t52920\t52733\t52885\t52990\t52943\t52768\t52710\t52687\t56728\tHelmet of Orgnum's Scales",
            [13] = "53019\t52921\t52734\t52886\t52991\t52944\t52769\t52711\t52688\t56729\tGuards of Orgnum's Scales",
            [14] = "53020\t52922\t52735\t52887\t52992\t52945\t52770\t52712\t52689\t56730\tArm Cops of Orgnum's Scales",
            [15] = "53021\t52923\t52736\t52888\t52993\t52946\t52771\t52713\t52690\t56731\tBelt of Orgnum's Scales",
        },
        [6] =
        {
            [1] = "53014\t52850\t52652\t52862\t52745\t52664\t52955\t52897\t52967\t56705\tBow of Orgnum's Scales",
            [2] = "44036\t52924\t52737\t52889\t52994\t52947\t52772\t52714\t52691\t56732\tShield of Orgnum's Scales",
            [3] = "53022\t52851\t52653\t52863\t52746\t52665\t52956\t52898\t52968\t56706\tInferno Staff of Orgnum's Scales",
            [4] = "53023\t52852\t52654\t52864\t52747\t52666\t52957\t52899\t52969\t56707\tIce Staff of Orgnum's Scales",
            [5] = "53024\t52853\t52655\t52865\t52748\t52667\t52958\t52900\t52970\t56708\tLightning Staff of Orgnum's Scales",
            [6] = "53025\t52854\t52656\t52866\t52749\t52668\t52959\t52901\t52971\t56709\tRestoration Staff of Orgnum's Scales",
        },
    },
    [19] =
    {
        [1] =
        {
            [1] = "53376\t53224\t53026\t53236\t53119\t53038\t53329\t53271\t53341\t56733\tAxe of the Eyes of Mara",
            [2] = "53377\t53225\t53027\t53237\t53120\t53039\t53330\t53272\t53342\t56734\tHammer of the Eyes of Mara",
            [3] = "53378\t53226\t53028\t53238\t53121\t53040\t53331\t53273\t53343\t56735\tSword of the Eyes of Mara",
            [4] = "53379\t53227\t53029\t53239\t53122\t53041\t53332\t53274\t53344\t56736\tBattle Axe of the Eyes of Mara",
            [5] = "53380\t53228\t53030\t53240\t53123\t53042\t53333\t53275\t53345\t56737\tMaul of the Eyes of Mara",
            [6] = "53381\t53229\t53031\t53241\t53124\t53043\t53334\t53276\t53346\t56738\tGreatsword of the Eyes of Mara",
            [7] = "53382\t53230\t53032\t53242\t53125\t53044\t53335\t53277\t53347\t56739\tDagger of the Eyes of Mara",
            [8] = "53384\t53283\t53096\t53248\t53353\t53306\t53131\t53073\t53050\t56745\tCuirass of the Eyes of Mara",
            [9] = "53385\t53284\t53097\t53249\t53354\t53307\t53132\t53074\t53051\t56746\tSabatons of the Eyes of Mara",
            [10] = "53386\t53285\t53098\t53250\t53355\t53308\t53133\t53075\t53052\t56747\tGauntlets of the Eyes of Mara",
            [11] = "53387\t53286\t53099\t53251\t53356\t53309\t53134\t53076\t53053\t56748\tHelm of the Eyes of Mara",
            [12] = "53388\t53287\t53100\t53252\t53357\t53310\t53135\t53077\t53054\t56749\tGreaves of the Eyes of Mara",
            [13] = "53389\t53288\t53101\t53253\t53358\t53311\t53136\t53078\t53055\t56750\tPauldron of the Eyes of Mara",
            [14] = "53390\t53289\t53102\t53254\t53359\t53312\t53137\t53079\t53056\t56751\tGirdle of the Eyes of Mara",
        },
        [2] =
        {
            [1] = "44053\t53290\t53103\t53255\t53360\t53313\t53138\t53080\t53057\t56752\tRobe of the Eyes of Mara",
            [2] = "53392\t53295\t53108\t53260\t53365\t53318\t53143\t53085\t53062\t56757\tShirt of the Eyes of Mara",
            [3] = "53391\t53291\t53104\t53256\t53361\t53314\t53139\t53081\t53058\t56753\tShoes of the Eyes of Mara",
            [4] = "44051\t53292\t53105\t53257\t53362\t53315\t53140\t53082\t53059\t56754\tGloves of the Eyes of Mara",
            [5] = "44049\t53293\t53106\t53258\t53363\t53316\t53141\t53083\t53060\t56755\tHat of the Eyes of Mara",
            [6] = "44052\t53294\t53107\t53259\t53364\t53317\t53142\t53084\t53061\t56756\tBreeches of the Eyes of Mara",
            [7] = "44050\t53296\t53109\t53261\t53366\t53319\t53144\t53086\t53063\t56758\tEpaulets of the Eyes of Mara",
            [8] = "44054\t53297\t53110\t53262\t53367\t53320\t53145\t53087\t53064\t56759\tSash of the Eyes of Mara",
            [9] = "53394\t53298\t53111\t53263\t53368\t53321\t53146\t53088\t53065\t56760\tJack of the Eyes of Mara",
            [10] = "53395\t53299\t53112\t53264\t53369\t53322\t53147\t53089\t53066\t56761\tBoots of the Eyes of Mara",
            [11] = "53396\t53300\t53113\t53265\t53370\t53323\t53148\t53090\t53067\t56762\tBracers of the Eyes of Mara",
            [12] = "53397\t53301\t53114\t53266\t53371\t53324\t53149\t53091\t53068\t56763\tHelmet of the Eyes of Mara",
            [13] = "53398\t53302\t53115\t53267\t53372\t53325\t53150\t53092\t53069\t56764\tGuards of the Eyes of Mara",
            [14] = "53399\t53303\t53116\t53268\t53373\t53326\t53151\t53093\t53070\t56765\tArm Cops of the Eyes of Mara",
            [15] = "53400\t53304\t53117\t53269\t53374\t53327\t53152\t53094\t53071\t56766\tBelt of the Eyes of Mara",
        },
        [6] =
        {
            [1] = "53393\t53231\t53033\t53243\t53126\t53045\t53336\t53278\t53348\t56740\tBow of the Eyes of Mara",
            [2] = "53402\t53305\t53118\t53270\t53375\t53328\t53153\t53095\t53072\t56767\tShield of the Eyes of Mara",
            [3] = "53403\t53232\t53034\t53244\t53127\t53046\t53337\t53279\t53349\t56741\tInferno Staff of the Eyes of Mara",
            [4] = "53404\t53233\t53035\t53245\t53128\t53047\t53338\t53280\t53350\t56742\tIce Staff of the Eyes of Mara",
            [5] = "53405\t53234\t53036\t53246\t53129\t53048\t53339\t53281\t53351\t56743\tLightning Staff of the Eyes of Mara",
            [6] = "53406\t53235\t53037\t53247\t53130\t53049\t53340\t53282\t53352\t56744\tRestoration Staff of the Eyes of Mara",
        },
    },
    [20] =
    {
        [1] =
        {
            [1] = "54138\t53986\t53788\t53998\t53881\t53800\t54091\t54033\t54103\t56803\tAxe of Shalidor's Curse",
            [2] = "54139\t53987\t53789\t53999\t53882\t53801\t54092\t54034\t54104\t56804\tHammer of Shalidor's Curse",
            [3] = "54140\t53988\t53790\t54000\t53883\t53802\t54093\t54035\t54105\t56805\tSword of Shalidor's Curse",
            [4] = "54141\t53989\t53791\t54001\t53884\t53803\t54094\t54036\t54106\t56806\tBattle Axe of Shalidor's Curse",
            [5] = "54142\t53990\t53792\t54002\t53885\t53804\t54095\t54037\t54107\t56807\tMaul of Shalidor's Curse",
            [6] = "54143\t53991\t53793\t54003\t53886\t53805\t54096\t54038\t54108\t56808\tGreatsword of Shalidor's Curse",
            [7] = "54144\t53992\t53794\t54004\t53887\t53806\t54097\t54039\t54109\t56809\tDagger of Shalidor's Curse",
            [8] = "44102\t54045\t53858\t54010\t54115\t54068\t53893\t53835\t53812\t56815\tCuirass of Shalidor's Curse",
            [9] = "54146\t54046\t53859\t54011\t54116\t54069\t53894\t53836\t53813\t56816\tSabatons of Shalidor's Curse",
            [10] = "44100\t54047\t53860\t54012\t54117\t54070\t53895\t53837\t53814\t56817\tGauntlets of Shalidor's Curse",
            [11] = "44099\t54048\t53861\t54013\t54118\t54071\t53896\t53838\t53815\t56818\tHelm of Shalidor's Curse",
            [12] = "44101\t54049\t53862\t54014\t54119\t54072\t53897\t53839\t53816\t56819\tGreaves of Shalidor's Curse",
            [13] = "54147\t54050\t53863\t54015\t54120\t54073\t53898\t53840\t53817\t56820\tPauldron of Shalidor's Curse",
            [14] = "54148\t54051\t53864\t54016\t54121\t54074\t53899\t53841\t53818\t56821\tGirdle of Shalidor's Curse",
        },
        [2] =
        {
            [1] = "54149\t54052\t53865\t54017\t54122\t54075\t53900\t53842\t53819\t56822\tRobe of Shalidor's Curse",
            [2] = "54154\t54057\t53870\t54022\t54127\t54080\t53905\t53847\t53824\t56827\tShirt of Shalidor's Curse",
            [3] = "54150\t54053\t53866\t54018\t54123\t54076\t53901\t53843\t53820\t56823\tShoes of Shalidor's Curse",
            [4] = "54151\t54054\t53867\t54019\t54124\t54077\t53902\t53844\t53821\t56824\tGloves of Shalidor's Curse",
            [5] = "54152\t54055\t53868\t54020\t54125\t54078\t53903\t53845\t53822\t56825\tHat of Shalidor's Curse",
            [6] = "54153\t54056\t53869\t54021\t54126\t54079\t53904\t53846\t53823\t56826\tBreeches of Shalidor's Curse",
            [7] = "54155\t54058\t53871\t54023\t54128\t54081\t53906\t53848\t53825\t56828\tEpaulets of Shalidor's Curse",
            [8] = "54156\t54059\t53872\t54024\t54129\t54082\t53907\t53849\t53826\t56829\tSash of Shalidor's Curse",
            [9] = "54158\t54060\t53873\t54025\t54130\t54083\t53908\t53850\t53827\t56830\tJack of Shalidor's Curse",
            [10] = "54159\t54061\t53874\t54026\t54131\t54084\t53909\t53851\t53828\t56831\tBoots of Shalidor's Curse",
            [11] = "54160\t54062\t53875\t54027\t54132\t54085\t53910\t53852\t53829\t56832\tBracers of Shalidor's Curse",
            [12] = "54161\t54063\t53876\t54028\t54133\t54086\t53911\t53853\t53830\t56833\tHelmet of Shalidor's Curse",
            [13] = "54162\t54064\t53877\t54029\t54134\t54087\t53912\t53854\t53831\t56834\tGuards of Shalidor's Curse",
            [14] = "54163\t54065\t53878\t54030\t54135\t54088\t53913\t53855\t53832\t56835\tArm Cops of Shalidor's Curse",
            [15] = "54164\t54066\t53879\t54031\t54136\t54089\t53914\t53856\t53833\t56836\tBelt of Shalidor's Curse",
        },
        [6] =
        {
            [1] = "54157\t53993\t53795\t54005\t53888\t53807\t54098\t54040\t54110\t56810\tBow of Shalidor's Curse",
            [2] = "54165\t54067\t53880\t54032\t54137\t54090\t53915\t53857\t53834\t56837\tShield of Shalidor's Curse",
            [3] = "44104\t53994\t53796\t54006\t53889\t53808\t54099\t54041\t54111\t56811\tInferno Staff of Shalidor's Curse",
            [4] = "54166\t53995\t53797\t54007\t53890\t53809\t54100\t54042\t54112\t56812\tIce Staff of Shalidor's Curse",
            [5] = "54167\t53996\t53798\t54008\t53891\t53810\t54101\t54043\t54113\t56813\tLightning Staff of Shalidor's Curse",
            [6] = "54168\t53997\t53799\t54009\t53892\t53811\t54102\t54044\t54114\t56814\tRestoration Staff of Shalidor's Curse",
        },
    },
    [21] =
    {
        [1] =
        {
            [1] = "49946\t49794\t49596\t49806\t49689\t49608\t49899\t49841\t49911\t56418\tAxe of Oblivion's Foe",
            [2] = "49947\t49795\t49597\t49807\t49690\t49609\t49900\t49842\t49912\t56419\tHammer of Oblivion's Foe",
            [3] = "49948\t49796\t49598\t49808\t49691\t49610\t49901\t49843\t49913\t56420\tSword of Oblivion's Foe",
            [4] = "49949\t49797\t49599\t49809\t49692\t49611\t49902\t49844\t49914\t56421\tBattle Axe of Oblivion's Foe",
            [5] = "49950\t49798\t49600\t49810\t49693\t49612\t49903\t49845\t49915\t56422\tMaul of Oblivion's Foe",
            [6] = "49951\t49799\t49601\t49811\t49694\t49613\t49904\t49846\t49916\t56423\tGreatsword of Oblivion's Foe",
            [7] = "49952\t49800\t49602\t49812\t49695\t49614\t49905\t49847\t49917\t56424\tDagger of Oblivion's Foe",
            [8] = "49954\t49853\t49666\t49818\t49923\t49876\t49701\t49643\t49620\t56430\tCuirass of Oblivion's Foe",
            [9] = "49955\t49854\t49667\t49819\t49924\t49877\t49702\t49644\t49621\t56431\tSabatons of Oblivion's Foe",
            [10] = "49956\t49855\t49668\t49820\t49925\t49878\t49703\t49645\t49622\t56432\tGauntlets of Oblivion's Foe",
            [11] = "49957\t49856\t49669\t49821\t49926\t49879\t49704\t49646\t49623\t56433\tHelm of Oblivion's Foe",
            [12] = "49958\t49857\t49670\t49822\t49927\t49880\t49705\t49647\t49624\t56434\tGreaves of Oblivion's Foe",
            [13] = "49959\t49858\t49671\t49823\t49928\t49881\t49706\t49648\t49625\t56435\tPauldron of Oblivion's Foe",
            [14] = "49960\t49859\t49672\t49824\t49929\t49882\t49707\t49649\t49626\t56436\tGirdle of Oblivion's Foe",
        },
        [2] =
        {
            [1] = "43968\t49860\t49673\t49825\t49930\t49883\t49708\t49650\t49627\t56437\tRobe of Oblivion's Foe",
            [2] = "49962\t49865\t49678\t49830\t49935\t49888\t49713\t49655\t49632\t56442\tShirt of Oblivion's Foe",
            [3] = "43969\t49861\t49674\t49826\t49931\t49884\t49709\t49651\t49628\t56438\tShoes of Oblivion's Foe",
            [4] = "49961\t49862\t49675\t49827\t49932\t49885\t49710\t49652\t49629\t56439\tGloves of Oblivion's Foe",
            [5] = "43965\t49863\t49676\t49828\t49933\t49886\t49711\t49653\t49630\t56440\tHat of Oblivion's Foe",
            [6] = "43967\t49864\t49677\t49829\t49934\t49887\t49712\t49654\t49631\t56441\tBreeches of Oblivion's Foe",
            [7] = "43966\t49866\t49679\t49831\t49936\t49889\t49714\t49656\t49633\t56443\tEpaulets of Oblivion's Foe",
            [8] = "49963\t49867\t49680\t49832\t49937\t49890\t49715\t49657\t49634\t56444\tSash of Oblivion's Foe",
            [9] = "49965\t49868\t49681\t49833\t49938\t49891\t49716\t49658\t49635\t56445\tJack of Oblivion's Foe",
            [10] = "49966\t49869\t49682\t49834\t49939\t49892\t49717\t49659\t49636\t56446\tBoots of Oblivion's Foe",
            [11] = "49967\t49870\t49683\t49835\t49940\t49893\t49718\t49660\t49637\t56447\tBracers of Oblivion's Foe",
            [12] = "49968\t49871\t49684\t49836\t49941\t49894\t49719\t49661\t49638\t56448\tHelmet of Oblivion's Foe",
            [13] = "49969\t49872\t49685\t49837\t49942\t49895\t49720\t49662\t49639\t56449\tGuards of Oblivion's Foe",
            [14] = "49970\t49873\t49686\t49838\t49943\t49896\t49721\t49663\t49640\t56450\tArm Cops of Oblivion's Foe",
            [15] = "49971\t49874\t49687\t49839\t49944\t49897\t49722\t49664\t49641\t56451\tBelt of Oblivion's Foe",
        },
        [6] =
        {
            [1] = "49964\t49801\t49603\t49813\t49696\t49615\t49906\t49848\t49918\t56425\tBow of Oblivion's Foe",
            [2] = "49972\t49875\t49688\t49840\t49945\t49898\t49723\t49665\t49642\t56452\tShield of Oblivion's Foe",
            [3] = "49973\t49802\t49604\t49814\t49697\t49616\t49907\t49849\t49919\t56426\tInferno Staff of Oblivion's Foe",
            [4] = "49974\t49803\t49605\t49815\t49698\t49617\t49908\t49850\t49920\t56427\tIce Staff of Oblivion's Foe",
            [5] = "49975\t49804\t49606\t49816\t49699\t49618\t49909\t49851\t49921\t56428\tLightning Staff of Oblivion's Foe",
            [6] = "49976\t49805\t49607\t49817\t49700\t49619\t49910\t49852\t49922\t56429\tRestoration Staff of Oblivion's Foe",
        },
    },
    [22] =
    {
        [1] =
        {
            [1] = "50327\t50175\t49977\t50187\t50070\t49989\t50280\t50222\t50292\t56453\tAxe of the Spectre's Eye",
            [2] = "50328\t50176\t49978\t50188\t50071\t49990\t50281\t50223\t50293\t56454\tHammer of the Spectre's Eye",
            [3] = "50329\t50177\t49979\t50189\t50072\t49991\t50282\t50224\t50294\t56455\tSword of the Spectre's Eye",
            [4] = "50330\t50178\t49980\t50190\t50073\t49992\t50283\t50225\t50295\t56456\tBattle Axe of the Spectre's Eye",
            [5] = "50331\t50179\t49981\t50191\t50074\t49993\t50284\t50226\t50296\t56457\tMaul of the Spectre's Eye",
            [6] = "50332\t50180\t49982\t50192\t50075\t49994\t50285\t50227\t50297\t56458\tGreatsword of the Spectre's Eye",
            [7] = "50333\t50181\t49983\t50193\t50076\t49995\t50286\t50228\t50298\t56459\tDagger of the Spectre's Eye",
            [8] = "50335\t50234\t50047\t50199\t50304\t50257\t50082\t50024\t50001\t56465\tCuirass of the Spectre's Eye",
            [9] = "50336\t50235\t50048\t50200\t50305\t50258\t50083\t50025\t50002\t56466\tSabatons of the Spectre's Eye",
            [10] = "50337\t50236\t50049\t50201\t50306\t50259\t50084\t50026\t50003\t56467\tGauntlets of the Spectre's Eye",
            [11] = "50338\t50237\t50050\t50202\t50307\t50260\t50085\t50027\t50004\t56468\tHelm of the Spectre's Eye",
            [12] = "50339\t50238\t50051\t50203\t50308\t50261\t50086\t50028\t50005\t56469\tGreaves of the Spectre's Eye",
            [13] = "50340\t50239\t50052\t50204\t50309\t50262\t50087\t50029\t50006\t56470\tPauldron of the Spectre's Eye",
            [14] = "50341\t50240\t50053\t50205\t50310\t50263\t50088\t50030\t50007\t56471\tGirdle of the Spectre's Eye",
        },
        [2] =
        {
            [1] = "43972\t50241\t50054\t50206\t50311\t50264\t50089\t50031\t50008\t56472\tRobe of the Spectre's Eye",
            [2] = "50343\t50246\t50059\t50211\t50316\t50269\t50094\t50036\t50013\t56477\tShirt of the Spectre's Eye",
            [3] = "43974\t50242\t50055\t50207\t50312\t50265\t50090\t50032\t50009\t56473\tShoes of the Spectre's Eye",
            [4] = "43975\t50243\t50056\t50208\t50313\t50266\t50091\t50033\t50010\t56474\tGloves of the Spectre's Eye",
            [5] = "43971\t50244\t50057\t50209\t50314\t50267\t50092\t50034\t50011\t56475\tHat of the Spectre's Eye",
            [6] = "50342\t50245\t50058\t50210\t50315\t50268\t50093\t50035\t50012\t56476\tBreeches of the Spectre's Eye",
            [7] = "43973\t50247\t50060\t50212\t50317\t50270\t50095\t50037\t50014\t56478\tEpaulets of the Spectre's Eye",
            [8] = "50344\t50248\t50061\t50213\t50318\t50271\t50096\t50038\t50015\t56479\tSash of the Spectre's Eye",
            [9] = "50346\t50249\t50062\t50214\t50319\t50272\t50097\t50039\t50016\t56480\tJack of the Spectre's Eye",
            [10] = "50347\t50250\t50063\t50215\t50320\t50273\t50098\t50040\t50017\t56481\tBoots of the Spectre's Eye",
            [11] = "50348\t50251\t50064\t50216\t50321\t50274\t50099\t50041\t50018\t56482\tBracers of the Spectre's Eye",
            [12] = "50349\t50252\t50065\t50217\t50322\t50275\t50100\t50042\t50019\t56483\tHelmet of the Spectre's Eye",
            [13] = "50350\t50253\t50066\t50218\t50323\t50276\t50101\t50043\t50020\t56484\tGuards of the Spectre's Eye",
            [14] = "50351\t50254\t50067\t50219\t50324\t50277\t50102\t50044\t50021\t56485\tArm Cops of the Spectre's Eye",
            [15] = "50352\t50255\t50068\t50220\t50325\t50278\t50103\t50045\t50022\t56486\tBelt of the Spectre's Eye",
        },
        [6] =
        {
            [1] = "50345\t50182\t49984\t50194\t50077\t49996\t50287\t50229\t50299\t56460\tBow of the Spectre's Eye",
            [2] = "50354\t50256\t50069\t50221\t50326\t50279\t50104\t50046\t50023\t56487\tShield of the Spectre's Eye",
            [3] = "50355\t50183\t49985\t50195\t50078\t49997\t50288\t50230\t50300\t56461\tInferno Staff of the Spectre's Eye",
            [4] = "50356\t50184\t49986\t50196\t50079\t49998\t50289\t50231\t50301\t56462\tIce Staff of the Spectre's Eye",
            [5] = "50357\t50185\t49987\t50197\t50080\t49999\t50290\t50232\t50302\t56463\tLightning Staff of the Spectre's Eye",
            [6] = "43976\t50186\t49988\t50198\t50081\t50000\t50291\t50233\t50303\t56464\tRestoration Staff of the Spectre's Eye",
        },
    },
    [23] =
    {
        [1] =
        {
            [1] = "54965\t54810\t55039\t55074\t55109\t55144\t55179\t55214\t55249\t56069\tAxe of the Arena",
            [2] = "54966\t54811\t55040\t55075\t55110\t55145\t55180\t55215\t55250\t56070\tHammer of the Arena",
            [3] = "54964\t54809\t55038\t55073\t55108\t55143\t55178\t55213\t55248\t56068\tSword of the Arena",
            [4] = "54968\t54813\t55042\t55077\t55112\t55147\t55182\t55217\t55252\t56072\tBattle Axe of the Arena",
            [5] = "54969\t54814\t55043\t55078\t55113\t55148\t55183\t55218\t55253\t56073\tMaul of the Arena",
            [6] = "54967\t54812\t55041\t55076\t55111\t55146\t55181\t55216\t55251\t56071\tGreatsword of the Arena",
            [7] = "54970\t54815\t55044\t55079\t55114\t55149\t55184\t55219\t55254\t56074\tDagger of the Arena",
            [8] = "54942\t54787\t54822\t55051\t55086\t55121\t55156\t55191\t55226\t56080\tCuirass of the Arena",
            [9] = "54948\t54793\t55022\t55057\t55092\t55127\t55162\t55197\t55232\t56086\tSabatons of the Arena",
            [10] = "54945\t54790\t55019\t55054\t55089\t55124\t55159\t55194\t55229\t56083\tGauntlets of the Arena",
            [11] = "54943\t54788\t55017\t55052\t55087\t55122\t55157\t55192\t55227\t56081\tHelm of the Arena",
            [12] = "54947\t54792\t55021\t55056\t55091\t55126\t55161\t55196\t55231\t56085\tGreaves of the Arena",
            [13] = "54944\t54789\t55018\t55053\t55088\t55123\t55158\t55193\t55228\t56082\tPauldron of the Arena",
            [14] = "54946\t54791\t55020\t55055\t55090\t55125\t55160\t55195\t55230\t56084\tGirdle of the Arena",
        },
        [2] =
        {
            [1] = "54963\t54808\t55037\t55072\t55107\t55142\t55177\t55212\t55247\t56101\tRobe of the Arena",
            [2] = "54956\t54801\t55030\t55065\t55100\t55135\t55170\t55205\t55240\t56094\tShirt of the Arena",
            [3] = "54962\t54807\t55036\t55071\t55106\t55141\t55176\t55211\t55246\t56100\tShoes of the Arena",
            [4] = "54959\t54804\t55033\t55068\t55103\t55138\t55173\t55208\t55243\t56097\tGloves of the Arena",
            [5] = "54957\t54802\t55031\t55066\t55101\t55136\t55171\t55206\t55241\t56095\tHat of the Arena",
            [6] = "54961\t54806\t55035\t55070\t55105\t55140\t55175\t55210\t55245\t56099\tBreeches of the Arena",
            [7] = "54958\t54803\t55032\t55067\t55102\t55137\t55172\t55207\t55242\t56096\tEpaulets of the Arena",
            [8] = "54960\t54805\t55034\t55069\t55104\t55139\t55174\t55209\t55244\t56098\tSash of the Arena",
            [9] = "54949\t54794\t55023\t55058\t55093\t55128\t55163\t55198\t55233\t56087\tJack of the Arena",
            [10] = "54955\t54800\t55029\t55064\t55099\t55134\t55169\t55204\t55239\t56093\tBoots of the Arena",
            [11] = "54952\t54797\t55026\t55061\t55096\t55131\t55166\t55201\t55236\t56090\tBracers of the Arena",
            [12] = "54950\t54795\t55024\t55059\t55094\t55129\t55164\t55199\t55234\t56088\tHelmet of the Arena",
            [13] = "54954\t54799\t55028\t55063\t55098\t55133\t55168\t55203\t55238\t56092\tGuards of the Arena",
            [14] = "54951\t54796\t55025\t55060\t55095\t55130\t55165\t55200\t55235\t56089\tArm Cops of the Arena",
            [15] = "54953\t54798\t55027\t55062\t55097\t55132\t55167\t55202\t55237\t56091\tBelt of the Arena",
        },
        [6] =
        {
            [1] = "54971\t54816\t55045\t55080\t55115\t55150\t55185\t55220\t55255\t56075\tBow of the Arena",
            [2] = "54976\t54821\t55050\t55085\t55120\t55155\t55190\t55225\t55260\t56102\tShield of the Arena",
            [3] = "54972\t54817\t55046\t55081\t55116\t55151\t55186\t55221\t55256\t56076\tInferno Staff of the Arena",
            [4] = "54973\t54818\t55047\t55082\t55117\t55152\t55187\t55222\t55257\t56077\tIce Staff of the Arena",
            [5] = "54974\t54819\t55048\t55083\t55118\t55153\t55188\t55223\t55258\t56078\tLightning Staff of the Arena",
            [6] = "54975\t54820\t55049\t55084\t55119\t55154\t55189\t55224\t55259\t56079\tRestoration Staff of the Arena",
        },
    },
    [24] =
    {
        [1] =
        {
            [1] = "58175\t58245\t58280\t58315\t58350\t58385\t58420\t58455\t58490\t58210\tAxe of the Twice-Born Star",
            [2] = "58177\t58247\t58282\t58317\t58352\t58387\t58422\t58457\t58492\t58212\tHammer of the Twice-Born Star",
            [3] = "58176\t58246\t58281\t58316\t58351\t58386\t58421\t58456\t58491\t58211\tSword of the Twice-Born Star",
            [4] = "58178\t58248\t58283\t58318\t58353\t58388\t58423\t58458\t58493\t58213\tBattle Axe of the Twice-Born Star",
            [5] = "58179\t58249\t58284\t58319\t58354\t58389\t58424\t58459\t58494\t58214\tMaul of the Twice-Born Star",
            [6] = "58180\t58250\t58285\t58320\t58355\t58390\t58425\t58460\t58495\t58215\tGreatsword of the Twice-Born Star",
            [7] = "58181\t58251\t58286\t58321\t58356\t58391\t58426\t58461\t58496\t58216\tDagger of the Twice-Born Star",
            [8] = "58154\t58224\t58259\t58294\t58329\t58364\t58399\t58434\t58469\t58189\tCuirass of the Twice-Born Star",
            [9] = "58159\t58229\t58264\t58299\t58334\t58369\t58404\t58439\t58474\t58194\tSabatons of the Twice-Born Star",
            [10] = "58156\t58226\t58261\t58296\t58331\t58366\t58401\t58436\t58471\t58191\tGauntlets of the Twice-Born Star",
            [11] = "58153\t58223\t58258\t58293\t58328\t58363\t58398\t58433\t58468\t58188\tHelm of the Twice-Born Star",
            [12] = "58158\t58228\t58263\t58298\t58333\t58368\t58403\t58438\t58473\t58193\tGreaves of the Twice-Born Star",
            [13] = "58155\t58225\t58260\t58295\t58330\t58365\t58400\t58435\t58470\t58190\tPauldron of the Twice-Born Star",
            [14] = "58157\t58227\t58262\t58297\t58332\t58367\t58402\t58437\t58472\t58192\tGirdle of the Twice-Born Star",
        },
        [2] =
        {
            [1] = "58174\t58238\t58273\t58308\t58343\t58378\t58413\t58448\t58483\t58203\tRobe of the Twice-Born Star",
            [2] = "58168\t58239\t58274\t58309\t58344\t58379\t58414\t58449\t58484\t58204\tShirt of the Twice-Born Star",
            [3] = "58173\t58244\t58279\t58314\t58349\t58384\t58419\t58454\t58489\t58209\tShoes of the Twice-Born Star",
            [4] = "58170\t58241\t58276\t58311\t58346\t58381\t58416\t58451\t58486\t58206\tGloves of the Twice-Born Star",
            [5] = "58167\t58237\t58272\t58307\t58342\t58377\t58412\t58447\t58482\t58202\tHat of the Twice-Born Star",
            [6] = "58172\t58243\t58278\t58313\t58348\t58383\t58418\t58453\t58488\t58208\tBreeches of the Twice-Born Star",
            [7] = "58169\t58240\t58275\t58310\t58345\t58380\t58415\t58450\t58485\t58205\tEpaulets of the Twice-Born Star",
            [8] = "58171\t58242\t58277\t58312\t58347\t58382\t58417\t58452\t58487\t58207\tSash of the Twice-Born Star",
            [9] = "58161\t58231\t58266\t58301\t58336\t58371\t58406\t58441\t58476\t58196\tJack of the Twice-Born Star",
            [10] = "58166\t58236\t58271\t58306\t58341\t58376\t58411\t58446\t58481\t58201\tBoots of the Twice-Born Star",
            [11] = "58163\t58233\t58268\t58303\t58338\t58373\t58408\t58443\t58478\t58198\tBracers of the Twice-Born Star",
            [12] = "58160\t58230\t58265\t58300\t58335\t58370\t58405\t58440\t58475\t58195\tHelmet of the Twice-Born Star",
            [13] = "58165\t58235\t58270\t58305\t58340\t58375\t58410\t58445\t58480\t58200\tGuards of the Twice-Born Star",
            [14] = "58162\t58232\t58267\t58302\t58337\t58372\t58407\t58442\t58477\t58197\tArm Cops of the Twice-Born Star",
            [15] = "58164\t58234\t58269\t58304\t58339\t58374\t58409\t58444\t58479\t58199\tBelt of the Twice-Born Star",
        },
        [6] =
        {
            [1] = "58182\t58252\t58287\t58322\t58357\t58392\t58427\t58462\t58497\t58217\tBow of the Twice-Born Star",
            [2] = "58183\t58253\t58288\t58323\t58358\t58393\t58428\t58463\t58498\t58218\tShield of the Twice-Born Star",
            [3] = "58184\t58254\t58289\t58324\t58359\t58394\t58429\t58464\t58499\t58219\tInferno Staff of the Twice-Born Star",
            [4] = "58185\t58255\t58290\t58325\t58360\t58395\t58430\t58465\t58500\t58220\tIce Staff of the Twice-Born Star",
            [5] = "58186\t58256\t58291\t58326\t58361\t58396\t58431\t58466\t58501\t58221\tLightning Staff of the Twice-Born Star",
            [6] = "58187\t58257\t58292\t58327\t58362\t58397\t58432\t58467\t58502\t58222\tRestoration Staff of the Twice-Born Star",
        },
    },
    [25] =
    {
        [1] =
        {
            [1] = "60261\t59946\t59981\t60016\t60051\t60086\t60121\t60156\t60191\t60226\taxe of the Noble's Conquest",
            [2] = "60262\t59947\t59982\t60017\t60052\t60087\t60122\t60157\t60192\t60227\tmace of the Noble's Conquest",
            [3] = "60263\t59948\t59983\t60018\t60053\t60088\t60123\t60158\t60193\t60228\tSword of the Noble's Conquest",
            [4] = "60264\t59949\t59984\t60019\t60054\t60089\t60124\t60159\t60194\t60229\tBattle Axe of the Noble's Conquest",
            [5] = "60265\t59950\t59985\t60020\t60055\t60090\t60125\t60160\t60195\t60230\tMaul of the Noble's Conquest",
            [6] = "60266\t59951\t59986\t60021\t60056\t60091\t60126\t60161\t60196\t60231\tGreatsword of the Noble's Conquest",
            [7] = "60267\t59952\t59987\t60022\t60057\t60092\t60127\t60162\t60197\t60232\tDagger of the Noble's Conquest",
            [8] = "60273\t59958\t59993\t60028\t60063\t60098\t60133\t60168\t60203\t60238\tCuirass of the Noble's Conquest",
            [9] = "60274\t59959\t59994\t60029\t60064\t60099\t60134\t60169\t60204\t60239\tSabatons of the Noble's Conquest",
            [10] = "60275\t59960\t59995\t60030\t60065\t60100\t60135\t60170\t60205\t60240\tGauntlets of the Noble's Conquest",
            [11] = "60276\t59961\t59996\t60031\t60066\t60101\t60136\t60171\t60206\t60241\tHelm of the Noble's Conquest",
            [12] = "60277\t59962\t59997\t60032\t60067\t60102\t60137\t60172\t60207\t60242\tGreaves of the Noble's Conquest",
            [13] = "60278\t59963\t59998\t60033\t60068\t60103\t60138\t60173\t60208\t60243\tPauldron of the Noble's Conquest",
            [14] = "60279\t59964\t59999\t60034\t60069\t60104\t60139\t60174\t60209\t60244\tGirdle of the Noble's Conquest",
        },
        [2] =
        {
            [1] = "60280\t59965\t60000\t60035\t60070\t60105\t60140\t60175\t60210\t60245\tRobe of the Noble's Conquest",
            [2] = "60285\t59970\t60005\t60040\t60075\t60110\t60145\t60180\t60215\t60250\tJerkin of the Noble's Conquest",
            [3] = "60281\t59966\t60001\t60036\t60071\t60106\t60141\t60176\t60211\t60246\tShoes of the Noble's Conquest",
            [4] = "60282\t59967\t60002\t60037\t60072\t60107\t60142\t60177\t60212\t60247\tGloves of the Noble's Conquest",
            [5] = "60283\t59968\t60003\t60038\t60073\t60108\t60143\t60178\t60213\t60248\tHat of the Noble's Conquest",
            [6] = "60284\t59969\t60004\t60039\t60074\t60109\t60144\t60179\t60214\t60249\tBreeches of the Noble's Conquest",
            [7] = "60286\t59971\t60006\t60041\t60076\t60111\t60146\t60181\t60216\t60251\tEpaulets of the Noble's Conquest",
            [8] = "60287\t59972\t60007\t60042\t60077\t60112\t60147\t60182\t60217\t60252\tSash of the Noble's Conquest",
            [9] = "60288\t59973\t60008\t60043\t60078\t60113\t60148\t60183\t60218\t60253\tJack of the Noble's Conquest",
            [10] = "60289\t59974\t60009\t60044\t60079\t60114\t60149\t60184\t60219\t60254\tBoots of the Noble's Conquest",
            [11] = "60290\t59975\t60010\t60045\t60080\t60115\t60150\t60185\t60220\t60255\tBracers of the Noble's Conquest",
            [12] = "60291\t59976\t60011\t60046\t60081\t60116\t60151\t60186\t60221\t60256\tHelmet of the Noble's Conquest",
            [13] = "60292\t59977\t60012\t60047\t60082\t60117\t60152\t60187\t60222\t60257\tGuards of the Noble's Conquest",
            [14] = "60293\t59978\t60013\t60048\t60083\t60118\t60153\t60188\t60223\t60258\tArm Cops of the Noble's Conquest",
            [15] = "60294\t59979\t60014\t60049\t60084\t60119\t60154\t60189\t60224\t60259\tBelt of the Noble's Conquest",
        },
        [6] =
        {
            [1] = "60268\t59953\t59988\t60023\t60058\t60093\t60128\t60163\t60198\t60233\tBow of the Noble's Conquest",
            [2] = "60295\t59980\t60015\t60050\t60085\t60120\t60155\t60190\t60225\t60260\tShield of the Noble's Conquest",
            [3] = "60269\t59954\t59989\t60024\t60059\t60094\t60129\t60164\t60199\t60234\tInferno Staff of the Noble's Conquest",
            [4] = "60270\t59955\t59990\t60025\t60060\t60095\t60130\t60165\t60200\t60235\tIce Staff of the Noble's Conquest",
            [5] = "60271\t59956\t59991\t60026\t60061\t60096\t60131\t60166\t60201\t60236\tLightning Staff of the Noble's Conquest",
            [6] = "60272\t59957\t59992\t60027\t60062\t60097\t60132\t60167\t60202\t60237\tRestoration Staff of the Noble's Conquest",
        },
    },
    [26] =
    {
        [1] =
        {
            [1] = "60611\t60296\t60331\t60366\t60401\t60436\t60471\t60506\t60541\t60576\taxe of Redistribution",
            [2] = "60612\t60297\t60332\t60367\t60402\t60437\t60472\t60507\t60542\t60577\tmace of Redistribution",
            [3] = "60613\t60298\t60333\t60368\t60403\t60438\t60473\t60508\t60543\t60578\tSword of Redistribution",
            [4] = "60614\t60299\t60334\t60369\t60404\t60439\t60474\t60509\t60544\t60579\tBattle Axe of Redistribution",
            [5] = "60615\t60300\t60335\t60370\t60405\t60440\t60475\t60510\t60545\t60580\tMaul of Redistribution",
            [6] = "60616\t60301\t60336\t60371\t60406\t60441\t60476\t60511\t60546\t60581\tGreatsword of Redistribution",
            [7] = "60617\t60302\t60337\t60372\t60407\t60442\t60477\t60512\t60547\t60582\tDagger of Redistribution",
            [8] = "60623\t60308\t60343\t60378\t60413\t60448\t60483\t60518\t60553\t60588\tCuirass of Redistribution",
            [9] = "60624\t60309\t60344\t60379\t60414\t60449\t60484\t60519\t60554\t60589\tSabatons of Redistribution",
            [10] = "60625\t60310\t60345\t60380\t60415\t60450\t60485\t60520\t60555\t60590\tGauntlets of Redistribution",
            [11] = "60626\t60311\t60346\t60381\t60416\t60451\t60486\t60521\t60556\t60591\tHelm of Redistribution",
            [12] = "60627\t60312\t60347\t60382\t60417\t60452\t60487\t60522\t60557\t60592\tGreaves of Redistribution",
            [13] = "60628\t60313\t60348\t60383\t60418\t60453\t60488\t60523\t60558\t60593\tPauldron of Redistribution",
            [14] = "60629\t60314\t60349\t60384\t60419\t60454\t60489\t60524\t60559\t60594\tGirdle of Redistribution",
        },
        [2] =
        {
            [1] = "60630\t60315\t60350\t60385\t60420\t60455\t60490\t60525\t60560\t60595\tRobe of Redistribution",
            [2] = "60635\t60320\t60355\t60390\t60425\t60460\t60495\t60530\t60565\t60600\tJerkin of Redistribution",
            [3] = "60631\t60316\t60351\t60386\t60421\t60456\t60491\t60526\t60561\t60596\tShoes of Redistribution",
            [4] = "60632\t60317\t60352\t60387\t60422\t60457\t60492\t60527\t60562\t60597\tGloves of Redistribution",
            [5] = "60633\t60318\t60353\t60388\t60423\t60458\t60493\t60528\t60563\t60598\tHat of Redistribution",
            [6] = "60634\t60319\t60354\t60389\t60424\t60459\t60494\t60529\t60564\t60599\tBreeches of Redistribution",
            [7] = "60636\t60321\t60356\t60391\t60426\t60461\t60496\t60531\t60566\t60601\tEpaulets of Redistribution",
            [8] = "60637\t60322\t60357\t60392\t60427\t60462\t60497\t60532\t60567\t60602\tSash of Redistribution",
            [9] = "60638\t60323\t60358\t60393\t60428\t60463\t60498\t60533\t60568\t60603\tJack of Redistribution",
            [10] = "60639\t60324\t60359\t60394\t60429\t60464\t60499\t60534\t60569\t60604\tBoots of Redistribution",
            [11] = "60640\t60325\t60360\t60395\t60430\t60465\t60500\t60535\t60570\t60605\tBracers of Redistribution",
            [12] = "60641\t60326\t60361\t60396\t60431\t60466\t60501\t60536\t60571\t60606\tHelmet of Redistribution",
            [13] = "60642\t60327\t60362\t60397\t60432\t60467\t60502\t60537\t60572\t60607\tGuards of Redistribution",
            [14] = "60643\t60328\t60363\t60398\t60433\t60468\t60503\t60538\t60573\t60608\tArm Cops of Redistribution",
            [15] = "60644\t60329\t60364\t60399\t60434\t60469\t60504\t60539\t60574\t60609\tBelt of Redistribution",
        },
        [6] =
        {
            [1] = "60618\t60303\t60338\t60373\t60408\t60443\t60478\t60513\t60548\t60583\tBow of Redistribution",
            [2] = "60645\t60330\t60365\t60400\t60435\t60470\t60505\t60540\t60575\t60610\tShield of Redistribution",
            [3] = "60619\t60304\t60339\t60374\t60409\t60444\t60479\t60514\t60549\t60584\tInferno Staff of Redistribution",
            [4] = "60620\t60305\t60340\t60375\t60410\t60445\t60480\t60515\t60550\t60585\tIce Staff of Redistribution",
            [5] = "60621\t60306\t60341\t60376\t60411\t60446\t60481\t60516\t60551\t60586\tLightning Staff of Redistribution",
            [6] = "60622\t60307\t60342\t60377\t60412\t60447\t60482\t60517\t60552\t60587\tRestoration Staff of Redistribution",
        },
    },
    [27] =
    {
        [1] =
        {
            [1] = "60961\t60646\t60681\t60716\t60751\t60786\t60821\t60856\t60891\t60926\taxe of the Armor Master",
            [2] = "60962\t60647\t60682\t60717\t60752\t60787\t60822\t60857\t60892\t60927\tmace of the Armor Master",
            [3] = "60963\t60648\t60683\t60718\t60753\t60788\t60823\t60858\t60893\t60928\tSword of the Armor Master",
            [4] = "60964\t60649\t60684\t60719\t60754\t60789\t60824\t60859\t60894\t60929\tBattle Axe of the Armor Master",
            [5] = "60965\t60650\t60685\t60720\t60755\t60790\t60825\t60860\t60895\t60930\tMaul of the Armor Master",
            [6] = "60966\t60651\t60686\t60721\t60756\t60791\t60826\t60861\t60896\t60931\tGreatsword of the Armor Master",
            [7] = "60967\t60652\t60687\t60722\t60757\t60792\t60827\t60862\t60897\t60932\tDagger of the Armor Master",
            [8] = "60973\t60658\t60693\t60728\t60763\t60798\t60833\t60868\t60903\t60938\tCuirass of the Armor Master",
            [9] = "60974\t60659\t60694\t60729\t60764\t60799\t60834\t60869\t60904\t60939\tSabatons of the Armor Master",
            [10] = "60975\t60660\t60695\t60730\t60765\t60800\t60835\t60870\t60905\t60940\tGauntlets of the Armor Master",
            [11] = "60976\t60661\t60696\t60731\t60766\t60801\t60836\t60871\t60906\t60941\tHelm of the Armor Master",
            [12] = "60977\t60662\t60697\t60732\t60767\t60802\t60837\t60872\t60907\t60942\tGreaves of the Armor Master",
            [13] = "60978\t60663\t60698\t60733\t60768\t60803\t60838\t60873\t60908\t60943\tPauldron of the Armor Master",
            [14] = "60979\t60664\t60699\t60734\t60769\t60804\t60839\t60874\t60909\t60944\tGirdle of the Armor Master",
        },
        [2] =
        {
            [1] = "60980\t60665\t60700\t60735\t60770\t60805\t60840\t60875\t60910\t60945\tRobe of the Armor Master",
            [2] = "60985\t60670\t60705\t60740\t60775\t60810\t60845\t60880\t60915\t60950\tJerkin of the Armor Master",
            [3] = "60981\t60666\t60701\t60736\t60771\t60806\t60841\t60876\t60911\t60946\tShoes of the Armor Master",
            [4] = "60982\t60667\t60702\t60737\t60772\t60807\t60842\t60877\t60912\t60947\tGloves of the Armor Master",
            [5] = "60983\t60668\t60703\t60738\t60773\t60808\t60843\t60878\t60913\t60948\tHat of the Armor Master",
            [6] = "60984\t60669\t60704\t60739\t60774\t60809\t60844\t60879\t60914\t60949\tBreeches of the Armor Master",
            [7] = "60986\t60671\t60706\t60741\t60776\t60811\t60846\t60881\t60916\t60951\tEpaulets of the Armor Master",
            [8] = "60987\t60672\t60707\t60742\t60777\t60812\t60847\t60882\t60917\t60952\tSash of the Armor Master",
            [9] = "60988\t60673\t60708\t60743\t60778\t60813\t60848\t60883\t60918\t60953\tJack of the Armor Master",
            [10] = "60989\t60674\t60709\t60744\t60779\t60814\t60849\t60884\t60919\t60954\tBoots of the Armor Master",
            [11] = "60990\t60675\t60710\t60745\t60780\t60815\t60850\t60885\t60920\t60955\tBracers of the Armor Master",
            [12] = "60991\t60676\t60711\t60746\t60781\t60816\t60851\t60886\t60921\t60956\tHelmet of the Armor Master",
            [13] = "60992\t60677\t60712\t60747\t60782\t60817\t60852\t60887\t60922\t60957\tGuards of the Armor Master",
            [14] = "60993\t60678\t60713\t60748\t60783\t60818\t60853\t60888\t60923\t60958\tArm Cops of the Armor Master",
            [15] = "60994\t60679\t60714\t60749\t60784\t60819\t60854\t60889\t60924\t60959\tBelt of the Armor Master",
        },
        [6] =
        {
            [1] = "60968\t60653\t60688\t60723\t60758\t60793\t60828\t60863\t60898\t60933\tBow of the Armor Master",
            [2] = "60995\t60680\t60715\t60750\t60785\t60820\t60855\t60890\t60925\t60960\tShield of the Armor Master",
            [3] = "60969\t60654\t60689\t60724\t60759\t60794\t60829\t60864\t60899\t60934\tInferno Staff of the Armor Master",
            [4] = "60970\t60655\t60690\t60725\t60760\t60795\t60830\t60865\t60900\t60935\tIce Staff of the Armor Master",
            [5] = "60971\t60656\t60691\t60726\t60761\t60796\t60831\t60866\t60901\t60936\tLightning Staff of the Armor Master",
            [6] = "60972\t60657\t60692\t60727\t60762\t60797\t60832\t60867\t60902\t60937\tRestoration Staff of the Armor Master",
        },
    },
    [28] =
    {
        [1] =
        {
            [1] = "69949\t70019\t70054\t70089\t70124\t70159\t70194\t70229\t70264\t69984\taxe of Trials",
            [2] = "69951\t70021\t70056\t70091\t70126\t70161\t70196\t70231\t70266\t69986\tmace of Trials",
            [3] = "69950\t70020\t70055\t70090\t70125\t70160\t70195\t70230\t70265\t69985\tSword of Trials",
            [4] = "69952\t70022\t70057\t70092\t70127\t70162\t70197\t70232\t70267\t69987\tBattle Axe of Trials",
            [5] = "69953\t70023\t70058\t70093\t70128\t70163\t70198\t70233\t70268\t69988\tMaul of Trials",
            [6] = "69954\t70024\t70059\t70094\t70129\t70164\t70199\t70234\t70269\t69989\tGreatsword of Trials",
            [7] = "69955\t70025\t70060\t70095\t70130\t70165\t70200\t70235\t70270\t69990\tDagger of Trials",
            [8] = "69928\t69998\t70033\t70068\t70103\t70138\t70173\t70208\t70243\t69963\tCuirass of Trials",
            [9] = "69933\t70003\t70038\t70073\t70108\t70143\t70178\t70213\t70248\t69968\tSabatons of Trials",
            [10] = "69930\t70000\t70035\t70070\t70105\t70140\t70175\t70210\t70245\t69965\tGauntlets of Trials",
            [11] = "69927\t69997\t70032\t70067\t70102\t70137\t70172\t70207\t70242\t69962\tHelm of Trials",
            [12] = "69932\t70002\t70037\t70072\t70107\t70142\t70177\t70212\t70247\t69967\tGreaves of Trials",
            [13] = "69929\t69999\t70034\t70069\t70104\t70139\t70174\t70209\t70244\t69964\tPauldron of Trials",
            [14] = "69931\t70001\t70036\t70071\t70106\t70141\t70176\t70211\t70246\t69966\tGirdle of Trials",
        },
        [2] =
        {
            [1] = "69942\t70012\t70047\t70082\t70117\t70152\t70187\t70222\t70257\t69977\tRobe of Trials",
            [2] = "69943\t70013\t70048\t70083\t70118\t70153\t70188\t70223\t70258\t69978\tJerkin of Trials",
            [3] = "69948\t70018\t70053\t70088\t70123\t70158\t70193\t70228\t70263\t69983\tShoes of Trials",
            [4] = "69945\t70015\t70050\t70085\t70120\t70155\t70190\t70225\t70260\t69980\tGloves of Trials",
            [5] = "69941\t70011\t70046\t70081\t70116\t70151\t70186\t70221\t70256\t69976\tHat of Trials",
            [6] = "69947\t70017\t70052\t70087\t70122\t70157\t70192\t70227\t70262\t69982\tBreeches of Trials",
            [7] = "69944\t70014\t70049\t70084\t70119\t70154\t70189\t70224\t70259\t69979\tEpaulets of Trials",
            [8] = "69946\t70016\t70051\t70086\t70121\t70156\t70191\t70226\t70261\t69981\tSash of Trials",
            [9] = "69935\t70005\t70040\t70075\t70110\t70145\t70180\t70215\t70250\t69970\tJack of Trials",
            [10] = "69940\t70010\t70045\t70080\t70115\t70150\t70185\t70220\t70255\t69975\tBoots of Trials",
            [11] = "69937\t70007\t70042\t70077\t70112\t70147\t70182\t70217\t70252\t69972\tBracers of Trials",
            [12] = "69934\t70004\t70039\t70074\t70109\t70144\t70179\t70214\t70249\t69969\tHelmet of Trials",
            [13] = "69939\t70009\t70044\t70079\t70114\t70149\t70184\t70219\t70254\t69974\tGuards of Trials",
            [14] = "69936\t70006\t70041\t70076\t70111\t70146\t70181\t70216\t70251\t69971\tArm Cops of Trials",
            [15] = "69938\t70008\t70043\t70078\t70113\t70148\t70183\t70218\t70253\t69973\tBelt of Trials",
        },
        [6] =
        {
            [1] = "69956\t70026\t70061\t70096\t70131\t70166\t70201\t70236\t70271\t69991\tBow of Trials",
            [2] = "69957\t70027\t70062\t70097\t70132\t70167\t70202\t70237\t70272\t69992\tShield of Trials",
            [3] = "69958\t70028\t70063\t70098\t70133\t70168\t70203\t70238\t70273\t69993\tInferno Staff of Trials",
            [4] = "69959\t70029\t70064\t70099\t70134\t70169\t70204\t70239\t70274\t69994\tIce Staff of Trials",
            [5] = "69960\t70030\t70065\t70100\t70135\t70170\t70205\t70240\t70275\t69995\tLightning Staff of Trials",
            [6] = "69961\t70031\t70066\t70101\t70136\t70171\t70206\t70241\t70276\t69996\tRestoration Staff of Trials",
        },
    },
    [29] =
    {
        [1] =
        {
            [1] = "69599\t69669\t69704\t69739\t69774\t69809\t69844\t69879\t69914\t69634\taxe of Julianos",
            [2] = "69601\t69671\t69706\t69741\t69776\t69811\t69846\t69881\t69916\t69636\tmace of Julianos",
            [3] = "69600\t69670\t69705\t69740\t69775\t69810\t69845\t69880\t69915\t69635\tSword of Julianos",
            [4] = "69602\t69672\t69707\t69742\t69777\t69812\t69847\t69882\t69917\t69637\tBattle Axe of Julianos",
            [5] = "69603\t69673\t69708\t69743\t69778\t69813\t69848\t69883\t69918\t69638\tMaul of Julianos",
            [6] = "69604\t69674\t69709\t69744\t69779\t69814\t69849\t69884\t69919\t69639\tGreatsword of Julianos",
            [7] = "69605\t69675\t69710\t69745\t69780\t69815\t69850\t69885\t69920\t69640\tDagger of Julianos",
            [8] = "69578\t69648\t69683\t69718\t69753\t69788\t69823\t69858\t69893\t69613\tCuirass of Julianos",
            [9] = "69583\t69653\t69688\t69723\t69758\t69793\t69828\t69863\t69898\t69618\tSabatons of Julianos",
            [10] = "69580\t69650\t69685\t69720\t69755\t69790\t69825\t69860\t69895\t69615\tGauntlets of Julianos",
            [11] = "69577\t69647\t69682\t69717\t69752\t69787\t69822\t69857\t69892\t69612\tHelm of Julianos",
            [12] = "69582\t69652\t69687\t69722\t69757\t69792\t69827\t69862\t69897\t69617\tGreaves of Julianos",
            [13] = "69579\t69649\t69684\t69719\t69754\t69789\t69824\t69859\t69894\t69614\tPauldron of Julianos",
            [14] = "69581\t69651\t69686\t69721\t69756\t69791\t69826\t69861\t69896\t69616\tGirdle of Julianos",
        },
        [2] =
        {
            [1] = "69592\t69662\t69697\t69732\t69767\t69802\t69837\t69872\t69907\t69627\tRobe of Julianos",
            [2] = "69593\t69663\t69698\t69733\t69768\t69803\t69838\t69873\t69908\t69628\tJerkin of Julianos",
            [3] = "69598\t69668\t69703\t69738\t69773\t69808\t69843\t69878\t69913\t69633\tShoes of Julianos",
            [4] = "69595\t69665\t69700\t69735\t69770\t69805\t69840\t69875\t69910\t69630\tGloves of Julianos",
            [5] = "69591\t69661\t69696\t69731\t69766\t69801\t69836\t69871\t69906\t69626\tHat of Julianos",
            [6] = "69597\t69667\t69702\t69737\t69772\t69807\t69842\t69877\t69912\t69632\tBreeches of Julianos",
            [7] = "69594\t69664\t69699\t69734\t69769\t69804\t69839\t69874\t69909\t69629\tEpaulets of Julianos",
            [8] = "69596\t69666\t69701\t69736\t69771\t69806\t69841\t69876\t69911\t69631\tSash of Julianos",
            [9] = "69585\t69655\t69690\t69725\t69760\t69795\t69830\t69865\t69900\t69620\tJack of Julianos",
            [10] = "69590\t69660\t69695\t69730\t69765\t69800\t69835\t69870\t69905\t69625\tBoots of Julianos",
            [11] = "69587\t69657\t69692\t69727\t69762\t69797\t69832\t69867\t69902\t69622\tBracers of Julianos",
            [12] = "69584\t69654\t69689\t69724\t69759\t69794\t69829\t69864\t69899\t69619\tHelmet of Julianos",
            [13] = "69589\t69659\t69694\t69729\t69764\t69799\t69834\t69869\t69904\t69624\tGuards of Julianos",
            [14] = "69586\t69656\t69691\t69726\t69761\t69796\t69831\t69866\t69901\t69621\tArm Cops of Julianos",
            [15] = "69588\t69658\t69693\t69728\t69763\t69798\t69833\t69868\t69903\t69623\tBelt of Julianos",
        },
        [6] =
        {
            [1] = "69606\t69676\t69711\t69746\t69781\t69816\t69851\t69886\t69921\t69641\tBow of Julianos",
            [2] = "69607\t69677\t69712\t69747\t69782\t69817\t69852\t69887\t69922\t69642\tShield of Julianos",
            [3] = "69608\t69678\t69713\t69748\t69783\t69818\t69853\t69888\t69923\t69643\tInferno Staff of Julianos",
            [4] = "69609\t69679\t69714\t69749\t69784\t69819\t69854\t69889\t69924\t69644\tIce Staff of Julianos",
            [5] = "69610\t69680\t69715\t69750\t69785\t69820\t69855\t69890\t69925\t69645\tLightning Staff of Julianos",
            [6] = "69611\t69681\t69716\t69751\t69786\t69821\t69856\t69891\t69926\t69646\tRestoration Staff of Julianos",
        },
    },
    [30] =
    {
        [1] =
        {
            [1] = "70649\t70719\t70754\t70789\t70824\t70859\t70894\t70929\t70964\t70684\taxe of Morkuldin",
            [2] = "70651\t70721\t70756\t70791\t70826\t70861\t70896\t70931\t70966\t70686\tmace of Morkuldin",
            [3] = "70650\t70720\t70755\t70790\t70825\t70860\t70895\t70930\t70965\t70685\tSword of Morkuldin",
            [4] = "70652\t70722\t70757\t70792\t70827\t70862\t70897\t70932\t70967\t70687\tBattle Axe of Morkuldin",
            [5] = "70653\t70723\t70758\t70793\t70828\t70863\t70898\t70933\t70968\t70688\tMaul of Morkuldin",
            [6] = "70654\t70724\t70759\t70794\t70829\t70864\t70899\t70934\t70969\t70689\tGreatsword of Morkuldin",
            [7] = "70655\t70725\t70760\t70795\t70830\t70865\t70900\t70935\t70970\t70690\tDagger of Morkuldin",
            [8] = "70628\t70698\t70733\t70768\t70803\t70838\t70873\t70908\t70943\t70663\tCuirass of Morkuldin",
            [9] = "70633\t70703\t70738\t70773\t70808\t70843\t70878\t70913\t70948\t70668\tSabatons of Morkuldin",
            [10] = "70630\t70700\t70735\t70770\t70805\t70840\t70875\t70910\t70945\t70665\tGauntlets of Morkuldin",
            [11] = "70627\t70697\t70732\t70767\t70802\t70837\t70872\t70907\t70942\t70662\tHelm of Morkuldin",
            [12] = "70632\t70702\t70737\t70772\t70807\t70842\t70877\t70912\t70947\t70667\tGreaves of Morkuldin",
            [13] = "70629\t70699\t70734\t70769\t70804\t70839\t70874\t70909\t70944\t70664\tPauldron of Morkuldin",
            [14] = "70631\t70701\t70736\t70771\t70806\t70841\t70876\t70911\t70946\t70666\tGirdle of Morkuldin",
        },
        [2] =
        {
            [1] = "70642\t70712\t70747\t70782\t70817\t70852\t70887\t70922\t70957\t70677\tRobe of Morkuldin",
            [2] = "70643\t70713\t70748\t70783\t70818\t70853\t70888\t70923\t70958\t70678\tJerkin of Morkuldin",
            [3] = "70648\t70718\t70753\t70788\t70823\t70858\t70893\t70928\t70963\t70683\tShoes of Morkuldin",
            [4] = "70645\t70715\t70750\t70785\t70820\t70855\t70890\t70925\t70960\t70680\tGloves of Morkuldin",
            [5] = "70641\t70711\t70746\t70781\t70816\t70851\t70886\t70921\t70956\t70676\tHat of Morkuldin",
            [6] = "70647\t70717\t70752\t70787\t70822\t70857\t70892\t70927\t70962\t70682\tBreeches of Morkuldin",
            [7] = "70644\t70714\t70749\t70784\t70819\t70854\t70889\t70924\t70959\t70679\tEpaulets of Morkuldin",
            [8] = "70646\t70716\t70751\t70786\t70821\t70856\t70891\t70926\t70961\t70681\tSash of Morkuldin",
            [9] = "70635\t70705\t70740\t70775\t70810\t70845\t70880\t70915\t70950\t70670\tJack of Morkuldin",
            [10] = "70640\t70710\t70745\t70780\t70815\t70850\t70885\t70920\t70955\t70675\tBoots of Morkuldin",
            [11] = "70637\t70707\t70742\t70777\t70812\t70847\t70882\t70917\t70952\t70672\tBracers of Morkuldin",
            [12] = "70634\t70704\t70739\t70774\t70809\t70844\t70879\t70914\t70949\t70669\tHelmet of Morkuldin",
            [13] = "70639\t70709\t70744\t70779\t70814\t70849\t70884\t70919\t70954\t70674\tGuards of Morkuldin",
            [14] = "70636\t70706\t70741\t70776\t70811\t70846\t70881\t70916\t70951\t70671\tArm Cops of Morkuldin",
            [15] = "70638\t70708\t70743\t70778\t70813\t70848\t70883\t70918\t70953\t70673\tBelt of Morkuldin",
        },
        [6] =
        {
            [1] = "70656\t70726\t70761\t70796\t70831\t70866\t70901\t70936\t70971\t70691\tBow of Morkuldin",
            [2] = "70657\t70727\t70762\t70797\t70832\t70867\t70902\t70937\t70972\t70692\tShield of Morkuldin",
            [3] = "70658\t70728\t70763\t70798\t70833\t70868\t70903\t70938\t70973\t70693\tInferno Staff of Morkuldin",
            [4] = "70659\t70729\t70764\t70799\t70834\t70869\t70904\t70939\t70974\t70694\tIce Staff of Morkuldin",
            [5] = "70660\t70730\t70765\t70800\t70835\t70870\t70905\t70940\t70975\t70695\tLightning Staff of Morkuldin",
            [6] = "70661\t70731\t70766\t70801\t70836\t70871\t70906\t70941\t70976\t70696\tRestoration Staff of Morkuldin",
        },
    },
    [31] =
    {
        [1] =
        {
            [1] = "71813\t71883\t71918\t71953\t71988\t72023\t72058\t72093\t72128\t71848\taxe of Tava's Favor",
            [2] = "71815\t71885\t71920\t71955\t71990\t72025\t72060\t72095\t72130\t71850\tmace of Tava's Favor",
            [3] = "71814\t71884\t71919\t71954\t71989\t72024\t72059\t72094\t72129\t71849\tSword of Tava's Favor",
            [4] = "71816\t71886\t71921\t71956\t71991\t72026\t72061\t72096\t72131\t71851\tBattle Axe of Tava's Favor",
            [5] = "71817\t71887\t71922\t71957\t71992\t72027\t72062\t72097\t72132\t71852\tMaul of Tava's Favor",
            [6] = "71818\t71888\t71923\t71958\t71993\t72028\t72063\t72098\t72133\t71853\tGreatsword of Tava's Favor",
            [7] = "71819\t71889\t71924\t71959\t71994\t72029\t72064\t72099\t72134\t71854\tDagger of Tava's Favor",
            [8] = "71792\t71862\t71897\t71932\t71967\t72002\t72037\t72072\t72107\t71827\tCuirass of Tava's Favor",
            [9] = "71797\t71867\t71902\t71937\t71972\t72007\t72042\t72077\t72112\t71832\tSabatons of Tava's Favor",
            [10] = "71794\t71864\t71899\t71934\t71969\t72004\t72039\t72074\t72109\t71829\tGauntlets of Tava's Favor",
            [11] = "71791\t71861\t71896\t71931\t71966\t72001\t72036\t72071\t72106\t71826\tHelm of Tava's Favor",
            [12] = "71796\t71866\t71901\t71936\t71971\t72006\t72041\t72076\t72111\t71831\tGreaves of Tava's Favor",
            [13] = "71793\t71863\t71898\t71933\t71968\t72003\t72038\t72073\t72108\t71828\tPauldron of Tava's Favor",
            [14] = "71795\t71865\t71900\t71935\t71970\t72005\t72040\t72075\t72110\t71830\tGirdle of Tava's Favor",
        },
        [2] =
        {
            [1] = "71806\t71876\t71911\t71946\t71981\t72016\t72051\t72086\t72121\t71841\tRobe of Tava's Favor",
            [2] = "71807\t71877\t71912\t71947\t71982\t72017\t72052\t72087\t72122\t71842\tJerkin of Tava's Favor",
            [3] = "71812\t71882\t71917\t71952\t71987\t72022\t72057\t72092\t72127\t71847\tShoes of Tava's Favor",
            [4] = "71809\t71879\t71914\t71949\t71984\t72019\t72054\t72089\t72124\t71844\tGloves of Tava's Favor",
            [5] = "71805\t71875\t71910\t71945\t71980\t72015\t72050\t72085\t72120\t71840\tHat of Tava's Favor",
            [6] = "71811\t71881\t71916\t71951\t71986\t72021\t72056\t72091\t72126\t71846\tBreeches of Tava's Favor",
            [7] = "71808\t71878\t71913\t71948\t71983\t72018\t72053\t72088\t72123\t71843\tEpaulets of Tava's Favor",
            [8] = "71810\t71880\t71915\t71950\t71985\t72020\t72055\t72090\t72125\t71845\tSash of Tava's Favor",
            [9] = "71799\t71869\t71904\t71939\t71974\t72009\t72044\t72079\t72114\t71834\tJack of Tava's Favor",
            [10] = "71804\t71874\t71909\t71944\t71979\t72014\t72049\t72084\t72119\t71839\tBoots of Tava's Favor",
            [11] = "71801\t71871\t71906\t71941\t71976\t72011\t72046\t72081\t72116\t71836\tBracers of Tava's Favor",
            [12] = "71798\t71868\t71903\t71938\t71973\t72008\t72043\t72078\t72113\t71833\tHelmet of Tava's Favor",
            [13] = "71803\t71873\t71908\t71943\t71978\t72013\t72048\t72083\t72118\t71838\tGuards of Tava's Favor",
            [14] = "71800\t71870\t71905\t71940\t71975\t72010\t72045\t72080\t72115\t71835\tArm Cops of Tava's Favor",
            [15] = "71802\t71872\t71907\t71942\t71977\t72012\t72047\t72082\t72117\t71837\tBelt of Tava's Favor",
        },
        [6] =
        {
            [1] = "71820\t71890\t71925\t71960\t71995\t72030\t72065\t72100\t72135\t71855\tBow of Tava's Favor",
            [2] = "71821\t71891\t71926\t71961\t71996\t72031\t72066\t72101\t72136\t71856\tShield of Tava's Favor",
            [3] = "71822\t71892\t71927\t71962\t71997\t72032\t72067\t72102\t72137\t71857\tInferno Staff of Tava's Favor",
            [4] = "71823\t71893\t71928\t71963\t71998\t72033\t72068\t72103\t72138\t71858\tIce Staff of Tava's Favor",
            [5] = "71824\t71894\t71929\t71964\t71999\t72034\t72069\t72104\t72139\t71859\tLightning Staff of Tava's Favor",
            [6] = "71825\t71895\t71930\t71965\t72000\t72035\t72070\t72105\t72140\t71860\tRestoration Staff of Tava's Favor",
        },
    },
    [32] =
    {
        [1] =
        {
            [1] = "72163\t72233\t72268\t72303\t72338\t72373\t72408\t72443\t72478\t72198\tClever Alchemist axe",
            [2] = "72165\t72235\t72270\t72305\t72340\t72375\t72410\t72445\t72480\t72200\tClever Alchemist mace",
            [3] = "72164\t72234\t72269\t72304\t72339\t72374\t72409\t72444\t72479\t72199\tClever Alchemist Sword",
            [4] = "72166\t72236\t72271\t72306\t72341\t72376\t72411\t72446\t72481\t72201\tClever Alchemist Battle Axe",
            [5] = "72167\t72237\t72272\t72307\t72342\t72377\t72412\t72447\t72482\t72202\tClever Alchemist Maul",
            [6] = "72168\t72238\t72273\t72308\t72343\t72378\t72413\t72448\t72483\t72203\tClever Alchemist Greatsword",
            [7] = "72169\t72239\t72274\t72309\t72344\t72379\t72414\t72449\t72484\t72204\tClever Alchemist Dagger",
            [8] = "72142\t72212\t72247\t72282\t72317\t72352\t72387\t72422\t72457\t72177\tClever Alchemist Cuirass",
            [9] = "72147\t72217\t72252\t72287\t72322\t72357\t72392\t72427\t72462\t72182\tClever Alchemist Sabatons",
            [10] = "72144\t72214\t72249\t72284\t72319\t72354\t72389\t72424\t72459\t72179\tClever Alchemist Gauntlets",
            [11] = "72141\t72211\t72246\t72281\t72316\t72351\t72386\t72421\t72456\t72176\tClever Alchemist Helm",
            [12] = "72146\t72216\t72251\t72286\t72321\t72356\t72391\t72426\t72461\t72181\tClever Alchemist Greaves",
            [13] = "72143\t72213\t72248\t72283\t72318\t72353\t72388\t72423\t72458\t72178\tClever Alchemist Pauldron",
            [14] = "72145\t72215\t72250\t72285\t72320\t72355\t72390\t72425\t72460\t72180\tClever Alchemist Girdle",
        },
        [2] =
        {
            [1] = "72156\t72226\t72261\t72296\t72331\t72366\t72401\t72436\t72471\t72191\tClever Alchemist Robe",
            [2] = "72157\t72227\t72262\t72297\t72332\t72367\t72402\t72437\t72472\t72192\tClever Alchemist Jerkin",
            [3] = "72162\t72232\t72267\t72302\t72337\t72372\t72407\t72442\t72477\t72197\tClever Alchemist Shoes",
            [4] = "72159\t72229\t72264\t72299\t72334\t72369\t72404\t72439\t72474\t72194\tClever Alchemist Gloves",
            [5] = "72155\t72225\t72260\t72295\t72330\t72365\t72400\t72435\t72470\t72190\tClever Alchemist Hat",
            [6] = "72161\t72231\t72266\t72301\t72336\t72371\t72406\t72441\t72476\t72196\tClever Alchemist Breeches",
            [7] = "72158\t72228\t72263\t72298\t72333\t72368\t72403\t72438\t72473\t72193\tClever Alchemist Epaulets",
            [8] = "72160\t72230\t72265\t72300\t72335\t72370\t72405\t72440\t72475\t72195\tClever Alchemist Sash",
            [9] = "72149\t72219\t72254\t72289\t72324\t72359\t72394\t72429\t72464\t72184\tClever Alchemist Jack",
            [10] = "72154\t72224\t72259\t72294\t72329\t72364\t72399\t72434\t72469\t72189\tClever Alchemist Boots",
            [11] = "72151\t72221\t72256\t72291\t72326\t72361\t72396\t72431\t72466\t72186\tClever Alchemist Bracers",
            [12] = "72148\t72218\t72253\t72288\t72323\t72358\t72393\t72428\t72463\t72183\tClever Alchemist Helmet",
            [13] = "72153\t72223\t72258\t72293\t72328\t72363\t72398\t72433\t72468\t72188\tClever Alchemist Guards",
            [14] = "72150\t72220\t72255\t72290\t72325\t72360\t72395\t72430\t72465\t72185\tClever Alchemist Arm Cops",
            [15] = "72152\t72222\t72257\t72292\t72327\t72362\t72397\t72432\t72467\t72187\tClever Alchemist Belt",
        },
        [6] =
        {
            [1] = "72170\t72240\t72275\t72310\t72345\t72380\t72415\t72450\t72485\t72205\tClever Alchemist Bow",
            [2] = "72171\t72241\t72276\t72311\t72346\t72381\t72416\t72451\t72486\t72206\tClever Alchemist Shield",
            [3] = "72172\t72242\t72277\t72312\t72347\t72382\t72417\t72452\t72487\t72207\tClever Alchemist Inferno Staff",
            [4] = "72173\t72243\t72278\t72313\t72348\t72383\t72418\t72453\t72488\t72208\tClever Alchemist Ice Staff",
            [5] = "72174\t72244\t72279\t72314\t72349\t72384\t72419\t72454\t72489\t72209\tClever Alchemist Lightning Staff",
            [6] = "72175\t72245\t72280\t72315\t72350\t72385\t72420\t72455\t72490\t72210\tClever Alchemist Restoration Staff",
        },
    },
    [33] =
    {
        [1] =
        {
            [1] = "72513\t72583\t72618\t72653\t72688\t72723\t72758\t72793\t72828\t72548\tEternal Hunt axe",
            [2] = "72515\t72585\t72620\t72655\t72690\t72725\t72760\t72795\t72830\t72550\tEternal Hunt mace",
            [3] = "72514\t72584\t72619\t72654\t72689\t72724\t72759\t72794\t72829\t72549\tEternal Hunt Sword",
            [4] = "72516\t72586\t72621\t72656\t72691\t72726\t72761\t72796\t72831\t72551\tEternal Hunt Battle Axe",
            [5] = "72517\t72587\t72622\t72657\t72692\t72727\t72762\t72797\t72832\t72552\tEternal Hunt Maul",
            [6] = "72518\t72588\t72623\t72658\t72693\t72728\t72763\t72798\t72833\t72553\tEternal Hunt Greatsword",
            [7] = "72519\t72589\t72624\t72659\t72694\t72729\t72764\t72799\t72834\t72554\tEternal Hunt Dagger",
            [8] = "72492\t72562\t72597\t72632\t72667\t72702\t72737\t72772\t72807\t72527\tEternal Hunt Cuirass",
            [9] = "72497\t72567\t72602\t72637\t72672\t72707\t72742\t72777\t72812\t72532\tEternal Hunt Sabatons",
            [10] = "72494\t72564\t72599\t72634\t72669\t72704\t72739\t72774\t72809\t72529\tEternal Hunt Gauntlets",
            [11] = "72491\t72561\t72596\t72631\t72666\t72701\t72736\t72771\t72806\t72526\tEternal Hunt Helm",
            [12] = "72496\t72566\t72601\t72636\t72671\t72706\t72741\t72776\t72811\t72531\tEternal Hunt Greaves",
            [13] = "72493\t72563\t72598\t72633\t72668\t72703\t72738\t72773\t72808\t72528\tEternal Hunt Pauldron",
            [14] = "72495\t72565\t72600\t72635\t72670\t72705\t72740\t72775\t72810\t72530\tEternal Hunt Girdle",
        },
        [2] =
        {
            [1] = "72506\t72576\t72611\t72646\t72681\t72716\t72751\t72786\t72821\t72541\tEternal Hunt Robe",
            [2] = "72507\t72577\t72612\t72647\t72682\t72717\t72752\t72787\t72822\t72542\tEternal Hunt Jerkin",
            [3] = "72512\t72582\t72617\t72652\t72687\t72722\t72757\t72792\t72827\t72547\tEternal Hunt Shoes",
            [4] = "72509\t72579\t72614\t72649\t72684\t72719\t72754\t72789\t72824\t72544\tEternal Hunt Gloves",
            [5] = "72505\t72575\t72610\t72645\t72680\t72715\t72750\t72785\t72820\t72540\tEternal Hunt Hat",
            [6] = "72511\t72581\t72616\t72651\t72686\t72721\t72756\t72791\t72826\t72546\tEternal Hunt Breeches",
            [7] = "72508\t72578\t72613\t72648\t72683\t72718\t72753\t72788\t72823\t72543\tEternal Hunt Epaulets",
            [8] = "72510\t72580\t72615\t72650\t72685\t72720\t72755\t72790\t72825\t72545\tEternal Hunt Sash",
            [9] = "72499\t72569\t72604\t72639\t72674\t72709\t72744\t72779\t72814\t72534\tEternal Hunt Jack",
            [10] = "72504\t72574\t72609\t72644\t72679\t72714\t72749\t72784\t72819\t72539\tEternal Hunt Boots",
            [11] = "72501\t72571\t72606\t72641\t72676\t72711\t72746\t72781\t72816\t72536\tEternal Hunt Bracers",
            [12] = "72498\t72568\t72603\t72638\t72673\t72708\t72743\t72778\t72813\t72533\tEternal Hunt Helmet",
            [13] = "72503\t72573\t72608\t72643\t72678\t72713\t72748\t72783\t72818\t72538\tEternal Hunt Guards",
            [14] = "72500\t72570\t72605\t72640\t72675\t72710\t72745\t72780\t72815\t72535\tEternal Hunt Arm Cops",
            [15] = "72502\t72572\t72607\t72642\t72677\t72712\t72747\t72782\t72817\t72537\tEternal Hunt Belt",
        },
        [6] =
        {
            [1] = "72520\t72590\t72625\t72660\t72695\t72730\t72765\t72800\t72835\t72555\tEternal Hunt Bow",
            [2] = "72521\t72591\t72626\t72661\t72696\t72731\t72766\t72801\t72836\t72556\tEternal Hunt Shield",
            [3] = "72522\t72592\t72627\t72662\t72697\t72732\t72767\t72802\t72837\t72557\tEternal Hunt Inferno Staff",
            [4] = "72523\t72593\t72628\t72663\t72698\t72733\t72768\t72803\t72838\t72558\tEternal Hunt Ice Staff",
            [5] = "72524\t72594\t72629\t72664\t72699\t72734\t72769\t72804\t72839\t72559\tEternal Hunt Lightning Staff",
            [6] = "72525\t72595\t72630\t72665\t72700\t72735\t72770\t72805\t72840\t72560\tEternal Hunt Restoration Staff",
        },
    },
    [34] =
    {
        [1] =
        {
            [1] = "75386\t75456\t75596\t75491\t75421\t75526\t75666\t75561\t75631\t75701\tGladiator's Axe",
            [2] = "75387\t75457\t75597\t75492\t75422\t75527\t75667\t75562\t75632\t75702\tGladiator's Mace",
            [3] = "75388\t75458\t75598\t75493\t75423\t75528\t75668\t75563\t75633\t75703\tGladiator's Sword",
            [4] = "75389\t75459\t75599\t75494\t75424\t75529\t75669\t75564\t75634\t75704\tGladiator's Battle Axe",
            [5] = "75390\t75460\t75600\t75495\t75425\t75530\t75670\t75565\t75635\t75705\tGladiator's Maul",
            [6] = "75391\t75461\t75601\t75496\t75426\t75531\t75671\t75566\t75636\t75706\tGladiator's Greatsword",
            [7] = "75392\t75462\t75602\t75497\t75427\t75532\t75672\t75567\t75637\t75707\tGladiator's Dagger",
            [8] = "75399\t75644\t75574\t75539\t75504\t75679\t75434\t75609\t75469\t75714\tGladiator's Cuirass",
            [9] = "75400\t75645\t75575\t75540\t75505\t75680\t75435\t75610\t75470\t75715\tGladiator's Sabatons",
            [10] = "75401\t75646\t75576\t75541\t75506\t75681\t75436\t75611\t75471\t75716\tGladiator's Gauntlets",
            [11] = "75402\t75647\t75577\t75542\t75507\t75682\t75437\t75612\t75472\t75717\tGladiator's Helm",
            [12] = "75403\t75648\t75578\t75543\t75508\t75683\t75438\t75613\t75473\t75718\tGladiator's Greaves",
            [13] = "75404\t75649\t75579\t75544\t75509\t75684\t75439\t75614\t75474\t75719\tGladiator's Pauldron",
            [14] = "75405\t75650\t75580\t75545\t75510\t75685\t75440\t75615\t75475\t75720\tGladiator's Girdle",
        },
        [2] =
        {
            [1] = "75406\t75651\t75581\t75546\t75511\t75686\t75441\t75616\t75476\t75721\tGladiator's Robe",
            [2] = "75411\t75656\t75586\t75551\t75516\t75691\t75446\t75621\t75481\t75726\tGladiator's Jerkin",
            [3] = "75407\t75652\t75582\t75547\t75512\t75687\t75442\t75617\t75477\t75722\tGladiator's Shoes",
            [4] = "75408\t75653\t75583\t75548\t75513\t75688\t75443\t75618\t75478\t75723\tGladiator's Gloves",
            [5] = "75409\t75654\t75584\t75549\t75514\t75689\t75444\t75619\t75479\t75724\tGladiator's Hat",
            [6] = "75410\t75655\t75585\t75550\t75515\t75690\t75445\t75620\t75480\t75725\tGladiator's Breeches",
            [7] = "75412\t75657\t75587\t75552\t75517\t75692\t75447\t75622\t75482\t75727\tGladiator's Epaulets",
            [8] = "75413\t75658\t75588\t75553\t75518\t75693\t75448\t75623\t75483\t75728\tGladiator's Sash",
            [9] = "75414\t75659\t75589\t75554\t75519\t75694\t75449\t75624\t75484\t75729\tGladiator's Jack",
            [10] = "75415\t75660\t75590\t75555\t75520\t75695\t75450\t75625\t75485\t75730\tGladiator's Boots",
            [11] = "75416\t75661\t75591\t75556\t75521\t75696\t75451\t75626\t75486\t75731\tGladiator's Bracers",
            [12] = "75417\t75662\t75592\t75557\t75522\t75697\t75452\t75627\t75487\t75732\tGladiator's Helmet",
            [13] = "75418\t75663\t75593\t75558\t75523\t75698\t75453\t75628\t75488\t75733\tGladiator's Guards",
            [14] = "75419\t75664\t75594\t75559\t75524\t75699\t75454\t75629\t75489\t75734\tGladiator's Arm Cops",
            [15] = "75420\t75665\t75595\t75560\t75525\t75700\t75455\t75630\t75490\t75735\tGladiator's Belt",
        },
        [6] =
        {
            [1] = "75393\t75463\t75603\t75498\t75428\t75533\t75673\t75568\t75638\t75708\tGladiator's Bow",
            [2] = "75398\t75643\t75573\t75538\t75503\t75678\t75433\t75608\t75468\t75713\tGladiator's Shield",
            [3] = "75394\t75464\t75604\t75499\t75429\t75534\t75674\t75569\t75639\t75709\tGladiator's Inferno Staff",
            [4] = "75395\t75465\t75605\t75500\t75430\t75535\t75675\t75570\t75640\t75710\tGladiator's Ice Staff",
            [5] = "75396\t75466\t75606\t75501\t75431\t75536\t75676\t75571\t75641\t75711\tGladiator's Lightning Staff",
            [6] = "75397\t75467\t75607\t75502\t75432\t75537\t75677\t75572\t75642\t75712\tGladiator's Restoration Staff",
        },
    },
    [35] =
    {
        [1] =
        {
            [1] = "75736\t75806\t75946\t75841\t75771\t75876\t76016\t75911\t75981\t76051\tAxe of Varen's Legacy",
            [2] = "75737\t75807\t75947\t75842\t75772\t75877\t76017\t75912\t75982\t76052\tMace of Varen's Legacy",
            [3] = "75738\t75808\t75948\t75843\t75773\t75878\t76018\t75913\t75983\t76053\tSword of Varen's Legacy",
            [4] = "75739\t75809\t75949\t75844\t75774\t75879\t76019\t75914\t75984\t76054\tBattle Axe of Varen's Legacy",
            [5] = "75740\t75810\t75950\t75845\t75775\t75880\t76020\t75915\t75985\t76055\tMaul of Varen's Legacy",
            [6] = "75741\t75811\t75951\t75846\t75776\t75881\t76021\t75916\t75986\t76056\tGreatsword of Varen's Legacy",
            [7] = "75742\t75812\t75952\t75847\t75777\t75882\t76022\t75917\t75987\t76057\tDagger of Varen's Legacy",
            [8] = "75749\t75994\t75924\t75889\t75854\t76029\t75784\t75959\t75819\t76064\tCuirass of Varen's Legacy",
            [9] = "75750\t75995\t75925\t75890\t75855\t76030\t75785\t75960\t75820\t76065\tSabatons of Varen's Legacy",
            [10] = "75751\t75996\t75926\t75891\t75856\t76031\t75786\t75961\t75821\t76066\tGauntlets of Varen's Legacy",
            [11] = "75752\t75997\t75927\t75892\t75857\t76032\t75787\t75962\t75822\t76067\tHelm of Varen's Legacy",
            [12] = "75753\t75998\t75928\t75893\t75858\t76033\t75788\t75963\t75823\t76068\tGreaves of Varen's Legacy",
            [13] = "75754\t75999\t75929\t75894\t75859\t76034\t75789\t75964\t75824\t76069\tPauldron of Varen's Legacy",
            [14] = "75755\t76000\t75930\t75895\t75860\t76035\t75790\t75965\t75825\t76070\tGirdle of Varen's Legacy",
        },
        [2] =
        {
            [1] = "75756\t76001\t75931\t75896\t75861\t76036\t75791\t75966\t75826\t76071\tRobe of Varen's Legacy",
            [2] = "75761\t76006\t75936\t75901\t75866\t76041\t75796\t75971\t75831\t76076\tJerkin of Varen's Legacy",
            [3] = "75757\t76002\t75932\t75897\t75862\t76037\t75792\t75967\t75827\t76072\tShoes of Varen's Legacy",
            [4] = "75758\t76003\t75933\t75898\t75863\t76038\t75793\t75968\t75828\t76073\tGloves of Varen's Legacy",
            [5] = "75759\t76004\t75934\t75899\t75864\t76039\t75794\t75969\t75829\t76074\tHat of Varen's Legacy",
            [6] = "75760\t76005\t75935\t75900\t75865\t76040\t75795\t75970\t75830\t76075\tBreeches of Varen's Legacy",
            [7] = "75762\t76007\t75937\t75902\t75867\t76042\t75797\t75972\t75832\t76077\tEpaulets of Varen's Legacy",
            [8] = "75763\t76008\t75938\t75903\t75868\t76043\t75798\t75973\t75833\t76078\tSash of Varen's Legacy",
            [9] = "75764\t76009\t75939\t75904\t75869\t76044\t75799\t75974\t75834\t76079\tJack of Varen's Legacy",
            [10] = "75765\t76010\t75940\t75905\t75870\t76045\t75800\t75975\t75835\t76080\tBoots of Varen's Legacy",
            [11] = "75766\t76011\t75941\t75906\t75871\t76046\t75801\t75976\t75836\t76081\tBracers of Varen's Legacy",
            [12] = "75767\t76012\t75942\t75907\t75872\t76047\t75802\t75977\t75837\t76082\tHelmet of Varen's Legacy",
            [13] = "75768\t76013\t75943\t75908\t75873\t76048\t75803\t75978\t75838\t76083\tGuards of Varen's Legacy",
            [14] = "75769\t76014\t75944\t75909\t75874\t76049\t75804\t75979\t75839\t76084\tArm Cops of Varen's Legacy",
            [15] = "75770\t76015\t75945\t75910\t75875\t76050\t75805\t75980\t75840\t76085\tBelt of Varen's Legacy",
        },
        [6] =
        {
            [1] = "75743\t75813\t75953\t75848\t75778\t75883\t76023\t75918\t75988\t76058\tBow of Varen's Legacy",
            [2] = "75748\t75993\t75923\t75888\t75853\t76028\t75783\t75958\t75818\t76063\tShield of Varen's Legacy",
            [3] = "75744\t75814\t75954\t75849\t75779\t75884\t76024\t75919\t75989\t76059\tInferno Staff of Varen's Legacy",
            [4] = "75745\t75815\t75955\t75850\t75780\t75885\t76025\t75920\t75990\t76060\tIce Staff of Varen's Legacy",
            [5] = "75746\t75816\t75956\t75851\t75781\t75886\t76026\t75921\t75991\t76061\tLightning Staff of Varen's Legacy",
            [6] = "75747\t75817\t75957\t75852\t75782\t75887\t76027\t75922\t75992\t76062\tRestoration Staff of Varen's Legacy",
        },
    },
    [36] =
    {
        [1] =
        {
            [1] = "76086\t76156\t76296\t76191\t76121\t76226\t76366\t76261\t76331\t76401\tPelinal's Axe",
            [2] = "76087\t76157\t76297\t76192\t76122\t76227\t76367\t76262\t76332\t76402\tPelinal's Mace",
            [3] = "76088\t76158\t76298\t76193\t76123\t76228\t76368\t76263\t76333\t76403\tPelinal's Sword",
            [4] = "76089\t76159\t76299\t76194\t76124\t76229\t76369\t76264\t76334\t76404\tPelinal's Battle Axe",
            [5] = "76090\t76160\t76300\t76195\t76125\t76230\t76370\t76265\t76335\t76405\tPelinal's Maul",
            [6] = "76091\t76161\t76301\t76196\t76126\t76231\t76371\t76266\t76336\t76406\tPelinal's Greatsword",
            [7] = "76092\t76162\t76302\t76197\t76127\t76232\t76372\t76267\t76337\t76407\tPelinal's Dagger",
            [8] = "76099\t76344\t76274\t76239\t76204\t76379\t76134\t76309\t76169\t76414\tPelinal's Cuirass",
            [9] = "76100\t76345\t76275\t76240\t76205\t76380\t76135\t76310\t76170\t76415\tPelinal's Sabatons",
            [10] = "76101\t76346\t76276\t76241\t76206\t76381\t76136\t76311\t76171\t76416\tPelinal's Gauntlets",
            [11] = "76102\t76347\t76277\t76242\t76207\t76382\t76137\t76312\t76172\t76417\tPelinal's Helm",
            [12] = "76103\t76348\t76278\t76243\t76208\t76383\t76138\t76313\t76173\t76418\tPelinal's Greaves",
            [13] = "76104\t76349\t76279\t76244\t76209\t76384\t76139\t76314\t76174\t76419\tPelinal's Pauldron",
            [14] = "76105\t76350\t76280\t76245\t76210\t76385\t76140\t76315\t76175\t76420\tPelinal's Girdle",
        },
        [2] =
        {
            [1] = "76106\t76351\t76281\t76246\t76211\t76386\t76141\t76316\t76176\t76421\tPelinal's Robe",
            [2] = "76111\t76356\t76286\t76251\t76216\t76391\t76146\t76321\t76181\t76426\tPelinal's Jerkin",
            [3] = "76107\t76352\t76282\t76247\t76212\t76387\t76142\t76317\t76177\t76422\tPelinal's Shoes",
            [4] = "76108\t76353\t76283\t76248\t76213\t76388\t76143\t76318\t76178\t76423\tPelinal's Gloves",
            [5] = "76109\t76354\t76284\t76249\t76214\t76389\t76144\t76319\t76179\t76424\tPelinal's Hat",
            [6] = "76110\t76355\t76285\t76250\t76215\t76390\t76145\t76320\t76180\t76425\tPelinal's Breeches",
            [7] = "76112\t76357\t76287\t76252\t76217\t76392\t76147\t76322\t76182\t76427\tPelinal's Epaulets",
            [8] = "76113\t76358\t76288\t76253\t76218\t76393\t76148\t76323\t76183\t76428\tPelinal's Sash",
            [9] = "76114\t76359\t76289\t76254\t76219\t76394\t76149\t76324\t76184\t76429\tPelinal's Jack",
            [10] = "76115\t76360\t76290\t76255\t76220\t76395\t76150\t76325\t76185\t76430\tPelinal's Boots",
            [11] = "76116\t76361\t76291\t76256\t76221\t76396\t76151\t76326\t76186\t76431\tPelinal's Bracers",
            [12] = "76117\t76362\t76292\t76257\t76222\t76397\t76152\t76327\t76187\t76432\tPelinal's Helmet",
            [13] = "76118\t76363\t76293\t76258\t76223\t76398\t76153\t76328\t76188\t76433\tPelinal's Guards",
            [14] = "76119\t76364\t76294\t76259\t76224\t76399\t76154\t76329\t76189\t76434\tPelinal's Arm Cops",
            [15] = "76120\t76365\t76295\t76260\t76225\t76400\t76155\t76330\t76190\t76435\tPelinal's Belt",
        },
        [6] =
        {
            [1] = "76093\t76163\t76303\t76198\t76128\t76233\t76373\t76268\t76338\t76408\tPelinal's Bow",
            [2] = "76098\t76343\t76273\t76238\t76203\t76378\t76133\t76308\t76168\t76413\tPelinal's Shield",
            [3] = "76094\t76164\t76304\t76199\t76129\t76234\t76374\t76269\t76339\t76409\tPelinal's Inferno Staff",
            [4] = "76095\t76165\t76305\t76200\t76130\t76235\t76375\t76270\t76340\t76410\tPelinal's Ice Staff",
            [5] = "76096\t76166\t76306\t76201\t76131\t76236\t76376\t76271\t76341\t76411\tPelinal's Lightning Staff",
            [6] = "76097\t76167\t76307\t76202\t76132\t76237\t76377\t76272\t76342\t76412\tPelinal's Restoration Staff",
        },
    },
    [37] =
    {
        [1] =
        {
            [1] = "121551\t121621\t121761\t121656\t121586\t121691\t121831\t121726\t121796\t121866\tAssassin's Axe",
            [2] = "121552\t121622\t121762\t121657\t121587\t121692\t121832\t121727\t121797\t121867\tAssassin's Mace",
            [3] = "121553\t121623\t121763\t121658\t121588\t121693\t121833\t121728\t121798\t121868\tAssassin's Sword",
            [4] = "121554\t121624\t121764\t121659\t121589\t121694\t121834\t121729\t121799\t121869\tAssassin's Battle Axe",
            [5] = "121555\t121625\t121765\t121660\t121590\t121695\t121835\t121730\t121800\t121870\tAssassin's Maul",
            [6] = "121556\t121626\t121766\t121661\t121591\t121696\t121836\t121731\t121801\t121871\tAssassin's Greatsword",
            [7] = "121557\t121627\t121767\t121662\t121592\t121697\t121837\t121732\t121802\t121872\tAssassin's Dagger",
            [8] = "121564\t121809\t121739\t121704\t121669\t121844\t121599\t121774\t121634\t121879\tAssassin's Cuirass",
            [9] = "121565\t121810\t121740\t121705\t121670\t121845\t121600\t121775\t121635\t121880\tAssassin's Sabatons",
            [10] = "121566\t121811\t121741\t121706\t121671\t121846\t121601\t121776\t121636\t121881\tAssassin's Gauntlets",
            [11] = "121567\t121812\t121742\t121707\t121672\t121847\t121602\t121777\t121637\t121882\tAssassin's Helm",
            [12] = "121568\t121813\t121743\t121708\t121673\t121848\t121603\t121778\t121638\t121883\tAssassin's Greaves",
            [13] = "121569\t121814\t121744\t121709\t121674\t121849\t121604\t121779\t121639\t121884\tAssassin's Pauldron",
            [14] = "121570\t121815\t121745\t121710\t121675\t121850\t121605\t121780\t121640\t121885\tAssassin's Girdle",
        },
        [2] =
        {
            [1] = "121571\t121816\t121746\t121711\t121676\t121851\t121606\t121781\t121641\t121886\tAssassin's Robe",
            [2] = "121576\t121821\t121751\t121716\t121681\t121856\t121611\t121786\t121646\t121891\tAssassin's Jerkin",
            [3] = "121572\t121817\t121747\t121712\t121677\t121852\t121607\t121782\t121642\t121887\tAssassin's Shoes",
            [4] = "121573\t121818\t121748\t121713\t121678\t121853\t121608\t121783\t121643\t121888\tAssassin's Gloves",
            [5] = "121574\t121819\t121749\t121714\t121679\t121854\t121609\t121784\t121644\t121889\tAssassin's Hat",
            [6] = "121575\t121820\t121750\t121715\t121680\t121855\t121610\t121785\t121645\t121890\tAssassin's Breeches",
            [7] = "121577\t121822\t121752\t121717\t121682\t121857\t121612\t121787\t121647\t121892\tAssassin's Epaulets",
            [8] = "121578\t121823\t121753\t121718\t121683\t121858\t121613\t121788\t121648\t121893\tAssassin's Sash",
            [9] = "121579\t121824\t121754\t121719\t121684\t121859\t121614\t121789\t121649\t121894\tAssassin's Jack",
            [10] = "121580\t121825\t121755\t121720\t121685\t121860\t121615\t121790\t121650\t121895\tAssassin's Boots",
            [11] = "121581\t121826\t121756\t121721\t121686\t121861\t121616\t121791\t121651\t121896\tAssassin's Bracers",
            [12] = "121582\t121827\t121757\t121722\t121687\t121862\t121617\t121792\t121652\t121897\tAssassin's Helmet",
            [13] = "121583\t121828\t121758\t121723\t121688\t121863\t121618\t121793\t121653\t121898\tAssassin's Guards",
            [14] = "121584\t121829\t121759\t121724\t121689\t121864\t121619\t121794\t121654\t121899\tAssassin's Arm Cops",
            [15] = "121585\t121830\t121760\t121725\t121690\t121865\t121620\t121795\t121655\t121900\tAssassin's Belt",
        },
        [6] =
        {
            [1] = "121558\t121628\t121768\t121663\t121593\t121698\t121838\t121733\t121803\t121873\tAssassin's Bow",
            [2] = "121563\t121808\t121738\t121703\t121668\t121843\t121598\t121773\t121633\t121878\tAssassin's Shield",
            [3] = "121559\t121629\t121769\t121664\t121594\t121699\t121839\t121734\t121804\t121874\tAssassin's Inferno Staff",
            [4] = "121560\t121630\t121770\t121665\t121595\t121700\t121840\t121735\t121805\t121875\tAssassin's Ice Staff",
            [5] = "121561\t121631\t121771\t121666\t121596\t121701\t121841\t121736\t121806\t121876\tAssassin's Lightning Staff",
            [6] = "121562\t121632\t121772\t121667\t121597\t121702\t121842\t121737\t121807\t121877\tAssassin's Restoration Staff",
        },
    },
    [38] =
    {
        [1] =
        {
            [1] = "122251\t122321\t122461\t122356\t122286\t122391\t122531\t122426\t122496\t122566\tShacklebreaker Axe",
            [2] = "122252\t122322\t122462\t122357\t122287\t122392\t122532\t122427\t122497\t122567\tShacklebreaker Mace",
            [3] = "122253\t122323\t122463\t122358\t122288\t122393\t122533\t122428\t122498\t122568\tShacklebreaker Sword",
            [4] = "122254\t122324\t122464\t122359\t122289\t122394\t122534\t122429\t122499\t122569\tShacklebreaker Battle Axe",
            [5] = "122255\t122325\t122465\t122360\t122290\t122395\t122535\t122430\t122500\t122570\tShacklebreaker Maul",
            [6] = "122256\t122326\t122466\t122361\t122291\t122396\t122536\t122431\t122501\t122571\tShacklebreaker Greatsword",
            [7] = "122257\t122327\t122467\t122362\t122292\t122397\t122537\t122432\t122502\t122572\tShacklebreaker Dagger",
            [8] = "122264\t122509\t122439\t122404\t122369\t122544\t122299\t122474\t122334\t122579\tShacklebreaker Cuirass",
            [9] = "122265\t122510\t122440\t122405\t122370\t122545\t122300\t122475\t122335\t122580\tShacklebreaker Sabatons",
            [10] = "122266\t122511\t122441\t122406\t122371\t122546\t122301\t122476\t122336\t122581\tShacklebreaker Gauntlets",
            [11] = "122267\t122512\t122442\t122407\t122372\t122547\t122302\t122477\t122337\t122582\tShacklebreaker Helm",
            [12] = "122268\t122513\t122443\t122408\t122373\t122548\t122303\t122478\t122338\t122583\tShacklebreaker Greaves",
            [13] = "122269\t122514\t122444\t122409\t122374\t122549\t122304\t122479\t122339\t122584\tShacklebreaker Pauldron",
            [14] = "122270\t122515\t122445\t122410\t122375\t122550\t122305\t122480\t122340\t122585\tShacklebreaker Girdle",
        },
        [2] =
        {
            [1] = "122271\t122516\t122446\t122411\t122376\t122551\t122306\t122481\t122341\t122586\tShacklebreaker Robe",
            [2] = "122276\t122521\t122451\t122416\t122381\t122556\t122311\t122486\t122346\t122591\tShacklebreaker Jerkin",
            [3] = "122272\t122517\t122447\t122412\t122377\t122552\t122307\t122482\t122342\t122587\tShacklebreaker Shoes",
            [4] = "122273\t122518\t122448\t122413\t122378\t122553\t122308\t122483\t122343\t122588\tShacklebreaker Gloves",
            [5] = "122274\t122519\t122449\t122414\t122379\t122554\t122309\t122484\t122344\t122589\tShacklebreaker Hat",
            [6] = "122275\t122520\t122450\t122415\t122380\t122555\t122310\t122485\t122345\t122590\tShacklebreaker Breeches",
            [7] = "122277\t122522\t122452\t122417\t122382\t122557\t122312\t122487\t122347\t122592\tShacklebreaker Epaulets",
            [8] = "122278\t122523\t122453\t122418\t122383\t122558\t122313\t122488\t122348\t122593\tShacklebreaker Sash",
            [9] = "122279\t122524\t122454\t122419\t122384\t122559\t122314\t122489\t122349\t122594\tShacklebreaker Jack",
            [10] = "122280\t122525\t122455\t122420\t122385\t122560\t122315\t122490\t122350\t122595\tShacklebreaker Boots",
            [11] = "122281\t122526\t122456\t122421\t122386\t122561\t122316\t122491\t122351\t122596\tShacklebreaker Bracers",
            [12] = "122282\t122527\t122457\t122422\t122387\t122562\t122317\t122492\t122352\t122597\tShacklebreaker Helmet",
            [13] = "122283\t122528\t122458\t122423\t122388\t122563\t122318\t122493\t122353\t122598\tShacklebreaker Guards",
            [14] = "122284\t122529\t122459\t122424\t122389\t122564\t122319\t122494\t122354\t122599\tShacklebreaker Arm Cops",
            [15] = "122285\t122530\t122460\t122425\t122390\t122565\t122320\t122495\t122355\t122600\tShacklebreaker Belt",
        },
        [6] =
        {
            [1] = "122258\t122328\t122468\t122363\t122293\t122398\t122538\t122433\t122503\t122573\tShacklebreaker Bow",
            [2] = "122263\t122508\t122438\t122403\t122368\t122543\t122298\t122473\t122333\t122578\tShacklebreaker Shield",
            [3] = "122259\t122329\t122469\t122364\t122294\t122399\t122539\t122434\t122504\t122574\tShacklebreaker Inferno Staff",
            [4] = "122260\t122330\t122470\t122365\t122295\t122400\t122540\t122435\t122505\t122575\tShacklebreaker Ice Staff",
            [5] = "122261\t122331\t122471\t122366\t122296\t122401\t122541\t122436\t122506\t122576\tShacklebreaker Lightning Staff",
            [6] = "122262\t122332\t122472\t122367\t122297\t122402\t122542\t122437\t122507\t122577\tShacklebreaker Restoration Staff",
        },
    },
    [39] =
    {
        [1] =
        {
            [1] = "121901\t121971\t122111\t122006\t121936\t122041\t122181\t122076\t122146\t122216\tAxe of Daedric Trickery",
            [2] = "121902\t121972\t122112\t122007\t121937\t122042\t122182\t122077\t122147\t122217\tMace of Daedric Trickery",
            [3] = "121903\t121973\t122113\t122008\t121938\t122043\t122183\t122078\t122148\t122218\tSword of Daedric Trickery",
            [4] = "121904\t121974\t122114\t122009\t121939\t122044\t122184\t122079\t122149\t122219\tBattle Axe of Daedric Trickery",
            [5] = "121905\t121975\t122115\t122010\t121940\t122045\t122185\t122080\t122150\t122220\tMaul of Daedric Trickery",
            [6] = "121906\t121976\t122116\t122011\t121941\t122046\t122186\t122081\t122151\t122221\tGreatsword of Daedric Trickery",
            [7] = "121907\t121977\t122117\t122012\t121942\t122047\t122187\t122082\t122152\t122222\tDagger of Daedric Trickery",
            [8] = "121914\t122159\t122089\t122054\t122019\t122194\t121949\t122124\t121984\t122229\tCuirass of Daedric Trickery",
            [9] = "121915\t122160\t122090\t122055\t122020\t122195\t121950\t122125\t121985\t122230\tSabatons of Daedric Trickery",
            [10] = "121916\t122161\t122091\t122056\t122021\t122196\t121951\t122126\t121986\t122231\tGauntlets of Daedric Trickery",
            [11] = "121917\t122162\t122092\t122057\t122022\t122197\t121952\t122127\t121987\t122232\tHelm of Daedric Trickery",
            [12] = "121918\t122163\t122093\t122058\t122023\t122198\t121953\t122128\t121988\t122233\tGreaves of Daedric Trickery",
            [13] = "121919\t122164\t122094\t122059\t122024\t122199\t121954\t122129\t121989\t122234\tPauldron of Daedric Trickery",
            [14] = "121920\t122165\t122095\t122060\t122025\t122200\t121955\t122130\t121990\t122235\tGirdle of Daedric Trickery",
        },
        [2] =
        {
            [1] = "121921\t122166\t122096\t122061\t122026\t122201\t121956\t122131\t121991\t122236\tRobe of Daedric Trickery",
            [2] = "121926\t122171\t122101\t122066\t122031\t122206\t121961\t122136\t121996\t122241\tJerkin of Daedric Trickery",
            [3] = "121922\t122167\t122097\t122062\t122027\t122202\t121957\t122132\t121992\t122237\tShoes of Daedric Trickery",
            [4] = "121923\t122168\t122098\t122063\t122028\t122203\t121958\t122133\t121993\t122238\tGloves of Daedric Trickery",
            [5] = "121924\t122169\t122099\t122064\t122029\t122204\t121959\t122134\t121994\t122239\tHat of Daedric Trickery",
            [6] = "121925\t122170\t122100\t122065\t122030\t122205\t121960\t122135\t121995\t122240\tBreeches of Daedric Trickery",
            [7] = "121927\t122172\t122102\t122067\t122032\t122207\t121962\t122137\t121997\t122242\tEpaulets of Daedric Trickery",
            [8] = "121928\t122173\t122103\t122068\t122033\t122208\t121963\t122138\t121998\t122243\tSash of Daedric Trickery",
            [9] = "121929\t122174\t122104\t122069\t122034\t122209\t121964\t122139\t121999\t122244\tJack of Daedric Trickery",
            [10] = "121930\t122175\t122105\t122070\t122035\t122210\t121965\t122140\t122000\t122245\tBoots of Daedric Trickery",
            [11] = "121931\t122176\t122106\t122071\t122036\t122211\t121966\t122141\t122001\t122246\tBracers of Daedric Trickery",
            [12] = "121932\t122177\t122107\t122072\t122037\t122212\t121967\t122142\t122002\t122247\tHelmet of Daedric Trickery",
            [13] = "121933\t122178\t122108\t122073\t122038\t122213\t121968\t122143\t122003\t122248\tGuards of Daedric Trickery",
            [14] = "121934\t122179\t122109\t122074\t122039\t122214\t121969\t122144\t122004\t122249\tArm Cops of Daedric Trickery",
            [15] = "121935\t122180\t122110\t122075\t122040\t122215\t121970\t122145\t122005\t122250\tBelt of Daedric Trickery",
        },
        [6] =
        {
            [1] = "121908\t121978\t122118\t122013\t121943\t122048\t122188\t122083\t122153\t122223\tBow of Daedric Trickery",
            [2] = "121913\t122158\t122088\t122053\t122018\t122193\t121948\t122123\t121983\t122228\tShield of Daedric Trickery",
            [3] = "121909\t121979\t122119\t122014\t121944\t122049\t122189\t122084\t122154\t122224\tInferno Staff of Daedric Trickery",
            [4] = "121910\t121980\t122120\t122015\t121945\t122050\t122190\t122085\t122155\t122225\tIce Staff of Daedric Trickery",
            [5] = "121911\t121981\t122121\t122016\t121946\t122051\t122191\t122086\t122156\t122226\tLightning Staff of Daedric Trickery",
            [6] = "121912\t121982\t122122\t122017\t121947\t122052\t122192\t122087\t122157\t122227\tRestoration Staff of Daedric Trickery",
        },
    },
    [40] =
    {
        [1] =
        {
            [1] = "131070\t131140\t131280\t131175\t131105\t131210\t131350\t131245\t131315\t131385\tAxe of Mechanical Acuity",
            [2] = "131071\t131141\t131281\t131176\t131106\t131211\t131351\t131246\t131316\t131386\tMace of Mechanical Acuity",
            [3] = "131072\t131142\t131282\t131177\t131107\t131212\t131352\t131247\t131317\t131387\tSword of Mechanical Acuity",
            [4] = "131073\t131143\t131283\t131178\t131108\t131213\t131353\t131248\t131318\t131388\tBattle Axe of Mechanical Acuity",
            [5] = "131074\t131144\t131284\t131179\t131109\t131214\t131354\t131249\t131319\t131389\tMaul of Mechanical Acuity",
            [6] = "131075\t131145\t131285\t131180\t131110\t131215\t131355\t131250\t131320\t131390\tGreatsword of Mechanical Acuity",
            [7] = "131076\t131146\t131286\t131181\t131111\t131216\t131356\t131251\t131321\t131391\tDagger of Mechanical Acuity",
            [8] = "131083\t131328\t131258\t131223\t131188\t131363\t131118\t131293\t131153\t131398\tCuirass of Mechanical Acuity",
            [9] = "131084\t131329\t131259\t131224\t131189\t131364\t131119\t131294\t131154\t131399\tSabatons of Mechanical Acuity",
            [10] = "131085\t131330\t131260\t131225\t131190\t131365\t131120\t131295\t131155\t131400\tGauntlets of Mechanical Acuity",
            [11] = "131086\t131331\t131261\t131226\t131191\t131366\t131121\t131296\t131156\t131401\tHelm of Mechanical Acuity",
            [12] = "131087\t131332\t131262\t131227\t131192\t131367\t131122\t131297\t131157\t131402\tGreaves of Mechanical Acuity",
            [13] = "131088\t131333\t131263\t131228\t131193\t131368\t131123\t131298\t131158\t131403\tPauldron of Mechanical Acuity",
            [14] = "131089\t131334\t131264\t131229\t131194\t131369\t131124\t131299\t131159\t131404\tGirdle of Mechanical Acuity",
        },
        [2] =
        {
            [1] = "131090\t131335\t131265\t131230\t131195\t131370\t131125\t131300\t131160\t131405\tRobe of Mechanical Acuity",
            [2] = "131095\t131340\t131270\t131235\t131200\t131375\t131130\t131305\t131165\t131410\tJerkin of Mechanical Acuity",
            [3] = "131091\t131336\t131266\t131231\t131196\t131371\t131126\t131301\t131161\t131406\tShoes of Mechanical Acuity",
            [4] = "131092\t131337\t131267\t131232\t131197\t131372\t131127\t131302\t131162\t131407\tGloves of Mechanical Acuity",
            [5] = "131093\t131338\t131268\t131233\t131198\t131373\t131128\t131303\t131163\t131408\tHat of Mechanical Acuity",
            [6] = "131094\t131339\t131269\t131234\t131199\t131374\t131129\t131304\t131164\t131409\tBreeches of Mechanical Acuity",
            [7] = "131096\t131341\t131271\t131236\t131201\t131376\t131131\t131306\t131166\t131411\tEpaulets of Mechanical Acuity",
            [8] = "131097\t131342\t131272\t131237\t131202\t131377\t131132\t131307\t131167\t131412\tSash of Mechanical Acuity",
            [9] = "131098\t131343\t131273\t131238\t131203\t131378\t131133\t131308\t131168\t131413\tJack of Mechanical Acuity",
            [10] = "131099\t131344\t131274\t131239\t131204\t131379\t131134\t131309\t131169\t131414\tBoots of Mechanical Acuity",
            [11] = "131100\t131345\t131275\t131240\t131205\t131380\t131135\t131310\t131170\t131415\tBracers of Mechanical Acuity",
            [12] = "131101\t131346\t131276\t131241\t131206\t131381\t131136\t131311\t131171\t131416\tHelmet of Mechanical Acuity",
            [13] = "131102\t131347\t131277\t131242\t131207\t131382\t131137\t131312\t131172\t131417\tGuards of Mechanical Acuity",
            [14] = "131103\t131348\t131278\t131243\t131208\t131383\t131138\t131313\t131173\t131418\tArm Cops of Mechanical Acuity",
            [15] = "131104\t131349\t131279\t131244\t131209\t131384\t131139\t131314\t131174\t131419\tBelt of Mechanical Acuity",
        },
        [6] =
        {
            [1] = "131077\t131147\t131287\t131182\t131112\t131217\t131357\t131252\t131322\t131392\tBow of Mechanical Acuity",
            [2] = "131082\t131327\t131257\t131222\t131187\t131362\t131117\t131292\t131152\t131397\tShield of Mechanical Acuity",
            [3] = "131078\t131148\t131288\t131183\t131113\t131218\t131358\t131253\t131323\t131393\tInferno Staff of Mechanical Acuity",
            [4] = "131079\t131149\t131289\t131184\t131114\t131219\t131359\t131254\t131324\t131394\tIce Staff of Mechanical Acuity",
            [5] = "131080\t131150\t131290\t131185\t131115\t131220\t131360\t131255\t131325\t131395\tLightning Staff of Mechanical Acuity",
            [6] = "131081\t131151\t131291\t131186\t131116\t131221\t131361\t131256\t131326\t131396\tRestoration Staff of Mechanical Acuity",
        },
    },
    [41] =
    {
        [1] =
        {
            [1] = "130370\t130440\t130580\t130475\t130405\t130510\t130650\t130545\t130615\t130685\tInnate Axiom axe",
            [2] = "130371\t130441\t130581\t130476\t130406\t130511\t130651\t130546\t130616\t130686\tInnate Axiom mace",
            [3] = "130372\t130442\t130582\t130477\t130407\t130512\t130652\t130547\t130617\t130687\tInnate Axiom Sword",
            [4] = "130373\t130443\t130583\t130478\t130408\t130513\t130653\t130548\t130618\t130688\tInnate Axiom Battle Axe",
            [5] = "130374\t130444\t130584\t130479\t130409\t130514\t130654\t130549\t130619\t130689\tInnate Axiom Maul",
            [6] = "130375\t130445\t130585\t130480\t130410\t130515\t130655\t130550\t130620\t130690\tInnate Axiom Greatsword",
            [7] = "130376\t130446\t130586\t130481\t130411\t130516\t130656\t130551\t130621\t130691\tInnate Axiom Dagger",
            [8] = "130383\t130628\t130558\t130523\t130488\t130663\t130418\t130593\t130453\t130698\tInnate Axiom Cuirass",
            [9] = "130384\t130629\t130559\t130524\t130489\t130664\t130419\t130594\t130454\t130699\tInnate Axiom Sabatons",
            [10] = "130385\t130630\t130560\t130525\t130490\t130665\t130420\t130595\t130455\t130700\tInnate Axiom Gauntlets",
            [11] = "130386\t130631\t130561\t130526\t130491\t130666\t130421\t130596\t130456\t130701\tInnate Axiom Helm",
            [12] = "130387\t130632\t130562\t130527\t130492\t130667\t130422\t130597\t130457\t130702\tInnate Axiom Greaves",
            [13] = "130388\t130633\t130563\t130528\t130493\t130668\t130423\t130598\t130458\t130703\tInnate Axiom Pauldron",
            [14] = "130389\t130634\t130564\t130529\t130494\t130669\t130424\t130599\t130459\t130704\tInnate Axiom Girdle",
        },
        [2] =
        {
            [1] = "130390\t130635\t130565\t130530\t130495\t130670\t130425\t130600\t130460\t130705\tInnate Axiom Robe",
            [2] = "130395\t130640\t130570\t130535\t130500\t130675\t130430\t130605\t130465\t130710\tInnate Axiom Jerkin",
            [3] = "130391\t130636\t130566\t130531\t130496\t130671\t130426\t130601\t130461\t130706\tInnate Axiom Shoes",
            [4] = "130392\t130637\t130567\t130532\t130497\t130672\t130427\t130602\t130462\t130707\tInnate Axiom Gloves",
            [5] = "130393\t130638\t130568\t130533\t130498\t130673\t130428\t130603\t130463\t130708\tInnate Axiom Hat",
            [6] = "130394\t130639\t130569\t130534\t130499\t130674\t130429\t130604\t130464\t130709\tInnate Axiom Breeches",
            [7] = "130396\t130641\t130571\t130536\t130501\t130676\t130431\t130606\t130466\t130711\tInnate Axiom Epaulets",
            [8] = "130397\t130642\t130572\t130537\t130502\t130677\t130432\t130607\t130467\t130712\tInnate Axiom Sash",
            [9] = "130398\t130643\t130573\t130538\t130503\t130678\t130433\t130608\t130468\t130713\tInnate Axiom Jack",
            [10] = "130399\t130644\t130574\t130539\t130504\t130679\t130434\t130609\t130469\t130714\tInnate Axiom Boots",
            [11] = "130400\t130645\t130575\t130540\t130505\t130680\t130435\t130610\t130470\t130715\tInnate Axiom Bracers",
            [12] = "130401\t130646\t130576\t130541\t130506\t130681\t130436\t130611\t130471\t130716\tInnate Axiom Helmet",
            [13] = "130402\t130647\t130577\t130542\t130507\t130682\t130437\t130612\t130472\t130717\tInnate Axiom Guards",
            [14] = "130403\t130648\t130578\t130543\t130508\t130683\t130438\t130613\t130473\t130718\tInnate Axiom Arm Cops",
            [15] = "130404\t130649\t130579\t130544\t130509\t130684\t130439\t130614\t130474\t130719\tInnate Axiom Belt",
        },
        [6] =
        {
            [1] = "130377\t130447\t130587\t130482\t130412\t130517\t130657\t130552\t130622\t130692\tInnate Axiom Bow",
            [2] = "130382\t130627\t130557\t130522\t130487\t130662\t130417\t130592\t130452\t130697\tInnate Axiom Shield",
            [3] = "130378\t130448\t130588\t130483\t130413\t130518\t130658\t130553\t130623\t130693\tInnate Axiom Inferno Staff",
            [4] = "130379\t130449\t130589\t130484\t130414\t130519\t130659\t130554\t130624\t130694\tInnate Axiom Ice Staff",
            [5] = "130380\t130450\t130590\t130485\t130415\t130520\t130660\t130555\t130625\t130695\tInnate Axiom Lightning Staff",
            [6] = "130381\t130451\t130591\t130486\t130416\t130521\t130661\t130556\t130626\t130696\tInnate Axiom Restoration Staff",
        },
    },
    [42] =
    {
        [1] =
        {
            [1] = "130720\t130790\t130930\t130825\t130755\t130860\t131000\t130895\t130965\t131035\tFortified Brass axe",
            [2] = "130721\t130791\t130931\t130826\t130756\t130861\t131001\t130896\t130966\t131036\tFortified Brass mace",
            [3] = "130722\t130792\t130932\t130827\t130757\t130862\t131002\t130897\t130967\t131037\tFortified Brass Sword",
            [4] = "130723\t130793\t130933\t130828\t130758\t130863\t131003\t130898\t130968\t131038\tFortified Brass Battle Axe",
            [5] = "130724\t130794\t130934\t130829\t130759\t130864\t131004\t130899\t130969\t131039\tFortified Brass Maul",
            [6] = "130725\t130795\t130935\t130830\t130760\t130865\t131005\t130900\t130970\t131040\tFortified Brass Greatsword",
            [7] = "130726\t130796\t130936\t130831\t130761\t130866\t131006\t130901\t130971\t131041\tFortified Brass Dagger",
            [8] = "130733\t130978\t130908\t130873\t130838\t131013\t130768\t130943\t130803\t131048\tFortified Brass Cuirass",
            [9] = "130734\t130979\t130909\t130874\t130839\t131014\t130769\t130944\t130804\t131049\tFortified Brass Sabatons",
            [10] = "130735\t130980\t130910\t130875\t130840\t131015\t130770\t130945\t130805\t131050\tFortified Brass Gauntlets",
            [11] = "130736\t130981\t130911\t130876\t130841\t131016\t130771\t130946\t130806\t131051\tFortified Brass Helm",
            [12] = "130737\t130982\t130912\t130877\t130842\t131017\t130772\t130947\t130807\t131052\tFortified Brass Greaves",
            [13] = "130738\t130983\t130913\t130878\t130843\t131018\t130773\t130948\t130808\t131053\tFortified Brass Pauldron",
            [14] = "130739\t130984\t130914\t130879\t130844\t131019\t130774\t130949\t130809\t131054\tFortified Brass Girdle",
        },
        [2] =
        {
            [1] = "130740\t130985\t130915\t130880\t130845\t131020\t130775\t130950\t130810\t131055\tFortified Brass Robe",
            [2] = "130745\t130990\t130920\t130885\t130850\t131025\t130780\t130955\t130815\t131060\tFortified Brass Jerkin",
            [3] = "130741\t130986\t130916\t130881\t130846\t131021\t130776\t130951\t130811\t131056\tFortified Brass Shoes",
            [4] = "130742\t130987\t130917\t130882\t130847\t131022\t130777\t130952\t130812\t131057\tFortified Brass Gloves",
            [5] = "130743\t130988\t130918\t130883\t130848\t131023\t130778\t130953\t130813\t131058\tFortified Brass Hat",
            [6] = "130744\t130989\t130919\t130884\t130849\t131024\t130779\t130954\t130814\t131059\tFortified Brass Breeches",
            [7] = "130746\t130991\t130921\t130886\t130851\t131026\t130781\t130956\t130816\t131061\tFortified Brass Epaulets",
            [8] = "130747\t130992\t130922\t130887\t130852\t131027\t130782\t130957\t130817\t131062\tFortified Brass Sash",
            [9] = "130748\t130993\t130923\t130888\t130853\t131028\t130783\t130958\t130818\t131063\tFortified Brass Jack",
            [10] = "130749\t130994\t130924\t130889\t130854\t131029\t130784\t130959\t130819\t131064\tFortified Brass Boots",
            [11] = "130750\t130995\t130925\t130890\t130855\t131030\t130785\t130960\t130820\t131065\tFortified Brass Bracers",
            [12] = "130751\t130996\t130926\t130891\t130856\t131031\t130786\t130961\t130821\t131066\tFortified Brass Helmet",
            [13] = "130752\t130997\t130927\t130892\t130857\t131032\t130787\t130962\t130822\t131067\tFortified Brass Guards",
            [14] = "130753\t130998\t130928\t130893\t130858\t131033\t130788\t130963\t130823\t131068\tFortified Brass Arm Cops",
            [15] = "130754\t130999\t130929\t130894\t130859\t131034\t130789\t130964\t130824\t131069\tFortified Brass Belt",
        },
        [6] =
        {
            [1] = "130727\t130797\t130937\t130832\t130762\t130867\t131007\t130902\t130972\t131042\tFortified Brass Bow",
            [2] = "130732\t130977\t130907\t130872\t130837\t131012\t130767\t130942\t130802\t131047\tFortified Brass Shield",
            [3] = "130728\t130798\t130938\t130833\t130763\t130868\t131008\t130903\t130973\t131043\tFortified Brass Inferno Staff",
            [4] = "130729\t130799\t130939\t130834\t130764\t130869\t131009\t130904\t130974\t131044\tFortified Brass Ice Staff",
            [5] = "130730\t130800\t130940\t130835\t130765\t130870\t131010\t130905\t130975\t131045\tFortified Brass Lightning Staff",
            [6] = "130731\t130801\t130941\t130836\t130766\t130871\t131011\t130906\t130976\t131046\tFortified Brass Restoration Staff",
        },
    },
    ["none"] =
    {
        [1] =
        {
            [1] = "43529\t45018\t45053\t45088\t45123\t45158\t45193\t45228\t45263\t56026\tiron axe^n",
            [2] = "43530\t45019\t45054\t45089\t45124\t45159\t45194\t45229\t45264\t56027\tiron mace^n",
            [3] = "43531\t45020\t45055\t45090\t45125\t45160\t45195\t45230\t45265\t56028\tiron sword^n",
            [4] = "43532\t45021\t45056\t45091\t45126\t45161\t45196\t45231\t45266\t56029\tiron battle axe^n",
            [5] = "43533\t45022\t45057\t45092\t45127\t45162\t45197\t45232\t45267\t56030\tiron maul^n",
            [6] = "43534\t45023\t45058\t45093\t45128\t45163\t45198\t45233\t45268\t56031\tiron greatsword^n",
            [7] = "43535\t45024\t45059\t45094\t45129\t45164\t45199\t45234\t45269\t56032\tiron dagger^n",
            [8] = "43537\t45025\t45060\t45095\t45130\t45165\t45200\t45235\t45270\t56038\tiron cuirass^n",
            [9] = "43538\t45026\t45061\t45096\t45131\t45166\t45201\t45236\t45271\t56039\tiron sabatons^p",
            [10] = "43539\t45027\t45062\t45097\t45132\t45167\t45202\t45237\t45272\t56040\tiron gauntlets^p",
            [11] = "43562\t45028\t45063\t45098\t45133\t45168\t45203\t45238\t45273\t56041\tiron helm^n",
            [12] = "43540\t45029\t45064\t45099\t45134\t45169\t45204\t45239\t45274\t56042\tiron greaves^p",
            [13] = "43541\t45030\t45065\t45100\t45135\t45170\t45205\t45240\t45275\t56043\tiron pauldron^p",
            [14] = "43542\t45031\t45066\t45101\t45136\t45171\t45206\t45241\t45276\t56044\tiron girdle^n",
        },
        [2] =
        {
            [1] = "43543\t45032\t45067\t45102\t45137\t45172\t45207\t45242\t45277\t56045\thomespun robe^n",
            [2] = "44241\t45037\t45072\t45107\t45142\t45177\t45212\t45247\t45282\t56050\thomespun jerkin^n",
            [3] = "43544\t45033\t45068\t45103\t45138\t45173\t45208\t45243\t45278\t56046\thomespun shoes^p",
            [4] = "43545\t45034\t45069\t45104\t45139\t45174\t45209\t45244\t45858\t56047\thomespun gloves^p",
            [5] = "43564\t45035\t45070\t45105\t45140\t45175\t45210\t45245\t45280\t56048\thomespun hat^n",
            [6] = "43546\t45036\t45071\t45106\t45141\t45176\t45211\t45246\t45281\t56049\thomespun breeches^p",
            [7] = "43547\t45038\t45073\t45108\t45143\t45178\t45213\t45248\t45283\t56051\thomespun epaulets^p",
            [8] = "43548\t45039\t45074\t45109\t45144\t45179\t45214\t45249\t45284\t56052\thomespun sash^p",
            [9] = "43550\t45041\t45076\t45111\t45146\t45181\t45216\t45251\t45286\t56053\trawhide jack^n",
            [10] = "43551\t45042\t45077\t45112\t45147\t45182\t45217\t45252\t45287\t56054\trawhide boots^p",
            [11] = "43552\t45043\t45078\t45113\t45148\t45183\t45218\t45253\t45288\t56055\trawhide bracers^p",
            [12] = "43563\t45044\t45079\t45114\t45149\t45184\t45219\t45254\t45289\t56056\trawhide helmet^n",
            [13] = "43553\t45045\t45080\t45115\t45150\t45185\t45220\t45255\t45290\t56057\trawhide guards^p",
            [14] = "43554\t45046\t45081\t45116\t45151\t45186\t45221\t45256\t45291\t56058\trawhide arm cops^p",
            [15] = "43555\t45047\t45082\t45117\t45152\t45187\t45222\t45257\t45292\t56059\trawhide belt^n",
        },
        [6] =
        {
            [1] = "43549\t45040\t45075\t45110\t45145\t45180\t45215\t45250\t45285\t56033\tmaple bow^n",
            [2] = "43556\t45048\t45083\t45118\t45153\t45188\t45223\t45258\t45293\t56060\tmaple shield^n",
            [3] = "43557\t45049\t45084\t45119\t45154\t45189\t45224\t45259\t45294\t56034\tmaple inferno staff^n",
            [4] = "43558\t45050\t45085\t45120\t45155\t45190\t45225\t45260\t45295\t56035\tmaple ice staff^n",
            [5] = "43559\t45051\t45086\t45121\t45156\t45191\t45226\t45261\t45296\t56036\tmaple lightning staff^n",
            [6] = "43560\t45052\t45087\t45122\t45157\t45192\t45227\t45262\t45297\t56037\tmaple restoration staff^n",
        },
    },
}
