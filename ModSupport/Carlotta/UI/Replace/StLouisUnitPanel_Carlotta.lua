-- StLouisUnitPanel_Carlotta
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/22 11:01:29
--------------------------------------------------------------

local StLouisCarlottaReinit = StLouisReinit
local emeraldType = 'RESOURCE_EMERALD_BU'

function StLouisReinit()
    StLouisCarlottaReinit()
    local emerald = EagleResource:new(emeraldType)
    Luxuries.Resources[emeraldType] = emerald
end

include('StLouisUnitPanel_Carlotta_', true)
