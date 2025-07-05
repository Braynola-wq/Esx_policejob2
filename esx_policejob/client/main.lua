local CurrentActionData, handcuffTimer, dragStatus, currentTask = {}, {}, {}, {}
local HasAlreadyEnteredMarker, isDead, isHandcuffed, AnkleCuffed = false, false, false, false
local LastStation, LastPart, LastPartNum, LastEntity, CurrentAction, CurrentActionMsg
dragStatus.isDragged = false
local cuffprop
local blocklobjects = false
local handcuffing = false
local lastbackup
local recentlyIN = nil
local chasetimer = false

local varbar

RegisterNetEvent('ElFatahKuds')
AddEventHandler('ElFatahKuds', function(variable)
	varbar = variable
end)

local function DrawOutlineEntity(entity, bool)
	if IsEntityAPed(entity) or not DoesEntityExist(entity) then return end
	SetEntityDrawOutline(entity, bool)
	SetEntityDrawOutlineColor(255, 255, 255, 255)
	SetEntityDrawOutlineShader(1)
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
	if(xPlayer.job.name == "police") then
		recentlyIN = true
		Wait(120000)
		recentlyIN = nil
	end
end)

function cleanPlayer(playerPed)
	local grade = ESX.PlayerData.job.grade_name
	if(grade ~= "agent" and grade ~= "boss" and grade ~= "lieutenant") then
		SetPedArmour(playerPed, 0)
	end
	ClearPedBloodDamage(playerPed)
	ResetPedVisibleDamage(playerPed)
	ClearPedLastWeaponDamage(playerPed)
	ResetPedMovementClipset(playerPed, 0)
	TriggerEvent('gi-emotes:RevertWalk')
end

RegisterNetEvent("esx_policejob:Backup_C")
AddEventHandler("esx_policejob:Backup_C", function(coords,name,id, isCop)
	if(ESX ~= nil) then
		local blip = nil

		if not ESX.PlayerData or not ESX.PlayerData.job then
			return
		end
		if ESX.PlayerData.job.name == "police" then
			if isCop then
				exports["mythic_notify"]:SendAlert("inform", "!שוטר מבקש תגבורת", 10000, {["background-color"] = "#CD472A", ["color"] = "#ffffff"})
			else
				exports["mythic_notify"]:SendAlert("inform", "!מאבטח מבקש תגבורת", 10000, {["background-color"] = "#CD472A", ["color"] = "#ffffff"})
			end
			if not DoesBlipExist(blip) then
				blip = AddBlipForCoord(coords.x, coords.y, coords.z)
				SetBlipSprite(blip, 42)
				SetBlipScale(blip, 0.8)
				BeginTextCommandSetBlipName('STRING')
				AddTextComponentString("Backup | " ..name.." | "..id)
				EndTextCommandSetBlipName(blip)
				PlaySoundFrontend(-1, "HACKING_SUCCESS", 0, 1)

				Citizen.Wait(25000)
				RemoveBlip(blip)
			end
		end
	end
end)

RegisterNetEvent("esx_policejob:RecieveHeli_C")
AddEventHandler("esx_policejob:RecieveHeli_C", function(coords,name,id)
	if(ESX ~= nil) then
		

		if not ESX.PlayerData or not ESX.PlayerData.job then
			return
		end
		if ESX.PlayerData.job.name == "police" then
			exports["mythic_notify"]:SendAlert("inform", ".סימון מסוק משטרתי התקבל", 10000, {["background-color"] = "#CD472A", ["color"] = "#ffffff"})
			local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
			local alpha = 250

			SetBlipHighDetail(blip, true)
			SetBlipSprite(blip, 162)
			SetBlipScale(blip, 0.9)
			SetBlipColour(blip,48)
			SetBlipAlpha(blip, alpha)

			BeginTextCommandSetBlipName('STRING')
			AddTextComponentString("Target Marked | " ..name.." | "..id)
			EndTextCommandSetBlipName(blip)
			PlaySoundFrontend(-1, "HACKING_SUCCESS", 0, 1)

			Citizen.Wait(750)
			while alpha ~= 0 do
				Citizen.Wait(40 * 4)
				alpha = alpha - 1
				SetBlipAlpha(blip, alpha)

				if alpha == 0 then
					RemoveBlip(blip)
					return
				end
			end



			Citizen.Wait(25000)
			RemoveBlip(blip)
		end
	end
end)

function setUniform(job, playerPed,GetIn)
	TriggerEvent('skinchanger:getSkin', function(skin)
		if skin.sex == 0 then
			if Config.Uniforms[job].male then
				PlayClothesAnim(skin, Config.Uniforms[job].male, job, GetIn)
				--TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].male)
			else
				ESX.ShowNotification(_U('no_outfit'))
			end
		else
			if Config.Uniforms[job].female then
				PlayClothesAnim(skin, Config.Uniforms[job].female, job, GetIn)
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].female)
			else
				ESX.ShowNotification(_U('no_outfit'))
			end
		end
	end)
end

