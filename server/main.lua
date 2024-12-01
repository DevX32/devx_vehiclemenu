RegisterServerEvent("devx_vehiclemenu:server:setstate", function(netId, value)
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	Entity(vehicle).state.indicate = value
	Entity(vehicle).state.interiorlight = value
end)