local ADDON_NAME = "CritHitMarker"
local POOL_SIZE = 10
local MARKER_DURATION = 700
local SPREAD_RADIUS = 60

local defaults = {
    size  = 25,
    color = { r = 1, g = 1, b = 1 }
}

local sv
local markerPool = {}

local function CreateMarkerPool()
    for i = 1, POOL_SIZE do
        local ctrl = WINDOW_MANAGER:CreateControl(ADDON_NAME .. "_Marker" .. i, CritHitMarkerContainer, CT_TEXTURE)
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

    ctrl:SetDimensions(sv.size, sv.size)
    ctrl:SetColor(sv.color.r, sv.color.g, sv.color.b, 1)
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

local function RegisterSettings()
    local LAM = LibAddonMenu2
    if not LAM then return end

    local panelData = {
        type        = "panel",
        name        = "Crit Hit Marker",
        displayName = "Crit Hit Marker",
        author      = "|cBF00FF@Y|c8F39F2ar|c6073E6bo|c30ACD9Ja|c01E5CDnks|r",
        version     = "1.0.0",
        registerForRefresh = true,
    }

    local optionsData = {
        {
            type    = "slider",
            name    = "Marker Size",
            tooltip = "Size of the hit marker in pixels.",
            min     = 10,
            max     = 200,
            step    = 1,
            getFunc = function() return sv.size end,
            setFunc = function(value) sv.size = value end,
        },
        {
            type    = "colorpicker",
            name    = "Marker Color",
            tooltip = "Color tint applied to the hit marker. White = no tint.",
            getFunc = function() return sv.color.r, sv.color.g, sv.color.b, 1 end,
            setFunc = function(r, g, b, a)
                sv.color = { r = r, g = g, b = b }
            end,
        },
        {
            type    = "button",
            name    = "Test Marker",
            tooltip = "Trigger a test hit marker.",
            func    = function() ShowMarker() end,
        },
        {
            type    = "button",
            name    = "Reset to Defaults",
            tooltip = "Reset size and color back to default values.",
            func    = function()
                sv.size  = defaults.size
                sv.color = { r = defaults.color.r, g = defaults.color.g, b = defaults.color.b }
                LAM:RefreshPanel(ADDON_NAME .. "Panel")
            end,
        },
    }

    LAM:RegisterAddonPanel(ADDON_NAME .. "Panel", panelData)
    LAM:RegisterOptionControls(ADDON_NAME .. "Panel", optionsData)
end

local function OnAddOnLoaded(eventCode, addOnName)
    if addOnName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    CritHitMarkerSV = CritHitMarkerSV or {}
    sv = CritHitMarkerSV
    if sv.size == nil then sv.size = defaults.size end
    if sv.color == nil then sv.color = { r = defaults.color.r, g = defaults.color.g, b = defaults.color.b } end

    CreateMarkerPool()
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, OnCombatEvent)
    RegisterSettings()

    SLASH_COMMANDS["/crithit"] = function(args)
        if args == "test" then ShowMarker() end
    end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
