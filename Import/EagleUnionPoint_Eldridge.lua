-- EagleUnionPoint_Eldridge
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/27 7:30:37
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||===================local variables====================||--

local EldridgePerPop = 1

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
