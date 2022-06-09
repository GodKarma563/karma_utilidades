ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
  TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
  Citizen.Wait(0)
    end
end)

-- TIRARSE AL SUELO 

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		if IsControlPressed(2, 303) then
			ragdol = 1 end
			if ragdol == 1 then
		SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
		TriggerEvent('esx:showNotification', "Pulsa Y para levantarte", "ERROR")
		Citizen.Wait(10000)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsControlPressed(2, 246) then
			ragdol = 0 end
			if ragdol == 1 then
		SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
		end
	end
end)

-- AGACHARSE

local agacharse = false
Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(1)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then 
            DisableControlAction(0,36,true)  
            if not IsPauseMenuActive() then 
                if IsDisabledControlJustPressed(0,36) then 
                    RequestAnimSet("move_ped_crouched")
                    RequestAnimSet("move_ped_crouched_strafing")
                    if agacharse == true then 
                        ResetPedMovementClipset(ped,0.55)
                        ResetPedStrafeClipset(ped)
                        agacharse = false 
                    elseif agacharse == false then
                        SetPedMovementClipset(ped,"move_ped_crouched",0.55)
                        SetPedStrafeClipset(ped,"move_ped_crouched_strafing")
                        agacharse = true 
                    end 
                end
            end 
        end 
    end
end)

-- APUNTAR CON LA MANO

local mp_pointing = false
local keyPressed = false

local function startPointing()
    local ped = PlayerPedId()
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end

local function stopPointing()
    local ped = PlayerPedId()
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

local once = true
local oldval = false
local oldvalped = false

Citizen.CreateThread(function()
    while true do
        Wait(0)

        if once then
            once = false
        end

        if not keyPressed then
            if IsControlPressed(0, 29) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
                Wait(200)
                if not IsControlPressed(0, 29) then
                    keyPressed = true
                    startPointing()
                    mp_pointing = true
                else
                    keyPressed = true
                    while IsControlPressed(0, 29) do
                        Wait(50)
                    end
                end
            elseif (IsControlPressed(0, 29) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                keyPressed = true
                mp_pointing = false
                stopPointing()
            end
        end

        if keyPressed then
            if not IsControlPressed(0, 29) then
                keyPressed = false
            end
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) and not mp_pointing then
            stopPointing()
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
            if not IsPedOnFoot(PlayerPedId()) then
                stopPointing()
            else
                local ped = PlayerPedId()
                local camPitch = GetGameplayCamRelativePitch()
                if camPitch < -70.0 then
                    camPitch = -70.0
                elseif camPitch > 42.0 then
                    camPitch = 42.0
                end
                camPitch = (camPitch + 70.0) / 112.0

                local camHeading = GetGameplayCamRelativeHeading()
                local cosCamHeading = Cos(camHeading)
                local sinCamHeading = Sin(camHeading)
                if camHeading < -180.0 then
                    camHeading = -180.0
                elseif camHeading > 180.0 then
                    camHeading = 180.0
                end
                camHeading = (camHeading + 180.0) / 360.0

                local blocked = 0
                local nn = 0

                local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                nn,blocked,coords,coords = GetRaycastResult(ray)

                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)

            end
        end
    end
end)

-- CAMINAR HERIDO

local hurt = false
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if GetEntityHealth(PlayerPedId()) <= 159 then
            setHurt()
        elseif hurt and GetEntityHealth(PlayerPedId()) > 160 then
            setNotHurt()
        end
    end
end)

function setHurt()
    hurt = true
    RequestAnimSet("move_m@injured")
    SetPedMovementClipset(PlayerPedId(), "move_m@injured", true)
end

function setNotHurt()
    hurt = false
    ResetPedMovementClipset(PlayerPedId())
    ResetPedWeaponMovementClipset(PlayerPedId())
    ResetPedStrafeClipset(PlayerPedId())
end

-- LEVANTAR BRAZOS

local handsup = false
local cabeca = false

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		local ped = PlayerPedId()
		DisableControlAction(0, 36, true)
		if not IsPedInAnyVehicle(ped) then
			RequestAnimSet("move_ped_crouched")
			RequestAnimSet("move_ped_crouched_strafing")
			if IsControlJustPressed(1, 323) then
				local dict = "missminuteman_1ig_2"
				RequestAnimDict(dict)
				while not HasAnimDictLoaded(dict) do
					Citizen.Wait(100)
				end

				if handsup == false then
					ClearPedTasks(PlayerPedId())
					TaskPlayAnim(PlayerPedId(), dict, "handsup_enter", 8.0, 8.0, -1, 50, 0, false, false, false)
					handsup = true
					TriggerServerEvent("tac_thief:update", handsup)
				elseif cabeca == false then
					while not HasAnimDictLoaded("random@arrests@busted") do
						RequestAnimDict("random@arrests@busted")
						Citizen.Wait(5)
					end
				cabeca = true
				TaskPlayAnim(PlayerPedId(), "random@arrests@busted", "idle_c", 8.0, 8.0, -1, 50, 0, false, false, false)
				else
					cabeca = false
					handsup = false
					TriggerServerEvent("tac_thief:update", handsup)
					ClearPedTasks(PlayerPedId())
				end
			end
		end
	end
