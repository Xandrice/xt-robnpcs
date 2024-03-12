local config = require 'configs.server'
local shared = require 'configs.shared'
local totalCops = 0

local function distanceCheck(player, target)
    local pCoords = GetEntityCoords(GetPlayerPed(player))
    local tCoords = GetEntityCoords(NetworkGetEntityFromNetworkId(target))
    local dist = #(tCoords - pCoords)

    return dist <= 5
end

-- Checks if Player is Police --
local function hasPoliceJob(src, jobs)
    local pJob = getPlayerJob(src)
    if type(jobs) == 'table' then
        for x = 1, #jobs do
            if jobs[x] == pJob then
                return true
            end
        end
    else
        return (pJob == jobs)
    end
end

-- Receive Cash --
local function receiveCashChance(src)
    local payChance = math.random(config.payOutChance.min, config.payOutChance.max)
    local randomChance = math.random(100)
    local callback = false

    if randomChance <= payChance then
        local pay = math.random(config.payOut.min, config.payOut.max)
        if config.addCash(src, pay) then
            callback = true
        end
    else
        lib.notify(src, { title = 'No Cash!', description = 'They didn\'t have any cash!', type = 'error' })
        callback = true
    end

    return callback
end

-- Receive Items --
local function receiveItemsChance(src)
    local itemChance = math.random(config.chanceItemsFound.min, config.chanceItemsFound.max)
    local randomChance = math.random(100)
    local callback = false

    if randomChance <= itemChance then
        local randomItem = math.random(#config.lootableItems)
        local randomAmount = math.random(config.lootableItems[randomItem].min, config.lootableItems[randomItem].max)
        if config.addItem(src, config.lootableItems[randomItem].item, randomAmount) then
            callback = true
        end
    end

    return callback
end

-- Get Paid (or not) & Set State --
lib.callback.register('xt-robnpcs:server:robNPC', function(source, netID)
    local src = source
    local dist = distanceCheck(source, netID)
    local callback = false
    if not dist then return callback end

    local entity = NetworkGetEntityFromNetworkId(netID)
    local state = Entity(entity).state

    if state then
        state:set('robbed', src, true)
        local payChance = math.random(config.payOutChance.min, config.payOutChance.max)
        local randomChance = math.random(100)
        if receiveCashChance(src) then
            receiveItemsChance(src)
            callback = true
        end
    end

    return callback
end)

-- Constantly Update Cop Count --
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if shared.requiredCops == 0 then return end

    SetInterval(function()
        local players = GetPlayers()
        local copCount = 0

        for _, src in pairs(players) do
            if hasPoliceJob(tonumber(src), config.policeJobs) then
                copCount += 1
            end
        end

        if totalCops ~= copCount then
            totalCops = copCount
            TriggerClientEvent('xt-robnpcs:client:setCopCount', -1, totalCops)
        end
    end, 60000)
end)