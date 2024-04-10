local Configuration = require('shared.config')

iconHTML = function(source, classes)
    return string.format('<img class="%s" src="%s"/>', classes, source)
end

faIconHTML = function(iconClass)
    return string.format('<i class="%s icon"></i>', iconClass)
end

local vehicleParts = {
    bonnet = faIconHTML('fas fa-car'),
    boot = iconHTML('icons/boot.png', 'icon'),
    handle_dside_f = iconHTML('icons/door.png', 'icon'),
    handle_dside_r = iconHTML('icons/door.png', 'icon'),
    handle_pside_f = iconHTML('icons/door.png', 'icon'),
    handle_pside_r = iconHTML('icons/door.png', 'icon'),
    engine = faIconHTML('fas fa-cogs'),
    interiorLight = faIconHTML('far fa-lightbulb'),
    window_driver = faIconHTML('fas fa-car-side'),
    window_passenger = faIconHTML('fas fa-car-side'),
    window_rear_left = faIconHTML('fas fa-car-side'),
    window_rear_right = faIconHTML('fas fa-car-side'),
}

local vehicleSeats = {
    seat_dside_f = iconHTML('icons/seat.png', 'icon'),
    seat_dside_r = iconHTML('icons/seat.png', 'icon'),
    seat_pside_f = iconHTML('icons/seat.png', 'icon'),
    seat_pside_r = iconHTML('icons/seat.png', 'icon')
}

local windowBones = {
    GetEntityBoneIndexByName(vehicle, 'window_lf'),
    GetEntityBoneIndexByName(vehicle, 'window_rf'),
    GetEntityBoneIndexByName(vehicle, 'window_lr'),
    GetEntityBoneIndexByName(vehicle, 'window_rr')
}

local keyBind = Configuration.keyBind
local nuiActive = false

getVehiclePartIcon = function(partName)
    return vehicleParts[partName] or ""
end

drawHTML = function(coords, text, id)
    local show, x, y = GetHudScreenPositionFromWorldPosition(coords.x, coords.y, coords.z + 0.35)
    if not show then
        SendNUIMessage({
            action = "show",
            html = text,
            id = id,
            position = { x, y }
        })
    end
end

showNUIMode = function()
    CreateThread(function()
        while nuiActive and not seatsUI do
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle ~= 0 and IsPedInAnyVehicle(PlayerPedId(), false) then
                local isEngineRunning = GetIsVehicleEngineRunning(vehicle)
                for k, v in pairs(vehicleParts) do
                    local part = GetEntityBoneIndexByName(vehicle, k)
                    if part ~= -1 then
                        local pos = GetWorldPositionOfEntityBone(vehicle, part)
                        if #(GetEntityCoords(vehicle) - pos) < 10 and GetEntityCoords(vehicle) ~= pos then
                            DisableMouse = true
                            drawHTML(pos, getVehiclePartIcon(k), k)
                        end
                    end
                end
                if isEngineRunning then
                    for windowIndex = 1, 4 do
                        local windowPos = GetWorldPositionOfEntityBone(vehicle, windowBones[windowIndex])
                        if windowPos then
                            drawHTML(windowPos, getVehiclePartIcon('window_' .. windowIndex), 'window_' .. windowIndex)
                        end
                    end
                end
            else
                DisableMouse = false
                nuiActive = false
            end
            Wait(25)
        end
        if not seatsUI then
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            SendNUIMessage({ action = 'close' })
        end
    end)
end

showSeatsUI = function()
    SendNUIMessage({ action = 'close' })
    CreateThread(function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        while nuiActive and vehicle ~= 0 do
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                for k, v in pairs(vehicleSeats) do
                    local part = GetEntityBoneIndexByName(vehicle, k)
                    local pos = GetWorldPositionOfEntityBone(vehicle, part)
                    if part ~= -1 and #(GetEntityCoords(vehicle) - pos) < 10 and GetEntityCoords(vehicle) ~= pos then
                        DisableMouse = true
                        drawHTML(pos, v, k)
                    end
                end
            else
                DisableMouse = false
                nuiActive = false
            end
            Wait(25)
        end
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'close' })
    end)
end

closeVehicleDoor = function(part)
    if IsPedSittingInAnyVehicle(PlayerPedId()) then
        if GetVehicleDoorAngleRatio(vehicle, part) > 0.0 then
            SetVehicleDoorShut(vehicle, part, false)
            PlaySoundFrontend(-1, 'CLOSED', 'MP_RADIO_SFX', false)
        else
            SetVehicleDoorOpen(vehicle, part, false)
            PlaySoundFrontend(-1, 'OPENED', 'MP_RADIO_SFX', false)
        end
    end
end

