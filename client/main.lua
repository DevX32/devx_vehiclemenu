
local config = require('shared.config')
local defaultIconStyle = "outline:none; border:none; -webkit-user-select:none; user-select:none; width:1vw; height:2vh;"
local defaultFaIconStyle = "font-size:1.5vh;"

local function generateHTML(tag, classes, source, style, isIcon)
    local defaultStyle = isIcon and defaultIconStyle or defaultFaIconStyle
    local combinedStyle = style and (defaultStyle .. style) or defaultStyle
    local styleAttr = string.format('style="%s"', combinedStyle)
    if isIcon then
        return string.format('<img class="%s" src="%s" %s draggable="false"/>', classes, source, styleAttr)
    else
        return string.format('<i class="%s icon" %s></i>', classes, styleAttr)
    end
end

local vehicleParts = {
    bonnet = generateHTML('img', 'icon', 'icons/boot.webp', nil, true),
    boot = generateHTML('img', 'icon', 'icons/boot.webp', 'transform: scale(-1, 1)', true),
    handle_dside_f = generateHTML('img', 'icon', 'icons/door.webp', nil, true),
    handle_dside_r = generateHTML('img', 'icon', 'icons/door.webp', nil, true),
    handle_pside_f = generateHTML('img', 'icon', 'icons/door.webp', nil, true),
    handle_pside_r = generateHTML('img', 'icon', 'icons/door.webp', nil, true),
    engine = generateHTML('img', 'icon', 'icons/engine.webp', 'width:1.5vw; height:2.5vh;', true),
    interiorLight = generateHTML('i', 'far fa-lightbulb', nil, nil, false),
    window_driver = generateHTML('i', 'fas fa-sort', nil, nil, false),
    window_passenger = generateHTML('i', 'fas fa-sort', nil, nil, false),
    window_rear_left = generateHTML('i', 'fas fa-sort', nil, nil, false),
    window_rear_right = generateHTML('i', 'fas fa-sort', nil, nil, false),
}

