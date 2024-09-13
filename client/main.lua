local config = require('shared.config')

iconHTML = function(source, classes, style)
    local styleAttr = style and string.format(' style="%s"', style) or ''
    return string.format('<img class="%s" src="%s"%s/>', classes, source, styleAttr)
end

faIconHTML = function(iconClass, style)
    local styleAttr = style and string.format(' style="%s"', style) or ''
    return string.format('<i class="%s icon"%s></i>', iconClass, styleAttr)
end

local vehicleParts = {
    bonnet = iconHTML('icons/boot.webp', 'icon'),
    boot = iconHTML('icons/boot.webp', 'icon', 'transform: scale(-1, 1)'),
    handle_dside_f = iconHTML('icons/door.webp', 'icon'),
    handle_dside_r = iconHTML('icons/door.webp', 'icon'),
    handle_pside_f = iconHTML('icons/door.webp', 'icon'),
    handle_pside_r = iconHTML('icons/door.webp', 'icon'),
    engine = faIconHTML('fas fa-cogs'),
    interiorLight = faIconHTML('far fa-lightbulb'),
    window_driver = faIconHTML('fas fa-sort'),
    window_passenger = faIconHTML('fas fa-sort'),
    window_rear_left = faIconHTML('fas fa-sort'),
    window_rear_right = faIconHTML('fas fa-sort'),
}

local vehicleSeats = {
    seat_dside_f = iconHTML('icons/seat.webp', 'icon'),
    seat_dside_r = iconHTML('icons/seat.webp', 'icon'),
    seat_pside_f = iconHTML('icons/seat.webp', 'icon'),
    seat_pside_r = iconHTML('icons/seat.webp', 'icon')
}

local windowBones = {
    window_driver = 'window_lf',
    window_passenger = 'window_rf',
    window_rear_left = 'window_lr',
    window_rear_right = 'window_rr'
}

local keyBind = config.keyBind
local nuiActive = false

getVehiclePartIcon = function(partName, isEngineRunning)
    local icon = vehicleParts[partName] or ''
    if partName:sub(1, 6) == 'window' then
        icon = '<span style="color: #FFFFFF;">' .. icon .. '</span>'
    elseif partName == 'engine' and isEngineRunning then
        icon = '<span style="color: #6FEEE7;">' .. icon .. '</span>'
    end
    return icon
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
            local vehicle = GetVehiclePedIsIn(cache.ped, false)
            if vehicle ~= 0 and IsPedInAnyVehicle(cache.ped, false) then
                local isEngineRunning = GetIsVehicleEngineRunning(vehicle)
                for partName, v in pairs(vehicleParts) do
                    local part = GetEntityBoneIndexByName(vehicle, partName)
                    if part ~= -1 then
                        local pos = GetWorldPositionOfEntityBone(vehicle, part)
                        if #(GetEntityCoords(vehicle) - pos) < 10 and GetEntityCoords(vehicle) ~= pos then
                            DisableMouse = true
                            drawHTML(pos, getVehiclePartIcon(partName, isEngineRunning), partName)
                        end
                    end
                end
                if isEngineRunning then
                    for partName, boneName in pairs(windowBones) do
                        local part = GetEntityBoneIndexByName(vehicle, boneName)
                        if part ~= -1 then
                            local pos = GetWorldPositionOfEntityBone(vehicle, part)
                            if pos then
                                drawHTML(pos, getVehiclePartIcon(partName, isEngineRunning), partName)
                            end
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
        local vehicle = GetVehiclePedIsIn(cache.ped, false)
        while nuiActive and vehicle ~= 0 do
            if IsPedInAnyVehicle(cache.ped, false) then
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
    if IsPedSittingInAnyVehicle(cache.ped) then
        if GetVehicleDoorAngleRatio(vehicle, part) > 0.0 then
            SetVehicleDoorShut(vehicle, part, false)
        else
            SetVehicleDoorOpen(vehicle, part, false)
        end
    end
end

toggleWindow = function(windowIndex)
    local vehicle = GetVehiclePedIsIn(cache.ped)
    if not IsPedSittingInAnyVehicle(cache.ped) then return end
    local windowBones = {0, 1, 2, 3 }
    if windowIndex >= 0 and windowIndex <= 3 then
        local windowBone = windowBones[windowIndex + 1]
        if windowBone then
            local windowState = IsVehicleWindowIntact(vehicle, windowBone)
            if windowState then
                RollDownWindow(vehicle, windowBone)
            else
                RollUpWindow(vehicle, windowBone)
            end
        end
    end
end

switchSeats = function(seatIndex)
    local vehicle = cache.vehicle
    if not vehicle then return end
    local currentSeat = GetPedInVehicleSeat(vehicle, -1)
    if currentSeat == seatIndex then return end
    local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6
    if vehicleSpeed < 1.0 then
        local isSeatOccupied = not IsVehicleSeatFree(vehicle, seatIndex)
        if not isSeatOccupied then
            SetPedConfigFlag(cache.ped, 184, true)
            SetPedIntoVehicle(cache.ped, vehicle, seatIndex)
        end
    end
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
    cb('devx32')
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
        vehicle = GetVehiclePedIsIn(cache.ped)
        if vehicle ~= 0 then
            isEngineRunning = GetIsVehicleEngineRunning(vehicle)
        else
            isEngineRunning = false
        end
        Wait(3)
    end
end)

RegisterNUICallback('VehicleMenu', handleVehicleMenu)

RegisterNetEvent('devx_vehiclemenu', function()
    if not nuiActive then
        nuiActive = true
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        showNUIMode()
    end
end)
