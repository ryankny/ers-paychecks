local wageCache = {} -- Performance enhancement to cache player wage rates to save fetching them each time

if not Config.CacheRefreshInterval then
    Config.CacheRefreshInterval = 3600000  -- Default to 1 hour if not set
end

-- Function to clear old wage rate cache entries
local function ClearOldCacheEntries()
    for playerSrc, _ in pairs(wageCache) do
        -- Check if the player is still connected, if not, clear their cache
        if not GetPlayerPing(playerSrc) then  -- GetPlayerPing returns nil if player is not online
            wageCache[playerSrc] = nil
        end
    end
end

-- Thread to clear the wage rate cache every hour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.CacheRefreshInterval)  -- 1 hour in milliseconds
        ClearOldCacheEntries()
    end
end)

-- Function to check if the player is part of any defined Discord Role
local function PlayerHasDiscordRole(src)
    local rolesForCheck = {}
    for _, role in ipairs(Config.DiscordRoles) do
        table.insert(rolesForCheck, role.DiscordRoleName)
    end
    return exports.night_discordapi:IsMemberPartOfAnyOfTheseRoles(src, rolesForCheck)
end

-- Function to get the FiveM identifier for a player
local function GetFiveMIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, string.len("fivem:")) == "fivem:" then
            return id
        end
    end
    return nil -- Return nil if no player FiveM identifier is found (huh?)
end

-- Function to calculate the players specific wage per minute depending on their role
-- and choosing the specific wage that is the highest in value if the user has more
-- than one role
local function GetWagePerMinute(src)
    if wageCache[src] then
        return wageCache[src]  -- Return cached value if available
    end

    local playerRoles = exports.night_discordapi:GetDiscordMemberRoles(src)
    local wagePerMinute = 0 -- Default wage per minute

    if playerRoles then
        for _, roleConfig in ipairs(Config.DiscordRoles) do
            -- Check if the role is in the player's roles array
            for _, playerRole in ipairs(playerRoles) do
                if playerRole == roleConfig.DiscordRoleName then
                    -- Update wagePerMinute with the highest pay rate
                    wagePerMinute = math.max(wagePerMinute, roleConfig.PayratePerMinute)
                    if Config.Debug then
                        print("[INFO] Wage per minute for player " .. src .. " updated to " .. Config.PaymentCurrency .. wagePerMinute .. " for role " .. roleConfig.DiscordRoleName)
                    end
                end
            end
        end
    else
        if Config.Debug then
            print("[ERROR] Failed to retrieve Discord roles for player with source " .. src)
        end
    end

    -- Cache the result
    wageCache[src] = wagePerMinute
    return wagePerMinute
end

-- Function to delete shift records from database
local function DeleteShiftRecord(src, playerId, startTime)
    exports['oxmysql']:execute('DELETE FROM ers_shift_times WHERE player_id = @playerID AND start_time = @startTime', {
        ['@playerID'] = playerId, 
        ['@startTime'] = startTime
    }, function(result)
        if result then
            print('[INFO] ' .. playerId .. ' ERS paycheck shift record deleted.')
        else
            print('[ERROR] Failed to delete ERS paycheck shift record for player ' .. playerId)
        end
    end)
end

-- Function to update shift records in database if you want to persist shift data
local function UpdateShiftRecord(src, playerId, startTime, endTime, payment, wagePerMinute, minutesWorked)
    exports['oxmysql']:execute('UPDATE ers_shift_times SET end_time = @endTime, payment = @payment, rate_per_minute = @wagePerMinute, shift_duration = @minutesWorked WHERE player_id = @playerID AND start_time = @startTime', {
        ['@playerID'] = playerId, 
        ['@startTime'] = startTime,
        ['@endTime'] = endTime,
        ['@payment'] = payment,
        ['@wagePerMinute'] = wagePerMinute,
        ['@minutesWorked'] = minutesWorked,
    }, function(result)
        if result then
            print('[INFO] ' .. playerId .. ' ERS paycheck shift record updated.')
        else
            print('[ERROR] Failed to update ERS paycheck shift record for player ' .. playerId)
        end
    end)
end

-- Function to pay the player for the shift they have just ended
local function PayPlayerForShift(src, payment, minutesWorked)
    if Config.Framework == "QB" then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(src)

        player.Functions.AddMoney('bank', payment, 'Paycheck') -- Feel free to change the reason i.e. ("Police Pay")
    elseif Config.Framework == "ESX" then
        local ESX = exports["es_extended"]:getSharedObject()
        local player = ESX.GetPlayerFromId(src)

        player.addAccountMoney('bank', payment) -- No reason needed
    elseif Config.Framework == "Standalone" then
        -- Implement your own standalone payment system here or simply have it as a nice to have feature
        -- without all of the payment mechanics.
    end

    -- Show notification to player to let them know how much they've earned
    TriggerClientEvent('chatMessage', src, "State of San Andreas", "success", "You've been paid " .. Config.PaymentCurrency .. payment .. " for your shift (" .. minutesWorked .. " mins)")
end

