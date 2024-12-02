RegisterServerEvent("devx_vehiclemenu:server:setstate", function(netId, value)
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	Entity(vehicle).state.indicate = value
end)

RegisterServerEvent("devx_vehiclemenu:server:setInteriorLightState", function(netId, value)
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	Entity(vehicle).state.interiorLight = value
end)