end)

-- CRUZAR LOS BRAZOS

Citizen.CreateThread(function()
    local dict = "amb@world_human_hang_out_street@female_arms_crossed@base"
    
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(100)
	end
    local handsup = false
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(1, 47) then --Start holding g
            if not handsup then
                TaskPlayAnim(PlayerPedId(), dict, "base", 8.0, 8.0, -1, 50, 0, false, false, false)
                handsup = true
            else
                handsup = false
                ClearPedTasks(PlayerPedId())
            end
        end
    end
end)

-- Quitar NPCs ---

DensityMultiplier = 0.5
Citizen.CreateThread(function()
	while true do
	    Citizen.Wait(0)
	    SetVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetPedDensityMultiplierThisFrame(DensityMultiplier)
	    SetRandomVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetParkedVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetScenarioPedDensityMultiplierThisFrame(DensityMultiplier, DensityMultiplier)
	end
end)

-- Quitar NPCs Policiales --

Citizen.CreateThread(function()
    while true do
    Citizen.Wait(0)
    local playerPed = PlayerPedId()
    local playerLocalisation = GetEntityCoords(playerPed)
    ClearAreaOfCops(playerLocalisation.x, playerLocalisation.y, playerLocalisation.z, 500.0)
    end
    end)

-- NPCs No dropean armas --

function SetWeaponDrops()
    local handle, ped = FindFirstPed()
    local finished = false 

    repeat 
        if not IsEntityDead(ped) then
            SetPedDropsWeaponsWhenDead(ped, false) 
        end
        finished, ped = FindNextPed(handle)
    until not finished

    EndFindPed(handle)
end

Citizen.CreateThread(function()
    while true do
        SetWeaponDrops()
        Citizen.Wait(500)
    end
end)


-- NPC NO DISPARAN y ELIMINACIÓN DE ARMAS A NPC --

Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)
      RemoveAllPickupsOfType(0xDF711959)
      RemoveAllPickupsOfType(0xF9AFB48F)
      RemoveAllPickupsOfType(0xA9355DCD)
    end
  end)

  local relationshipTypes = {
	'GANG_1',
	'GANG_2',
	'GANG_9',
	'GANG_10',
	'AMBIENT_GANG_LOST',
	'AMBIENT_GANG_MEXICAN',
	'AMBIENT_GANG_FAMILY',
	'AMBIENT_GANG_BALLAS',
	'AMBIENT_GANG_MARABUNTE',
	'AMBIENT_GANG_CULT',
	'AMBIENT_GANG_SALVA',
	'AMBIENT_GANG_WEICHENG',
	'AMBIENT_GANG_HILLBILLY',
	'DEALER',
	'COP',
	'PRIVATE_SECURITY',
	'SECURITY_GUARD',
	'ARMY',
	'MEDIC',
	'FIREMAN',
	'HATES_PLAYER',
	'NO_RELATIONSHIP',
	'SPECIAL',
	'MISSION2',
	'MISSION3',
	'MISSION4',
	'MISSION5',
	'MISSION6',
	'MISSION7',
	'MISSION8'
}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5000)

		for _, group in ipairs(relationshipTypes) do
			SetRelationshipBetweenGroups(1, GetHashKey('PLAYER'), GetHashKey(group)) -- could be removed
			SetRelationshipBetweenGroups(1, GetHashKey(group), GetHashKey('PLAYER'))
		end
	end
end)
  
-- QUITAR ARMAS VEHÍCULOS POLICIALES --

Citizen.CreateThread(function()

	local id = PlayerId()
	
	while true do
	
		Citizen.Wait(1)
	
		DisablePlayerVehicleRewards(id)
	
	end
	end)


-- DESACTIVAR "Q"

Citizen.CreateThread(function()
    while false do
      s = 1000
      if not IsPauseMenuActive() then
        s = 5
        DisableControlAction(0,44,true)
      else
        s = 100
      end
      Citizen.Wait(s)
    end
  end)
  
  RegisterCommand('QU',
    function()
      DisableControlAction(0,44,true)
    end
  )

  --- NO CULATAZOS
  
Citizen.CreateThread(function()
  local pausa1 = 500
  while true do
    Citizen.Wait(pausa1)

    pausa1 = 500

    local ped = PlayerPedId()

    if IsPedArmed(ped, 6) then
      pausa1 = 0
      DisableControlAction(1, 140, true)
      DisableControlAction(1, 141, true)
      DisableControlAction(1, 142, true)
    end

    if oculto then
      pausa1 = 0
      DisableControlAction(0, 37, true)
      DisableControlAction(0, 157, true)
      DisableControlAction(0, 158, true)
    end
    
  end
end)
  
  RegisterKeyMapping('QU','','keyboard','Q')