toggleWindow = function(windowIndex)
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    if IsPedSittingInAnyVehicle(PlayerPedId()) then
        local windowBone = windowBones[windowIndex + 1]
        if windowBone then
            local windowState = IsVehicleWindowIntact(vehicle, windowBone)
            if windowState then
                RollDownWindow(vehicle, windowBone)
                PlaySoundFrontend(-1, 'WINDOW_ROLL_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
            else
                RollUpWindow(vehicle, windowBone)
                PlaySoundFrontend(-1, 'WINDOW_ROLL_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
            end
        end
    end
end

switchSeats = function(seatIndex)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6
    local isSeatOccupied = not IsVehicleSeatFree(vehicle, seatIndex)
    if vehicleSpeed > 100.0 or isSeatOccupied then return end
    SetPedIntoVehicle(PlayerPedId(), vehicle, seatIndex)
end

toggleEngine = function()
    active = not active
    SetVehicleEngineOn(vehicle, active, false, true)
end

toggleInteriorLight = function()
    active = not active
    SetVehicleInteriorlight(vehicle, active)
    PlaySoundFrontend(-1, 'Toggle_Lights', 'PI_Menu_Sounds', false)
end

toggleHazardLights = function()
    hazardLightsActive = not hazardLightsActive
    SetVehicleIndicatorLights(vehicle, 0, hazardLightsActive)
    SetVehicleIndicatorLights(vehicle, 1, hazardLightsActive)
    if hazardLightsActive then
        PlaySoundFrontend(-1, 'Indicator', 'HUD_LIghts_Indicator', false)
    else
        StopSound(-1, 'Indicator')
    end
end

toggleIndicatorLights = function(indicatorType)
    if indicatorType == 0 then
        leftIndicatorActive = not leftIndicatorActive
        SetVehicleIndicatorLights(vehicle, 0, leftIndicatorActive)
        if leftIndicatorActive then
            rightIndicatorActive = false
            PlaySoundFrontend(-1, 'Indicator', 'HUD_LIghts_Indicator', false)
        else
            StopSound(-1, 'Indicator')
        end
    elseif indicatorType == 1 then
        rightIndicatorActive = not rightIndicatorActive
        SetVehicleIndicatorLights(vehicle, 1, rightIndicatorActive)
        if rightIndicatorActive then
            leftIndicatorActive = false
            PlaySoundFrontend(-1, 'Indicator', 'HUD_LIghts_Indicator', false)
        else
            StopSound(-1, 'Indicator')
        end
    end
end

toggleHandbrake = function()
    handbrakeEngaged = not handbrakeEngaged
    SetVehicleHandbrake(vehicle, handbrakeEngaged)
end

toggleNui = function()
    nuiActive = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    showNUIMode()
end

resetNui = function()
    nuiActive = false
    DisableMouse = false
    showNUIMode()
end

disableControls = function()
    DisableControlAction(0, 1, true)
    DisableControlAction(0, 2, true)
    DisableControlAction(0, 106, true)
end

handleSeatsUI = function()
    if IsControlJustPressed(0, 25) then
        seatsUI = true
        showSeatsUI()
    elseif IsControlJustReleased(0, 25) then
        seatsUI = false
    end
end

handleControls = function()
    if IsControlJustPressed(0, 172) then
        toggleHazardLights()
    elseif IsControlJustPressed(0, 175) then
        toggleIndicatorLights(0)
    elseif IsControlJustPressed(0, 174) then
        toggleIndicatorLights(1)
    elseif IsControlPressed(0, 173) then
        toggleHandbrake()
    elseif IsControlJustPressed(0, 322) and nuiActive then
        resetNui()
    elseif IsControlJustPressed(0, 25) then
        if nuiActive then
            seatsUI = true
            showSeatsUI()
        end
    end
end

handleVehicleMenu = function(data, cb)
    local actions = {
        boot = function() closeVehicleDoor(5) end,
        handle_dside_f = function() closeVehicleDoor(0) end,
        handle_dside_r = function() closeVehicleDoor(2) end,
        handle_pside_f = function() closeVehicleDoor(1) end,
        handle_pside_r = function() closeVehicleDoor(3) end,
        bonnet = function() closeVehicleDoor(4) end,
        engine = toggleEngine,
        interiorLight = toggleInteriorLight,
        seat_dside_f = function() switchSeats(-1) end,
        seat_dside_r = function() switchSeats(1) end,
        seat_pside_f = function() switchSeats(0) end,
        seat_pside_r = function() switchSeats(2) end,
        window_driver = function() toggleWindow(0) end,
        window_passenger = function() toggleWindow(1) end,
        window_rear_left = function() toggleWindow(2) end,
        window_rear_right = function() toggleWindow(3) end,
    }
    local action = actions[data.id]
    if action then
        action()
    end
    cb('ok')
end

CreateThread(function()
    while true do
        if IsControlJustPressed(0, keyBind) then
            toggleNui()
        end
        if IsControlJustReleased(0, keyBind) then
            resetNui()
        end
        if DisableMouse then
            disableControls()
        end
        if nuiActive then
            handleSeatsUI()
        end
        handleControls()
        Wait(3)
    end
end)

CreateThread(function()
    while true do
        vehicle = GetVehiclePedIsIn(PlayerPedId())
        isEngineRunning = GetIsVehicleEngineRunning(vehicle)
        Wait(500)
    end
end)

RegisterNUICallback('VehicleMenu', handleVehicleMenu)

RegisterNetEvent('devx_vehiclemenu')
AddEventHandler('devx_vehiclemenu', function()
    if not nuiActive then
        nuiActive = true
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        showNUIMode()
    end
end)
