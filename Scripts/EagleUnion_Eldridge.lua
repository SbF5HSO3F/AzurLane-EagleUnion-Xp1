-- EagleUnion_Eldridge
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/24 22:55:24
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnion_Core.lua')

--||=================GameEvents functions=================||--

--transmission unit
function EldridgePlaceUnit(playerID, param)
    local pPlayer = Players[playerID]
    if pPlayer then
        local pUnit = UnitManager.GetUnit(playerID, param.unitID)
        if pUnit then
            UnitManager.PlaceUnit(pUnit, param.x, param.y)
        end
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------

    ---------------------GameEvents---------------------
    GameEvents.EldridgeRePlaceUnit.Add(EldridgePlaceUnit)
    ----------------------------------------------------
    ----------------------------------------------------
    print('Initial success!')
end

include('EagleUnion_Eldridge_', true)

Initialize()
