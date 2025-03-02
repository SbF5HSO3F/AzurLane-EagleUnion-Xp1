-- FlasherExtraPanel
-- Author: HSbF6HSO3F
-- DateCreated: 2024/3/7 19:49:07
--------------------------------------------------------------
--||=======================include========================||--
include('EagleUnionCore')

--||====================ExposedMembers====================||--

ExposedMembers.Flasher = ExposedMembers.Flasher or {}

--||===================local variables====================||--

local killCounter      = 'FlasherKills'
local goldBaseNum      = 100
local goldAddNum       = 50

--||====================base functions====================||--

--Reset the panel
function FlasherResetPanel(killNum)
    --get the loacl player
    local loaclPlayerID = Game.GetLocalPlayer()
    --check the player leader
    if EagleCore.CheckLeaderMatched(loaclPlayerID, 'LEADER_FLASHER_SS249') then
        Controls.FlasherPanelGrid:SetHide(false)
        --get the kill number
        local killNumber = nil
        if killNum then
            killNumber = killNum
        else
            --get the player
            local pPlayer = Players[loaclPlayerID]
            --get the kill number
            killNumber = pPlayer:GetProperty(killCounter) or 0
        end
        --get the gold base number
        local goldNum = EagleCore:ModifyBySpeed(goldBaseNum + goldAddNum * killNumber)
        --set the num
        Controls.FlasherGainCount:SetText(goldNum)
        --set the tooltip
        local tooltip = Locale.Lookup('LOC_TRAIT_LEADER_TEARY_EYED_HUNTRESS_NAME')
            .. '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_FLASHER_HUNTRESS_DESC', killNumber, goldNum)
            .. '[NEWLINE][NEWLINE]' .. Locale.Lookup('LOC_FLASHER_HUNTRESS_REFESRH')
        Controls.FlasherGainButton:SetToolTipString(tooltip)
    else
        Controls.FlasherPanelGrid:SetHide(true)
    end
end

--||===================Events functions===================||--s

--attach to the panel
function FlasherAttachPanel()
    --get the parent
    local parent = ContextPtr:LookUpControl("/InGame/WorldTracker/PanelStack")
    if parent ~= nil then
        Controls.FlasherPanelGrid:ChangeParent(parent)
        parent:AddChildAtIndex(Controls.FlasherPanelGrid, 1)
        Controls.FlasherGainButton:RegisterCallback(Mouse.eLClick,
            function()
                FlasherResetPanel()
                UI.PlaySound('UI_Screen_Open')
            end
        )
        Controls.FlasherGainButton:RegisterCallback(Mouse.eMouseEnter, EagleUnionEnter)

        parent:CalculateSize()
        parent:ReprocessAnchoring()
        FlasherResetPanel()
    end
end

--||======================initialize======================||--

--initialization function
function Initialize()
    -----------------------Events-----------------------
    Events.LoadGameViewStateDone.Add(FlasherAttachPanel)
    Events.LocalPlayerChanged.Add(FlasherResetPanel)
    ---------------------GameEvents---------------------
    ExposedMembers.Flasher.Reset = FlasherResetPanel
    ----------------------------------------------------
    print('Initial success!')
end

Initialize()
