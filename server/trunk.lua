local trunkBusy = {}

RegisterNetEvent('radialmenu:trunk:server:Door', function(open, plate, door)
    TriggerClientEvent('radialmenu:trunk:client:Door', -1, plate, door, open)
end)

RegisterNetEvent('trunk:server:setTrunkBusy', function(plate, busy)
    trunkBusy[plate] = busy
end)

RegisterNetEvent('trunk:server:KidnapTrunk', function(targetId, closestVehicle)
    TriggerClientEvent('trunk:client:KidnapGetIn', targetId, closestVehicle)
end)

ESX.RegisterServerCallback('trunk:server:getTrunkBusy', function(_, cb, plate)
    if trunkBusy[plate] then cb(true) return end
    cb(false)
end)

lib.addCommand('getintrunk', {
    help = Translations[Config.Local].general.getintrunk_command_desc,
}, function(source, args, raw)
    TriggerClientEvent('trunk:client:GetIn', source)
end)

lib.addCommand('putintrunk', {
    help = Translations[Config.Local].general.putintrunk_command_desc,
}, function(source, args, raw)
    TriggerClientEvent('trunk:server:KidnapTrunk', source)
end)