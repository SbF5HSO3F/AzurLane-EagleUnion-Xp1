-- EagleUnionPoint_Eldridge
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/27 7:30:37
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||===================local variables====================||--

local EldridgePerPop = 1
local EldridgeReduction = 10
local EldridgeAddLimit = 25

--||====================base functions====================||--

--添加新额外点数
EaglePointManager.Points.Extra.Eldridge = {
    Tooltip = 'LOC_EAGLE_POINT_FROM_ELDRIDGE_DE173',
    GetPointYield = function(playerID)
        local point = 0
        --是否是埃尔德里奇
        if EagleCore.CheckLeaderMatched(playerID, 'LEADER_ELDRIDGE_DE173') then
            --获取玩家人口
            local cities = Players[playerID]:GetCities()
            for _, city in cities:Members() do
                local pop = city:GetPopulation()
                point = point + pop * EldridgePerPop
            end
        end
        return EagleCore.Floor(point)
    end,
    GetTooltip = function(self, playerID)
        local yield = self.GetPointYield(playerID)
        return yield ~= 0 and Locale.Lookup(self.Tooltip, yield) or ''
    end
}

--花费减免与上限
EaglePointManager.Reduction.Sources.Eldridge = {
    Tooltip = 'LOC_EAGLE_POINT_REDUCTION_ELDRIDGE_DE173',
    GetModifier = function(self, playerID)
        --获取点数减免
        local modifier = 0
        if EagleCore.CheckLeaderMatched(playerID, 'LEADER_ELDRIDGE_DE173') then
            modifier = EldridgeReduction
        end
        --获取点数减免上限
        local limit = self.Limit
        if limit ~= nil then modifier = math.min(modifier, limit) end
        --返回最终的减免
        return EagleCore.Round(modifier)
    end,
    GetTooltip = function(self, playerID)
        local modifier = -self:GetModifier(playerID)
        return modifier ~= 0 and Locale.Lookup(self.Tooltip, modifier) or ''
    end
}

EaglePointManager.Reduction.Limit.Factor.Eldridge = {
    GetLimitChange = function(playerID)
        if EagleCore.CheckLeaderMatched(playerID, 'LEADER_ELDRIDGE_DE173') then
            return EldridgeAddLimit
        end
        return 0
    end
}