local function GetJobArmor()
	local armor = 100

	if(ESX.PlayerData.job.grade_name == "boss" or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
		return 100
	end

	local grade_name = ESX.PlayerData.job.grade_name
	if(grade_name == "recruit") then
		armor = 50
	elseif(grade_name == "officer") then
		armor = 60
	elseif(grade_name == "seniorofficer" or grade_name == "magav" or grade_name == "sergeant") then
		armor = 75
	end

	return armor
end

function PlayClothesAnim(skin, jobclothes, job, GetIn)
	if(currentTask.busy) then
		ESX.ShowRGBNotification("error","אתה כבר מחליף בגדים")
		return
	end
	currentTask.busy = true
	DoScreenFadeOut(800)
	while not IsScreenFadedOut() do
		Wait(10)
	end
	if(skin) then
		if(jobclothes) then
			TriggerEvent('skinchanger:loadClothes', skin, jobclothes)
		else
			TriggerEvent('skinchanger:loadSkin', skin)
		end
	end
	TriggerEvent('InteractSound_CL:PlayOnOne', 'zipcloth', 1.0)
	RequestAnimDict("move_m@_idles@shake_off")
	while not HasAnimDictLoaded("move_m@_idles@shake_off") do
		Wait(10)
	end
	TaskPlayAnim(cache.ped, "move_m@_idles@shake_off", "shakeoff_1", 7.0, 7.0, 3500, 51, 0, false, false, false)
	RemoveAnimDict("move_m@_idles@shake_off")
	DoScreenFadeIn(800)
	while not IsScreenFadedIn() do
		Wait(10)
	end
	if(not GetIn) then
		
		if( job == 'bullet_wear' or job == 'yamam_wear' or job == "magav_vest" ) then
			if(not ESX.HitRecently()) then
				SetPedArmour(cache.ped, GetJobArmor())
				PlaySoundFrontend(-1, "Armour_On", "DLC_GR_Steal_Miniguns_Sounds", true)
			else
				ESX.ShowRGBNotification("error","נפצעת לאחרונה ואתה לא יכול לחדש את הווסט")
			end
		elseif( job == 'gilet_wear') then
			if(not ESX.HitRecently()) then
				SetPedArmour(cache.ped, 15)
				PlaySoundFrontend(-1, "Armour_On", "DLC_GR_Steal_Miniguns_Sounds", true)
			else
				ESX.ShowRGBNotification("error","נפצעת לאחרונה ואתה לא יכול לחדש את הווסט")
			end
		end
		
	end
	currentTask.busy = false

end

local function OpenOutfits()
	ESX.TriggerServerCallback('esx_property:getPlayerDressing', function(dressing)
		local elements = {
			{unselectable = true, icon = "fas fa-shirt", title = "חדר לבוש משטרתי" .. ' - ' .. "בגדים שלך"},
		}

		for i=1, #dressing, 1 do
			table.insert(elements, {
				title = dressing[i],
				value = i
			})
		end

		ESX.OpenContext("left", elements, function(menu,element)
			local data = {current = element}
			
			TriggerEvent('skinchanger:getSkin', function(skin)
				ESX.TriggerServerCallback('esx_property:getPlayerOutfit', function(clothes)
					TriggerEvent('skinchanger:loadClothes', skin, clothes)
					TriggerEvent('esx_skin:setLastSkin', skin)

					TriggerEvent('skinchanger:getSkin', function(skin)
						ESX.SEvent('esx_skin:save', skin)
					end)
				end, data.current.value)
			end)
		end, function(menu)
			ESX.CloseContext()
			OpenCloakroomMenu()
		end)
	
	end)
end

function OpenCloakroomMenu(GetIn)
	local playerPed = cache.ped
	local grade = ESX.PlayerData.job.grade_name
	local elements = {
		{unselectable = true, icon = "fas fa-shirt", title = TranslateCap("cloakroom")},
		{icon = "fas fa-shirt", title = "Outfits", value = 'outfits'},
		{icon = "fas fa-shirt", title = TranslateCap('citizen_wear'), value = 'citizen_wear'},
		{icon = "fas fa-shield-alt", title = TranslateCap('bullet_wear'), value = 'bullet_wear'},
		{icon = "fas fa-shield-alt", title = TranslateCap('gilet_wear'), value = 'gilet_wear'},
		{icon = "fas fa-shield-alt", title = 'ווסט ימ"מ', value = 'yamam_wear'},
		{icon = "fas fa-shield-alt", title = 'ווסט מג"ב', value = 'magav_vest'},
		{icon = "fas fa-user-cog", title = "הגדרות", value = 'settings'},
	}

	if grade == 'recruit' then
		elements[#elements+1] = {icon = "fas fa-shirt", title = _U('police_wear') , value = 'recruit_wear'}
	elseif grade == 'officer' then
		elements[#elements+1] = {icon = "fas fa-shirt", title = _U('police_wear') , value = 'officer_wear'}
	elseif grade == 'seniorofficer' then
		elements[#elements+1] = {icon = "fas fa-shirt", title = "לבוש רב סיור" , value = 'seniorofficer_wear'}
	elseif grade == 'sergeant' then
		elements[#elements+1] = {icon = "fas fa-shirt", title = _U('police_wear') , value = 'sergeant_wear'}
	elseif grade == 'agent' then
		elements[#elements+1] = {icon = "fas fa-shirt", title = _U('police_wear') , value = 'lieutenant_wear'}
	elseif grade == 'magav' then
		elements[#elements+1] = {icon = "fas fa-shirt", title = 'בגדי מג"ב' , value = 'magav_wear'}
	elseif grade == 'lieutenant' then
		elements[#elements+1] = {icon = "fas fa-shirt", title = _U('police_wear') , value = 'lieutenant_wear'}
	elseif grade == 'boss' then
		elements[#elements+1] = {icon = "fas fa-shirt", title = _U('police_wear') , value = 'boss_wear'}
		elements[#elements+1] = {icon = "fas fa-shirt", title = 'בגדי מג"ב' , value = 'magav_wear'}
		elements[#elements+1] = {icon = "fas fa-shirt", title = 'מדי ימ"מ' , value = 'lieutenant_wear'}
		elements[#elements+1] = {icon = "fas fa-shirt", title = 'מדי יס"מ' , value = 'sergeant_wear'}
		elements[#elements+1] = {icon = "fas fa-shirt", title = 'מדי סיור' , value = 'officer_wear'}
		elements[#elements+1] = {icon = "fas fa-shirt", title = "לבוש רב סיור" , value = 'seniorofficer_wear'}
	end
	

	ESX.UI.Menu.CloseAll()
	ESX.CloseContext()
	ESX.OpenContext("left", elements, function(menu,element)
		cleanPlayer(playerPed)
		local data = {current = element}
		if data.current.value == 'outfits' then
			OpenOutfits()
		end

		if data.current.value == 'citizen_wear' then

			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
				PlayClothesAnim(skin)
				--TriggerEvent('skinchanger:loadSkin', skin)
			end)
		end

		if data.current.value == "settings" then
			UniformSettings()
		end

		if data.current.value == 'recruit_wear' or
			data.current.value == 'officer_wear' or
			data.current.value == 'sergeant_wear' or
			data.current.value == 'lieutenant_wear' or
			data.current.value == 'boss_wear' or
			data.current.value == 'bullet_wear' or
			data.current.value == 'gilet_wear' or
			data.current.value == 'yamam_wear' or
			data.current.value == 'magav_vest' or
			data.current.value == 'police_bag' or
			data.current.value == 'seniorofficer_wear' or
			data.current.value == 'magav_wear'
		then
			setUniform(data.current.value, playerPed,GetIn)
		end

	end, function(menu)
		ESX.CloseContext()
		HasAlreadyEnteredMarker = false
	end)
end

function UniformSettings()

	local elements = {
		{unselectable = true, icon = "fas fa-shirt", title = TranslateCap("cloakroom")},
		{icon = "fas fa-pistol", title = "אנימצית שליפה", value = 'draw_weapon'},
	}

	ESX.UI.Menu.CloseAll()

	ESX.OpenContext("left", elements, function(menu,element)
		local data = {current = element}
		if data.current.value == 'draw_weapon' then
			TriggerEvent('gi-holster:ForceNormal')
		end
	end, function(menu)
		ESX.CloseContext()
		OpenCloakroomMenu()
	end)
end



function OpenArmoryMenu(station)
	local elements = {}

	if Config.EnableArmoryManagement then
		elements[#elements+1] = {title = "ארון אחסון" , value = 'open_inventory', description = "!סטאש של המשטרה, לא לזרוק לפה זבל"}
		elements[#elements+1] = {title = "מחיקת ציוד משטרתי שעליך" , value = 'clear_inventory', description = "מוחק את כל הנשקים שעליך"}
		elements[#elements+1] = {title = "מזבלת משטרה" , value = 'trash', description = "מחיקת דברים ספציפים שעליך"}
		if(ESX.PlayerData.job.grade_name == "boss") then
			elements[#elements+1] = {title = "ניקוי ציוד סטאש" , value = 'stash_clearweapons', description = "מוחק את כל הנשקים + ציוד בסטאש"}
		end
	end

	ESX.OpenContext("left", elements, function(menu,element)
		local data = {current = element}
		local action = data.current.value

		if(ESX.PlayerData.job.name ~= "police") then
			ESX.CloseContext()
			return
		end

		if(action) then
			if(action == "open_inventory") then
				ESX.CloseContext()
				exports.ox_inventory:openInventory('stash', 'Stash_Police')
				HasAlreadyEnteredMarker = false
			elseif action == "clear_inventory" then
				if(ESX.PlayerData.job.name) then
					ESX.CloseContext()
					ESX.SEvent("esx_policejob:ClearINVWeapons")
				end
			elseif action == "stash_clearweapons" then
				if(ESX.PlayerData.job.grade_name == "boss") then
					local dialog = exports['qb-input']:ShowInput({
						header = "האם אתה בטוח?",
						submitText = "מחק ציוד מהסטאש",
						inputs = {
							{
								text = "",
								name = "clear",
								type = "radio",
								options = {
									{ value = "no", text = "לא"}, -- Options MUST include a value and a text option
									{ value = "yes", text = "כן"}, -- Options MUST include a value and a text option
								},
								default = "no",
							},
						}
					})
					ESX.CloseContext()
					HasAlreadyEnteredMarker = false
					if(dialog ~= nil) then
						if(dialog.clear and dialog.clear == "yes") then
							ESX.SEvent("esx_policejob:ClearStashWeapons")
						else
							ESX.ShowHDNotification("נשקייה משטרתית","ביטלת את המחיקה","error")
						end
					end
				else
					ESX.CloseContext()
					HasAlreadyEnteredMarker = false
				end
			elseif action == "trash" then
				ESX.CloseContext()
				OpenTrashMenu()
			end
		end
	end, function(menu)
		ESX.CloseContext()
		HasAlreadyEnteredMarker = false
	end)
end

function OpenKitchenMenu()
	HasAlreadyEnteredMarker = false
	exports.ox_inventory:openInventory('stash', 'Police_Fridge')
end

function OpenTrashMenu()
	local elements = {
		{unselectable = true, icon = "fas fa-trash", title = "ארון זבל, לחץ על כל אייטם שאתה רוצה לזרוק"},
	}

	ESX.UI.Menu.CloseAll()

	local inventory = ESX.GetPlayerData().inventory

	for k,v in pairs(inventory) do
		if(v.name == "cash" or v.name == "black_money") then
			goto continue
		end
		local img = GetConvar("inventory:imagepath","").."/"..v.name..".png"
		elements[#elements+1] = {icon = img, title = v.label.." - x"..v.count.." [Slot:"..v.slot.."]" , value = {name = v.name, slot = v.slot, type = v.type, amount = v.count},description = "!!!!!!!לחיצה = מחיקה אין החזרים"}
		::continue::
	end

	if(#elements == 1) then
		ESX.ShowHDNotification("ERROR","האינוונטורי שלך ריק","error")
		OpenArmoryMenu()
		--HasAlreadyEnteredMarker = false
		return
	end

	ESX.OpenContext("left", elements, function(menu,element)
		local data = {current = element}
		local item = data.current.value
		if(item) then
			if(ESX.PlayerData.job.name ~= "police") then
				ESX.CloseContext()
				return
			end
			if(item.type == "weapon") then
				ESX.SEvent("esx_policejob:ClearSpecificItem",item,1)
				ESX.CloseContext()
				Wait(200)
				OpenTrashMenu()
			else
				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'esx_policejob:trashamount', {
					title = "?כמה תרצה למחוק"
				}, function(data2, menu2)
					menu2.close()
					local trashAmount = tonumber(data2.value)
					if(trashAmount and tonumber(trashAmount)) then
						if(trashAmount <= item.amount) then
							ESX.SEvent("esx_policejob:ClearSpecificItem",item,trashAmount)
							ESX.CloseContext()
							Wait(200)
							OpenTrashMenu()
						else
							ESX.ShowHDNotification("ERROR","אין לך את הכמות המבוקשת מהאייטם הזה","error")
						end
					end
				end,
				function(data, menu2)
					menu2.close()	
				end)
			end

		end
	end, function(menu)
		ESX.CloseContext()
		OpenArmoryMenu()
		--HasAlreadyEnteredMarker = false
	end)
end

local lastscan
RegisterCommand('callbackup',function()
	if ESX.PlayerData.job.name == "police" then
		if(IsPedDeadOrDying(cache.ped) or LocalPlayer.state.down) then
			ESX.ShowNotification("!אתה לא יכול לקרוא תגבורת כשאתה מת")
			return
		end
		local playercuffed = exports['esx_thief']:IsTCuffed()

		if(playercuffed) then
			ESX.ShowNotification('אתה לא יכול לקרוא לתגבורת בזמן שאתה אזוק')
			return
		end

		if(not lastbackup or (GetTimeDifference(GetGameTimer(), lastbackup) > 30000)) then
			--FreezeEntityPosition(cache.ped,true)
			local text = "קורא לתגבורת"
			-- ExecuteCommand("me ".. text)
			TriggerEvent("gi-3dme:network:mecmd",text)
			RequestAnimDict("random@arrests");
			while not HasAnimDictLoaded("random@arrests") do
				Wait(5);
			end
			TaskPlayAnim(cache.ped,"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
			ESX.SEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)
			lastbackup = GetGameTimer()
			exports['progressBars']:startUI(1000, "קורא לתגבורת")
			Citizen.Wait(1000)
			--FreezeEntityPosition(cache.ped,false)
			--ESX.SEvent('esx_policejob:Backup')
			TriggerServerEvent('esx_policejob:server:RequestBackup')
			StopAnimTask(cache.ped, "random@arrests","generic_radio_chatter", -4.0);
			RemoveAnimDict("random@arrests")
		else
			ESX.ShowNotification('יש להמתין חצי דקה בין כל בקשת תגבורת')
		end
	elseif ESX.PlayerData.job.name == "ambulance" then
		if(IsPedDeadOrDying(cache.ped) or LocalPlayer.state.down) then
			ESX.ShowNotification("!אתה לא יכול לקרוא תגבורת כשאתה מת")
			return
		end
		local playercuffed = exports['esx_thief']:IsTCuffed()

		if(playercuffed) then
			ESX.ShowNotification('אתה לא יכול לקרוא לתגבורת בזמן שאתה אזוק')
			return
		end

		if(not lastbackup or (GetTimeDifference(GetGameTimer(), lastbackup) > 30000)) then
			--FreezeEntityPosition(cache.ped,true)
			local text = "קורא לתגבורת"
			TriggerEvent("gi-3dme:network:mecmd",text)
			-- ExecuteCommand("me ".. text)
			RequestAnimDict("random@arrests");
			while not HasAnimDictLoaded("random@arrests") do
				Wait(5);
			end
			TaskPlayAnim(cache.ped,"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
			ESX.SEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)
			lastbackup = GetGameTimer()
			exports['progressBars']:startUI(1000, "קורא לתגבורת")
			Citizen.Wait(1000)
			--FreezeEntityPosition(cache.ped,false)
			--ESX.SEvent('esx_policejob:Backup')
			TriggerServerEvent('esx_ambulancejob:server:RequestBackup')
			StopAnimTask(cache.ped, "random@arrests","generic_radio_chatter", -4.0);
			RemoveAnimDict("random@arrests")
		else
			ESX.ShowNotification('יש להמתין חצי דקה בין כל בקשת תגבורת')
		end
	end
end)

local TowMission = false

local function GetClosestTowSpot()
	local coords = GetEntityCoords(cache.ped)
	local closest = 5000
	local closestCoords

	for k,v in pairs(Config.TowSpot) do
		local dstcheck = GetDistanceBetweenCoords(coords, v)

		if dstcheck < closest then
			closest = dstcheck
            closestCoords = v
        end
    end
	return closestCoords
end



function OpenPoliceActionsMenu()
	ESX.UI.Menu.CloseAll()

	local elements = {
		{icon = 'fas fa-users-cog', label = _U('citizen_interaction'),	value = 'citizen_interaction', hint = "ניהול הקרציות" },
		{icon = 'fas fa-car', label = _U('vehicle_interaction'),	value = 'vehicle_interaction', hint = ".עיקול רכבים, דוח על רכב וכו"},
		{icon = 'fas fa-box', label = _U('object_spawner'),		value = 'object_spawner', hint = "נועד לשגר אובייקטים"},
		{icon = 'fas fa-running', label = "מרדפים",		value = 'chases', hint = "פעולות שקשורות למרדפים"},
		{icon = 'fas fa-lock', label = "שליחה לכלא",               value = 'jail_menu', hint = "לשלוח אדם לכלא ( להשתמש בזה רק בתוך מתחם הכלא )"},
		{icon = 'fas fa-map-marker-exclamation', label = "בקשת תגבורת",               value = 'backup_menu', hint = "מסמן את מיקומך לשאר השוטרים"},
	}

	if(recentlyIN == true) then
		table.insert(elements, {label = '<span style="color:cyan;">לבוש כניסה לשרת</span>',     value = 'clothes', hint = "תפריט בגדים ( עובד רק 2 דקות מרגע הכניסה לשרת )"})
	end

	if(not TowMission and Config.TowTrucks[GetEntityModel(GetVehiclePedIsIn(cache.ped,false))]) then
		table.insert(elements, {icon = 'fas fa-truck-pickup', label = 'משימת גרירת רכב', value = 'tow_mission'})
		table.insert(elements, {icon = 'fas fa-hand-peace', label = "שחרר את הרכב הנגרר", value = 'clear_tow'})
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'police_actions', {
		title    = 'תפריט משטרה',
		align    = 'top-left',
        elements = elements
    }, function(data, menu)


		if( data.current.value == "clothes") then
			menu.close()
			OpenCloakroomMenu(true)
			recentlyIN = nil
		elseif data.current.value == 'jail_menu' then
			menu.close()
			TriggerEvent("police:client:JailPlayer")
            -- TriggerEvent("esx-qalle-jail:openJailMenu")
        elseif data.current.value == 'backup_menu' then
			if(not lastbackup or (GetTimeDifference(GetGameTimer(), lastbackup) > 30000)) then
				lastbackup = GetGameTimer()
				local text = "קורא לתגבורת"
				TriggerEvent("gi-3dme:network:mecmd",text)
				-- ExecuteCommand("me ".. text)
				RequestAnimDict("random@arrests");
				while not HasAnimDictLoaded("random@arrests") do
					Wait(5);
				end
				TaskPlayAnim(cache.ped,"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
				ESX.SEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)
				exports['progressBars']:startUI(1000, "קורא לתגבורת")
				Citizen.Wait(1000)
				--ESX.SEvent('esx_policejob:Backup')
				TriggerServerEvent('esx_policejob:server:RequestBackup')
				StopAnimTask(cache.ped, "random@arrests","generic_radio_chatter", -4.0);
				RemoveAnimDict("random@arrests")
			else
				ESX.ShowNotification('יש להמתין חצי דקה בין כל בקשת תגבורת')
			end
		elseif data.current.value == 'tow_mission' then
			local towtruck = GetVehiclePedIsIn(cache.ped,false)
			local model = GetEntityModel(towtruck)
			if(Config.TowTrucks[model]) then
				local towedcar = GetEntityAttachedToTowTruck(towtruck)
				if(DoesEntityExist(towedcar)) then
					if(GetVehicleClass(towedcar) ~= 18) then
						if(not TowMission) then
							TowMission = true
							CreateThread(function()
								local towspot = GetClosestTowSpot()
								local blip = AddBlipForCoord(towspot)
								SetBlipSprite(blip,68)
								SetBlipColour(blip,1)
								SetBlipScale(blip,1.0)
								BeginTextCommandSetBlipName('STRING')
								AddTextComponentString("Tow Truck Mission")
								EndTextCommandSetBlipName(blip)
								SetNewWaypoint(towspot.x,towspot.y)
								ESX.ShowRGBNotification("job","תוביל את הרכב לסימון במפה")
								while TowMission do
									local sleep = 1000
									local ped = cache.ped
									local towtruck = GetVehiclePedIsIn(cache.ped,false)
									if(DoesEntityExist(towtruck)) then
										local model = GetEntityModel(towtruck)
										if(Config.TowTrucks[model]) then
											local towedcar = GetEntityAttachedToTowTruck(towtruck)
											if(DoesEntityExist(towedcar)) then
												local coords = GetEntityCoords(towedcar)
												local dist = #(coords - towspot)
												if dist < 50.0 then
													sleep = 0
													DrawMarker(9,towspot, 0, 0, 0, 0, 90.0, 90.0, 2.8, 2.8, 3.8, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
													if(dist < 5.0) then
														ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ To ~r~Pound~w~ The Vehicle")
														if(IsControlJustPressed(0,51)) then
															if(TowMission) then
																TowMission = false
																Wait(30)
																if(varbar and ESX.PlayerData.job.name == "police") then
																	while not NetworkHasControlOfEntity(towedcar) do
																		Citizen.Wait(1)
										
																		tries = tries + 1
																		NetworkRequestControlOfEntity(towedcar)
										
																		if(tries > 1000) then
																			ESX.ShowNotification("המערכת נכשלה, נסה שוב")
																			TowMission = false
																			return
																		end
																	end
																	DetachVehicleFromAnyTowTruck(towedcar)
																	while IsVehicleAttachedToTowTruck(towtruck,towedcar) do
																		Wait(50)
																	end
																	SetVehicleBrake(towedcar,true)
																	SetEntityVelocity(towedcar,0.0,0.0,0.0)
																	SetVehicleTowTruckArmPosition(towtruck,1.0)
																	Wait(500)
																	ESX.SEvent("esx_policejob:poundvehicle",VehToNet(towedcar),varbar)
																else
																	ESX.ShowNotification(".תקלה, נסה שוב","error")
																end
															end
														end
													end
												end
											else
												TowMission = false
											end
										else
											TowMission = false
										end
									else
										TowMission = false
									end
									Wait(sleep)
								end
								if(DoesBlipExist(blip)) then
									RemoveBlip(blip)
								end
							end)
						else
							TowMission = false
							ESX.ShowRGBNotification("info",".עצרת את המשימת גרירה")
						end
					else
						ESX.ShowRGBNotification("error",".אין אפשרות לבצע גרירה על רכב משטרתי")
					end

				else
					ESX.ShowRGBNotification("error",".לא נמצא רכב על הגרר")
				end
			end
		elseif data.current.value == 'clear_tow' then
			local towtruck = GetVehiclePedIsIn(cache.ped,false)
			local model = GetEntityModel(towtruck)
			if(Config.TowTrucks[model]) then
				local towedcar = GetEntityAttachedToTowTruck(towtruck)
				if(DoesEntityExist(towedcar)) then
					NetworkRequestControlOfEntity(towedcar)
					DetachVehicleFromAnyTowTruck(towedcar)
				end
			end
        elseif data.current.value == 'citizen_interaction' then
			local elements = {
				{label = _U('id_card'), value = 'identity_card', hint = "בשימוש ME חייב לעשות"},
				{label = _U('search'), value = 'search', hint = "חיפוש על שחקן"},
				{label = _U('handcuff'), value = 'handcuff', hint = "אזיקת שחקן"},
				{label = _U('uncuff'), value = 'uncuff', hint = "הורדת אזיקה לשחקן"},
				{label = _U('drag'), value = 'drag', hint = "לגרור שחקן אזוק"},
				{label = "להוריד מסיכה", value = 'maskoff'},
				{label = _U('put_in_vehicle'), value = 'put_in_vehicle'},
				{label = _U('out_the_vehicle'), value = 'out_the_vehicle'},
				{label = _U('fine'), value = 'fine', hint = "דוח לשחקן הקרוב"},
				{label = "עבודות שירות",	value = 'communityservice', hint = "עבודות שירות ( עד 60 )"},
				{label = _U('unpaid_bills'), value = 'unpaid_bills', hint = "דוחות לא משולמים"},
			}

			if NearFingerScanner() then
				table.insert(elements,{label = "סריקת אצבע בכוח",value = 'finger_force', hint = "כופה על שחקן לשים את האצבע על הסורק"})
			end

			if Config.EnableLicenses then
				table.insert(elements, { label = _U('license_check'), value = 'license' })
			end



			table.insert(elements, {label = "דוח ניהולי", value = "custom_bill"})

			if(ESX.PlayerData.job.grade_name == "boss") then
				table.insert(elements, {label = "בדיקת קנה", value = "barrel_check", hint = "נועד לתפוס שוטרים שירו בתחנה, לא נועד לפשע כי יש אבקת שריפה היום."})
				table.insert(elements, {label = '<strong><span style="color:cyan;">בדיקת בתים</strong>', value = "house_check"})
			elseif(string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
				table.insert(elements, {label = "בדיקת קנה", value = "barrel_check", hint = "נועד לתפוס שוטרים שירו בתחנה, לא נועד לפשע כי יש אבקת שריפה היום."})
			end


			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
				title    = _U('citizen_interaction'),
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if data2.current.value == 'house_check' then
					if(ESX.PlayerData.job.grade_name == "boss") then


						local keyboard, IDN = exports["nh-keyboard"]:Keyboard({
							header = "מספר תעודת זהות", 
							rows = {"מספר תז"}
						})
						
						if keyboard then
							local length = string.len(IDN)
							if IDN == nil or length < 2 or length > 13 then
								ESX.ShowNotification("מספר תעודת זהות שגוי")
							else
								OpenPropList(IDN)
							end
						end
					end
					return
				end
	

				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					local action = data2.current.value

					if action == 'identity_card' then
						OpenIdentityCardMenu(closestPlayer)
					elseif action == 'search' then
						OpenBodySearchMenu(closestPlayer)
						menu.close()
						menu2.close()
					elseif action == 'handcuff' then
						if(handcuffing == true) then
							ESX.ShowHelpNotification('You Are Already Cuffing/Uncuffing')
							return
						end
						local playerPed = cache.ped
						local target, distance = ESX.Game.GetClosestPlayer()
						local playerheading = GetEntityHeading(playerPed)
						local playerlocation = GetEntityForwardVector(playerPed)
						local playerCoords = GetEntityCoords(playerPed)
						local target_id = GetPlayerServerId(target)
						ESX.SEvent('esx_policejob:requestarrest', target_id, playerheading, playerCoords, playerlocation)
					elseif action == 'uncuff' then
						if(handcuffing == true) then
							ESX.ShowHelpNotification('You Are Already Cuffing/Uncuffing')
							return
						end
						local target,distance = ESX.Game.GetClosestPlayerCuffed()
						if target ~= -1 and distance <= 3.0 then
							local playerPed = cache.ped
							local playerheading = GetEntityHeading(playerPed)
							local playerlocation = GetEntityForwardVector(playerPed)
							local playerCoords = GetEntityCoords(playerPed)
							local target_id = GetPlayerServerId(target)
							ESX.SEvent('esx_policejob:requestrelease', target_id, playerheading, playerCoords, playerlocation)
						else
							ESX.ShowNotification("לא נמצא אף אחד אזוק בסביבתך","error")
						end
					elseif action == 'drag' then
						OnesyncEnableRemoteAttachmentSanitization(false)
						SetTimeout(200, function()
							OnesyncEnableRemoteAttachmentSanitization(true)
						end)
						TriggerEvent("gi-3dme:network:mecmd","גורר")
						ESX.SEvent('esx_policejob:drag', GetPlayerServerId(closestPlayer))
					elseif action == 'maskoff' then
						ESX.SEvent('esx_policejob:maskoff', GetPlayerServerId(closestPlayer))
					elseif action == 'put_in_vehicle' then
						local target,distance = ESX.Game.GetClosestPlayerCuffed()
						if target ~= -1 and distance <= 3.0 then
							TriggerEvent("gi-3dme:network:mecmd","מכניס לרכב")
							ESX.SEvent('esx_policejob:putInVehicle', GetPlayerServerId(target))
						else
							ESX.ShowNotification("לא נמצא אף אחד אזוק בסביבתך","error")
						end
					elseif action == 'out_the_vehicle' then
						local target,distance = ESX.Game.GetClosestPlayerCuffed()
						if target ~= -1 and distance <= 3.0 then
							TriggerEvent("gi-3dme:network:mecmd","מוציא מרכב")
							ESX.SEvent('esx_policejob:OutVehicle', GetPlayerServerId(target))
						else
							ESX.ShowNotification("לא נמצא אף אחד אזוק בסביבתך","error")
						end
					elseif action == 'fine' then
						OpenFineMenu(closestPlayer)
					elseif action == 'license' then
						ShowPlayerLicense(closestPlayer)
					elseif action == 'unpaid_bills' then
						OpenUnpaidBillsMenu(closestPlayer)
					elseif action == 'communityservice' then
	                    SendToCommunityService(GetPlayerServerId(closestPlayer))
					elseif action == 'barrel_check' then
						TriggerEvent('esx_policejob:CheckBarrel',GetPlayerServerId(closestPlayer))
					elseif action == 'custom_bill' then
						local keyboard, reason, amount = exports["nh-keyboard"]:Keyboard({
							header = "דוח ניהולי", 
							rows = {"סיבת דוח", "כמות כסף"}
						})
						
						if keyboard then
							local amount = tonumber(amount)
							if reason and amount then
								if amount == nil then
									ESX.ShowNotification("כמות שגויה")
								elseif amount > 60000 then
									ESX.ShowNotification('הסכום המקסימלי הוא 60,000 שקל בלבד')
								else

									menu2.close()
									local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
									if closestPlayer == -1 or closestDistance > 3.0 then
										ESX.ShowNotification(_U('no_players_nearby'))
									else


										local invoice = {}
										invoice.invoice_notes = reason
										invoice.invoice_item = "דוח משטרת ישראל"
										invoice.invoice_value = tonumber(amount)
										invoice.target = GetPlayerServerId(closestPlayer)
										invoice.action = "createInvoice"
										invoice.society = "society_police"
										invoice.society_name = "משטרת ישראל"
						
						
										ESX.SEvent("esx_billing:CreateInvoice", invoice)
									end
								end
							else
								ESX.ShowNotification('יש לציין את סכום הדוח וסיבת הדוח')
							end
						end
					elseif action == 'finger_force' then
						ForceFingerprint()
					end
				else
					ESX.ShowNotification(_U('no_players_nearby'),'error')
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'vehicle_interaction' then
			local elements  = {}
			local playerPed = cache.ped
			local vehicle = ESX.Game.GetVehicleInDirection()

			if DoesEntityExist(vehicle) then
				table.insert(elements, {label = _U('vehicle_info'), value = 'vehicle_infos'})
				table.insert(elements, {label = _U('pick_lock'), value = 'hijack_vehicle'})
				table.insert(elements, {label = _U('impound'), value = 'impound'})

				table.insert(elements, {label = "הצמדת דוח לרכב", value = 'car_billing'})
				if(ESX.PlayerData.job.grade > 0) then
					table.insert(elements, {label = "להוציא מהרכב בכוח", value = 'carjack_vehicle'})
				end
				if(ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
					if(GetVehicleClass(vehicle) == 18) then
						table.insert(elements, {label = '<strong><span style="color:cyan;">בדיקת ניידת</strong>', value = "scanveh"})
					end
				end

			else
				if(IsPedInAnyVehicle(playerPed,false)) then
					local veh = GetVehiclePedIsIn(playerPed,false)
					if(DoesEntityExist(veh)) then
						if(ESX.PlayerData.job.grade_name == 'boss') then
							if(GetVehicleClass(veh) ~= 18 and GetVehicleClass(veh) ~= 15) then
								local plate = GetVehicleNumberPlateText(veh)
								if(string.match(plate," ")) then
									table.insert(elements, {label = '<strong><span style="color:red;">החרמת רכב</strong></span>', value = 'seize_vehicle', hint = "מחרים את הרכב שאתם נמצאים בו"})
								end
							end
						end
					end
				else
					table.insert(elements, {label = "חיפוש קל לאופנוע", value = 'search_bike' , hint = "דרך קלה לעקל אופנועים וכו"})
				end
			end

			table.insert(elements, {label = _U('search_database'), value = 'search_database'})
			

			if(ESX.PlayerData.job.grade_name == 'boss') then
				table.insert(elements, {label = '<strong><span style="color:red;">חיפוש בעלות רכבים</strong></span>', value = 'seize_list'})
			end
			
			
			table.insert(elements, {label = "הזמנת ניידת", value = 'call_nayedet', hint = "מזמין ניידת בתשלום למיקומכם"})

			
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_interaction', {
				title    = _U('vehicle_interaction'),
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				local coords  = GetEntityCoords(playerPed)
				vehicle = ESX.Game.GetVehicleInDirection()
				action  = data2.current.value

				if action == 'search_database' then
					LookupVehicle()
				elseif action == 'seize_list' then
					LookupVehicleSeize()
				elseif action == 'search_bike' then
					local coords = GetEntityCoords(playerPed)

					local targetVehicle = GetClosestVehicle(coords, 4.0, 0, 71)

					if(DoesEntityExist(targetVehicle)) then
						local model = GetEntityModel(targetVehicle)
						if(GetVehicleClass(targetVehicle) == 8 or GetVehicleClass(targetVehicle) == 13 or IsThisModelABike(model)) then
							BikeInteraction2(targetVehicle)
						else
							ESX.ShowNotification('הרכב הכי קרוב אליך אינו אופנוע')
						end
					else
						ESX.ShowNotification('לא נמצא שום רכב')
					end

				elseif action == 'seize_vehicle' then

					if(IsPedInAnyVehicle(playerPed,false)) then

						local veh = GetVehiclePedIsIn(playerPed,false)
						if(DoesEntityExist(veh)) then
							if(ESX.PlayerData.job.grade_name == 'boss') then
								if(GetVehicleClass(veh) ~= 18) then
									local plate = GetVehicleNumberPlateText(veh)
									if(string.match(plate," ")) then

										TaskLeaveVehicle(playerPed,veh,0)

										while IsPedInAnyVehicle(cache.ped) do
											Citizen.Wait(500)
										end

										TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
									
										exports['progressBars']:startUI(7500, "מחרים רכב")

										Citizen.Wait(7500)

										ESX.SEvent("esx_policejob:SeizeVehicle",plate)

										ClearPedTasksImmediately(cache.ped)

										ImpoundVehicle(veh)
									else
										ESX.ShowNotification('אין אפשרות להחרים רכב מסוג זה')
									end
								end
							end
						end

					end
				elseif action == 'call_nayedet' then
					TriggerEvent('esx_policejob:callnayedet')
				elseif action == "scanveh" then
					if(DoesEntityExist(vehicle)) then
						if(GetVehicleClass(vehicle) == 18) then

							if(not lastscan or (GetTimeDifference(GetGameTimer(), lastscan) > 5000)) then
								lastscan = GetGameTimer()
								ESX.SEvent('esx_policejob:ScanVeh',ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
							else
								ESX.ShowHDNotification("ERROR","נא להמתין 5 שניות בין כל סריקה",'error')
							end
						else
							ESX.UI.Menu.CloseAll()
							ESX.ShowHDNotification("ERROR","הרכב שנבחר אינו משטרתי",'error')
						end
					end
				elseif DoesEntityExist(vehicle) then
					if action == 'vehicle_infos' then
						OpenVehicleInfosMenu(vehicle)
					elseif action == 'hijack_vehicle' then
						if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
							ESX.Game.Progress("esx_policejob:Hijack", "פורץ את הרכב", 15000, false, true, {
								disableMovement = true,
								disableCarMovement = true,
								disableMouse = false,
								disableCombat = true,
							}, {
								task = "WORLD_HUMAN_WELDING",
							}, {}, {}, function() -- Done
								if(DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle)) then
									if(ESX.PlayerData.job.name ~= "police") then return ClearPedTasksImmediately(cache.ped) end
									local success = lib.callback.await("esx_policejob:server:requestlockpick", false, VehToNet(vehicle))
									ClearPedTasksImmediately(cache.ped)
									if(success) then
										lib.requestNamedPtfxAsset("core")
										SetPtfxAssetNextCall("core")
										local vehcoords = GetEntityCoords(vehicle)
										StartParticleFxLoopedAtCoord("ent_brk_metal_frag", vehcoords.x, vehcoords.y, vehcoords.z, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
										RemoveNamedPtfxAsset("core")
										SetVehicleDoorsLocked(vehicle, 1)
										SetVehicleDoorsLockedForAllPlayers(vehicle, false)
										PlaySoundFromEntity(-1,"Drill_Pin_Break",vehicle,"DLC_HEIST_FLEECA_SOUNDSET",false,false)
										ESX.ShowRGBNotification("success","!הרכב נפרץ בהצלחה")
									end
								else
									ESX.ShowRGBNotification("error",".תקלה, נסה שוב")
								end
							end, function()
								ClearPedTasksImmediately(cache.ped)
							end,"fas fa-screwdriver")
						end

					elseif action == "carjack_vehicle" then
						if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
							if(GetPedInVehicleSeat(vehicle,-1) ~= 0) then
								ESX.ShowNotification('מתחיל הוצאה בכוח')

								local Skillbar = exports['gi-skillbar']:GetSkillbarObject()
								Skillbar.Start({
									duration = 1800, -- how long the skillbar runs for
									pos = math.random(5, 15), -- how far to the right the static box is
									width = math.random(11, 14), -- how wide the static box is
								}, function()
									TaskEnterVehicle(cache.ped,vehicle,3000,-1,2.0,8,0)
								end, function()
									exports['mythic_notify']:DoHudText('error', 'הוצאה נכשלה')
								end)
							else
								ESX.ShowNotification('לא נמצא אף אחד ברכב')
							end
						end
					elseif action == 'impound' then
						-- is the script busy?
						if currentTask.busy then
							return
						end

						local duration = 10000
						local plate = GetVehicleNumberPlateText(vehicle)
						if(not string.match(plate," ") or GetVehicleClass(vehicle) == 18) then
							duration = math.floor(duration / 2)
						end

						--ESX.ShowHelpNotification(_U('impound_prompt'))
						DrawOutlineEntity(vehicle,true)
						ESX.Game.Progress("esx_policejob:impound", "מעקל את הרכב", duration, false, true, {
							disableMovement = true,
							disableCarMovement = true,
							disableMouse = false,
							disableCombat = true,
						}, {
							task = "CODE_HUMAN_MEDIC_TEND_TO_DEAD",
						}, {}, {}, function() -- Done
							ClearPedTasksImmediately(playerPed)

							local vcoords = GetEntityCoords(vehicle)
							local pcoords = GetEntityCoords(playerPed)
	
							DrawOutlineEntity(vehicle,false)
							if(Vdist(pcoords,vcoords) < 6) then
								ClearPedTasks(playerPed)
								ImpoundVehicle(vehicle)
							else
								ESX.ShowNotification(_U('impound_canceled_moved'))
							end
						end, function()
							ClearPedTasksImmediately(playerPed)
							DrawOutlineEntity(vehicle,false)
						end,"fas fa-truck-pickup")
					elseif(action == 'car_billing') then


						local plate = GetVehicleNumberPlateText(vehicle)
						
						local dialog = exports['qb-input']:ShowInput({
							header = plate.." :רישום דוח לרכב",
							submitText = "שלח דוח ✏️",
							inputs = {
								{
									text = "סיבה לדוח",
									name = "reason",
									type = "text",
									isRequired = true,
								},
								{
									text = "כמה כסף",
									name = "amount",
									type = "number",
									isRequired = true, -- Optional [accepted values: true | false] but will submit the form if no value is inputted
								},
							}
						})
					
						if(dialog ~= nil) then
							local amount = tonumber(dialog.amount)
							if amount == nil then
								ESX.ShowNotification("כמות שגויה")
							elseif amount > 60000 then
								ESX.ShowNotification('הסכום המקסימלי הוא 60,000 שקל בלבד')
							else
								if not IsAnyVehicleNearPoint(GetEntityCoords(cache.ped), 3.0) then
									ESX.ShowNotification(_U('no_vehicles_nearby'))
								else
									ESX.Game.Progress("esx_policejob:WriteBillEye","כותב את הדוח", 12000, false, true, {
										disableMovement = true,
										disableCarMovement = true,
										disableMouse = false,
										disableCombat = true,
									}, {
										task = "CODE_HUMAN_MEDIC_TIME_OF_DEATH",
									}, {}, {}, function() -- Done
										ESX.SEvent('esx_policejob:carbill', plate, dialog.reason, tonumber(amount))
										ESX.ShowNotification("דוח נשלח")
										ClearPedTasksImmediately(cache.ped)
									end, function()
										ClearPedTasksImmediately(cache.ped)
									end,"fas fa-edit")
								end
							end
						end
					end
				else
					ESX.ShowNotification(_U('no_vehicles_nearby'))
				end

			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'object_spawner' then

			local elements = {}

			for k,v in pairs(Config.PoliceObjects) do
				if(not v.boss or ESX.PlayerData.job.grade_name == 'boss') then
					table.insert(elements, {label = v.label, model = v.model})
				end
			end

			table.insert(elements, {label = "ניקיון ספריי", model = "cleanspray"})

			--

			local emoji = '<span style="color:green;">פועל</span>'

			if(blocklobjects) then
				emoji = '<span style="color:red;">מבוטל</span>'
			end

			table.insert(elements, {label = "מצב מחיקת אובייקטים - "..emoji, model = "togglebool", hint = "E מדליק/מבטל את האופציה למחוק ב "})

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
				title    = _U('traffic_interaction'),
				align    = 'top-left',
				elements = elements,
			}, function(data2, menu2)
				local model = data2.current.model

				if(model) then

					if(model == "cleanspray") then
						menu2.close()
						TriggerEvent('rcore_spray:removeClosestSpray')
						return
					end

					if(model == "togglebool") then
						blocklobjects = not blocklobjects
						if(blocklobjects) then
							ESX.ShowHDNotification('SUCCESS',"חסמת את המחיקת אובייקטים",'success')
						else
							ESX.ShowHDNotification('SUCCESS',"הדלקת את המחיקת אובייקטים",'success')
						end
						menu2.close()
						return
					end

					if(cache.vehicle) then
						return ESX.ShowRGBNotification("error","!אתה לא יכול לבצע את הפעולה הזאת מתוך רכב")
					end

					local playerPed = cache.ped
					local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
					local objectCoords = (coords + forward * 1.0)
					local x,y,z = table.unpack(objectCoords)
					z = z - 1.0
					objectCoords = vector4(x,y,z,GetEntityHeading(playerPed))


					-- if(model == "p_ld_stinger_s") then
					-- 	RequestAnimDict("p_ld_stinger_s")
					-- 	while not HasAnimDictLoaded("p_ld_stinger_s") do
					-- 		Wait(50)
					-- 	end
					-- end
					local NetID, reason = lib.callback.await("esx_policejob:server:SpawnObject",500,model,objectCoords)

					if(NetID == nil) then
						ESX.ShowRGBNotification("error","נא להמתין חצי שנייה בין כל שיגור")
						return
					end
					if(not NetID) then
						if(reason) then
							ESX.ShowRGBNotification("error",reason)
						end
						return
					end
					-- ESX.Game.SpawnObject(model, objectCoords, function(obj)
					-- end,true,GetEntityHeading(playerPed))
					local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
					RequestAnimDict(dict)
					while not HasAnimDictLoaded(dict) do
						Wait(0)
					end
					TaskPlayAnim(cache.ped, dict, anim, 8.0, 1.0, 1000, 51, 0.0, false, false, false)
					RemoveAnimDict(dict)
					if(model == "p_ld_stinger_s") then
						PlaySoundFrontend(-1, "bomb_deployed", "DLC_SM_Bomb_Bay_Bombs_Sounds", true);
					end
					-- local obj = ESX.Game.VerifyEnt(NetID)
					-- if(DoesEntityExist(obj)) then
					-- 	Wait(1)
					-- 	-- SetEntityHeading(obj, GetEntityHeading(playerPed))
					-- 	PlaceObjectOnGroundProperly(obj)
					-- 	if(model == "prop_boxpile_07d") then
							-- if(GetEntityHeightAboveGround(obj) < 2.0) then
							-- 	FreezeEntityPosition(obj,true)
							-- end
					-- 	elseif(model == "prop_gazebo_03" or model == "prop_cs_office_chair") then
					-- 		Wait(5)
					-- 		FreezeEntityPosition(obj,true)
					-- 	elseif(model == "p_ld_stinger_s") then
					-- 		PlayEntityAnim(obj, "P_Stinger_S_Deploy", "p_ld_stinger_s", 1000.0, false, true, false, 0.0, 0)
					-- 		RemoveAnimDict("p_ld_stinger_s")
					-- 		PlaySoundFrontend(-1, "bomb_deployed", "DLC_SM_Bomb_Bay_Bombs_Sounds", true);
					-- 	end
					-- else
					-- 	ESX.ShowRGBNotification("error","תקלה, לא הצלחנו להשתלט על האוביקט")
					-- end

				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == "chases" then
			local elements = {}
			table.insert(elements, {label = "התחל טיימר", value = 'timer',"מתחיל לספור 60 שניות אחורה"})
			table.insert(elements, {label = "עצור טיימר", value = 'stoptimer',"עוצר טיימר במידה והוא פועל"})


			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pchase_menu', {
				title = "תפריט מרדפים",
				align = 'top-left',
				elements = elements
			}, function(data2, menu2)
				if data2.current.value == 'timer' then
					if not chasetimer then
						chasetimer = true
						ESX.ShowRGBNotification("info","הטיימר התחיל")
						SendNUIMessage({
							type = 'startTimer'
						})
					else
						ESX.ShowRGBNotification("error","כבר הפעלת טיימר")
					end
				elseif data2.current.value == "stoptimer" then
					if chasetimer then
						SendNUIMessage({
							type = 'stopTimer'
						})
						chasetimer = false
					else
						ESX.ShowRGBNotification("error","אין טיימר פועל")
					end
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function BikeInteraction2(vehicle)

	local elements = {}

	if DoesEntityExist(vehicle) then
		table.insert(elements, {label = _U('vehicle_info'), value = 'vehicle_infos'})
		table.insert(elements, {label = _U('pick_lock'), value = 'hijack_vehicle'})
		table.insert(elements, {label = _U('impound'), value = 'impound'})
		table.insert(elements, {label = "הצמדת דוח לרכב", value = 'car_billing'})

		if(ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
			if(GetVehicleClass(vehicle) == 18) then
				table.insert(elements, {label = '<strong><span style="color:cyan;">בדיקת ניידת</strong>', value = "scanveh"})
			end
		end
	end


	if(#elements <= 0) then
		return
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'bikeinteract', {
		title    = "אינטרקציה אופנועים",
		align    = 'top-left',
		elements = elements,
	}, function(data, menu)

		local playerPed = cache.ped

		local coords = GetEntityCoords(playerPed)

		local targetVehicle = GetClosestVehicle(coords, 4.0, 0, 71)

		local action = data.current.value

		if DoesEntityExist(targetVehicle) then
			local model = GetEntityModel(targetVehicle)
			if(GetVehicleClass(targetVehicle) == 8 or GetVehicleClass(targetVehicle) == 13 or IsThisModelABike(model)) then
				if action == 'vehicle_infos' then
					OpenVehicleInfosMenu(targetVehicle)
				elseif action == 'hijack_vehicle' then
					if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
						ESX.Game.Progress("esx_policejob:Hijack", "פורץ את הרכב", 15000, false, true, {
							disableMovement = true,
							disableCarMovement = true,
							disableMouse = false,
							disableCombat = true,
						}, {
							task = "WORLD_HUMAN_WELDING",
						}, {}, {}, function() -- Done
							if(DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle)) then
								if(ESX.PlayerData.job.name ~= "police") then return ClearPedTasksImmediately(cache.ped) end
								local success = lib.callback.await("esx_policejob:server:requestlockpick", false, VehToNet(vehicle))
								ClearPedTasksImmediately(cache.ped)
								if(success) then
									lib.requestNamedPtfxAsset("core")
									SetPtfxAssetNextCall("core")
									local vehcoords = GetEntityCoords(vehicle)
									StartParticleFxLoopedAtCoord("ent_brk_metal_frag", vehcoords.x, vehcoords.y, vehcoords.z, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
									RemoveNamedPtfxAsset("core")
									SetVehicleDoorsLocked(vehicle, 1)
									SetVehicleDoorsLockedForAllPlayers(vehicle, false)
									PlaySoundFromEntity(-1,"Drill_Pin_Break",vehicle,"DLC_HEIST_FLEECA_SOUNDSET",false,false)
									ESX.ShowRGBNotification("success","!הרכב נפרץ בהצלחה")
								end
							else
								ESX.ShowRGBNotification("error",".תקלה, נסה שוב")
							end
						end, function()
							ClearPedTasksImmediately(cache.ped)
						end,"fas fa-screwdriver")
					end
				elseif action == 'impound' then
					-- is the script busy?
					if currentTask.busy then
						return
					end

					local duration = 10000
					local plate = GetVehicleNumberPlateText(vehicle)
					if(not string.match(plate," ")) then
						duration = math.floor(duration / 2)
					end

					--ESX.ShowHelpNotification(_U('impound_prompt'))
					DrawOutlineEntity(vehicle,true)
					ESX.Game.Progress("esx_policejob:impound", "מעקל את הרכב", duration, false, true, {
						disableMovement = true,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {
						task = "CODE_HUMAN_MEDIC_TEND_TO_DEAD",
					}, {}, {}, function() -- Done
						ClearPedTasksImmediately(playerPed)

						local vcoords = GetEntityCoords(targetVehicle)
						local pcoords = GetEntityCoords(playerPed)

						DrawOutlineEntity(targetVehicle,false)
						if(Vdist(pcoords,vcoords) < 6) then
							ClearPedTasks(playerPed)
							ImpoundVehicle(targetVehicle)
						else
							ESX.ShowNotification(_U('impound_canceled_moved'))
						end
					end, function()
						ClearPedTasksImmediately(playerPed)
						DrawOutlineEntity(targetVehicle,false)
					end,"fas fa-truck-pickup")

				elseif action == "scanveh" then
					if(DoesEntityExist(vehicle)) then			
						if(GetVehicleClass(vehicle) == 18) then

							if(not lastscan or (GetTimeDifference(GetGameTimer(), lastscan) > 5000)) then
								lastscan = GetGameTimer()
								ESX.SEvent('esx_policejob:ScanVeh',ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
							else
								ESX.ShowHDNotification("ERROR","נא להמתין 5 שניות בין כל סריקה",'error')
							end
						else
							ESX.UI.Menu.CloseAll()
							ESX.ShowHDNotification("ERROR","הרכב שנבחר אינו משטרתי",'error')
						end
					end

				elseif(action == 'car_billing') then


					local plate = GetVehicleNumberPlateText(vehicle)

					local dialog = exports['qb-input']:ShowInput({
						header = plate.." :רישום דוח לרכב",
						submitText = "שלח דוח ✏️",
						inputs = {
							{
								text = "סיבה לדוח",
								name = "reason",
								type = "text",
								isRequired = true,
							},
							{
								text = "כמה כסף",
								name = "amount",
								type = "number",
								isRequired = true, -- Optional [accepted values: true | false] but will submit the form if no value is inputted
							},
						}
					})
				
					if(dialog ~= nil) then
						local amount = tonumber(dialog.amount)
						if amount == nil then
							ESX.ShowNotification("כמות שגויה")
						elseif amount > 60000 then
							ESX.ShowNotification('הסכום המקסימלי הוא 60,000 שקל בלבד')
						else
							if not IsAnyVehicleNearPoint(GetEntityCoords(cache.ped), 5.0) then
								ESX.ShowNotification(_U('no_vehicles_nearby'))
							else
								ESX.Game.Progress("esx_policejob:WriteBillEye","כותב את הדוח", 12000, false, true, {
									disableMovement = true,
									disableCarMovement = true,
									disableMouse = false,
									disableCombat = true,
								}, {
									task = "CODE_HUMAN_MEDIC_TIME_OF_DEATH",
								}, {}, {}, function() -- Done
									ESX.SEvent('esx_policejob:carbill', plate, dialog.reason, tonumber(amount))
									ESX.ShowNotification("דוח נשלח")
									ClearPedTasksImmediately(cache.ped)
								end, function()
									ClearPedTasksImmediately(cache.ped)
								end,"fas fa-edit")
							end
						end
					end					
				end
			else
				ESX.ShowNotification('הרכב הכי קרוב אליך אינו אופנוע')
			end
		else
			ESX.ShowNotification('לא נמצא הרכב')
		end

	end, function(data, menu)
		menu.close()
	end)
end

function OpenIdentityCardMenu(player)
	local target = GetPlayerServerId(player)
	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)
		local elements = {
			{label = data.id_number..' :מספר ת"ז',value = "copy",id_num = data.id_number},
			{label = _U('name', data.name),value = "copy2", name_num = data.name},
			{label = _U('job', ('%s - %s'):format(data.job.label, data.job.grade_label))}
		}

		local sex = IsPedMale(cache.ped)

		if(sex == 1) then
			sex = "Gender: זכר"
		else
			sex = "Gender: נקבה"
		end

		if Config.EnableESXIdentity then
			table.insert(elements, {label = sex})
			table.insert(elements, {label = _U('dob', data.dob), value = "copy3", date_num = data.dob})
			table.insert(elements, {label = _U('height', data.height)})
		end



		if(ESX.PlayerData.job.grade_name == 'boss') then
			table.insert(elements, {label = "Bank: "..ESX.Math.GroupDigits(data.bank), value = "seize_money", hint = "ניתן ללחוץ כאן כדי להחרים כספים"})
		else
			table.insert(elements, {label = "Bank: "..ESX.Math.GroupDigits(data.bank)})
		end

		if data.drunk then
			table.insert(elements, {label = _U('bac', data.drunk)})
		end

		if data.licenses then
			table.insert(elements, {label = _U('license_label')})

			for i=1, #data.licenses, 1 do
				table.insert(elements, {label = data.licenses[i].label})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_information', {
			title    = _U('citizen_interaction'),
			align    = 'top-left',
			elements = elements,
		}, function(data, menu)
			if(data.current.value == "copy") then
				TriggerEvent('CopyToClipBoard', data.current.id_num)
				ESX.ShowHDNotification('מספר תעודת זהות',"הועתק למקלדת",'success')
			elseif(data.current.value == "copy2") then
				TriggerEvent('CopyToClipBoard', data.current.name_num)
				ESX.ShowHDNotification('שם מלא',"הועתק למקלדת",'success')
			elseif(data.current.value == "copy3") then
				TriggerEvent('CopyToClipBoard', data.current.date_num)
				ESX.ShowHDNotification('תאריך לידה',"הועתק למקלדת",'success')
			elseif(data.current.value == "seize_money") then
				menu.close()
				if(ESX.PlayerData.job.grade_name == 'boss') then
					local dialog = exports['qb-input']:ShowInput({
						header = "תפריט החרמת כספים",
						submitText = "החרם כספים",
						inputs = {
							{
								text = "סיבה להחרמת כסף",
								name = "reason",
								type = "text",
								isRequired = true,
							},
							{
								text = "כמות כסף",
								name = "amount",
								type = "number",
								isRequired = true, -- Optional [accepted values: true | false] but will submit the form if no value is inputted
							},
						}
					})
				
					if(dialog ~= nil) then
						local amount = tonumber(dialog.amount)
						if amount == nil then
							ESX.ShowNotification("כמות שגויה")
						elseif amount > 5000000 then
							ESX.ShowNotification('הסכום המקסימלי הוא 5,000,000')
						else
							if not dialog.reason or dialog.reason == '' then
								ESX.ShowHDNotification("החרמת כספים","אתה חייב לציין סיבה להחרמה","error")
								return
							end
							if(ESX.PlayerData.job.grade_name == 'boss') then
								TriggerServerEvent("esx_policejob:server:seizemoney",target,amount,dialog.reason)
							end
						end
					end
				end
			end
		end, function(data, menu)
			menu.close()
		end)
	end, target)
end

function OpenBodySearchMenu(player)

	local TargetPed = GetPlayerPed(player)

	local targetid = GetPlayerServerId(player)

    if(not IsPedStill(TargetPed) and not IsPedDeadOrDying(TargetPed) and not Player(targetid).state.down) then
		ESX.ShowRGBNotification("error","השחקן חייב לעמוד במקום")
        return
    end

	local text = "מבצע חיפוש"
	TriggerEvent("gi-3dme:network:mecmd",text)
	ESX.SEvent('esx_securityjob:messagesearch',targetid,GetPlayerServerId(PlayerId()))
	if(varbar) then
		exports.ox_inventory:openInventory('player', targetid)
	else
		TriggerEvent('chatMessage',".תקלה, נסה שוב")
	end
end

function SendToCommunityService(player)
	local input = lib.inputDialog("תפריט שליחה לעבודות שירות", {
		{type = 'input', label = 'סיבה לעבודות שירות', description = '?למה הקרציה נכנס לעבודות שירות', required = true, min = 4, max = 80},
		{type = 'slider', label = 'כמות עבודות', description = 'כמה עבודות שירות לתת לקרציה', required = true, min = 5, max = 60},
	})
	if(input) then
		local reason = input[1]
		local amount = tonumber(input[2])
		ESX.SEvent("esx_communityservice:sendMustafa",player, amount, reason)
	end
end

exports("SendToCommunityService",function(player)
	SendToCommunityService(player)
end)

function OpenFineMenu(player)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fine', {
		title    = _U('fine'),
		align    = 'top-left',
		elements = {
			{label = _U('traffic_offense'), value = 0},
			{label = _U('minor_offense'),   value = 1},
			{label = _U('average_offense'), value = 2},
			{label = _U('major_offense'),   value = 3}
	}}, function(data, menu)
		OpenFineCategoryMenu(player, data.current.value)
	end, function(data, menu)
		menu.close()
	end)
end

function OpenFineCategoryMenu(player, category)
	ESX.TriggerServerCallback('esx_policejob:getFineList', function(fines)
		local elements = {}

		for k,fine in ipairs(fines) do
			table.insert(elements, {
				label     = ('%s <span style="color:green;">%s</span>'):format(fine.label, _U('armory_item', ESX.Math.GroupDigits(fine.amount))),
				value     = fine.id,
				amount    = fine.amount,
				fineLabel = fine.label
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fine_category', {
			title    = _U('fine'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			menu.close()

			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
			if closestPlayer == -1 or closestDistance > 3.0 then
				ESX.ShowNotification(_U('no_players_nearby'))
			else


				local invoice = {}
				invoice.invoice_notes = _U('fine_total', data.current.fineLabel)
				invoice.invoice_item = "דוח משטרת ישראל"
				invoice.invoice_value = data.current.amount
				invoice.target = GetPlayerServerId(closestPlayer)
				invoice.action = "createInvoice"
				invoice.society = "society_police"
				invoice.society_name = "משטרת ישראל"


				ESX.SEvent("esx_billing:CreateInvoice", invoice)
				ESX.SetTimeout(300, function()
					OpenFineCategoryMenu(closestPlayer, category)
				end)
			end

			-- local invoice = {}
			-- invoice.invoice_notes = _U('fine_total', data.current.fineLabel)
			-- invoice.invoice_item = "דוח משטרת ישראל"
			-- invoice.invoice_value = data.current.amount
			-- invoice.target = GetPlayerServerId(player)
			-- invoice.action = "createInvoice"
			-- invoice.society = "society_police"
			-- invoice.society_name = "משטרת ישראל"
			-- ESX.SEvent("esx_billing:CreateInvoice", invoice)

			
		end, function(data, menu)
			menu.close()
		end)
	end, category)
end

function LookupVehicle()
	local keyboard, plate = exports["nh-keyboard"]:Keyboard({
		header = _U('search_database_title'), 
		rows = {"לוחית רישוי"}
	})
	
	if keyboard then
		local length = string.len(plate)
		if plate == nil or length < 2 or length > 13 then
			ESX.ShowNotification(_U('search_database_error_invalid'))
		else
			ESX.TriggerServerCallback('esx_policejob:getVehicleFromPlate', function(owner, found)
				if found then
					ESX.ShowNotification(_U('search_database_found', owner))
				else
					ESX.ShowNotification(_U('search_database_error_not_found'))
				end
			end, plate)
		end
	end
end

function LookupVehicleSeize()

	if(ESX.PlayerData.job.grade_name == 'boss') then

		local keyboard, IDN = exports["nh-keyboard"]:Keyboard({
			header = "מספר תעודת זהות", 
			rows = {"מספר תז"}
		})
		
		if keyboard then
			local length = string.len(IDN)
			if IDN == nil or length < 2 or length > 13 then
				ESX.ShowNotification("מספר תעודת זהות שגוי")
			else
				SeizedVehicles(IDN)
			end
		end
	end
end


function SeizedVehicles(id_number)

	if(ESX.PlayerData.job.grade_name == 'boss') then

		local elements = {}

		ESX.TriggerServerCallback('esx_policejob:getPlayerCars', function(seizedCars)

			if #seizedCars == 0 then
				ESX.ShowNotification("אין רכבים מוחרמים כרגע")
			else

				for _,v in pairs(seizedCars) do
					local hashVehicule = v.vehicle.model
					local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
					local vehicleName  = aheadVehName
					--if(vehicleName == "NULL") then
						--vehicleName = "Custom Car"
					--end
					local plate        = v.plate

					local labelvehicle

					local emoji = '<span style="color:green;">חופשי</span>'

					if(v.impound) then
						emoji = '<span style="color:red;">מעוקל</span>'
					end


					labelvehicle = '| '..plate..' | '..vehicleName..' | Impounded: '..emoji

					table.insert(elements, {label = labelvehicle, value = v, impounded = v.impound})
				end
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_seized_car', {
				title    = "רכבים מוחרמים",
				align    = 'top-left',
				elements = elements
			}, function(data, menu)
				if(data.current.value ~= nil) then 
					menu.close()

					if(not data.current.impounded) then
						ESX.SEvent('esx_policejob:SeizeVehicle',data.current.value.plate)
					else
						ESX.SEvent('esx_policejob:freeVehicle',data.current.value.plate)
					end
					SeizedVehicles(id_number)
				end
			end, function(data, menu)
				menu.close()
			end)
		end,id_number)
	end
end

function ShowPlayerLicense(player)
	local elements = {}

	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(playerData)
		if playerData.licenses then
			for i=1, #playerData.licenses, 1 do
				if playerData.licenses[i].label and playerData.licenses[i].type then
					table.insert(elements, {
						label = playerData.licenses[i].label,
						type = playerData.licenses[i].type
					})
				end
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_license', {
			title    = _U('license_revoke'),
			align    = 'top-left',
			elements = elements,
		}, function(data, menu)
			ESX.ShowNotification(_U('licence_you_revoked', data.current.label, playerData.name))
			ESX.SEvent('esx_policejob:message', GetPlayerServerId(player), _U('license_revoked', data.current.label))

			ESX.SEvent('esx_license:removeLicense', GetPlayerServerId(player), data.current.type)

			ESX.SetTimeout(300, function()
				ShowPlayerLicense(player)
			end)
		end, function(data, menu)
			menu.close()
		end)

	end, GetPlayerServerId(player))
end


function OpenUnpaidBillsMenu(player)
	local elements = {}

	ESX.TriggerServerCallback("esx_billing:GetTargetInvoices", function(invoices)


		local totalmoney = 0

		local normalbills = {}

		local policebills = {}

		for k,bill in ipairs(invoices) do

			if(bill.society ~= "society_police") then
				table.insert(normalbills, {
					label = ('%s - <span style="color:red;">%s</span>'):format(bill.notes, _U('armory_item', ESX.Math.GroupDigits(bill.invoice_value))),
					billId = bill.id
				})
			else
				table.insert(policebills, {
					label = ('%s - <span style="color:red;">%s</span>'):format(bill.notes, _U('armory_item', ESX.Math.GroupDigits(bill.invoice_value))),
					billId = bill.id
				})

				if(bill and bill.invoice_value > 0) then
					totalmoney = totalmoney + bill.invoice_value
				end

			end
		end


		local elements = {}


		table.insert(elements,{label = '<span style="color:Aquamarine;"><---- קבלות משטרה -----></span>'})
		for i = 1, #policebills, 1 do
			table.insert(elements,policebills[i])
		end

		table.insert(elements,{label = '<span style="color:yellow;"><---- קבלות אזרחיות -----></span>'})
		for i = 1, #normalbills, 1 do
			table.insert(elements,normalbills[i])
		end



		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'billing', {
			title    = 'תשלומים ודוחות - Police Debt: <span style="color:green;">₪'..ESX.Math.GroupDigits(totalmoney)..'</span>',
			align    = 'top-left',
			elements = elements
		}, nil, function(data, menu)
			menu.close()
		end)



	end,GetPlayerServerId(player))

end

function OpenVehicleInfosMenu(veh)
	ESX.TriggerServerCallback('esx_policejob::server:VehicleDetailsPlate', function(retrivedInfo)
		local elements = {{label = _U('plate', retrivedInfo.plate)}}

		if retrivedInfo.owner == nil then
			table.insert(elements, {label = _U('owner_unknown')})
		else
			table.insert(elements, {label = _U('owner', retrivedInfo.owner)})
			table.insert(elements, {label = retrivedInfo.steam.." :שם בסטיים לרפורטים"})
		
			if retrivedInfo.is_inspection_valid then
				table.insert(elements, {label = "<span style='color: lightgreen; font-weight: bold;'>הרכב עבר טסט לאחרונה והוא תקין</span>"})
			else
				table.insert(elements, {label = "<span style='color: red; font-weight: bold;'>הרכב לא עבר טסט ואינו תקין</span>"})
			end
			
		end
		

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos', {
			title    = _U('vehicle_info'),
			align    = 'top-left',
			elements = elements
		}, nil, function(data, menu)
			menu.close()
		end)
	end, ESX.Math.Trim(GetVehicleNumberPlateText(veh)))
end

AddEventHandler('esx_policejob:hasEnteredMarker', function(station, part, partNum)
	if part == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	elseif part == 'Armory' then
		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	--[[elseif part == 'Archive' then
		CurrentAction     = 'menu_archive'
		CurrentActionMsg  = "Press ~INPUT_CONTEXT~ To Open Archive"
		CurrentActionData = {station = station}--]]
	elseif part == 'Evidence' then
		CurrentAction     = 'menu_evidence'
		CurrentActionMsg  = "Press ~INPUT_CONTEXT~ To Store Evidence"
		CurrentActionData = {station = station}
	elseif part == 'Weaponry' then
		CurrentAction     = 'menu_weaponry'
		CurrentActionMsg  = "Press ~INPUT_CONTEXT~ To Open Weapons Stock"
		CurrentActionData = {station = station}
	elseif part == 'Kitchen' then
		CurrentAction     = 'menu_kitchen'
		CurrentActionMsg  = "Press ~INPUT_CONTEXT~ To Open The ~b~Fridge~w~"
		--CurrentActionMsg  = "Press ~INPUT_CONTEXT~ To Buy A Meal."
		CurrentActionData = {station = station}
	elseif part == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	elseif part == 'BossBills' then
		CurrentAction     = 'menu_boss_bills'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	end
end)

AddEventHandler('esx_policejob:hasExitedMarker', function(station, part, partNum)
	ESX.UI.Menu.CloseAll()
	CurrentAction = nil
end)

AddEventHandler('esx_policejob:hasEnteredEntityZone', function(entity)
	local playerPed = cache.ped

	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and IsPedOnFoot(playerPed) then
		CurrentAction     = 'remove_entity'
		CurrentActionMsg  = _U('remove_prop')
		CurrentActionData = {entity = entity}
	end

	if GetEntityModel(entity) == joaat('p_ld_stinger_s') then
		local playerPed = cache.ped
		local coords    = GetEntityCoords(playerPed)

		if IsPedInAnyVehicle(playerPed, false) then
			local vehicle = GetVehiclePedIsIn(playerPed)

			for i=0, 7, 1 do
				--SetVehicleTyreBurst(vehicle, i, true, 1000)
			end
		end
	end
end)

AddEventHandler('esx_policejob:hasExitedEntityZone', function(entity)
	if CurrentAction == 'remove_entity' then
		CurrentAction = nil
	end
end)

RegisterNetEvent('esx_policejob:client:handcuff')
AddEventHandler('esx_policejob:client:handcuff', function()
	isHandcuffed = not isHandcuffed
	local playerPed = cache.ped

	if isHandcuffed then

		if(not LocalPlayer.state.down) then
			RequestAnimDict('mp_arresting')
			while not HasAnimDictLoaded('mp_arresting') do
				Citizen.Wait(0)
			end

			TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
			RemoveAnimDict('mp_arresting')
		end
		HandCuffedThread()
		SetEnableHandcuffs(playerPed, true)
		Player(GetPlayerServerId(PlayerId())).state:set("ankle",true,true)
		AnkleCuffed = true
		SetPedDiesInstantlyInWater(playerPed,false)
        SetPedDiesInWater(playerPed,false)
		CreateThread(function()
			Wait(1000)
			local IsInventoryOpen = LocalPlayer.state.invOpen
			if(IsInventoryOpen) then
				TriggerEvent('ox_inventory:closeInventory')
			end
			exports["lb-phone"]:ToggleDisabled(true)
			exports["lb-phone"]:ToggleOpen(false, false)
			ESX.SEvent("esx_policejob:server:ForceEndCall")
			-- if(LocalPlayer.state.callChannel ~= 0) then
			-- 	exports['qs-smartphone']:CancelCall()
			-- end
			SetFollowPedCamViewMode(0)
			
			TriggerEvent('canUseInventoryAndHotbar:toggle', false)
		end)
		LocalPlayer.state.canUseWeapons = false
		LocalPlayer.state.invBusy = true
		LocalPlayer.state.invHotkeys = false
		TriggerEvent('gi_carmenu:KillUI')
		TriggerEvent('gi-emotes:ForceClose')
		AddCuffProp()
		ExecuteCommand('closephone')
		TriggerEvent('ox_inventory:disarm', true)
		SetCurrentPedWeapon(playerPed, joaat('WEAPON_UNARMED'), true) -- unarm player
		SetPedCanPlayGestureAnims(playerPed, false)

		if Config.EnableHandcuffTimer then
			if handcuffTimer.active then
				ESX.ClearTimeout(handcuffTimer.task)
			end

			StartHandcuffTimer()
		end
	else
		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
		exports["lb-phone"]:ToggleDisabled(false)
		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
		Player(GetPlayerServerId(PlayerId())).state:set("ankle",nil,true)
		AnkleCuffed = false
		SetPedDiesInstantlyInWater(playerPed,false)
        SetPedDiesInWater(playerPed,true)
		TriggerEvent('canUseInventoryAndHotbar:toggle', true)
		RemoveCuffProp()
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)

		if(dragStatus.isDragged == true) then
			dragStatus.isDragged = false
			DetachEntity(playerPed, true, false)
		end

		LocalPlayer.state.canUseWeapons = true
		LocalPlayer.state.invBusy = false
		LocalPlayer.state.invHotkeys = true

		Citizen.Wait(500)
		ClearPedSecondaryTask(playerPed)
	end
end)

RegisterNetEvent('esx_policejob:unrestrain')
AddEventHandler('esx_policejob:unrestrain', function()
	if isHandcuffed then
		local playerPed = cache.ped
		isHandcuffed = false
		exports["lb-phone"]:ToggleDisabled(false)
		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
		Player(GetPlayerServerId(PlayerId())).state:set("ankle",nil,true)
		AnkleCuffed = false
		LocalPlayer.state.canUseWeapons = true
		LocalPlayer.state.invBusy = false
		LocalPlayer.state.invHotkeys = true
		SetPedDiesInstantlyInWater(playerPed,false)
        SetPedDiesInWater(playerPed,true)
		TriggerEvent('canUseInventoryAndHotbar:toggle', true)
		RemoveCuffProp()
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		FreezeEntityPosition(playerPed, false)

		ESX.SEvent('esx_policejob:RegisterRelease')
		-- end timer
		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end

		if(dragStatus.isDragged == true) then
			dragStatus.isDragged = false
			DetachEntity(playerPed, true, false)
		end
		
		Citizen.Wait(500)
		ClearPedSecondaryTask(playerPed)
	end
end)

RegisterNetEvent("esx_policejob:escortanim",function(targ)
	local ped = cache.ped
	local serverid = targ
	local target = GetPlayerFromServerId(serverid)
	if target ~= -1 then
		RequestAnimDict('anim@cop_pose_escorting')
		while not HasAnimDictLoaded('anim@cop_pose_escorting') do
			Citizen.Wait(100)
		end
		TaskPlayAnim(ped, 'anim@cop_pose_escorting', 'escorting_rifle', 8.0, -8, -1, 49, 0.0, false, false, false)
		RemoveAnimDict('anim@cop_pose_escorting')
		local targetped = GetPlayerPed(target)
		if not DoesEntityExist(targetped) then return end
		exports['okokTextUI']:Open("לשחרר את הגרירה [G] לחץ", "darkblue", "left")
		Wait(200)
		while true do
			Wait(0)
			ped = cache.ped

			if not IsEntityPlayingAnim(ped, 'anim@cop_pose_escorting', 'escorting_rifle',3) then
				RequestAnimDict('anim@cop_pose_escorting')
				while not HasAnimDictLoaded('anim@cop_pose_escorting') do
					Citizen.Wait(100)
				end
				TaskPlayAnim(ped, 'anim@cop_pose_escorting', 'escorting_rifle', 8.0, -8, -1, 49, 0.0, false, false, false)
				RemoveAnimDict('anim@cop_pose_escorting')
			end

			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 37, true) -- Select Weapon
			DisableControlAction(0, 47, true)  -- Disable weapon
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 263, true) -- Melee Attack 1
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 303, true) -- U Injured

			if IsControlJustReleased(0, 58) then
				ESX.ShowRGBNotification("success","משחרר גרירה")
				ESX.SEvent("esx_policejob:server:stopdrag",serverid)
				break
			end

			if not DoesEntityExist(targetped) or not IsPedCuffed(targetped) or GetEntityAttachedTo(targetped) ~= ped then
				break
			end
		end
		exports['okokTextUI']:Close()
		Wait(500)
		StopAnimTask(cache.ped, "anim@cop_pose_escorting","escorting_rifle", -4.0)
	end
end)

RegisterNetEvent('esx_policejob:drag')
AddEventHandler('esx_policejob:drag', function(copId)
	if not isHandcuffed then
		return
	end

	dragStatus.isDragged = not dragStatus.isDragged

	if(dragStatus.isDragged == false) then
		DetachEntity(cache.ped, true, false)
	end
	dragStatus.CopId = copId
end)


RegisterNetEvent("esx_policejob:DisableDrag",function()
	if(dragStatus.isDragged == true) then
		dragStatus.isDragged = false
		DetachEntity(cache.ped, true, false)
	end
end)

RegisterNetEvent('esx_policejob:putInVehicle')
AddEventHandler('esx_policejob:putInVehicle', function()

	if not isHandcuffed then
		return
	end

	local targetVehicle, distance = ESX.Game.GetClosestVehicle()

	if DoesEntityExist(targetVehicle) and distance < 5 then
		local playerPed = cache.ped
		local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(targetVehicle)

		for i=maxSeats - 1, 0, -1 do
			if IsVehicleSeatFree(targetVehicle, i) then
				if(i ~= -1) then
					freeSeat = i
					break
				end
			end
		end

		if freeSeat then
			SetPedIntoVehicle(playerPed, targetVehicle, freeSeat)
			TriggerEvent('gi-speedo:forcebelt')
			if(dragStatus.isDragged == true) then
				dragStatus.isDragged = false
				DetachEntity(playerPed, true, false)
			end
		end
	end
end)

RegisterNetEvent('esx_policejob:OutVehicle')
AddEventHandler('esx_policejob:OutVehicle', function()
	local playerPed = cache.ped

	if not IsPedSittingInAnyVehicle(playerPed) then
		return
	end

	local vehicle = GetVehiclePedIsIn(playerPed, false)
	TaskLeaveVehicle(playerPed, vehicle, 16)
	if(isHandcuffed) then
		Wait(500)
		RequestAnimDict('mp_arresting')
		while not HasAnimDictLoaded('mp_arresting') do
			Wait(100)
		end
		TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
		RemoveAnimDict('mp_arresting')
	end
end)


-- Handcuff
HandCuffedThread = function()
	CreateThread(function()
		local lastreset = GetGameTimer()
		while isHandcuffed do
			Wait(0)
			DisableControlAction(0, 21, true) -- Shift
			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 29, true)
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
			if(AnkleCuffed) then
				DisableControlAction(0, 32, true) -- W
				DisableControlAction(0, 34, true) -- A
				DisableControlAction(0, 31, true) -- S
				DisableControlAction(0, 30, true) -- D
			end

			DisableControlAction(0, 45, true) -- Reload
			DisableControlAction(0, 22, true) -- Jump
			DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 37, true) -- Select Weapon
			DisableControlAction(0, 23, true) -- Also 'enter'?

			DisableControlAction(0, 288,  true) -- Disable phone
			DisableControlAction(0, 289, true) -- F2
			DisableControlAction(0, 170, true) -- F3
			DisableControlAction(0, 167, true) -- F6

			DisableControlAction(0, 0, true) -- Disable changing view
			--DisableControlAction(0, 26, true) -- Disable looking behind
			DisableControlAction(0, 73, true) -- Disable clearing animation
			DisableControlAction(0, 166 , true) -- Disable Emote Menu
			DisableControlAction(2, 199, true) -- Disable pause screen

			DisableControlAction(0, 59, true) -- Disable steering in vehicle
			DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
			DisableControlAction(0, 72, true) -- Disable reversing in vehicle
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(0, 92,  true) -- Shoot in car
			DisableControlAction(0, 244,  true) -- Disable Car Locking
			DisableControlAction(0, 246, true) -- Y שלא יורידו בגדים הבני זונות
			

			DisableControlAction(2, 36, true) -- Disable going stealth

			DisableControlAction(0, 47, true)  -- Disable weapon
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Disable melee
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(27, 75, true) -- Disable exit vehicle


			local ped = cache.ped

			if dragStatus.isDragged then
				targetPed = GetPlayerPed(GetPlayerFromServerId(dragStatus.CopId))

				-- undrag if target is in an vehicle
				if not IsPedSittingInAnyVehicle(ped) then
					AttachEntityToEntity(ped, targetPed, 11816, -0.22, 0.6, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
					if(GetEntitySpeed(targetPed) > 0.1) then
						SimulatePlayerInputGait(PlayerId(), 1.0, 1, 1.0, 1, 0);
					end
				else
					dragStatus.isDragged = false
					DetachEntity(ped, true, false)
				end

				if IsPedDeadOrDying(ped, true) then
					dragStatus.isDragged = false
					DetachEntity(ped, true, false)
				end

			else
				if(not Transported) then
					DetachEntity(ped, true, false)
					if(IsPedSwimmingUnderWater(ped)) then
						SetEntityVelocity(ped,0.0,0.0,2.0)
					end
				end
			end

			if not IsEntityPlayingAnim(ped, 'mp_arresting', 'idle',3) then
				if(not lastreset or (GetTimeDifference(GetGameTimer(), lastreset) > 3000)) then
					lastreset = GetGameTimer()
					if(not LocalPlayer.state.down) then
						RequestAnimDict('mp_arresting')
						while not HasAnimDictLoaded('mp_arresting') do
							Citizen.Wait(100)
						end
						TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
						RemoveAnimDict('mp_arresting')
					end
				end
			end

			if DoesEntityExist(cuffprop) then
				if GetEntityHealth(cuffprop) <= 0 then
					PlaySoundFrontend(-1, "Drill_Pin_Break", "DLC_HEIST_FLEECA_SOUNDSET")
					TriggerEvent("esx_policejob:unrestrain")
					Wait(1500)
				end
			end
		end
	end)
end
--[[Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if isHandcuffed then
			--DisableControlAction(0, 1, true) -- Disable pan
			--DisableControlAction(0, 2, true) -- Disable tilt
			DisableControlAction(0, 21, true) -- Shift
			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 29, true)
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
			DisableControlAction(0, 32, true) -- W
			DisableControlAction(0, 34, true) -- A
			DisableControlAction(0, 31, true) -- S
			DisableControlAction(0, 30, true) -- D

			DisableControlAction(0, 45, true) -- Reload
			DisableControlAction(0, 22, true) -- Jump
			DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 37, true) -- Select Weapon
			DisableControlAction(0, 23, true) -- Also 'enter'?

			DisableControlAction(0, 288,  true) -- Disable phone
			DisableControlAction(0, 289, true) -- F2
			DisableControlAction(0, 170, true) -- F3
			DisableControlAction(0, 167, true) -- F6

			DisableControlAction(0, 0, true) -- Disable changing view
			DisableControlAction(0, 26, true) -- Disable looking behind
			DisableControlAction(0, 73, true) -- Disable clearing animation
			DisableControlAction(0, 166 , true) -- Disable Emote Menu
			DisableControlAction(2, 199, true) -- Disable pause screen

			DisableControlAction(0, 59, true) -- Disable steering in vehicle
			DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
			DisableControlAction(0, 72, true) -- Disable reversing in vehicle
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(0, 92,  true) -- Shoot in car
			DisableControlAction(0, 244,  true) -- Disable Car Locking
			DisableControlAction(0, 246, true) -- Y שלא יורידו בגדים הבני זונות
			

			DisableControlAction(2, 36, true) -- Disable going stealth

			DisableControlAction(0, 47, true)  -- Disable weapon
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Disable melee
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		else
			Citizen.Wait(500)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)
		if(isHandcuffed == true) then
			local ped = cache.ped

			if not IsEntityPlayingAnim(ped, 'mp_arresting', 'idle',3) then
				RequestAnimDict('mp_arresting')
				while not HasAnimDictLoaded('mp_arresting') do
					Citizen.Wait(100)
				end
				TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
				Citizen.Wait(2500)
				RemoveAnimDict('mp_arresting')
			end
		end
	end

end)--]]

-- Create blips
CreateThread(function()

	for k,v in pairs(Config.PoliceStations) do
		if(v.Blip) then
			local blip = AddBlipForCoord(v.Blip.Coords)

			SetBlipSprite (blip, v.Blip.Sprite)
			SetBlipDisplay(blip, 2)
			SetBlipScale  (blip, v.Blip.Scale)
			SetBlipColour (blip, v.Blip.Colour)
			SetBlipHighDetail(blip,true)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName('STRING')
			AddTextComponentString("Police Station")
			EndTextCommandSetBlipName(blip)
		end
	end

end)

-- Display markers
CreateThread(function()

	if not HasStreamedTextureDictLoaded("policemarker") then
        RequestStreamedTextureDict("policemarker", true)
        while not HasStreamedTextureDictLoaded("policemarker") do
            Wait(1)
        end
    end
	for k,v in pairs(Config.PoliceStations) do
		if(v.Archive) then
			for i=1, #v.Archive, 1 do
				exports["qb-target"]:AddBoxZone("police:Archive"..i, v.Archive[i], 1.5, 1.1, {
					name = "police:Archive"..i,
					minZ = v.Archive[i].z - 1,
					maxZ = v.Archive[i].z + 1,
					debugPoly = false
				}, {
					options = {
						{
							icon = "fa-solid fa-box-archive",
							label = "ארכיון עצורים",
							action = function(entity)
								if IsPedAPlayer(entity) then return false end
								ArchiveMenu()
							end,
							job = "police"
						},
						{
							type = 'client',
							event = 'esx_policejob:client:scanFingerPrint',
							icon = 'fas fa-fingerprint',
							label = 'טביעת אצבע',
							job = 'police',
						}
					},
					distance = 3.5
				})
			end
		end
	end

	-- local extradrawer = vector3(-558.178162, -99.664314, 32.518139)
	-- exports["qb-target"]:AddBoxZone("police:drawer1", extradrawer, 1.5, 1.1, {
	-- 	name = "police:drawer1",
	-- 	heading = 203.0,
	-- 	minZ = extradrawer.z - 1,
	-- 	maxZ = extradrawer.z + 1,
	-- 	debugPoly = false
	-- }, {
	-- 	options = {
	-- 		{
	-- 			type = 'client',
	-- 			icon = 'fa-solid fa-box-archive',
	-- 			label = 'מגירת ראיות',
	-- 			job = 'police',
	-- 			action = function()
	-- 				local drawer = exports['qb-input']:ShowInput({
	-- 					header = "מגירת ראיות",
	-- 					submitText = 'פתח',
	-- 					inputs = {
	-- 						{
	-- 							type = 'number',
	-- 							isRequired = true,
	-- 							name = 'slot',
	-- 							text = "מספר מגירה"
	-- 						}
	-- 					}
	-- 				})
	-- 				if drawer then
	-- 					if not drawer.slot then return end
	-- 					ESX.CloseContext()
	-- 					ESX.SEvent("esx_policejob:EvidenceDrawer",drawer.slot)
	-- 				end
	-- 			end,
	-- 		}
	-- 	},
	-- 	distance = 3.5
	-- })

	while true do
		Wait(0)

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then

			local playerPed = cache.ped
			local coords    = GetEntityCoords(playerPed)
			local isInMarker, hasExited, letSleep = false, false, true
			local currentStation, currentPart, currentPartNum

			for k,v in pairs(Config.PoliceStations) do

				for i=1, #v.Cloakrooms, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Cloakrooms[i], true)

					if distance < Config.DrawDistance then
						if(Config.CustomMarkers) then
							DrawMarker(9,v.Cloakrooms[i], 0, 0, 0, 0, 90.0, 90.0, 0.8, 0.8, 1.2, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
						else
							DrawMarker(20, v.Cloakrooms[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						end
						letSleep = false
					end

					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Cloakroom', i
					end
				end

				for i=1, #v.Armories, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Armories[i], true)

					if distance < Config.DrawDistance then
						if(Config.CustomMarkers) then
							DrawMarker(9,v.Armories[i], 0, 0, 0, 0, 90.0, 90.0, 0.8, 0.8, 1.2, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
						else
							DrawMarker(21, v.Armories[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						end
						
						letSleep = false
					end

					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Armory', i
					end
				end

				if(v.Evidence) then
					for i = 1, #v.Evidence, 1 do
						local distance = GetDistanceBetweenCoords(coords, v.Evidence[i], true)

						if distance < Config.DrawDistance then
							
							if(Config.CustomMarkers) then
								DrawMarker(9,v.Evidence[i], 0, 0, 0, 0, 90.0, 90.0, 0.8, 0.8, 1.2, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
							else
								DrawMarker(21, v.Evidence[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
							end
							letSleep = false
						end

						if distance < Config.MarkerSize.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Evidence', i
						end
					end
				end

				--[[if(v.Archive) then
					for i=1, #v.Archive, 1 do
						local distance = GetDistanceBetweenCoords(coords, v.Archive[i], true)

						if distance < Config.DrawDistance then
							
							if(Config.CustomMarkers) then
								DrawMarker(9,v.Archive[i], 0, 0, 0, 0, 90.0, 90.0, 0.8, 0.8, 1.2, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
							else
								DrawMarker(21, v.Archive[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
							end
							letSleep = false
						end

						if distance < Config.MarkerSize.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Archive', i
						end
					end
				end--]]

				if(v.Weaponry) then
					for i=1, #v.Weaponry, 1 do
						local distance = GetDistanceBetweenCoords(coords, v.Weaponry[i], true)

						if distance < Config.DrawDistance then
							if(Config.CustomMarkers) then
								DrawMarker(9,v.Weaponry[i], 0, 0, 0, 0, 90.0, 90.0, 0.8, 0.8, 1.2, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
							else
								DrawMarker(21, v.Weaponry[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
							end
							letSleep = false
						end

						if distance < Config.MarkerSize.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Weaponry', i
						end
					end
				end

				if(v.Kitchen) then
					for i=1, #v.Kitchen, 1 do
						local distance = GetDistanceBetweenCoords(coords, v.Kitchen[i], true)

						if distance < Config.DrawDistance then
							if(Config.CustomMarkers) then
								DrawMarker(9,v.Kitchen[i], 0, 0, 0, 0, 90.0, 90.0, 0.8, 0.8, 1.2, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
							else
								DrawMarker(21, v.Kitchen[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
							end
							

							letSleep = false
						end

						if distance < Config.MarkerSize.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Kitchen', i
						end
					end
				end
				if Config.EnablePlayerManagement and ESX.PlayerData.job.grade_name == 'boss' then
					if(v.BossActions) then
						for i=1, #v.BossActions, 1 do
							local distance = GetDistanceBetweenCoords(coords, v.BossActions[i], true)

							if distance < Config.DrawDistance then
								if(Config.CustomMarkers) then
									DrawMarker(9,v.BossActions[i], 0, 0, 0, 0, 90.0, 90.0, 0.8, 0.8, 1.2, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
								else
									DrawMarker(22, v.BossActions[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
								end
								letSleep = false
							end

							if distance < Config.MarkerSize.x then
								isInMarker, currentStation, currentPart, currentPartNum = true, k, 'BossActions', i
							end
						end
					end
					if(v.BossBills) then
						for i=1, #v.BossBills, 1 do
							local distance = GetDistanceBetweenCoords(coords, v.BossBills[i], true)

							if distance < Config.DrawDistance then
								if(Config.CustomMarkers) then
									DrawMarker(9,v.BossBills[i], 0, 0, 0, 0, 90.0, 90.0, 0.8, 0.8, 1.2, 255,255,255, 255, false, 0, 2, true, "policemarker", "policemarker", false)
								else
									DrawMarker(22, v.BossBills[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
								end
								letSleep = false
							end

							if distance < Config.MarkerSize.x then
								isInMarker, currentStation, currentPart, currentPartNum = true, k, 'BossBills', i
							end
						end
					end
				end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if
					(LastStation and LastPart and LastPartNum) and
					(LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('esx_policejob:hasExitedMarker', LastStation, LastPart, LastPartNum)
					hasExited = true
				end

				HasAlreadyEnteredMarker = true
				LastStation             = currentStation
				LastPart                = currentPart
				LastPartNum             = currentPartNum

				TriggerEvent('esx_policejob:hasEnteredMarker', currentStation, currentPart, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_policejob:hasExitedMarker', LastStation, LastPart, LastPartNum)
			end

			if letSleep then
				Wait(500)
			end

		else
			Wait(500)
		end
	end
end)

-- Enter / Exit entity zone events
CreateThread(function()
	local trackedEntities = {
		'prop_roadcone02a',
		'prop_barrier_work05',
		'p_ld_stinger_s',
		'prop_boxpile_07d',
		'hei_prop_cash_crate_half_full',
		'prop_worklight_03b',
		"prop_gazebo_03",
		"stt_prop_track_slowdown"
	}

	while true do
		local sleep = 1000
		if ESX.PlayerData.job and ESX.PlayerData.job.name == "police" then
			sleep = 500

			local playerPed = cache.ped
			local coords    = GetEntityCoords(playerPed)

			local closestDistance = -1
			local closestEntity   = nil

			if(not blocklobjects) then
				for i=1, #trackedEntities, 1 do
					local object = GetClosestObjectOfType(coords, 3.0, joaat(trackedEntities[i]), false, false, false)

					if DoesEntityExist(object) and IsEntityAMissionEntity(object) then
						local objCoords = GetEntityCoords(object)
						local distance  = #(coords - objCoords)

						if closestDistance == -1 or closestDistance > distance then
							closestDistance = distance
							closestEntity   = object
						end
					end
				end
			end

			if closestDistance ~= -1 and closestDistance <= 5.0 then
				if LastEntity ~= closestEntity then
					TriggerEvent('esx_policejob:hasEnteredEntityZone', closestEntity)
					LastEntity = closestEntity
				end
			else
				if LastEntity then
					TriggerEvent('esx_policejob:hasExitedEntityZone', LastEntity)
					LastEntity = nil
				end
			end
		end
		Wait(sleep)
	end
end)

-- CreateThread(function()
-- 	local hashkey = `p_ld_stinger_s`
-- 	while true do
-- 		local sleep = 650
-- 		local playerPed = cache.ped
		
-- 		local vehicle = GetVehiclePedIsIn(playerPed,false)
-- 		if vehicle ~= 0 then
-- 			sleep = 0
-- 			local coords = GetEntityCoords(vehicle)
-- 			local object = GetClosestObjectOfType(coords, 5.0, hashkey, false, false, false)
-- 			if object ~= 0 and GetEntityModel(object) == hashkey and IsEntityTouchingEntity(vehicle,object) then
-- 				for i=0, 7, 1 do
-- 					if(not IsVehicleTyreBurst(vehicle,i,true)) then
-- 						SetVehicleTyreBurst(vehicle, i, true, 500.0)
-- 					end
-- 				end
-- 			end

-- 		end
-- 		Wait(sleep)


-- 	end

-- end)


CreateThread(function()
	local Multiplied = false
    while true do
		local sleep = 1000
		local ped = cache.ped
		local veh = GetVehiclePedIsUsing(ped)
        if veh ~= 0 then
			if GetVehicleClass(veh) == 18 then
				local isDriver = GetPedInVehicleSeat(veh,-1) == ped
				if(isDriver) then
					sleep = 200
					if IsDisabledControlPressed(0, 86) then
						if(not Multiplied) then
							Multiplied = true
							SetVehicleLights(veh, 2)
							SetVehicleLightMultiplier(veh, 7.0)
						end
					elseif Multiplied then
						Multiplied = false
						SetVehicleLights(veh, 0)
						SetVehicleLightMultiplier(veh, 1.0)
					end
				end
			end
        end
		Wait(sleep)
	end
end)

-- Key Controls
CreateThread(function()
	while true do
		Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
				if CurrentAction == 'menu_cloakroom' then
					OpenCloakroomMenu()
				elseif CurrentAction == 'menu_armory' then
					OpenArmoryMenu(CurrentActionData.station)
				elseif CurrentAction == "menu_weaponry" then
					exports['gi-policearmory']:ExportWeaponry()
				--elseif CurrentAction == "menu_archive" then
					--ArchiveMenu()
				elseif CurrentAction == "menu_evidence" then
					EvidenceMenu()
				elseif CurrentAction == 'menu_kitchen' then
					OpenKitchenMenu(CurrentActionData.station)
				elseif CurrentAction == 'delete_vehicle' then
					ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
				elseif CurrentAction == 'menu_boss_actions' then
					ESX.UI.Menu.CloseAll()
					TriggerEvent('esx_society:openBossMenu', 'police', function(data, menu)
						menu.close()

						HasAlreadyEnteredMarker = false
					end, { wash = true }) -- disable washing money

				elseif CurrentAction == 'menu_boss_bills' then
					ESX.UI.Menu.CloseAll()

					--local elements = {}

					local elements = {
						head = {"שם השחקן", "פעולה"},
						rows = {}
					}

					local pre_players = ESX.GetInfinityPlayers()

					local sortplayers = mysort(pre_players)


					for _,v in pairs(sortplayers) do
						table.insert(elements.rows, {
							data = v,
							cols = {
								v.name.." ["..v.id.."]",
								"{{בדיקת דוחות|Select}}"
							}
						})
		
					end

					ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'billslead', elements, function(data, menu)

						local playerinfo = data.data
			
						if(playerinfo ~= nil) then
							OpenBillManagement(playerinfo)
						end
			
						menu.close()
						RefreshAction()
					end, function(data, menu)
						menu.close()
						RefreshAction()
					end)


				elseif CurrentAction == 'remove_entity' then
					-- if(not IsAimCamActive()) then
					-- 	-- while not NetworkHasControlOfEntity(CurrentActionData.entity) do
					-- 	-- 	Citizen.Wait(1)
					-- 	-- 	NetworkRequestControlOfEntity(CurrentActionData.entity)

					-- 	-- 	if(not DoesEntityExist(CurrentActionData.entity)) then
					-- 	-- 		break
					-- 	-- 	end
					-- 	-- end

					-- 	if(DoesEntityExist(CurrentActionData.entity)) then
					-- 		local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
					-- 		RequestAnimDict(dict)
					-- 		while not HasAnimDictLoaded(dict) do
					-- 			Citizen.Wait(100)
					-- 		end
					-- 		TaskPlayAnim(cache.ped, dict, anim, 8.0, 1.0, 1000, 51, 0.0, false, false, false)

					-- 		local targetent = CurrentActionData.entity
					-- 		RemoveAnimDict(dict)
					-- 		if(NetworkGetEntityIsNetworked(targetent)) then
					-- 			TriggerServerEvent("esx_policejob:server:RequestDeleteObject",NetworkGetNetworkIdFromEntity(targetent))
					-- 		else
					-- 			DeleteObject(targetent)
					-- 		end
					-- 		-- ESX.Game.DeleteObject(targetent)
					-- 	end
					-- end
				end

				CurrentAction = nil
			end
		end -- CurrentAction end

		if IsControlJustReleased(0, 167) and not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'police_actions') then
			OpenPoliceActionsMenu()
		end
	end
end)

function mysort(s)
    -- convert hash to array
    local t = {}
    for k, v in pairs(s) do
        table.insert(t, v)
    end

    -- sort
    table.sort(t, function(a, b)
        if a.id ~= b.id then
            return a.id < b.id
        end

        return a.name < b.name
    end)
    return t
end



function OpenBillManagement(iPlayer)

	local iPlayer = iPlayer

	local name = iPlayer.name

	local serverid = iPlayer.id


	local elements = {}

	ESX.TriggerServerCallback('esx_billing:GetTargetInvoices', function(bills)
		ESX.UI.Menu.CloseAll()

		local totalmoney = 0

		for i=1, #bills, 1 do

			if(bills[i].society == "society_police") then
				if(bills[i] and bills[i].invoice_value > 0) then
					totalmoney = totalmoney + bills[i].invoice_value
				end
				table.insert(elements, {
					label  = ('%s - <span style="color:red;">%s</span>'):format(bills[i].notes, _U('armory_item', ESX.Math.GroupDigits(bills[i].invoice_value))),
					billID = bills[i].id
				})
			end
		end

		if(#elements == 0) then
			ESX.ShowHDNotification("ERROR","אין לשחקן דוחות","error")
			RefreshAction()
			return
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'bill_boss',
		{
			title    = 'תפריט בוס - דוחות<br>Balance: <span style="color:green;">₪'..ESX.Math.GroupDigits(totalmoney)..'</span>',
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			menu.close()

			ESX.SEvent("esx_billing:CancelInvoice", data.current.billID)
			--ESX.SEvent('esx_billing:UnBill',data.current.billID,serverid)
			RefreshAction()
			ESX.SetTimeout(300, function()
				OpenBillManagement(iPlayer)
			end)
		end, function(data, menu)
			menu.close()
			RefreshAction()
		end)
	end,serverid)


end

	


AddEventHandler('playerSpawned', function(spawn)
	isDead = false
	TriggerEvent('esx_policejob:unrestrain')
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true

	if(IsPedInAnyPoliceVehicle(cache.ped)) then
		SetVehicleSiren(GetVehiclePedIsIn(cache.ped,false),false)
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('esx_policejob:unrestrain')
		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
		for id, objData in pairs(Config.SpawnedObjects) do
            if DoesEntityExist(objData.object) then
                DeleteEntity(objData.object)
            end
        end
	end
end)

RegisterNetEvent("esx_policejob:RestartTimer",function()
	StartHandcuffTimer()
end)

-- handcuff timer, unrestrain the player after an certain amount of time
function StartHandcuffTimer()
	if Config.EnableHandcuffTimer and handcuffTimer.active then
		ESX.ClearTimeout(handcuffTimer.task)
	end

	handcuffTimer.active = true

	handcuffTimer.task = ESX.SetTimeout(Config.HandcuffTimer, function()
		ESX.ShowNotification(_U('unrestrained_timer'))
		TriggerEvent('esx_policejob:unrestrain')

		handcuffTimer.active = false
	end)
end

function ImpoundVehicle(vehicle)
	--local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
	-- if(DoesEntityExist(vehicle)) then
	-- 	ESX.Game.DeleteVehicle(vehicle, true)
	-- end
	-- ESX.ShowNotification(_U('impound_successful'))
	local success = lib.callback.await("esx_policejob:server:requestImpound",false,VehToNet(vehicle))
	if(success) then
		ESX.ShowNotification(_U('impound_successful'))
	end
	currentTask.busy = false
end

RegisterNetEvent('esx_policejob:getarrested')
AddEventHandler('esx_policejob:getarrested', function(playerheading, playercoords, playerlocation)
	local playerPed = cache.ped
	TriggerEvent('ox_inventory:disarm', true)
	SetCurrentPedWeapon(playerPed, joaat('WEAPON_UNARMED'), true)
	local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
	SetEntityCoords(playerPed, x, y, z)
	SetEntityHeading(playerPed, playerheading)
	SetPlayerControl(PlayerId(), false, 1 << 8)
	Citizen.Wait(250)

	LoadAnimDict('mp_arrest_paired')
	TaskPlayAnim(playerPed, 'mp_arrest_paired', 'crook_p2_back_right', 8.0, -8, 3750 , 2, 0, 0, 0, 0)
	Citizen.Wait(3760)
	IsHandcuffed = true
	LocalPlayer.state.canUseWeapons = false
	LocalPlayer.state.invBusy = true
	LocalPlayer.state.invHotkeys = false
	HandCuffedThread()
	SetPlayerControl(PlayerId(), true, 1 << 8)
	TriggerEvent('esx_policejob:client:handcuff')
	if(not LocalPlayer.state.down) then
		LoadAnimDict('mp_arresting')
		TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)

		RemoveAnimDict('mp_arresting')
	end

	RemoveAnimDict('mp_arrest_paired')
end)

RegisterNetEvent('esx_policejob:doarrested')
AddEventHandler('esx_policejob:doarrested', function()
	handcuffing = true
	Citizen.Wait(250)
	local text = "אוזק"
	-- ExecuteCommand("me ".. text)
	TriggerEvent("gi-3dme:network:mecmd",text)
	LoadAnimDict('mp_arrest_paired')
	ESX.SEvent('InteractSound_SV:PlayWithinDistance', 4.5, 'handcuff', 0.9)
	TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'cop_p2_back_right', 8.0, -8,3750, 2, 0, 0, 0, 0)
	Citizen.Wait(3000)
	handcuffing = false

	RemoveAnimDict('mp_arrest_paired')

end)


RegisterNetEvent('esx_policejob:getuncuffed')
AddEventHandler('esx_policejob:getuncuffed', function(playerheading, playercoords, playerlocation)
	if(isHandcuffed == true) then
		local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
		local playerPed = cache.ped
		SetEntityCoords(playerPed, x, y, z)
		SetEntityHeading(playerPed, playerheading)
		Citizen.Wait(250)
		LoadAnimDict('mp_arresting')
		TaskPlayAnim(playerPed, 'mp_arresting', 'b_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
		Citizen.Wait(5500)
		IsHandcuffed = false
		TriggerEvent('esx_policejob:client:handcuff')
		TriggerEvent('esx_policejob:drag')
		ClearPedTasks(playerPed)
		RemoveAnimDict('mp_arresting')
	end
end)

RegisterNetEvent('esx_policejob:douncuffing')
AddEventHandler('esx_policejob:douncuffing', function()
	handcuffing = true
	Citizen.Wait(250)
	local text = "מוריד אזיקה"
	-- ExecuteCommand("me ".. text)
	TriggerEvent("gi-3dme:network:mecmd",text)
	LoadAnimDict('mp_arresting')
	local playerPed = cache.ped
	TaskPlayAnim(playerPed, 'mp_arresting', 'a_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
	Citizen.Wait(5500)
	ClearPedTasks(playerPed)
	handcuffing = false
	RemoveAnimDict('mp_arresting')
end)


RegisterNetEvent('esx_policejob:getuncuffedlp')
AddEventHandler('esx_policejob:getuncuffedlp', function(playerheading, playercoords, playerlocation)
	if(isHandcuffed == true) then
		local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
		local playerPed = cache.ped
		SetEntityCoords(playerPed, x, y, z)
		SetEntityHeading(playerPed, playerheading)
		Citizen.Wait(5000)
		LoadAnimDict('mp_arresting')
		TaskPlayAnim(playerPed, 'mp_arresting', 'b_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
		IsHandcuffed = false
		LocalPlayer.state.canUseWeapons = true
		LocalPlayer.state.invBusy = false
		LocalPlayer.state.invHotkeys = true
		TriggerEvent('esx_policejob:client:handcuff')
		TriggerEvent('esx_policejob:drag')
		Citizen.Wait(4000)
		ClearPedTasks(playerPed)
		RemoveAnimDict('mp_arresting')
	end
end)

RegisterNetEvent('esx_policejob:douncuffinglp')
AddEventHandler('esx_policejob:douncuffinglp', function(target)
	handcuffing = true
	LoadAnimDict('mp_arresting')
	local playerPed = cache.ped
	TaskPlayAnim(playerPed, 'mp_arresting', 'a_uncuff', 8.0, -8,-1, 81, 0, 0, 0, 0)
	RemoveAnimDict('mp_arresting')
	FreezeEntityPosition(playerPed,true)
	TriggerEvent("gi-3dme:network:mecmd",'פורץ אזיקים')
	local neededAttempts = 2
	local succeededAttempts = 0

	local success = exports["t3_lockpick"]:startLockpick(1, 2, 5)
	if success then
		exports.rprogress:Start("🧷 פורץ אזיקה 🧷", 5000)
		ESX.SEvent('esx_policejob:requestcuffsofflp', target)

		FreezeEntityPosition(playerPed,false)
		ClearPedTasks(playerPed)
		handcuffing = false
	else
		exports['mythic_notify']:DoHudText('error', 'פריצה נכשלה')
		ClearPedTasksImmediately(playerPed)
		FreezeEntityPosition(playerPed,false)
		ClearPedTasks(playerPed)
		handcuffing = false
	end

end)

RegisterNetEvent('esx_policejob:cuffsofflp')
AddEventHandler('esx_policejob:cuffsofflp', function()
	if(isHandcuffed == true) then
		Citizen.Wait(250)
		LoadAnimDict('mp_arresting')
		local playerPed = cache.ped
		TaskPlayAnim(playerPed, 'mp_arresting', 'b_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
		Citizen.Wait(4500)
		IsHandcuffed = false
		LocalPlayer.state.canUseWeapons = true
		LocalPlayer.state.invBusy = false
		LocalPlayer.state.invHotkeys = true
		TriggerEvent('esx_policejob:client:handcuff')
		TriggerEvent('esx_policejob:drag')
		Citizen.Wait(500)
		ClearPedTasks(playerPed)
		RemoveAnimDict('mp_arresting')
	end
end)

function LoadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(10)
    end
end

function IsPCuffed()
	return isHandcuffed
end


local lastspeaker

local VoiceLines = {
	"STOP_VEHICLE_CAR_MEGAPHONE",
	"STOP_VEHICLE_GENERIC_MEGAPHONE",
	--"COP_ARRIVAL_ANNOUNCE_MEGAPHONE",
	"STOP_VEHICLE_CAR_WARNING_MEGAPHONE",
	-- "SPOT_SUSPECT_CHOPPER_MEGAPHONE",
}

RegisterKeyMapping('PMEGA', 'Activates Megaphone', 'keyboard', "6")

RegisterCommand('PMEGA', function(source,args)
	if ESX.PlayerData.job.name ~= "police" then return end
	if LocalPlayer.state.invOpen then return end
	local playerPed = cache.ped
	local veh = GetVehiclePedIsIn(playerPed,false)
	if(veh == 0) then return end
	if IsPedInAnyPoliceVehicle(playerPed) then
		
		if(GetPedInVehicleSeat(veh,-1) == playerPed) then
			if(not lastspeaker or (GetTimeDifference(GetGameTimer(), lastspeaker) > 8000)) then
				local playerList = {}

				lastspeaker = GetGameTimer()
				local voiceline =  VoiceLines[math.random(#VoiceLines)]

				if(args and args[1]) then
					local line = tonumber(args[1])

					if(line == 1) then
						voiceline = "COP_ARRIVAL_ANNOUNCE_MEGAPHONE"
					elseif(line == 2) then
						voiceline = "SPOT_SUSPECT_CHOPPER_MEGAPHONE"
					elseif(line == 3) then
						voiceline = "SHOT_AT_HELI_MEGAPHONE"
					elseif(line == 4) then
						voiceline = "SHOT_TYRE_CHOPPER_MEGAPHONE"
					elseif(line == 5) then
						voiceline = "NO_LOITERING_MEGAPHONE"
					elseif(line == 6) then
						voiceline = "CLEAR_AREA_MEGAPHONE"
					elseif(line == 7) then
						voiceline = "CLEAR_AREA_PANIC_MEGAPHONE"
					elseif(line == 8) then
						voiceline = "STOP_VEHICLE_GENERIC_WARNING_MEGAPHONE"
					elseif(line == 9) then
						voiceline = "CHASE_VEHICLE_MEGAPHONE"
					elseif(line == 10) then
						voiceline = "STOP_VEHICLE_BOAT_MEGAPHONE"
					elseif(line == 11) then
						voiceline = "STOP_ON_FOOT_MEGAPHONE"
					end
				end
				local coords = GetEntityCoords(playerPed)
				for _, player in ipairs(GetActivePlayers()) do
					local ped = GetPlayerPed(player)
					if(DoesEntityExist(ped)) then
						local pcoords = GetEntityCoords(ped)
						if(#(pcoords - coords) < 300.0) then
							table.insert(playerList,GetPlayerServerId(player))
						end
					end
				end
				
	
				if(#playerList > 0) then
					TriggerEvent('routehere',playerList,voiceline)
				end
				--[[
					"STOP_VEHICLE_CAR_MEGAPHONE"
					"STOP_VEHICLE_BOAT_MEGAPHONE"

					"CLEAR_AREA_PANIC_MEGAPHONE"
					"CLEAR_AREA_MEGAPHONE"

					"NO_LOITERING_MEGAPHONE"
					"STOP_ON_FOOT_MEGAPHONE"
					"STOP_ON_FOOT_CHOPPER_MEGAPHONE"
					"STOP_VEHICLE_CAR_WARNING_MEGAPHONE"
					"STOP_VEHICLE_GENERIC_MEGAPHONE"
					"STOP_VEHICLE_GENERIC_WARNING_MEGAPHONE"
					"COP_ARRIVAL_ANNOUNCE_MEGAPHONE"
					"SHOT_AT_HELI_MEGAPHONE"
					"SHOT_TYRE_CHOPPER_MEGAPHONE"
					"LOST_SUSPECT_CHOPPER_MEGAPHONE"
					"SPOT_SUSPECT_CHOPPER_MEGAPHONE"
			
				--]]
			end
		end
	end

end)

RegisterNetEvent('routehere')
AddEventHandler('routehere',function(playerList,voiceline)
	local female = GetEntityModel(cache.ped) == `mp_f_freemode_01`
	ESX.SEvent("esx_policejob:sv_megaphone",playerList,voiceline,female)
end)

RegisterNetEvent("esx_policejob:Megaphone")
AddEventHandler("esx_policejob:Megaphone",function(target,line,female)


	local line = line


	if(not line) then
		line = "STOP_VEHICLE_CAR_MEGAPHONE"
	end
	
	local player = GetPlayerFromServerId(target)
	local playerPed = GetPlayerPed(player)
	if(not DoesEntityExist(playerPed)) then return end
	local Skin = joaat("S_M_Y_COP_01")
	local playerVeh = GetVehiclePedIsIn(playerPed, false)
	if(not DoesEntityExist(playerVeh)) then return end
	local playerPosition = GetEntityCoords(playerPed)
	Citizen.Wait(10)
	RequestModel(Skin)
	while(not HasModelLoaded(Skin)) do
		Citizen.Wait(10)
	end

	local Megaphone = CreatePed(26, Skin, playerPosition.x, playerPosition.y, playerPosition.z, 1, false, true)
	SetEntityInvincible(Megaphone, true)
	SetEntityVisible(Megaphone, false)
	SetEntityCollision(Megaphone, false, false)
	SetEntityCompletelyDisableCollision(Megaphone, true, true)
	AttachEntityToEntity(Megaphone, playerVeh, 0, 0.27, 0.0, 0.0, 0.5, 0.5, 180, false, false, false, false, 2, false)
	local SpeechName = "S_M_Y_COP_01_WHITE_FULL_01"
	if(female) then
		SpeechName = "S_F_Y_COP_01_BLACK_FULL_02"
	end
	PlayPedAmbientSpeechWithVoiceNative(Megaphone, line, SpeechName, "SPEECH_PARAMS_FORCE_SHOUTED", 6)
	SetModelAsNoLongerNeeded(Skin)

	Wait(5000)
	DeleteEntity(Megaphone)

end)


--STOP_VEHICLE_CAR_MEGAPHONE
--STOP_VEHICLE_CAR_WARNING_MEGAPHONE

local inVehicle = false
local left = false
local lastcar
local fizzPed = nil
local spawnRadius = 80.0
RegisterNetEvent('esx_policejob:callnayedet')
AddEventHandler('esx_policejob:callnayedet', function()
	if ESX.PlayerData.job.name == "police" then

		ESX.UI.Menu.CloseAll()

		local PoliceVehicles = {
			{ model = '19camry', label = "Toyota Camry", price = 0 },
			{ model = 'israeli', label = "Skoda Superb", price = 0 },
			{ model = 'qpsrav4', label = 'גיפ סיור', price = 0 },
			{ model = '18tahoenf', label = 'גיפ מפקד סיור', price = 0 },
			{ model = 'qpsprado', label = 'ניידת מג"ב', price = 0},
			{ model = 'policet', label = 'וואן יס"מ', price = 0},
			--{ model = 'umrazor', label = 'RZR מג"ב', price = 0},
			--{ model = 'policebikerb' , label = 'אופנוע שטח יס"מ' , price = 0},
			{ model = 'riot', label = 'זאב', price = 0 },
			{ model = 'foxkat', label = 'רכב מבצעים - רק יחידות מיוחדות', price = 0 },
			{ model = 'psp_bmwgs', label = 'אופנוע יסמ', price = 0 },	
			{ model = 'policebikerb', label = 'אופנוע יסמ שטח', price = 0 },	
			{ model = 'bcsspd', label = 'רכב שטח יממ', price = 0, limitedaccess = true },
			{ model = 'umprado', label = 'Land Cruiser משטרתית', price = 0 , limitedaccess = true},
			{ model = 'nm_z71', label = 'גיפ יממ', price = 0 , limitedaccess = true},
			{ model = 'mustang', label = 'רכב פיקוד משטרה', price = 0 , limitedaccess = true},
			{ model = 'gtrrb', label = '!רכב הנהלת משטרה - GTR', price = 0 , limitedaccess = true}
		}

		local elements = {}

		for k,v in pairs(PoliceVehicles) do
			if IsModelValid(joaat(v.model)) then
				table.insert(elements,{label = v.label, name = v.label, model = v.model})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), "esx_policeGarage_vehicle_garage",
		{
			title    = "הזמנת רכבים - משטרת ישראל",
			align    = "center",
			elements = elements
		},
		function(data, menu)

			ESX.UI.Menu.CloseAll()
			SpawnVehicle(data.current.model)


		end, function(data, menu)
			menu.close()
		end, function(data, menu)
		end)
	end
end)


ESX.RegisterClientCallback("esx_policejob:client:GetClosestNode",function(cb,coords)
	local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-spawnRadius, spawnRadius), coords.y + math.random(-spawnRadius, spawnRadius), coords.z, 0, 1, 0)
	if(not found) then return cb(false) end
	return cb(vector4(spawnPos.x,spawnPos.y,spawnPos.z,spawnHeading))
end)

function SpawnVehicle(vehhash)

	if(lastcar and (GetTimeDifference(GetGameTimer(), lastcar) < 600000)) then
		ESX.ShowNotification('אתה יכול להזמין ניידת כל 10 דקות')	
		return
	end

	if not varbar then
		ESX.ShowNotification("תקלה, נסה שנית")
		return
	end

	local vehhash = joaat(vehhash)
	lastcar = GetGameTimer()
	local text = "מזמין ניידת"
	TriggerEvent("gi-3dme:network:mecmd",text)
	RequestAnimDict("random@arrests");
	local playerPed = cache.ped
	while not HasAnimDictLoaded("random@arrests") do
		Wait(5);
	end
	TaskPlayAnim(playerPed,"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
	ESX.SEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)
	exports['progressBars']:startUI(1000, "מזמין ניידת")
	Citizen.Wait(1000)
	StopAnimTask(playerPed, "random@arrests","generic_radio_chatter", -4.0)
	RemoveAnimDict("random@arrests")

	ESX.ShowNotification('ניידת בדרך')

	local driverhash = joaat("s_m_y_cop_01")
	RequestModel(vehhash)
	RequestModel(driverhash)
	while not HasModelLoaded(vehhash) and not HasModelLoaded(driverhash) do
		Citizen.Wait(0)
	end 

	ESX.TriggerServerCallback("esx_policejob:server:SpawnNayedet",function(netid, pednet)
		if not netid or type(netid) == "boolean" then
			lastcar = nil
			SetModelAsNoLongerNeeded(vehhash)
			SetModelAsNoLongerNeeded(driverhash)
			ESX.ShowHDNotification("Delivery Failed","הזמנת הניידת נכשלה, נסה שוב","warning")
			return
		end

		local callback_vehicle = ESX.Game.VerifyEnt(netid)
		if not callback_vehicle then 
			lastcar = nil
			SetModelAsNoLongerNeeded(vehhash)
			SetModelAsNoLongerNeeded(driverhash)
			ESX.ShowRGBNotification("error","שיגור הרכב כשל") 
		end
		fizzPed = ESX.Game.VerifyEnt(pednet)
		if(not DoesEntityExist(fizzPed)) then
			ESX.ShowRGBNotification("error","שיגור הרכב כשל 2") 
			return
		end
		SetVehRadioStation(callback_vehicle, "OFF")			
		SetVehicleNumberPlateTextIndex(callback_vehicle,6) -- לוחית משטרה
		

		SetEntityLoadCollisionFlag(callback_vehicle,true)
		ESX.SEvent('esx_policejob:paymoney',500)
		local pedid = PedToNet(fizzPed)
		SetNetworkIdCanMigrate(pedid,false)
		SetPedCanRagdollFromPlayerImpact(fizzPed,false)
		SetBlockingOfNonTemporaryEvents(fizzPed, true)
		SetEntityAsMissionEntity(fizzPed, true, true)
		SetEntityLoadCollisionFlag(fizzPed,true)
		SetDriverAbility(fizzPed,1.0)
		SetEntityInvincible(fizzPed, true)
		SetVehicleDoorsLocked(callback_vehicle, 2)
		Wait(500)
		SetVehicleSiren(callback_vehicle,true)
		local carblip = AddBlipForEntity(callback_vehicle)
		SetBlipSprite(carblip, 42)
		SetBlipScale(carblip, 0.8)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentString("Police Delivery")
		EndTextCommandSetBlipName(carblip)
		local plate = exports['okokVehicleShop']:GeneratePlate()
		SetVehicleNumberPlateText(callback_vehicle,plate)
		TriggerEvent('cl_carlock:givekey',plate,false)
		ESX.SEvent("esx_policejob:CacheVeh",ESX.Math.Trim(GetVehicleNumberPlateText(callback_vehicle)))
		ClearAreaOfVehicles(GetEntityCoords(callback_vehicle), 4.0, false, false, false, false, false);  
		SetVehicleOnGroundProperly(callback_vehicle)
		inVehicle = true
		TaskVehicle(callback_vehicle,carblip)
	end,varbar,vehhash)
	

end

function TaskVehicle(vehicle,carblip)
	while inVehicle do
		Citizen.Wait(250)
		local pedcoords = GetEntityCoords(cache.ped)
		local plycoords = GetEntityCoords(fizzPed)
		local dist = GetDistanceBetweenCoords(plycoords, pedcoords.x,pedcoords.y,pedcoords.z, false)
		
		if dist <= 25.0 then
			SetVehicleMaxSpeed(vehicle,4.5)
			TaskVehicleDriveToCoord(fizzPed, vehicle, pedcoords.x, pedcoords.y, pedcoords.z, 10.0, 1, vehhash, 2883621, 5.0, 1)
			SetVehicleFixed(vehicle)
			if dist <= 14.5 then
				LeaveIt(vehicle)
				RemoveBlip(carblip)
			else
				Citizen.Wait(250)
			end
		else
			TaskVehicleDriveToCoord(fizzPed, vehicle, pedcoords.x, pedcoords.y, pedcoords.z, 20.0, 1, vehhash, 2883621, 5.0, 1)
			Citizen.Wait(250)
		end
		while left do
			Citizen.Wait(250)
			local Xpedcoords = GetEntityCoords(cache.ped)
			local Ypedcoords = GetEntityCoords(fizzPed)
			local distPed = GetDistanceBetweenCoords(Xpedcoords, Ypedcoords, false)
			TaskGoToCoordAnyMeans(fizzPed, Xpedcoords.x, Xpedcoords.y, Xpedcoords.z, 1.0, 0, 0, 786603, 1.0)
			if distPed <= 2.3 then
				left = false
				GiveKeysTakeMoney()
			end
		end
	end
end

function LeaveIt(vehicle)
	TaskLeaveVehicle(fizzPed, vehicle, 14)
	inVehicle = false
	while IsPedInAnyVehicle(fizzPed, false) do
		Citizen.Wait(0)
	end 
	SetVehicleMaxSpeed(vehicle,0.0)
	
	Citizen.Wait(500)
	TaskWanderStandard(fizzPed, 10.0, 10)
	left = true
end

function GiveKeysTakeMoney()
	TaskStandStill(fizzPed, 2250)
	TaskTurnPedToFaceEntity(fizzPed, cache.ped, 1.0)
	PlayAmbientSpeech1(fizzPed, "Generic_Hi", "Speech_Params_Force")
	Citizen.Wait(500)
	startPropAnim(fizzPed, "mp_common", "givetake1_a")
	Citizen.Wait(1500)
	stopPropAnim(fizzPed, "mp_common", "givetake1_a")
	left = false
end

function startPropAnim(ped, dictionary, anim)
	Citizen.CreateThread(function()
	  	RequestAnimDict(dictionary)
		while not HasAnimDictLoaded(dictionary) do
			Citizen.Wait(0)
	  	end
		TaskPlayAnim(ped, dictionary, anim ,8.0, -8.0, -1, 50, 0, false, false, false)
		RemoveAnimDict(dictionary)
	end)
end

function stopPropAnim(ped, dictionary, anim)
	StopAnimTask(ped, dictionary, anim ,8.0, -8.0, -1, 50, 0, false, false, false)
	Citizen.Wait(100)
	while not NetworkHasControlOfEntity(fizzPed) and DoesEntityExist(fizzPed) do
		Citizen.Wait(1)
		NetworkRequestControlOfEntity(fizzPed)
	end
    DeletePed(fizzPed)
    fizzPed = nil
end


local isTaz = false

AddEventHandler('gameEventTriggered', function (name, data)
	
    if name == 'CEventNetworkEntityDamage' then

        local vType = GetEntityType(data[1])
		local vType = GetEntityType(data[2])



		if aType == 0 or vType == 0 or aType == 2 or vType == 2 or aType == 3 or vType == 3 then
            return
        end

		local ped = cache.ped
		local victim = data[1]
		
		if(victim == ped) then
			local weapon = data[7]
			if(weapon and (weapon == joaat("WEAPON_STUNGUN") or weapon == joaat("WEAPON_STUNROD"))) then

				if(GetPlayerUnderwaterTimeRemaining(PlayerId()) <= 0) then
					return
				end

				if not isTaz then

					local dontBreak = true
					

					Citizen.CreateThread(function()
						while dontBreak do
							Citizen.Wait(250)
							SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
						end
					end)
					
					isTaz = true
					SetTimecycleModifier("REDMIST_blend")
					ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 0.1)
					
					
					Wait(7000)

					dontBreak = false
					
					SetTimecycleModifier("hud_def_desat_Trevor")
					
					Wait(8000)
					
					SetTimecycleModifier("")
					SetTransitionTimecycleModifier("")
					StopGameplayCamShaking()
					isTaz = false
				end
			end
		end
	end
end)

function RefreshAction()
	CurrentAction = nil
	CurrentActionMsg  = ""
	HasAlreadyEnteredMarker = false
end


function ArchiveMenu()

	local elements = {}
	table.insert(elements, {label = "לרשום דוח מעצר",     value = 'write_arrest'})
	table.insert(elements, {label = "רשימת מעצרים",     value = 'arrest_list'})

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory', {
		title    = "ארכיון מעצרים",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'write_arrest' then
			WriteReport()
		elseif data.current.value == 'arrest_list' then
			ArrestList()
		end

	end, function(data, menu)
		menu.close()
	end)


end



function WriteReport()

	local playersInArea = ESX.Game.GetPlayersInArea(GetEntityCoords(cache.ped), 20.0)

	local elements = {}

	for i=1, #playersInArea, 1 do
		if playersInArea[i] ~= PlayerId() then
			table.insert(elements, {label = GetPlayerName(playersInArea[i]).." [ "..GetPlayerServerId(playersInArea[i]).." ]", value = playersInArea[i]})
		end
	end

	--[[
		table.insert(elements, {label = GetPlayerName(PlayerId()).." [ "..GetPlayerServerId(PlayerId()).." ]", value = PlayerId()})
	--]]

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'show_prisoners_list', {
		title    = "רשימת עצורים ( לא לבחור שוטרים )",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if(data.current.value ~= nil) then 
			menu.close()

			local target = GetPlayerServerId(data.current.value)

			if(target == 0) then
				ESX.ShowNotification('.תקלה, השחקן יצא מהשרת')
				return
			end

			local dialog = exports['qb-input']:ShowInput({
				header = "סיבת מעצר",
				submitText = "שלח דוח מעצר✏️",
				inputs = {
					{
						text = "סיבת מעצר",
						name = "reason",
						type = "text",
						isRequired = true,
					},
					{
						text = "כלי נשק", -- text you want to be displayed as a input header
						name = "weapons", -- name of the input should be unique otherwise it might override
						type = "select", -- type of the input - Select is useful for 3+ amount of "or" options e.g; someselect = none OR other OR other2 OR other3...etc
						options = { -- Select drop down options, the first option will by default be selected
							{ value = "אין", text = "אין" }, -- Options MUST include a value and a text option
							{ value = "נשק קר ( סכין וכו )", text = "נשק קר"}, -- Options MUST include a value and a text option
							{ value = "אקדח", text = "אקדח" }, -- Options MUST include a value and a text option
							{ value = "נשק כבד", text = "נשק כבד" }, -- Options MUST include a value and a text option
							{ value = "נשק כבד ואקדח", text = "נשק כבד ואקדח" }, -- Options MUST include a value and a text option
							{ value = "נשק כבד", text = "נשק כבד אקדח וסכין" }, -- Options MUST include a value and a text option
						},
						default = 'none', -- Default select option, must match a value from above, this is optional
					},
					{
						text = "הערות נוספות", -- text you want to be displayed as a input header
						name = "notes", -- name of the input should be unique otherwise it might override
						type = "checkbox", -- type of the input - Check is useful for "AND" options e.g; taxincle = gst AND business AND othertax
						options = { -- The options (in this case for a check) you want displayed, more than 6 is not recommended
							{ value = "copkill", text = "?רצח שוטרים"}, -- Options MUST include a value and a text option
							{ value = "chase", text = "?מרדף"}  -- Options MUST include a value and a text option
						}
					},
				}
			})
		
			if(dialog ~= nil) then
				local reason = dialog.reason

				if reason  then
					local weapons = dialog.weapons

					local notes = dialog.notes

					if(dialog.copkill == "false") then
						dialog.copkill = false
					else
						dialog.copkill = true
					end

					if(dialog.chase == "false") then
						dialog.chase = false
					else
						dialog.chase = true
					end

					ESX.SEvent('esx_policejob:ArchivePlayerById', target, reason,dialog)
					ESX.ShowHDNotification("SUCCESS","הדוח מעצר נשלח בהצלחה",'success')
				else
					ESX.ShowNotification('יש לציין סיבת מעצר')
				end
			end
		end
	end, function(data, menu)
		menu.close()
	end)

	

end


function ArrestList()


	ESX.TriggerServerCallback('esx_policejob:getArrests', function(arrests)

		local elements = {}

		if #arrests == 0 then
			ESX.ShowNotification("אין עצורים רשומים כרגע")
		else

			for _,v in pairs(arrests) do
				local Prisoner = '<strong>'..v.name..'</strong> - [ <span style="color:green;"><strong>'..v.ID..'</span></strong> ]'


				table.insert(elements, {label = Prisoner, value = v})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'show_prisoners', {
			title    = "ארכיון עצורים",
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			if(data.current.value ~= nil) then 
				menu.close()

				OpenDetailedArrestMenu(data.current.label,data.current.value)
			end
		end, function(data, menu)
			menu.close()
		end)
	end)

end

function OpenDetailedArrestMenu(label,prisoner)

	local elements = {}

	table.insert(elements, {label = label, value = "nil"})

	table.insert(elements, {label = 'זמן מעצר: <span style="color:yellow;"><strong>'..prisoner.time..'</span></strong>', value = "nil"})



	table.insert(elements, {label = 'סיבת מעצר: <span style="color:orange;"><strong>'..prisoner.reason..'</span></strong>', value = "nil"})

	table.insert(elements, {label = 'נכתב על ידי: <strong>'..prisoner.arrester..'</span></strong>', value = "nil"})
	table.insert(elements, {label = 'נשקים: <strong>'..prisoner.weapons..'</span></strong>', value = "nil"})
	table.insert(elements, {label = 'רצח שוטרים?: <strong>'..prisoner.copkill..'</span></strong>', value = "nil"})
	table.insert(elements, {label = 'מרדף משטרתי: <strong>'..prisoner.chase..'</span></strong>', value = "nil"})



	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'show_prisoners', {
		title    = "ארכיון עצורים",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

	end, function(data, menu)
		menu.close()
	end)

end

function EvidenceMenu()
	if ESX.PlayerData.job.name == "police" then
		ESX.CloseContext()
		local elements = {
			{unselectable = true, icon = "fas fa-shirt", title = "חדר ראיות"},
			{icon = "fas fa-shirt", title = "הכנסת כסף/כסף שחור", value = 'storeevidence'},
			{icon = "fas fa-user-cog", title = "הפקדת ראיות", value = 'evidencestorage'},
			{icon = "fa-solid fa-sack-dollar", title = "תיק משא ומתן", value = 'negomoney'},
			{icon = "fa-solid fa-hand-holding-dollar", title = "הפקדת תיק משא ומתן", value = 'depositmoney'},
			
		}
		ESX.OpenContext("left", elements, function(menu,element)
			local data = {current = element}
			if data.current.value == 'storeevidence' then
				ESX.CloseContext()
				local elements = {
					head = {"תפריט הפקדת ראיות - משטרת ישראל"},
					rows = {}
				}
		
				table.insert(elements.rows, {
					data = "money",
					cols = {
						"{{הפקד כסף רגיל|Select}}"
					}
				})
				
				table.insert(elements.rows, {
					data = "black",
					cols = {
						"{{הפקד כסף שחור|Select}}"
					}
				})
		

		
				ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'evider', elements, function(data, menu)
		
					local evinfo = data.data
		
					if(evinfo ~= nil) then
						--SpawnSeizedVehicle(carinfo.vehicle, carinfo.plate)
						ESX.SEvent('esx_policejob:DumpEvidence',evinfo)
					end
		
					menu.close()
				end, function(data, menu)
					menu.close()
				end)
			elseif data.current.value == 'evidencestorage' then
				local drawer = exports['qb-input']:ShowInput({
					header = "מגירת ראיות",
					submitText = 'פתח',
					inputs = {
						{
							type = 'number',
							isRequired = true,
							name = 'slot',
							text = "מספר מגירה"
						}
					}
				})
				if drawer then
					if not drawer.slot then return end
					ESX.CloseContext()
					ESX.SEvent("esx_policejob:EvidenceDrawer",drawer.slot)
				end
			elseif data.current.value == "negomoney" then
				local input = lib.inputDialog("הוצאת תיק משא ומתן", {
					{type = 'slider', label = 'כמות כסף', description = 'כמה כסף תרצה לשים בתיק', required = true, min = 1000, max = 20000},
				})
				if(input and input[1]) then
					ESX.Game.Progress("on_moneybag", string.format("₪%s אורז תיק בשווי", input[1]), 9000, true, true, {
						disableMovement = true,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {
						animDict = 'mini@triathlon',
						anim = 'rummage_bag',
						flags = 1,
					}, {}, {}, function()
						ClearPedTasksImmediately(cache.ped)
						SetPedCurrentWeaponVisible(cache.ped, true, false, false, false)
						TriggerServerEvent("esx_policejob:server:RequestMoneyBag", input[1])
					end, function()
						ClearPedTasksImmediately(cache.ped)
						SetPedCurrentWeaponVisible(cache.ped, true, false, false, false)
					end)
				end
			elseif data.current.value == "depositmoney" then
				exports['gi-grangeillegal']:MoneyDeposit()
			end
		end, function(menu)
			ESX.CloseContext()
			HasAlreadyEnteredMarker = false
		end)

	end

end


function OpenPropList(id_number)
	if(ESX.PlayerData.job.grade_name == "boss") then
		TriggerEvent("ps-housing:SendHousePolice",id_number)
	end

end


RegisterNetEvent('esx_policejob:showAnim')
AddEventHandler('esx_policejob:showAnim',function()
	TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
end)


RegisterNetEvent('esx_policejob:FireClient')
AddEventHandler('esx_policejob:FireClient',function(pednets)
	local peds = {}
	--local startPos, startAng = vector3(431.76, -992.14, 30.35), -100.0
	local startPos, startAng = vector3(-534.41, -136.81, 38.6), 326.0
	local anim = "mini@strip_club@throwout_d@"
	RequestAnimDict(anim)

	DoScreenFadeOut(800)

	while not IsScreenFadedOut() do
		Wait(10)
	end

	DoScreenFadeIn(800)

	Wait(50)

	local InMotion = true


	CreateThread(function()
		while InMotion do
			Wait(0)
			DisableAllControlActions(0)
			EnableControlAction(0,1,true)
			EnableControlAction(0,2,true)
			EnableControlAction(0,137,true)
			EnableControlAction(0,245,true)
			EnableControlAction(0,249,true)
		end
	end)

	local peds = {}
	peds[1] = CreatePed(4, joaat("mp_m_freemode_01"),startPos + vector3(-10.0, .0, .0), .0, true, true)

	local face1 = math.random(1,50)
	SetPedComponentVariation(peds[1], 0, face1, 0, 0)
	SetPedHeadBlendData     (peds[1], face1, face1, face1, 0, 0, 0, 1.0, 1.0, 1.0, true)
	SetPedComponentVariation(peds[1], 2, math.random(1,30), 1, 2)
	SetPedHairColor(peds[1],math.random(1,5),math.random(1,5))
	SetPedComponentVariation(peds[1], 3, 0, 0, 0)
	SetPedComponentVariation(peds[1], 4, 83, 0, 0)
	SetPedComponentVariation(peds[1], 6, 65, 0, 0)
	SetPedComponentVariation(peds[1], 8, 161, 0, 0)
	SetPedComponentVariation(peds[1], 9, 7, 0, 0)
	SetPedComponentVariation(peds[1], 11, 6, 0, 0)
	SetPedPropIndex(peds[1],0,1,0,2)
	SetPedCombatAttributes(peds[1], 46, true)                     
	SetPedFleeAttributes(peds[1], 0, 0)                      
	SetBlockingOfNonTemporaryEvents(peds[1], true)
	SetEntityInvincible(peds[1], true)
	FreezeEntityPosition(peds[1], true)
	SetAmbientVoiceName(peds[1], "G_M_Y_Lost_02_WHITE_FULL_01")
	PlayAmbientSpeech1(peds[1], "Generic_Insult_High", "Speech_Params_Force")

	peds[2] = CreatePed(4, joaat("mp_m_freemode_01"), startPos + vector3(-10.0, .0, .0), .0, true, true)
	local face2 = math.random(1,50)
	SetPedComponentVariation(peds[2], 0, face2, 0, 0)
	SetPedHeadBlendData(peds[2], face2, face2, face2, 0, 0, 0, 1.0, 1.0, 1.0, true)
	SetPedComponentVariation(peds[2], 2, math.random(1,30), 1, 2)
	SetPedHairColor(peds[2],math.random(1,5),math.random(1,5))
	SetPedComponentVariation(peds[2], 3, 0, 0, 0)
	SetPedComponentVariation(peds[2], 4, 83, 0, 0)
	SetPedComponentVariation(peds[2], 6, 65, 0, 0)
	SetPedComponentVariation(peds[2], 8, 161, 0, 0)
	SetPedComponentVariation(peds[2], 9, 7, 0, 0)
	SetPedComponentVariation(peds[2], 11, 6, 0, 0)
	SetPedPropIndex(peds[2],0,1,0,2)
	SetPedCombatAttributes(peds[2], 46, true)                     
	SetPedFleeAttributes(peds[2], 0, 0)                      
	SetBlockingOfNonTemporaryEvents(peds[2], true)
	SetEntityInvincible(peds[2], true)
	FreezeEntityPosition(peds[2], true)

	peds[3] = cache.ped
	ped = peds[3]
	SetEntityCoords(peds[3], startPos + vector3(-10.0, .0, .0), 0, false, 0, 1)
	FreezeEntityPosition(peds[3], true)

	local cam = CreateCamera(964613260, 0)
	SetEntityVisibleInCutscene(ped, 1, 1)

	local scene = NetworkCreateSynchronisedScene(startPos, .0, .0, startAng, 1, 1, 0, 1.0, 0.0, 1.0)
	FreezeEntityPosition(peds[1], false)
	NetworkAddPedToSynchronisedScene(peds[1], scene, anim, "throwout_d_bouncer_a", 1000.0, -2.0, 0, 4, 1148846080, 0)
	FreezeEntityPosition(peds[2], false)
	NetworkAddPedToSynchronisedScene(peds[2], scene, anim, "throwout_d_bouncer_b", 1000.0, -2.0, 0, 4, 1148846080, 0)
	FreezeEntityPosition(peds[3], false)
	NetworkAddPedToSynchronisedScene(peds[3], scene, anim, "throwout_d_victim", 1000.0, -2.0, 0, 4, 1148846080, 0)

	NetworkStartSynchronisedScene(scene)


	Wait(8000)


	NetworkStopSynchronisedScene(scene)

	InMotion = false
	RemoveAnimDict(anim)

	
	ClearPedTasks(ped)
	while not NetworkHasControlOfEntity(peds[1]) do
		NetworkRequestControlOfEntity(peds[1])
		Wait(50)
	end
	DeleteEntity(peds[1])

	while not NetworkHasControlOfEntity(peds[2]) do
		NetworkRequestControlOfEntity(peds[2])
		Wait(50)
	end
	DeleteEntity(peds[2])

	

end)


RegisterCommand('mivhan',function()
	if ESX.PlayerData.job.name == "police" then
		if(ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
			if closestPlayer == -1 or closestDistance > 3.0 then
				ESX.ShowNotification(_U('no_players_nearby'))
				return
			end
			TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

			local input = lib.inputDialog("הגשת טופס בחינה", {
				{type = 'number', label = 'גיל אוסי', description = 'הגיל של השחקן במציאות', required = true, min = 10, max = 120},
				{type = 'number', label = 'גיל אייסי', description = 'הגיל של השחקן בשרת', required = true, min = 16, max = 120},
				{type = 'input', label = 'שם אוסי', description = 'שם של השחקן במציאות', required = true, min = 2, max = 255},
				{type = 'slider', label = '⭐ דירוג בחינה ⭐', description = 'איך הייתם מדרגים את הבחינה במספר', required = true, min = 0, max = 10},
				{type = 'checkbox', label = '?האם עבר'},
			})
			ClearPedTasksImmediately(cache.ped)
			if(input) then
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer == -1 or closestDistance > 3.0 then
					ESX.ShowNotification(_U('no_players_nearby'))
				else
					ESX.SEvent('esx_policejob:SendTest',GetPlayerServerId(closestPlayer),input[1],input[2],input[3],input[4],input[5])
					ESX.ShowHDNotification("SUCCESS","הדוח נשלח בהצלחה",'success')
				end
			end
		end
	end

end)


RegisterNetEvent('esx_gangs:OutfitstorageGang')
AddEventHandler('esx_gangs:OutfitstorageGang',function(gangname)

	local gang = gangname

	local elements = {
		{ label = "Outfits", value = 'outfits' },
		{ label = "Storage", value = 'storage' },
		{ label = "Food Storage", value = 'kitchen' },
	}


	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'GangMenu', {
		title    = "Storage / Outfits",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'outfits' then
			ESX.TriggerServerCallback('esx_property:getPlayerDressing', function(dressing)
				local elements = {}

				for i=1, #dressing, 1 do
					table.insert(elements, {
						label = dressing[i],
						value = i
					})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_dressingGang', {
					title    = "חדר לבוש גאנגים" .. ' - ' .. "בגדים שלך",
					align    = 'top-left',
					elements = elements
				}, function(data2, menu2)
					TriggerEvent('skinchanger:getSkin', function(skin)
						ESX.TriggerServerCallback('esx_property:getPlayerOutfit', function(clothes)
							TriggerEvent('skinchanger:loadClothes', skin, clothes)
							TriggerEvent('esx_skin:setLastSkin', skin)

							TriggerEvent('skinchanger:getSkin', function(skin)
								ESX.SEvent('esx_skin:save', skin)
							end)
						end, data2.current.value)
					end)
				end, function(data2, menu2)
					menu2.close()
				end)
			end)

		elseif data.current.value == 'storage' then
			exports.ox_inventory:openInventory('stash', "Stash_"..gang)
		elseif data.current.value == 'kitchen' then
			exports.ox_inventory:openInventory('stash', gang.."_Fridge")
		end
	end, function(data, menu)
		menu.close()
	end)


end)

RegisterNetEvent('esx_policejob:cameras')
AddEventHandler('esx_policejob:cameras',function(coords,camera)

	if(ESX.PlayerData.job.grade_name ~= "boss") then
		ESX.ShowNotification('המצלמות נועדו להנהלת המשטרה בלבד')
		return
	end

	local coords = vector3(-532.73, -165.5, 42.09)
	local camera = 2
	PoliceCam(coords,camera)
end)

local fov_max = 80.0
local fov_min = 40.0 -- max zoom level (smaller fov is more zoom)
local speed_lr = 8.0 -- speed by which the camera pans left-right 
local speed_ud = 8.0 -- speed by which the camera pans up-down
local fov = (fov_max+fov_min)*0.5
function PoliceCam(coords, camnum)
  

  local coords = coords
  local camnum = camnum
  DoScreenFadeOut(150)
  Citizen.Wait(500)
  cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 0.5, 0.0, 0.00, 350 - 180, 80.00, false, 0)
  SetCamActive(cam, true)
  RenderScriptCams(true, true, 500, true, true)

  FrontCam = true
  local ped = cache.ped
  FreezeEntityPosition(ped, true)
  ExecuteCommand('e tablet2')
  Citizen.Wait(500)
  DoScreenFadeIn(150)
  local soundid = GetSoundId()
  Citizen.CreateThread(function()
    fov = (fov_max+fov_min)*0.5
    PlaySoundFrontend(soundid,"Pan", "MP_CCTV_SOUNDSET", false);
    SetFocusPosAndVel(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z)
    SetCamCoord(cam, coords.x, coords.y, coords.z)
    SetCamFov(cam, fov)
    while FrontCam do
    	local instructions = CreateInstuctionScaleform("instructional_buttons")
		DrawScaleformMovieFullscreen(instructions, 255, 255, 255, 255, 0)
		SetTimecycleModifier("scanline_cam_cheap")
		SetTimecycleModifierStrength(1.0)
		DisableAllControlActions(0)
		EnableControlAction(0,1,true)
		EnableControlAction(0,2,true)
		EnableControlAction(0,137,true)
		EnableControlAction(0,245,true)
		EnableControlAction(0,249,true)
		local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
		CheckInputRotation(cam, zoomvalue)
		HandleZoom(cam)
      	if(IsDisabledControlPressed(1, 20)) then
			if(camnum == 1) then
				camnum = 2

				StopSound(soundid)
				ReleaseSoundId(soundid)
				DoScreenFadeOut(150)
				Citizen.Wait(500)
				SetCamActive(cam, false)
				DestroyCam(cam, true)
				ClearTimecycleModifier("scanline_cam_cheap")
				coords = vector3(-532.73, -165.5, 42.09)
				cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 0.5, 0.0, 0.00, 350 - 180, 80.00, false, 0)
				SetCamActive(cam, true)
				SetFocusPosAndVel(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z)
				SetCamCoord(cam, coords.x, coords.y, coords.z)
				RenderScriptCams(true, true, 500, true, true)
				soundid = GetSoundId()
				PlaySoundFrontend(soundid,"Pan", "MP_CCTV_SOUNDSET", false);
				DoScreenFadeIn(150)
			elseif(camnum == 2) then
				camnum = 3

				StopSound(soundid)
				ReleaseSoundId(soundid)
				DoScreenFadeOut(150)
				Citizen.Wait(500)
				SetCamActive(cam, false)
				DestroyCam(cam, true)
				ClearTimecycleModifier("scanline_cam_cheap")
				coords = vector3(-546.07, -121.03, 41.49)
				cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 0.5, 0.0, 0.00, 350 - 180, 80.00, false, 0)
				SetCamActive(cam, true)
				SetFocusPosAndVel(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z)
				SetCamCoord(cam, coords.x, coords.y, coords.z)
				RenderScriptCams(true, true, 500, true, true)
				soundid = GetSoundId()
				PlaySoundFrontend(soundid,"Pan", "MP_CCTV_SOUNDSET", false);
				DoScreenFadeIn(150)
			elseif(camnum == 3) then
				camnum = 4
	
				StopSound(soundid)
				ReleaseSoundId(soundid)
				DoScreenFadeOut(150)
				Citizen.Wait(500)
				SetCamActive(cam, false)
				DestroyCam(cam, true)
				ClearTimecycleModifier("scanline_cam_cheap")
				coords = vector3(-556.46, -121.46, 61.41)
				cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 0.5, 0.0, 0.00, 350 - 180, 80.00, false, 0)
				SetCamActive(cam, true)
				SetFocusPosAndVel(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z)
				SetCamCoord(cam, coords.x, coords.y, coords.z)
				RenderScriptCams(true, true, 500, true, true)
				soundid = GetSoundId()
				PlaySoundFrontend(soundid,"Pan", "MP_CCTV_SOUNDSET", false);
				DoScreenFadeIn(150)
			elseif(camnum == 4) then
				camnum = 5
	
				StopSound(soundid)
				ReleaseSoundId(soundid)
				DoScreenFadeOut(150)
				Citizen.Wait(500)
				SetCamActive(cam, false)
				DestroyCam(cam, true)
				ClearTimecycleModifier("scanline_cam_cheap")
				coords = vector3(-588.22, -109.24, 35.89)
				cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 0.5, 0.0, 0.00, 350 - 180, 80.00, false, 0)
				SetCamActive(cam, true)
				SetFocusPosAndVel(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z)
				SetCamCoord(cam, coords.x, coords.y, coords.z)
				RenderScriptCams(true, true, 500, true, true)
				soundid = GetSoundId()
				PlaySoundFrontend(soundid,"Pan", "MP_CCTV_SOUNDSET", false);
				DoScreenFadeIn(150)

				
			elseif(camnum == 5) then
				camnum = 1
				coords = vector3(207.27, -784.15, 42.99)
				StopSound(soundid)
				ReleaseSoundId(soundid)
				DoScreenFadeOut(150)
				Citizen.Wait(500)
				SetCamActive(cam, false)
				DestroyCam(cam, true)
				ClearTimecycleModifier("scanline_cam_cheap")
				cam = nil
				cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 0.5, 0.0, 0.00, 350 - 180, 80.00, false, 0)
				SetCamActive(cam, true)
				SetFocusPosAndVel(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z)
				SetCamCoord(cam, coords.x, coords.y, coords.z)
				RenderScriptCams(true, true, 500, true, true)
				soundid = GetSoundId()
				PlaySoundFrontend(soundid,"Pan", "MP_CCTV_SOUNDSET", false);
				DoScreenFadeIn(150)

			end
    	end

		if IsDisabledControlPressed(1, 177) or IsEntityDead(ped) then
			StopSound(soundid)
			ReleaseSoundId(soundid)
			DoScreenFadeOut(150)
			Citizen.Wait(500)
			RenderScriptCams(false, true, 500, true, true)
			FreezeEntityPosition(cache.ped, false)
			SetCamActive(cam, false)
			DestroyCam(cam, true)
			ClearTimecycleModifier("scanline_cam_cheap")
			cam = nil
			FrontCam = false
			SetFocusEntity(cache.ped)
			Citizen.Wait(500)
			DoScreenFadeIn(150)
		end
		Citizen.Wait(1)
	end

  end)
end

function CheckInputRotation(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5) -- Clamping at top (cant see top of heli) and at bottom (doesn't glitch out in -90deg)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function HandleZoom(cam)
	if IsDisabledControlJustPressed(0,241) then -- Scrollup
		fov = math.max(fov - 2.0, fov_min)
	end
	if IsDisabledControlJustPressed(0,242) then
		fov = math.min(fov + 2.0, fov_max) -- ScrollDown	
	end
	local current_fov = GetCamFov(cam)
	if math.abs(fov-current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
		fov = current_fov
	end
	SetCamFov(cam, current_fov + (fov - current_fov)*0.05) -- Smoothing of camera zoom
end

function CreateInstuctionScaleform(scaleform)
  local scaleform = RequestScaleformMovie(scaleform)
  while not HasScaleformMovieLoaded(scaleform) do
      Citizen.Wait(0)
  end
  PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
  PopScaleformMovieFunctionVoid()
  
  PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
  PushScaleformMovieFunctionParameterInt(200)
  PopScaleformMovieFunctionVoid()

  PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
  PushScaleformMovieFunctionParameterInt(1)
  InstructionButton(GetControlInstructionalButton(1, 194, true))
  InstructionButtonMessage("Close Camera")
  PopScaleformMovieFunctionVoid()

  PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
  PushScaleformMovieFunctionParameterInt(2)
  InstructionButton(GetControlInstructionalButton(1, 20, true))
  InstructionButtonMessage("Change Camera")
  PopScaleformMovieFunctionVoid()

  PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
  PopScaleformMovieFunctionVoid()

  PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
  PushScaleformMovieFunctionParameterInt(0)
  PushScaleformMovieFunctionParameterInt(0)
  PushScaleformMovieFunctionParameterInt(0)
  PushScaleformMovieFunctionParameterInt(80)
  PopScaleformMovieFunctionVoid()

  return scaleform
end

function InstructionButton(ControlButton)
  N_0xe83a3e3557a56640(ControlButton)
end

function InstructionButtonMessage(text)
  BeginTextCommandScaleformString("STRING")
  AddTextComponentScaleform(text)
  EndTextCommandScaleformString()
end

function AddCuffProp()
    if(not DoesEntityExist(cuffprop)) then
        RequestModel(joaat("p_cs_cuffs_02_s"));
        local coords = GetEntityCoords(cache.ped, false);
        cuffprop = CreateObject(joaat("p_cs_cuffs_02_s"), coords.x, coords.y, coords.z, true, true, true);
        SetEntityHealth(cuffprop,200)
        SetEntityProofs(cuffprop,false,true,true,true,true,true,1,true)
		SetModelAsNoLongerNeeded(joaat("p_cs_cuffs_02_s"))
        local networkId = ObjToNet(cuffprop);
        SetNetworkIdCanMigrate(networkId, false);
        AttachEntityToEntity(cuffprop, cache.ped, GetPedBoneIndex(cache.ped, 60309), -0.055, 0.06, 0.04, 265.0, 155.0, 80.0, true, false, false, false, 0, true);
    end
end


function RemoveCuffProp()
    if(DoesEntityExist(cuffprop)) then
        DetachEntity(cuffprop, true, true);
        DeleteEntity(cuffprop);
    end
end


function DoBilling(vehicle)

	local plate = GetVehicleNumberPlateText(vehicle)
			
	local dialog = exports['qb-input']:ShowInput({
		header = plate.." :רישום דוח לרכב",
		submitText = "שלח דוח ✏️",
		inputs = {
			{
				text = "סיבה לדוח",
				name = "reason",
				type = "text",
				isRequired = true,
			},
			{
				text = "כמה כסף",
				name = "amount",
				type = "number",
				isRequired = true,
			},
		}
	})

	if(dialog ~= nil) then
		local amount = tonumber(dialog.amount)
		if amount == nil then
			ESX.ShowNotification("כמות שגויה")
		elseif amount > 60000 then
			ESX.ShowNotification('הסכום המקסימלי הוא 60,000 שקל בלבד')
		else
			if not IsAnyVehicleNearPoint(GetEntityCoords(cache.ped), 5.0) then
				ESX.ShowNotification(_U('no_vehicles_nearby'))
			else
				ESX.Game.Progress("esx_policejob:WriteBillEye","כותב את הדוח", 12000, false, true, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {
					task = "CODE_HUMAN_MEDIC_TIME_OF_DEATH",
				}, {}, {}, function() -- Done
					ESX.SEvent('esx_policejob:carbill', plate, dialog.reason, tonumber(amount))
					ESX.ShowNotification("דוח נשלח")
					ClearPedTasksImmediately(cache.ped)
				end, function()
					ClearPedTasksImmediately(cache.ped)
				end,"fas fa-edit")
			end
		end
	end
end



AddEventHandler("esx_policejob:ResetCuffs",function(target)
	local serverid = GetPlayerServerId(target)
	if(serverid == -1) then
		ESX.ShowHDNotification("","לא נמצאה המטרה","error")
		return
	end

	if ESX.PlayerData.job.name ~= "police" then
		return
	end

	TriggerEvent("gi-3dme:network:mecmd","מהדק אזיקה")
	ESX.SEvent("esx_policejob:sv_resetcuffs",serverid)
end)


RegisterNetEvent("esx_policejob:cl_resetcuffs",function()
	if(not isHandcuffed) then
		return
	end

	StartHandcuffTimer()
	ESX.ShowHDNotification("משטרת ישראל","האזיקים שלך הודקו","police")
end)

CreateThread(function()
	exports['qb-target']:AddGlobalVehicle({
		options = {
		  {
			type = "client",
			icon = 'fas fa-pencil', 
			label = "לשים דוח על הרכב",
			action = function(entity)
			  if IsPedAPlayer(entity) then return false end 
			  	DoBilling(entity)
			end,
			canInteract = function(entity, distance, data)
			  if IsPedAPlayer(entity) then return false end 

			  return true
			end,
			job = "police"
		  },
		  {
			type = "client",
			icon = 'fas fa-car-crash', 
			label = "בדיקת מצב רכב",
			action = function(entity)
			  if IsPedAPlayer(entity) or not NetworkGetEntityIsNetworked(entity) then return false end 
			  ESX.Game.Progress("esx_policejob:checkvehicle", "בודק את הרכב", 3000, false, true, {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			}, {
				task = "CODE_HUMAN_MEDIC_TEND_TO_DEAD",
			}, {}, {}, function() -- Done
				ClearPedTasksImmediately(cache.ped)
				ESX.TriggerServerCallback("esx_policejob:getDamagedByBullet",function(Damaged)
					if(Damaged) then
						ESX.ShowHDNotification("Police Evidence","הרכב נפגע מכדורים","success")
					else
						ESX.ShowHDNotification("Police Evidence","הרכב לא נפגע מכדורים","info")
					end
				end,VehToNet(entity))
			end, function()
				ClearPedTasksImmediately(cache.ped)
			end,"fas fa-car-crash")

			  	
			end,
			canInteract = function(entity, distance, data)
			  if IsPedAPlayer(entity) then return false end 

			  return true
			end,
			job = "police"
			
		  }
		},
		distance = 2.5,
	  })

	  exports.ox_target:addGlobalPlayer({
		{
			label = "הידוק אזיקה",
			name = "ptiecuffs",
			icon = 'fa-solid fa-handcuffs',
			distance = 1.5,
			onSelect = function(data)
				TriggerEvent('esx_policejob:ResetCuffs', NetworkGetPlayerIndexFromPed(data.entity))
			end,
			canInteract = function(entity)
				if(not IsPedAPlayer(entity) or not IsPedCuffed(entity)) then return false end
			  return true
			end,
			groups = "police",
		},
		{
			label = 'אזיקת רגליים',
			name = "tielegs",
			icon = 'fa-solid fa-handcuffs',
			distance = 1.5,
			onSelect = function(data)
				local entity = data.entity
				local player = NetworkGetPlayerIndexFromPed(entity)
				local targetPed = GetPlayerPed(player)
				if(DoesEntityExist(targetPed)) then
					if(ESX.PlayerData.job.name == "police") then
			  			ESX.SEvent('esx_policejob:server:CuffLegs',GetPlayerServerId(player))
					end
				end
			end,
			canInteract = function(entity)
				if(not IsPedAPlayer(entity) or not IsPedCuffed(entity)) then return false end
			  return true
			end,
			groups = "police",
		}
	  })

	  exports.ox_target:addGlobalVehicle({
		{
			label = "שבירת חלונות",
			name = "windowbreak",
			icon = "fa-brands fa-windows",
			bones = { 'window_lf', 'window_rf', 'window_lr', 'window_rr', 'window_lm', 'window_rm'},
			distance = 1.0,
			onSelect = function(data)
				local veh = data.entity
				if(not DoesEntityExist(veh)) then return end
				TaskTurnPedToFaceEntity(cache.ped, veh, 1.0)
				Wait(350)
			 	LoadAnimDict('melee@hatchet@streamed_core')
                TaskPlayAnim(cache.ped, 'melee@hatchet@streamed_core', 'plyr_rear_takedown_b', 8.0, -8.0, -1, 2, 0, false, false, false)
				RemoveAnimDict('melee@hatchet@streamed_core')
				Wait(1300)
				StopAnimTask(cache.ped,'melee@hatchet@streamed_core','plyr_rear_takedown_b',1.0)

				ESX.SEvent("esx_policejob:server:smashWindows",VehToNet(veh))
				ShakeGameplayCam("SMALL_EXPLOSION_SHAKE",0.5)
			end,
			canInteract = function()
				return GetSelectedPedWeapon(cache.ped) == `WEAPON_NIGHTSTICK`
			end,
			groups = "police",

		}
	  })
end)


AddStateBagChangeHandler("ankle","player:"..GetPlayerServerId(PlayerId()), function(bagName, key, value)
	AnkleCuffed = value
end)

RegisterNetEvent("esx_policejob:client:smashWindows",function(netid)
    if(not NetworkDoesEntityExistWithNetworkId(netid)) then return end
    local veh = NetToVeh(netid)
    if(DoesEntityExist(veh)) then
		for i = -1, 10, 1 do
			SmashVehicleWindow(veh,i)
		end
		if(veh == GetVehiclePedIsIn(cache.ped,false)) then
			ESX.ShowRGBNotification("error","שברו את החלונות של הרכב שלך")
			ShakeGameplayCam("SMALL_EXPLOSION_SHAKE",0.5)
		end
	end
end)

function ApplyStuff(xPlayer)
	if(not xPlayer) then
		xPlayer = ESX.GetPlayerData()
	end

	ESX.PlayerData = xPlayer
end


if(ESX.IsPlayerLoaded()) then
	ApplyStuff()
end

-- Countdown Timer

RegisterNuiCallback("timer",function(data,cb)
	ESX.ShowHDNotification("Timer","הטיימר נעצר","info")
	chasetimer = false
end)

-- Bonus System
RegisterCommand("bonus",function()
	if(ESX.PlayerData.job.name ~= "police") then return end
	if(ESX.PlayerData.job.grade_name ~= "boss") then return end
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	if closestPlayer == -1 or closestDistance > 3.0 then
		ESX.ShowNotification(_U('no_players_nearby'))
	else
		local targetid = GetPlayerServerId(closestPlayer)
		if(targetid == 0) then 
			ESX.ShowRGBNotification("error","לא נמצא המטרה שבחרת")
			return 
		end
		local dialog = exports['qb-input']:ShowInput({
			header = "Target: "..GetPlayerName(closestPlayer).." ["..targetid.."]",
			submitText = "הענקת בונוס",
			inputs = {
				{
					text = "כמה כסף",
					name = "amount",
					type = "number",
					isRequired = true,
				},
				{
					text = "הערות",
					name = "info",
					type = "text",
				},
			}
		})

		if(dialog ~= nil) then
			local amount = tonumber(dialog.amount)
			if amount == nil then
				ESX.ShowNotification("כמות שגויה")
			elseif amount > 600000 then
				ESX.ShowNotification('הסכום המקסימלי הוא 600,000 שקל בלבד')
			else
				if(ESX.PlayerData.job.name ~= "police") then return end
				if(ESX.PlayerData.job.grade_name ~= "boss") then return end
				ESX.SEvent("esx_policejob:HandOutBonus",targetid,amount,dialog.info)
			end
		end
	end
end)

RegisterKeyMapping('TOGGLESIRMUTE', 'Toggle Siren Mute', 'keyboard', "Y")
RegisterCommand("TOGGLESIRMUTE",function()
	local ped = cache.ped
	local policecar = GetVehiclePedIsIn(ped,false)
	if(GetVehicleClass(policecar) == 18 or IsPedInAnyPoliceVehicle(ped)) then
		if(GetPedInVehicleSeat(policecar,-1) ~= ped) then ESX.ShowRGBNotification("error",".רק הנהג יכול לשלוט על הסירנה") return end
		if IsPedInAnyHeli(ped) then return end
		if(ESX.PlayerData.job.name ~= "police" and ESX.PlayerData.job.name ~= "ambulance") then return end
		PlaySoundFrontend(-1, "HACKING_CLICK_GOOD", 0, 1)
		ESX.SEvent("esx_policejob:mutesirens",VehToNet(policecar), not Entity(policecar).state['sirensilence'])
	end
end)

AddStateBagChangeHandler("sirensilence", nil, function(bagName, key, value, _unused, replicated)
    if bagName:sub(1, 7) == "entity:" then
        local ent = ESX.Game.GetEntityFromStateBag(bagName,6500)
		if(DoesEntityExist(ent)) then
			SetVehicleHasMutedSirens(ent, value)
		end
    end
end)


local neverknock = false
AddEventHandler("esx:enteredVehicle",function(vehicle,_,_,displayname)
	if(displayname == "FBI2") then
		SetPedCanBeKnockedOffVehicle(cache.ped,1)
		neverknock = true
	end
end)

AddEventHandler('esx:exitedVehicle',function(vehicle)
	if(not neverknock) then return end
	SetPedCanBeKnockedOffVehicle(cache.ped,0)
	neverknock = false
end)

CreateThread(function()
	exports.ox_target:addBoxZone({
		coords = vector3(Config.Flag.Target.x, Config.Flag.Target.y, Config.Flag.Target.z),
		size = vec3(2, 2, 2),
		debug = false,
		drawSprite = true,
		options = {
			{
				name = "policeflagup",
				icon = "fa-solid fa-up-long",
				label = "הנפת דגל",
				distance = 2.5,
				onSelect = function(data)
					if(ESX.PlayerData.job.name == "police") then
						ClearPedTasksImmediately(cache.ped)
						TaskTurnPedToFaceCoord(cache.ped,Config.Flag.Target.x, Config.Flag.Target.y, Config.Flag.Target.z,1000)
						ESX.SEvent("esx_policejob:server:SendFlag",Config.Flag.MaxZ)
						-- Wait(1000)
						-- TriggerEvent('animations:client:EmoteCommandStart',{"salute4"})
					end
				end,
			},
			{
				name = "policeflagdown",
				icon = "fa-solid fa-down-long",
				label = "הורדת דגל",
				distance = 2.5,
				onSelect = function(data)
					if(ESX.PlayerData.job.name == "police") then
						ClearPedTasksImmediately(cache.ped)
						TaskTurnPedToFaceCoord(cache.ped,Config.Flag.Target.x, Config.Flag.Target.y, Config.Flag.Target.z,1000)
						ESX.SEvent("esx_policejob:server:SendFlag",Config.Flag.MinZ)
						-- Wait(1000)
						-- TriggerEvent('animations:client:EmoteCommandStart',{"salute4"})
					end
				end,
			},
			{
				name = "policeflaghalf",
				icon = "fa-solid fa-flag",
				label = "חצי התורן",
				distance = 2.5,
				onSelect = function(data)
					if(ESX.PlayerData.job.name == "police") then
						ClearPedTasksImmediately(cache.ped)
						TaskTurnPedToFaceCoord(cache.ped,Config.Flag.Target.x, Config.Flag.Target.y, Config.Flag.Target.z,1000)
						ESX.SEvent("esx_policejob:server:SendFlag",(Config.Flag.MaxZ + Config.Flag.MinZ) / 2)
						-- Wait(1000)
						-- TriggerEvent('animations:client:EmoteCommandStart',{"salute4"})
					end
				end,
			}
		}
	})
end)

local customFlag = 0

local function RemoveNearbyFlags(coords)
	local flag = joaat("prop_flag_sheriff")
	local objs = GetGamePool("CObject")
	for i = 1,#objs, 1 do
		local obj = objs[i]
		if(not IsEntityAMissionEntity(obj)) then
			if(#(GetEntityCoords(obj) - coords) < 12.0 and GetEntityModel(obj) == flag) then
				SetEntityAsMissionEntity(obj,true,true)
				DeleteEntity(obj)
				break
			end
		end
	end
end

RegisterNetEvent("esx_policejob:client:SendFlag",function(height)
	local flag = joaat("prop_flag_sheriff")
	RemoveNearbyFlags(Config.Flag.Default)
	if(not DoesEntityExist(customFlag)) then
		RequestModel(flag)
		while not HasModelLoaded(flag) do
			Wait(50)
		end
		customFlag = CreateObject(flag,Config.Flag.Default.x,Config.Flag.Default.y,Config.Flag.Default.z,false,true,false)
		SetEntityLoadCollisionFlag(flag,true)
		SetModelAsNoLongerNeeded(flag)
	end

	local ccoords = GetEntityCoords(customFlag)
	local goup = ccoords.z < height
	local flagsound = GetSoundId()
	PlaySoundFromEntity(flagsound, "Rappel_Loop",customFlag, "GTAO_Rappel_Sounds",false, true);
	if(not goup) then
		while GetEntityCoords(customFlag).z > height do
			Wait(0)
			SetEntityCoords(customFlag,GetOffsetFromEntityInWorldCoords(customFlag,0.0,0.0,-0.01))
		end
		SetEntityCoords(customFlag,Config.Flag.Default.x,Config.Flag.Default.y,height)
	else
		while GetEntityCoords(customFlag).z < height do
			Wait(0)
			SetEntityCoords(customFlag,GetOffsetFromEntityInWorldCoords(customFlag,0.0,0.0,0.01))
		end
		SetEntityCoords(customFlag,Config.Flag.Default.x,Config.Flag.Default.y,height)
	end
	StopSound(flagsound)
	ReleaseSoundId(flagsound)
	PlaySoundFromEntity(-1,"Rappel_Land",customFlag,"GTAO_Rappel_Sounds",false,0)
	PlaySoundFromEntity(-1,"Rappel_Stop",customFlag,"GTAO_Rappel_Sounds",false,0)

end)

CreateThread(function()
    local model = 741314661
    local location = vector3(1818.16, 2608.48, 45.6)
    while true do
        Wait(1000)
        local obj = GetClosestObjectOfType(location.x, location.y,location.z, 8.0, model,false, false, false)
        if(obj ~= 0) then
            SetEntityAsMissionEntity(obj, true, true)
            DeleteEntity(obj)
        end
    end
end)



DecorRegister("IsPoliceObj", 3)

local Spikes = {}

local function AddLocalSyncedObject(id)
	CreateThread(function()
		local objData = Config.SpawnedObjects[id]
		if objData then
			if not objData.object or not DoesEntityExist(objData.object) then
				local model = objData.model
				lib.requestModel(model, 5000)
				if(not Config.SpawnedObjects[id] or objData.object and DoesEntityExist(objData.object)) then 
					SetModelAsNoLongerNeeded(model)
					return 
				end
				objData.object = CreateObject(model, objData.coords.x, objData.coords.y, objData.coords.z, false, true, false)
				SetEntityHeading(objData.object, objData.coords.w)
				SetModelAsNoLongerNeeded(model)
				DecorSetInt(objData.object, "IsPoliceObj", id)
				PlaceObjectOnGroundProperly(objData.object)
				if objData.isSpike then
					Spikes[id] = objData.object
				end
				
				if model == "prop_boxpile_07d" then
					FreezeEntityPosition(objData.object, true)
				end

				if not objData.PlayedAnim then
					objData.PlayedAnim = true
					if model == "p_ld_stinger_s" then
						FreezeEntityPosition(objData.object,true)
						CreateThread(function()
							RequestAnimDict("p_ld_stinger_s")
							while not HasAnimDictLoaded("p_ld_stinger_s") do
								Wait(0)
							end
							if DoesEntityExist(objData.object) then
								PlayEntityAnim(objData.object, "P_Stinger_S_Deploy", "p_ld_stinger_s", 1000.0, false, true, false, 0.0, 0)
							end
							RemoveAnimDict("p_ld_stinger_s")
						end)
						PlaceObjectOnGroundProperly(objData.object)
					end
				end
			end
		end
	end)
    
end

RegisterNetEvent("esx_policejob:client:AddSyncObj", function(id, obj)
    Config.SpawnedObjects[id] = obj
    Config.SpawnedObjects[id].PlayedAnim = false
	if #(GetEntityCoords(cache.ped) - obj.coords.xyz) < 423 then
		AddLocalSyncedObject(id)
	end
end)

local function RemoveLocalSyncedObject(id, ClearFromList)
    local objData = Config.SpawnedObjects[id]
	if ClearFromList then
		Config.SpawnedObjects[id] = nil
	end
    if objData and objData.object then
        if DoesEntityExist(objData.object) then
            DeleteObject(objData.object)
        end
    end
end

RegisterNetEvent("esx_policejob:client:RemoveSyncObj", function(id)
    RemoveLocalSyncedObject(id, true)
end)

local function RequestDeleteObject(id)
	if(LocalPlayer.state.down or IsPedDeadOrDying(cache.ped,false)) then return end
    if Config.SpawnedObjects[id] then
        local answer = lib.callback.await("esx_policejob:server:RequestDeleteObject", false, id)
        if not answer then
            Config.SpawnedObjects[id].RequestDelete = nil
		else
			local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
			RequestAnimDict(dict)
			while not HasAnimDictLoaded(dict) do
				Wait(0)
			end
			TaskPlayAnim(cache.ped, dict, anim, 8.0, 1.0, 1000, 51, 0.0, false, false, false)
			RemoveAnimDict(dict)
		end
    end
end

RegisterNetEvent("esx_policejob:client:SyncAll", function(objconfig)
    Config.SpawnedObjects = objconfig
end)

CreateThread(function()
    while not ESX.IsPlayerLoaded() do
        Wait(0)
    end
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(cache.ped)
        for id, objData in pairs(Config.SpawnedObjects) do
            local distance = #(playerCoords - vector3(objData.coords.x, objData.coords.y, objData.coords.z))
            if distance > 424 then
                RemoveLocalSyncedObject(id)
            elseif distance <= 423 then
                AddLocalSyncedObject(id)
            end
  
            if distance <= 3 and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and not blocklobjects then
                sleep = 0
				ESX.ShowHelpNotification(_U('remove_prop'),true)
				if IsControlJustReleased(0, 101) then
					if(ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
						if Config.SpawnedObjects[id] and not Config.SpawnedObjects[id].RequestDelete then
							if(not lastscan or (GetTimeDifference(GetGameTimer(), lastscan) > 5000)) then
								lastscan = GetGameTimer()
								ESX.SEvent('esx_policejob:ScanObject',id)
								goto restart
							else
								ESX.ShowHDNotification("ERROR","נא להמתין 5 שניות בין כל סריקת אובייקט",'error')
							end
						end
					end
	
					
				end
                if IsControlJustReleased(0, 51) then
                    if Config.SpawnedObjects[id] and not Config.SpawnedObjects[id].RequestDelete then
                        RequestDeleteObject(id)
                    end
                    goto restart
                end
            end
        end
        ::restart::
        Wait(sleep)
    end
end)

local closestSpike = nil

CreateThread(function()
    while true do
		local sleep = 1000
 
        if cache.vehicle then
			sleep = 150
			local vehCoords = GetEntityCoords(cache.vehicle)
			local closestDistance = math.huge

			for id, spike in pairs(Spikes) do
				if DoesEntityExist(spike) then
					local spikeCoords = GetEntityCoords(spike)
					local distance = #(vehCoords - spikeCoords)
					
					if distance < closestDistance and distance < 100.0 then
						closestSpike = spike
						closestDistance = distance
					end
				end
			end
        else
            closestSpike = nil
        end
		Wait(sleep) 
    end
end)

local tires = {
    {bone = "wheel_lf", index = 0},
    {bone = "wheel_rf", index = 1},
    {bone = "wheel_lm", index = 2},
    {bone = "wheel_rm", index = 3},
    {bone = "wheel_lr", index = 4},
    {bone = "wheel_rr", index = 5},
}

CreateThread(function()
    while true do
		local sleep = 500
        if closestSpike and cache.vehicle then
			sleep = 0
			
			if IsEntityTouchingEntity(cache.vehicle,closestSpike) then
				for k,v in pairs(tires) do
					local boneIndex = GetEntityBoneIndexByName(cache.vehicle, v.bone)
					if boneIndex ~= -1 then
						local wheelPos = GetWorldPositionOfEntityBone(cache.vehicle, boneIndex)
						if #(wheelPos - GetEntityCoords(closestSpike)) < 1.8 then
							if not IsVehicleTyreBurst(cache.vehicle, v.index, true) then
								SetVehicleTyreBurst(cache.vehicle, v.index, true, 1000.0)
							end
						end
					end
				end
			end
        end
		Wait(sleep)
    end
end)