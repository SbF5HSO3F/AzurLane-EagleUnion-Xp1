-- EagleUnion_EldridgeUnitUI
-- Author: HSbF6HSO3F
-- DateCreated: 2024/12/24 20:39:42
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnion_Core')

--||===================local variables====================||--

local COLOR = UILens.CreateLensLayerHash("Hex_Coloring_Movement")
local m_EldridgeSelected, m_EldridgePlot = false, nil

--||======================MetaTable=======================||--

EldridgeUnitPanel = {
    --彩虹计划：传送
    Rainbow = {
        GetPlots = function(pUnit)
            --the plots
            local plots, hash = {}, {}
            --get the unitdef
            local unitdef = GameInfo.Units[pUnit:GetType()]
            if unitdef then
                local domain = unitdef.Domain
                --get the player
                local pPlayer = Players[pUnit:GetOwner()]
                --get cities
                local cities = pPlayer:GetCities()
                for _, city in cities:Members() do
                    --get the city plot
                    local plot = Map.GetPlot(city:GetX(), city:GetY())
                    if EagleCore.CanHaveUnit(plot, unitdef) then
                        --check if the unit is Sea
                        if domain == 'DOMAIN_SEA' then
                            if plot:IsAdjacentToShallowWater() then
                                table.insert(plots, plot:GetIndex())
                                hash[plot:GetIndex()] = 1
                            end
                        else
                            table.insert(plots, plot:GetIndex())
                            hash[plot:GetIndex()] = 1
                        end
                    end
                end
            end
            --return the plots
            return plots, hash
        end,
        --退出
        Quit = function(quit)
            if quit then
                UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
            end
            --清除颜色
            UILens.ClearLayerHexes(COLOR)
            UILens.ToggleLayerOff(COLOR)
            m_EldridgeSelected = false
            Controls.Rainbow:SetSelected(false)
        end,
        --设置状态
        SetState = function(self, state, pUnit)
            --set ui state
            if state then
                UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
                UI.SetInterfaceMode(InterfaceModeTypes.WB_SELECT_PLOT)
                local plots, hash = self.GetPlots(pUnit)
                m_SeydlitzPlot = hash
                if #plots > 0 then
                    UILens.SetLayerHexesArea(COLOR, Game.GetLocalPlayer(), plots)
                    UILens.ToggleLayerOn(COLOR)
                end
            else
                self.Quit(true)
            end
            --set the button selected state
            Controls.Rainbow:SetSelected(state)
        end,
        --回调函数
        Callback = function(self)
            --Get the unit and set param
            local pUnit = UI.GetHeadSelectedUnit()
            if pUnit then
                --Switched Selected State
                m_EldridgeSelected = not m_EldridgeSelected
                --set the button state
                self:SetState(m_EldridgeSelected, pUnit)
            end
        end
    },
    --电气功率：电击
    Voltage = {

    }
}

--||====================base functions====================||--


include('EagleUnion_EldridgeUnitUI_', true)
