RegisterServerEvent("devx_vehiclemenu:server:setIndicatorState", function(netId, value)
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	if DoesEntityExist(vehicle) then
		Entity(vehicle).state.indicate = value
	end
end)

RegisterServerEvent("devx_vehiclemenu:server:setInteriorLightState", function(netId, value)
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	if DoesEntityExist(vehicle) then
		Entity(vehicle).state.interiorLight = value
	end
end)

RegisterNetEvent("devx_vehiclemenu:server:setWindowState", function(netId, windowStates)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
	if DoesEntityExist(vehicle) then
        Entity(vehicle).state.windowStates = windowStates
    end
end)