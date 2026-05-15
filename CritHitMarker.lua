local ADDON_NAME = "CritHitMarker"
local POOL_SIZE = 10
local MARKER_DURATION = 700
local SPREAD_RADIUS = 60
local MARKER_W = 25
local MARKER_H = 25

local markerPool = {}

local function CreateMarkerPool()
    for i = 1, POOL_SIZE do
        local ctrl = WINDOW_MANAGER:CreateControl(ADDON_NAME .. "_Marker" .. i, CritHitMarkerContainer, CT_TEXTURE)
        ctrl:SetDimensions(MARKER_W, MARKER_H)
        ctrl:SetTexture("CritHitMarker/marker.dds")
        ctrl:SetDrawLayer(DL_OVERLAY)
        ctrl:SetHidden(true)

        local timeline = ANIMATION_MANAGER:CreateTimeline()
        local alphaAnim = timeline:InsertAnimation(ANIMATION_ALPHA, ctrl, 0)
        alphaAnim:SetStartAlpha(1)
        alphaAnim:SetEndAlpha(0)
        alphaAnim:SetDuration(MARKER_DURATION)

        timeline:SetHandler("OnStop", function()
            ctrl:SetHidden(true)
            ctrl:SetAlpha(1)
            table.insert(markerPool, ctrl)
        end)

        ctrl.timeline = timeline
        table.insert(markerPool, ctrl)
    end
end

local function ShowMarker()
    local ctrl = table.remove(markerPool)
    if not ctrl then return end

    local sw = CritHitMarkerContainer:GetWidth()
    local sh = CritHitMarkerContainer:GetHeight()
    local x = (sw / 2) + math.random(-SPREAD_RADIUS, SPREAD_RADIUS)
    local y = (sh / 2) + math.random(-SPREAD_RADIUS, SPREAD_RADIUS)

    ctrl:ClearAnchors()
    ctrl:SetAnchor(CENTER, CritHitMarkerContainer, TOPLEFT, x, y)
    ctrl:SetAlpha(1)
    ctrl:SetHidden(false)
    ctrl.timeline:PlayFromStart()
end

local function OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic,
    abilityActionSlotType, sourceName, sourceType, targetName, targetType,
    hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)

    if result ~= ACTION_RESULT_CRITICAL_DAMAGE then return end
    if sourceName:gsub("%^.*", "") ~= GetUnitName("player") then return end
    ShowMarker()
end

local function OnAddOnLoaded(eventCode, addOnName)
    if addOnName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    CreateMarkerPool()
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, OnCombatEvent)

    SLASH_COMMANDS["/crithit"] = function(args)
        if args == "test" then
            ShowMarker()
        end
    end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
