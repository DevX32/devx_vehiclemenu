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

local seatIndexMap = {
    seat_dside_f = -1,
    seat_pside_f = 0,
    seat_dside_r = 1,
    seat_pside_r = 2
}

local windowBones = {
    window_driver = 'window_lf',
    window_passenger = 'window_rf',
    window_rear_left = 'window_lr',
    window_rear_right = 'window_rr'
}

local colors = {
    default = '#FFFFFF',
    running = '#8685ef',
}

local nuiActive = false
local seatsUI = false

getVehiclePartIcon = function(partName, isEngineRunning)
    local icon = vehicleParts[partName] or ''
    local color = colors.default
    if partName == 'engine' and isEngineRunning then
        color = colors.running
    end
    return string.format('<span style="color: %s;">%s</span>', color, icon)
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
                for partName, _ in pairs(vehicleParts) do
                    local part = GetEntityBoneIndexByName(vehicle, partName)
                    if part ~= -1 then
                        local pos = GetWorldPositionOfEntityBone(vehicle, part)
                        if #(GetEntityCoords(vehicle) - pos) < 10 and GetEntityCoords(vehicle) ~= pos then
                            drawHTML(pos, getVehiclePartIcon(partName, isEngineRunning), partName)
                        end
                    end
                end
                if isEngineRunning then
                    for partName, boneName in pairs(windowBones) do
                        local part = GetEntityBoneIndexByName(vehicle, boneName)
                        if part ~= -1 then
                            local pos = GetWorldPositionOfEntityBone(vehicle, part)
                            drawHTML(pos, getVehiclePartIcon(partName, isEngineRunning), partName)
                        end
                    end
                end
            else
                nuiActive = false
            end
            Wait(25)
        end
        if not seatsUI then
            SetNuiFocus(false, false)
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
                        drawHTML(pos, v, k)
                    end
                end
            else
                nuiActive = false
            end
            Wait(25)
        end
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    end)
end

closeVehicleDoor = function(part)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if GetVehicleDoorAngleRatio(vehicle, part) > 0.0 then
        SetVehicleDoorShut(vehicle, part, false)
    else
        SetVehicleDoorOpen(vehicle, part, false)
    end
end

toggleWindow = function(windowIndex)
    local vehicle = GetVehiclePedIsIn(cache.ped)
    local windowState = IsVehicleWindowIntact(vehicle, windowIndex)
    if windowState then
        RollDownWindow(vehicle, windowIndex)
    else
        RollUpWindow(vehicle, windowIndex)
    end
end

switchSeats = function(seatKey)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then return end
    local targetSeat = seatIndexMap[seatKey]
    local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6
    if vehicleSpeed < 1.0 then
        local isSeatOccupied = not IsVehicleSeatFree(vehicle, targetSeat)
        if not isSeatOccupied then
            SetPedConfigFlag(cache.ped, 184, true)
            SetPedIntoVehicle(cache.ped, vehicle, targetSeat)
        end
    end
end

toggleEngine = function()
    local vehicle = GetVehiclePedIsIn(cache.ped)
    local isRunning = GetIsVehicleEngineRunning(vehicle)
    SetVehicleEngineOn(vehicle, not isRunning, false, true)
end

toggleInteriorLight = function()
    local vehicle = GetVehiclePedIsIn(cache.ped)
    local isLightOn = GetVehicleInteriorlight(vehicle)
    SetVehicleInteriorlight(vehicle, not isLightOn)
end

toggleHazardLights = function()
    local vehicle = GetVehiclePedIsIn(cache.ped)
    local hazardLightsActive = not IsVehicleIndicatorLightsOn(vehicle, 0) and not IsVehicleIndicatorLightsOn(vehicle, 1)
    SetVehicleIndicatorLights(vehicle, 0, hazardLightsActive)
    SetVehicleIndicatorLights(vehicle, 1, hazardLightsActive)
end

toggleIndicatorLights = function(indicatorType)
    local vehicle = GetVehiclePedIsIn(cache.ped)
    if indicatorType == 0 then
        SetVehicleIndicatorLights(vehicle, 0, not IsVehicleIndicatorLightsOn(vehicle, 0))
    elseif indicatorType == 1 then
        SetVehicleIndicatorLights(vehicle, 1, not IsVehicleIndicatorLightsOn(vehicle, 1))
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
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterKeyMapping('toggle_vehicle_menu', 'Toggle Vehicle Menu', 'keyboard', config.keyBind)
RegisterKeyMapping('toggle_hazard_lights', 'Toggle Hazard Lights', 'keyboard', 'UP')
RegisterKeyMapping('toggle_left_indicator', 'Toggle Left Indicator', 'keyboard', 'LEFT')
RegisterKeyMapping('toggle_right_indicator', 'Toggle Right Indicator', 'keyboard', 'RIGHT')
RegisterKeyMapping('close_vehicle_menu', 'Close Vehicle Menu', 'keyboard', 'BACK')

RegisterCommand('toggle_vehicle_menu', function()
    if nuiActive then
        resetNui()
    else
        toggleNui()
    end
end, false)

RegisterCommand('toggle_hazard_lights', toggleHazardLights, false)
RegisterCommand('toggle_left_indicator', function() toggleIndicatorLights(0) end, false)
RegisterCommand('toggle_right_indicator', function() toggleIndicatorLights(1) end, false)
RegisterCommand('close_vehicle_menu', resetNui, false)

TriggerEvent('chat:removeSuggestion', 'toggle_hazard_lights')
TriggerEvent('chat:removeSuggestion', 'toggle_left_indicator')
TriggerEvent('chat:removeSuggestion', 'toggle_right_indicator')
TriggerEvent('chat:removeSuggestion', 'close_vehicle_menu')
TriggerEvent('chat:removeSuggestion', 'toggle_vehicle_menu')

disableControls = function()
    if nuiActive then
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
    else
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
    end
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
        seat_dside_f = function() switchSeats('seat_dside_f') end,
        seat_dside_r = function() switchSeats('seat_dside_r') end,
        seat_pside_f = function() switchSeats('seat_pside_f') end,
        seat_pside_r = function() switchSeats('seat_pside_r') end,
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
        local vehicle = GetVehiclePedIsIn(cache.ped)
        if DisableMouse then
            disableControls()
        end
        if nuiActive then
            handleSeatsUI()
        end
        handleControls()
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
        toggleNui()
    end
end)