-- Triggers when the player starts their shift within ERS
RegisterServerEvent('ers-paychecks:startingShift')
AddEventHandler('ers-paychecks:startingShift', function()
	local src = source
    local playerId = GetFiveMIdentifier(src)

    if PlayerHasDiscordRole(src) then
        if playerId then
            -- Add a new shift to track
            StartTrackingPlayerShift(src, playerId)
        else
            if Config.Debug then
                -- Unable to obtain the player's FiveM identifier... this shouldn't be possible
                print('[ERROR] Unable to obtain player FiveM identifier')
            end
        end
    else
        if Config.Debug then
            -- Player isn't in any Discord Role defined in the config, don't notify them and print to console
            print('[WARN] Player with source ' .. src .. ' is not in any defined Discord role. Check the config file if you think this is a mistake')
        end
    end
end)

-- Trigged when a player disconnects from the server, proactively checking to see if they didn't end their shift before leaving
AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerId = GetFiveMIdentifier(src)
    local endTime = os.time() -- Shift end time (time of disconnect)

    if Config.Debug then
        print('[INFO] Player ' .. playerId .. ' disconnected, checking to see if there is unprocessed shift')
    end

    -- Process the player shift as normal if exists with the end time on disconnect
    ProcessPlayerShiftPaycheck(src, playerId, endTime)

    -- Clear the player's cache data
    wageCache[src] = nil
end)

RegisterServerEvent('ers-paychecks:endingShift')
AddEventHandler('ers-paychecks:endingShift', function()
    local src = source
	local playerId = GetFiveMIdentifier(src)
	
	if playerId then
        ProcessPlayerShiftPaycheck(src, playerId)
    else
        if Config.Debug then
            -- Unable to obtain the player's FiveM identifier... this shouldn't be possible
            print('[ERROR] Unable to obtain player FiveM identifier')
        end
	end
end)

-- Function to insert a record into the ers_shift_times table to start tracking player shift times
local function StartTrackingPlayerShift(src, playerId)
    local startTime = os.time() -- Shift start time

    exports['oxmysql']:execute('INSERT INTO ers_shift_times (player_id, start_time) VALUES (@playerID, @startTime)', 
    {
        ['@playerID'] = playerId, 
        ['@startTime'] = startTime
    }, 
    function(result)
        -- Notify the player of the result
        if result then
            if Config.Debug then
                print('[INFO] ' .. playerId .. ' has started their shift at ' .. os.date("%c", startTime) .. ' and this is now being tracked for their paycheck')
            end
            
            -- Feel free to edit this and add your own notification alert for the player
            TriggerClientEvent('chatMessage', src, "State of San Andreas", "success", "You'll be paid when you end your shift")
        else
            if Config.Debug then
                print('[ERROR] Failed to start shift for player ' .. playerId)
            end

            -- Feel free to edit this and add your own notification alert for the player
            TriggerClientEvent('chatMessage', src, "State of San Andreas", "error", "Unable to log your shift time for payment. Please contact an admin")
        end
    end)
end

-- Function to calculate and process the specific players paycheck
local function ProcessPlayerShiftPaycheck(src, playerId, endTime)
    local endTime = endTime or os.time() -- Shift end time
    local wagePerMinute = GetWagePerMinute(src) -- Calculate wage per minute based on Discord role

    exports['oxmysql']:execute('SELECT start_time FROM ers_shift_times WHERE player_id = @playerID AND payment IS NULL ORDER BY start_time DESC LIMIT 1', {
        ['@playerID'] = playerId
    }, function(result)
        if result[1] then
            local startTime = result[1].start_time
            local shiftDuration = endTime - startTime
            local minutesWorked = math.floor(shiftDuration / 60)
            local payment = minutesWorked * wagePerMinute

            if payment > 0 then
                PayPlayerForShift(src, payment, minutesWorked)
            
                -- Here is an example of also adding transaction data to your banking system (whichever one you use)
                -- this is optional of course
                --TriggerEvent('okokBanking:AddTransferTransactionFromSocietyToP', payment, "GOV", "State of San Andreas", playerId, player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname)
                --TriggerClientEvent('okokBanking:updateTransactions', src, player.PlayerData.money.bank, player.PlayerData.money.cash)
            end

            print('[INFO] Shift ended for player ' .. playerId .. '. Paid: ' .. Config.PaymentCurrency .. payment .. '.')

            if Config.Debug then
                print('[INFO] Rate: ' .. Config.PaymentCurrency .. wagePerMinute .. ' per minute')
                print('[INFO] Minutes Worked: ' .. minutesWorked .. ' minutes')
            end

            if Config.DeleteRecordOnEndShift then
                -- Delete this shift record to *clean up* DB table
                DeleteShiftRecord(src, playerId, startTime)
            else
                -- If you want to persist shift records (I may add NUI in the future or some way of viewing these)
                -- It would be really cool if Night decided to integrate this into the MDT to see all of your shifts!
                UpdateShiftRecord(src, playerId, startTime, endTime, payment, wagePerMinute, minutesWorked)
            end
        else
            print('[WARN] No active shift found for player ' .. playerId)
        end
    end)
end