local vehicleSeats = {
    seat_dside_f = generateHTML('img', 'icon', 'icons/seat.webp', nil, true),
    seat_dside_r = generateHTML('img', 'icon', 'icons/seat.webp', nil, true),
    seat_pside_f = generateHTML('img', 'icon', 'icons/seat.webp', nil, true),
    seat_pside_r = generateHTML('img', 'icon', 'icons/seat.webp', nil, true)
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

local speedConversionFactors = {
    kmph = 3.6,
    mph = 2.23694
}

local nuiActive = false
local seatsUI = false

local function getVehiclePartIcon(partName)
    local icon = vehicleParts[partName] or ''
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if partName == 'engine' then
        if GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then
            icon = ''
        end
    end
    return icon
end

local function drawHTML(coords, text, id)
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

local function showVehicleParts()
    while nuiActive and not seatsUI do
        local vehicle = GetVehiclePedIsIn(cache.ped, false)
        if vehicle ~= 0 and IsPedInAnyVehicle(cache.ped, false) then
            local isEngineRunning = GetIsVehicleEngineRunning(vehicle)
            local vehiclePos = GetEntityCoords(vehicle)
            for partName, _ in pairs(vehicleParts) do
                local part = GetEntityBoneIndexByName(vehicle, partName)
                if part ~= -1 then
                    local pos = GetWorldPositionOfEntityBone(vehicle, part)
                    if #(vehiclePos - pos) < 10 and vehiclePos ~= pos then
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
end

local function showSeats()
    SendNUIMessage({ action = 'close' })
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    while nuiActive and vehicle ~= 0 do
        if IsPedInAnyVehicle(cache.ped, false) then
            local vehiclePos = GetEntityCoords(vehicle)
            for k, v in pairs(vehicleSeats) do
                local part = GetEntityBoneIndexByName(vehicle, k)
                if part ~= -1 then
                    local pos = GetWorldPositionOfEntityBone(vehicle, part)
                    if #(vehiclePos - pos) < 10 and vehiclePos ~= pos then
                        local isSeatOccupied = not IsVehicleSeatFree(vehicle, seatIndexMap[k])
                        local seatIcon = isSeatOccupied and generateHTML('img', 'icon', 'icons/seat.webp', nil, true) or v
                        drawHTML(pos, seatIcon, k)
                    end
                end
            end
        else
            nuiActive = false
        end
        Wait(25)
    end
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

CreateThread(showVehicleParts)
CreateThread(showSeats)

local function closeVehicleDoor(part)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if GetVehicleDoorAngleRatio(vehicle, part) > 0.0 then
        SetVehicleDoorShut(vehicle, part, false)
    else
        SetVehicleDoorOpen(vehicle, part, false)
    end
end

local function toggleWindow(windowIndex)
    local vehicle = GetVehiclePedIsIn(cache.ped)
    if not vehicle then return end
    local netId = VehToNet(vehicle)
    local currentState = Entity(vehicle).state.windowStates or {}
    currentState[windowIndex] = not (currentState[windowIndex] or false)
    TriggerServerEvent("devx_vehiclemenu:server:setWindowState", netId, currentState)
end

local function getVehicleSpeed(vehicle)
    local vehicleSpeedMS = GetEntitySpeed(vehicle)
    return vehicleSpeedMS * speedConversionFactors[config.speedUnit]
end

local function switchSeats(seatKey)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not vehicle then return end
    local targetSeat = seatIndexMap[seatKey]
    local vehicleSpeed = getVehicleSpeed(vehicle)
    if vehicleSpeed < 1.0 then
        local isSeatOccupied = not IsVehicleSeatFree(vehicle, targetSeat)
        if not isSeatOccupied then
            SetPedConfigFlag(cache.ped, 184, true)
            SetPedIntoVehicle(cache.ped, vehicle, targetSeat)
            showSeats()
        end
    end
end

local function toggleEngine()
    local vehicle = GetVehiclePedIsIn(cache.ped)
    if not vehicle then return end
    local isRunning = GetIsVehicleEngineRunning(vehicle)
    exports['keys']:toggleEngine()
    SetVehicleEngineOn(vehicle, not isRunning, false, true)
end

local function isInteriorLightOn(vehicle)
    if not Entity(vehicle).state.interiorLight then return false end
    local state = Entity(vehicle).state.interiorLight
    return state == true
end

local function toggleInteriorLight()
    if not IsPedInAnyVehicle(cache.ped) then return false end
    local vehicle = GetVehiclePedIsIn(cache.ped)
    local netId = VehToNet(vehicle)
    local value = not isInteriorLightOn(vehicle)
    TriggerServerEvent('devx_vehiclemenu:server:setInteriorLightState', netId, value)
end

local function isIndicating(vehicle, type)
    if not Entity(vehicle).state.indicate then return false end
    local state = Entity(vehicle).state.indicate
    if state[1] and state[2] and type == "hazards" then return true end
    if state[1] and not state[2] and type == "right" then return true end
    if not state[1] and state[2] and type == "left" then return true end
    return false
end

local function indicate(type)
    if not IsPedInAnyVehicle(cache.ped) then return false end
    local vehicle = GetVehiclePedIsIn(cache.ped)
    local netId = VehToNet(vehicle)
    local value = {}
    if type == "left" and not isIndicating(vehicle, "left") then value = {false, true}
    elseif type == "right" and not isIndicating(vehicle, "right") then value = {true, false}
    elseif type == "hazards" and not isIndicating(vehicle, "hazards") then value = {true, true}
    else value = {false, false} end
    TriggerServerEvent("devx_vehiclemenu:server:setIndicatorState", netId, value)
end

local function toggleNui()
    nuiActive = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    showVehicleParts()
end

local function resetNui()
    nuiActive = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function disableControls()
    if nuiActive then
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
    else
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
    end
    DisableControlAction(0, 106, true)
end

local function handleSeatsUI()
    if IsControlJustPressed(0, 25) then
        seatsUI = true
        showSeats()
    elseif IsControlJustReleased(0, 25) then
        seatsUI = false
    end
end

AddStateBagChangeHandler("indicate", nil, function(bagName, key, data)
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 then return end
    for i, status in ipairs(data) do
      SetVehicleIndicatorLights(entity, i - 1, status)
    end
end)

AddStateBagChangeHandler('interiorLight', nil, function(bagName, key, data)
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 then return end
    SetVehicleInteriorlight(entity, data)
end)

AddStateBagChangeHandler('windowStates', nil, function(bagName, key, state)
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 then return end
    for windowIndex, isOpen in pairs(state) do
        if isOpen then
            RollDownWindow(entity, windowIndex)
        else
            RollUpWindow(entity, windowIndex)
        end
    end
end)

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

RegisterCommand('toggle_hazard_lights', function() indicate("hazards") end, false)
RegisterCommand('toggle_left_indicator', function() indicate("left") end, false)
RegisterCommand('toggle_right_indicator', function() indicate("right") end, false)
RegisterCommand('close_vehicle_menu', resetNui, false)

TriggerEvent('chat:removeSuggestion', 'toggle_hazard_lights')
TriggerEvent('chat:removeSuggestion', 'toggle_left_indicator')
TriggerEvent('chat:removeSuggestion', 'toggle_right_indicator')
TriggerEvent('chat:removeSuggestion', 'close_vehicle_menu')
TriggerEvent('chat:removeSuggestion', 'toggle_vehicle_menu')

RegisterNUICallback('VehicleMenu', function(data)
    local actions = {
        boot = function() closeVehicleDoor(5) end,
        handle_dside_f = function() closeVehicleDoor(0) end,
        handle_dside_r = function() closeVehicleDoor(2) end,
        handle_pside_f = function() closeVehicleDoor(1) end,
        handle_pside_r = function() closeVehicleDoor(3) end,
        bonnet = function() closeVehicleDoor(4) end,
        engine = function() toggleEngine() end,
        interiorLight = function() toggleInteriorLight() end,
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
end)

lib.onCache('vehicle', function(vehicle)
    local lastVehicle = nil
    while true do
        if vehicle ~= lastVehicle then
            lastVehicle = vehicle
            if vehicle ~= 0 then
                isEngineRunning = GetIsVehicleEngineRunning(vehicle)
            else
                isEngineRunning = false
            end
        end
        if nuiActive then
            if DisableMouse then
                disableControls()
            end
            handleSeatsUI()
            if IsControlJustPressed(0, 322) then
                resetNui()
            end
        end
        Wait(3)
    end
end)

RegisterNetEvent('devx_vehiclemenu:client:open', function()
    if not nuiActive then
        toggleNui()
    end
end)
