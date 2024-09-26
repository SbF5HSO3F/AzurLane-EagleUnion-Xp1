-- EagleUnion_Laffey
-- Author: jjj
-- DateCreated: 2023/10/31 22:01:41
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnion_Core.lua')

--||====================base functions====================||--

--Boost No Boost Tech
--[[function LaffeyBoostNoBoostTech(pPlayer)
    local PlayerTech = pPlayer:GetTechs()
    for i in GameInfo.Technologies() do
        local HasBoost = false
        local Tech = i.TechnologyType
        for j in GameInfo.Boosts() do
            if j.TechnologyType then
                HasBoost = true
                break
            end
        end
        if not HasBoost and not PlayerTech:HasBoostBeenTriggered(i.Index) then
            PlayerTech:TriggerBoost(i.Index)
            print(Tech, 'is boosted!')
        end
    end
end]]

--Boost No Boost Civic
--[[function LaffeyBoostNoBoostCivic(pPlayer)
    local PlayerCulture = pPlayer:GetCulture()
    for i in GameInfo.Civics() do
        local HasBoost = false
        local Civic = i.CivicType
        for j in GameInfo.Boosts() do
            if Civic == j.CivicType then
                HasBoost = true
                break
            end
        end
        if not HasBoost and not PlayerCulture:HasBoostBeenTriggered(i.Index) then
            PlayerCulture:TriggerBoost(i.Index)
            print(Civic, 'is boosted!')
        end
    end
end]]

--Initialize Laffey
--[[function InitializeLaffeyBoost()
    if Game:GetProperty('LAFFEY_INITALIZE') then
        return
    end
    local players = Game.GetPlayers();
    for _, player in ipairs(players) do
        local pPlayerConfig = PlayerConfigurations[player:GetID()]
        if pPlayerConfig:GetLeaderTypeName() == 'LEADER_LAFFEY_DD459' then
            LaffeyBoostNoBoostTech(player)
            LaffeyBoostNoBoostCivic(player)
            break;
        end
    end
    Game:SetProperty('LAFFEY_INITALIZE', true)
    print(Game:GetProperty('LAFFEY_INITALIZE'))
end]]

--Is No Boost?
function LaffeyIsNoBoost(Type)
    local NoBoost = false
    for row in GameInfo.Laffey_NoBoost() do
        if row.NoBoostType == Type then
            NoBoost = true
            break
        end
    end
    return NoBoost
end

--Tech Boost
function LaffeyTechBoost(pPlayer)
    local baseIndex = 1;
    local PlayerTech = pPlayer:GetTechs();
    while true do
        print(baseIndex)
        local EraType = nil;
        for era in GameInfo.Eras() do
            if era.ChronologyIndex == baseIndex then
                EraType = era.EraType
                print(EraType)
                break
            end
        end
        if EraType then
            local techlist = {};
            for row in GameInfo.Technologies() do
                if row.EraType == EraType and ((not PlayerTech:HasTech(row.Index)) or row.Repeatable == true) then
                    table.insert(techlist, row.Index)
                end
            end
            if #techlist > 0 then
                local iTech = techlist[EagleUnionGetRandNum(#techlist)]
                local TechType = GameInfo.Technologies[iTech].TechnologyType
                print(TechType)
                if PlayerTech:HasBoostBeenTriggered(iTech) or LaffeyIsNoBoost(TechType) then
                    PlayerTech:SetResearchProgress(iTech, PlayerTech:GetResearchCost(iTech))
                else
                    PlayerTech:TriggerBoost(iTech, 2)
                end
                break
            else
                baseIndex = baseIndex + 1
            end
        else
            break
        end
    end
end

--Civic Boost
function LaffeyCivicBoost(pPlayer)
    local baseIndex = 1;
    local PlayerCulture = pPlayer:GetCulture();
    while true do
        print(baseIndex)
        local EraType = nil;
        for era in GameInfo.Eras() do
            if era.ChronologyIndex == baseIndex then
                EraType = era.EraType
                print(EraType)
                break
            end
        end
        if EraType then
            local civiclist = {};
            for row in GameInfo.Civics() do
                if row.EraType == EraType and ((not PlayerCulture:HasCivic(row.Index)) or row.Repeatable == true) then
                    table.insert(civiclist, row.Index)
                end
            end
            if #civiclist > 0 then
                local iCivic = civiclist[EagleUnionGetRandNum(#civiclist)];
                local CivicType = GameInfo.Civics[iCivic].CivicType
                print(CivicType)
                if PlayerCulture:HasBoostBeenTriggered(iCivic) or LaffeyIsNoBoost(CivicType) then
                    PlayerCulture:SetCulturalProgress(iCivic, PlayerCulture:GetCultureCost(iCivic))
                else
                    PlayerCulture:TriggerBoost(iCivic, 2)
                end
                break
            else
                baseIndex = baseIndex + 1
            end
        else
            break
        end
    end
end

--||===================Events functions===================||--

--Laffey Defended Buff
--[[function LaffeyUnitsOnDefending(pCombatResult)
    local defender = pCombatResult[CombatResultParameters.DEFENDER];
    local defenderInfo = defender[CombatResultParameters.ID];
    local pDefenderUnit = UnitManager.GetUnit(defenderInfo.player, defenderInfo.id);
    if pDefenderUnit == nil then
        return;
    end
    if pDefenderUnit:GetAbility():GetAbilityCount('ABILITY_LAFFEY_COMBAT_UNITS_BUFF') > 0 then
        local attacker = pCombatResult[CombatResultParameters.ATTACKER];
        local attackerInfo = attacker[CombatResultParameters.ID];
        if (defenderInfo.type == ComponentType.UNIT and attackerInfo.type == ComponentType.UNIT) then
            local defenderDamage = defender[CombatResultParameters.DAMAGE_TO];
            local damageNum = defenderDamage * 0.5;
            local pAttackerUnit = UnitManager.GetUnit(attackerInfo.player, attackerInfo.id);
            if (pAttackerUnit:GetDamage() + damageNum) >= 100 then
                pAttackerUnit:SetDamage(100);
                UnitManager.Kill(pAttackerUnit, false);
            else
                pAttackerUnit:ChangeDamage(damageNum);
            end
        end
    end
end]]

--Kill Stronger Unit Boosted
function LaffeyKillStrongerUnitBoosted(killedPlayerID, killedUnitID, playerID, unitID)
    --is Laffey?
    if EagleUnionLeaderTypeMatched(playerID, 'LEADER_LAFFEY_DD459') then
        local pPlayer = Players[playerID]; LaffeyTechBoost(pPlayer); LaffeyCivicBoost(pPlayer)
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------Events-----------------
    Events.UnitKilledInCombat.Add(LaffeyKillStrongerUnitBoosted)
    ----------------------------------------
    print('EagleUnion_Laffey Initial success!')
end

Initialize()
