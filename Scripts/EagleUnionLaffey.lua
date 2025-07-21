-- EagleUnion_Laffey
-- Author: HSbF6HSO3F
-- DateCreated: 2023/10/31 22:01:41
--------------------------------------------------------------
--||=======================include========================||--
include('EagleCore')

--||====================base functions====================||--

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
                local iTech = techlist[EagleMath.GetRandNum(#techlist)]
                local TechType = GameInfo.Technologies[iTech].TechnologyType
                print(TechType)
                if PlayerTech:HasBoostBeenTriggered(iTech) or not EagleCore.HasBoost(TechType) then
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
                local iCivic = civiclist[EagleMath.GetRandNum(#civiclist)];
                local CivicType = GameInfo.Civics[iCivic].CivicType
                print(CivicType)
                if PlayerCulture:HasBoostBeenTriggered(iCivic) or not EagleCore.HasBoost(CivicType) then
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
    if EagleCore.CheckLeaderMatched(playerID, 'LEADER_LAFFEY_DD459') then
        local pPlayer = Players[playerID]; LaffeyTechBoost(pPlayer); LaffeyCivicBoost(pPlayer)
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------Events-----------------
    Events.UnitKilledInCombat.Add(LaffeyKillStrongerUnitBoosted)
    ----------------------------------------
    print('Initial success!')
end

include('EagleUnionLaffey_', true)

Initialize()
