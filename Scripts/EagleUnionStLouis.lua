-- EagleUnionStLouis
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 19:54:51
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||=================GameEvents functions=================||--

--创建随机资源
function StLouisCreated(playerID, param)
    local plot, list = Map.GetPlot(param.X, param.Y), param.List
    --get the random resource index
    local index = list[EagleCore.tableRandom(#list)]
    --create deer resource
    ResourceBuilder.SetResourceType(plot, index, 1)
    --get the unit
    local unit = UnitManager.GetUnit(playerID, param.UnitID)
    --report the unit active
    UnitManager.ReportActivation(unit, "STLOUIS_CREATED")
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------

    ---------------------GameEvents---------------------
    GameEvents.StLouisCreated.Add(StLouisCreated)
    ----------------------------------------------------
    ----------------------------------------------------
    print('Initial success!')
end

include('EagleUnionStLouis_', true)

Initialize()
