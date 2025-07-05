local plateModel = "prop_fib_badge"
local plateModel2 = "prop_fib_badge"
local animDict = "missfbi_s4mop"
local animName = "swipe_card"

RegisterCommand('pdbadge', function()
    startAnim()
end)

function startAnim()
	local playerPed = PlayerPedId()
	local jobname = ESX.PlayerData.job.name

	if(jobname ~= "offpolice" and jobname ~= 'police' and jobname ~= 'ambulance' and jobname ~= 'offambulance' and jobname ~= "lawyer") then
		TriggerEvent('br_notify:show', 'error', 'Police Job', "רק שוטרים/מדא/עורכי דין יכולים להשתמש בפקודה הזאת", 5000, false)
		return
	end

	if(IsEntityDead(playerPed) or LocalPlayer.state.down) then
		TriggerEvent('br_notify:show', 'error', 'Police Job', "אתה מת ולא יכול להציג תעודה", 5000, false)
		return
	end

    if(IsPedCuffed(playerPed)) then
        return
    end

    RequestModel(GetHashKey(plateModel))
    while not HasModelLoaded(GetHashKey(plateModel)) do
        Wait(0)
    end
	ClearPedSecondaryTask(PlayerPedId())
	RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

	SetPedCurrentWeaponVisible(playerPed, false, 1, 1, 1)
    local plyCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.0, -5.0)
    local platespawned = CreateObject(GetHashKey(plateModel), plyCoords.x, plyCoords.y, plyCoords.z, true, true, 0)
    Wait(100)
    if(jobname == "police" or jobname == "offpolice") then
	    ExecuteCommand("me 👮 מציג תעודת שוטר 👮")
        TriggerEvent("gi-3dme:network:mecmd","👮 מציג תעודת שוטר 👮")
    elseif(jobname == "ambulance" or jobname == "offambulance") then
        TriggerEvent("gi-3dme:network:mecmd","👨‍⚕️ מציג תעודת פרמדיק 👨‍⚕️")
    elseif(jobname == "lawyer") then
        TriggerEvent("gi-3dme:network:mecmd","👨‍🎓 מציג תעודת עורך דין 👨‍🎓")
    end
	PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_CLOTHESSHOP_SOUNDSET", 1)
    local netid = ObjToNet(platespawned)
    SetNetworkIdExistsOnAllMachines(netid, true)
    SetNetworkIdCanMigrate(netid, false)
    TaskPlayAnim(playerPed, 1.0, -1, -1, 50, 0, 0, 0, 0)
    TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, 50, 0, 0, 0, 0)
    Wait(800)
    AttachEntityToEntity(platespawned, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
    local plate_net = netid
    Wait(3000)
    ClearPedSecondaryTask(playerPed)
	SetPedCurrentWeaponVisible(playerPed, true, 1, 1, 1)
    DetachEntity(NetToObj(plate_net), 1, 1)
    DeleteEntity(NetToObj(plate_net))
    plate_net = nil
end

RegisterNetEvent("esx_policejob:CivIDAnim",function()
    IdAnim()
end)

function IdAnim()
	local playerPed = PlayerPedId()

	if(IsEntityDead(playerPed) or LocalPlayer.state.down or IsPedInAnyVehicle(playerPed,false) or IsPedCuffed(playerPed)) then
		return
	end


    RequestModel(GetHashKey(plateModel))
    while not HasModelLoaded(GetHashKey(plateModel)) do
        Wait(0)
    end
	ClearPedSecondaryTask(PlayerPedId())
	RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

	SetPedCurrentWeaponVisible(playerPed, false, 1, 1, 1)
    local plyCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.0, -5.0)
    local platespawned = CreateObject(GetHashKey(plateModel), plyCoords.x, plyCoords.y, plyCoords.z, true, true, 0)
    Wait(100)
    local netid = ObjToNet(platespawned)
    SetNetworkIdExistsOnAllMachines(netid, true)
    SetNetworkIdCanMigrate(netid, false)
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 50, 0, 0, 0, 0)
    SetEntityAnimSpeed(playerPed, animDict, animName, 5.0)
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(GetHashKey(plateModel))
    Wait(800)
    AttachEntityToEntity(platespawned, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
    local plate_net = netid
    Wait(3000)
    ClearPedSecondaryTask(playerPed)
	SetPedCurrentWeaponVisible(playerPed, true, 1, 1, 1)
    DetachEntity(NetToObj(plate_net), 1, 1)
    DeleteEntity(NetToObj(plate_net))
    plate_net = nil
end
