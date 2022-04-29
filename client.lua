local QBCore = exports["qb-core"]:GetCoreObject()
local ACTIVE = false
local currentBlips = {}
local PlayerData = QBCore.Functions.GetPlayerData() -- Just for resource restart (same as event handler)
local onGPS = false
local gpsProp = 0

local function isPolice()
    PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData ~= nil then
        local isPolice = false
        if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
            isPolice = true
        end
        return isPolice
    end
end

local function LoadAnimDic(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
end

local function GpsToggle(toggle)
    if not isPolice() then return end
    onGPS = toggle
    TriggerServerEvent("tnj-polgps:server:ToggleGPS", toggle)
end

local function RemoveAnyExistingEmergencyBlips()
	for i = #currentBlips, 1, -1 do
		local b = currentBlips[i]
		if b ~= 0 then
			RemoveBlip(b)
			table.remove(currentBlips, i)
		end
	end
end

local function RefreshBlips(activeEmergencyPersonnel)
	local myServerId = GetPlayerServerId(PlayerId())
	if isPolice() then
		for src, info in pairs(activeEmergencyPersonnel) do
			if src ~= myServerId then
				if info and info.coords then
					local blip = AddBlipForCoord(info.coords.x, info.coords.y, info.coords.z)
					SetBlipSprite(blip, 1)
					SetBlipColour(blip, info.color)
					SetBlipAsShortRange(blip, true)
					SetBlipDisplay(blip, 4)
					SetBlipShowCone(blip, true)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString(info.name)
					EndTextCommandSetBlipName(blip)
					table.insert(currentBlips, blip)
				end
			end
		end
	end
end

local function toggleGpsAnimation(pState)
    if not isPolice() then return end
	LoadAnimDic("cellphone@")
	if pState then
		TaskPlayAnim(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 2.0, 3.0, -1, 49, 0, 0, 0, 0)
		gpsProp = CreateObject(`prop_cs_hand_radio`, 1.0, 1.0, 1.0, 1, 1, 0)
		AttachEntityToEntity(gpsProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.14, 0.01, -0.02, 110.0, 120.0, -15.0, 1, 0, 0, 0, 2, 1)
	else
		StopAnimTask(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 1.0)
		ClearPedTasks(PlayerPedId())
		if gpsProp ~= 0 then
			DeleteObject(gpsProp)
			gpsProp = 0
		end
	end
end

local function toggleGps(toggle)
    if not isPolice() then return end
    gpsMenu = toggle
    SetNuiFocus(gpsMenu, gpsMenu)
    if gpsMenu then
        toggleGpsAnimation(true)
        SendNUIMessage({type = "open"})
    else
        toggleGpsAnimation(false)
        SendNUIMessage({type = "close"})
    end
end

local function IsGpsOn()
    return onGPS
end
exports("IsGpsOn", IsGpsOn)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    GpsToggle(false)
end)

RegisterNetEvent('tnj-polgps:use', function()
    if isPolice() then
        toggleGps(not gpsMenu)
    end
end)

RegisterNetEvent('tnj-polgps:onGpsDrop', function()
    if isPolice() then
        GpsToggle(false)
    end
end)

RegisterNUICallback('escape', function(data, cb)
    toggleGps(false)
end)

RegisterNUICallback('GPSON', function(data, cb)
    if not isPolice() then return end
    if not onGPS then
        onGPS = true
        GpsToggle(true)
    else
        TriggerEvent("QBCore:Notify", "GPS is already on", 'error')
    end
end)

RegisterNUICallback('GPSOFF', function(data, cb)
    if not isPolice() then return end
    if onGPS then
        onGPS = false
        GpsToggle(false)
    else
        TriggerEvent("QBCore:Notify", "GPS Isnt on yet", 'error')
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if LocalPlayer.state.isLoggedIn and onGPS and isPolice() then
            QBCore.Functions.TriggerCallback('tnj-polgps:server:GetItem', function(hasItem)
                if not hasItem then
                    if not isPolice() then return end
                    onGPS = false
                    GpsToggle(false)
                end
            end, "gps")
        end
    end
end)

RegisterNetEvent("tnj-polgps:toggle", function(on)
	if isPolice() then
		ACTIVE = on
		if not ACTIVE then
			RemoveAnyExistingEmergencyBlips()
		end
	end
end)

RegisterNetEvent("tnj-polgps:updateAll", function(data)
	if isPolice() then
		if ACTIVE then
			RemoveAnyExistingEmergencyBlips()
			RefreshBlips(data)
		end
	end
end)