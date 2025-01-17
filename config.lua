--------------------------------------------------------------------
-------------------------] ers-paychecks [--------------------------
--------------------------------------------------------------------
--------------------------] Config File [---------------------------
--------------------------------------------------------------------

-- This paycheck system was designed for Night's Emergency Response 
-- Simulator system however, feel free to use with any other system
-- you use to start/stop LEO shifts.

-- To determine pay rates and access, this script uses Night's API
-- however, feel free to adapt the script to use another system
-- Night's Discord API: (https://store.nights-software.com/package/5035729) 

-- For adding records to the database, this script uses oxmysql
-- https://github.com/overextended/oxmysql

-- Pay rate is calculated on system time not in-game time.

Config  = Config or {}

Config = {
    Framework = "QB", -- "QB", "ESX", "Standalone"
    Debug = true,
    PaymentCurrency = "$", -- Choose whatever currency you'd like $, £, YEN
    DeleteRecordOnEndShift = false, -- Toggle deleting the shift record in MySQL when the player ends their shift.

    --====================== DISCORD ROLES ======================--
    DiscordRoles = {
        [1] = {
            RoleName = "SASP Probationary Trooper", -- Name which is visible
            DiscordRoleName = "SASP", -- Rank name as detailed in Night's Discord API Config.lua
            PayratePerMinute = 1.0 -- This is $1 per minute ($60 an hour real-time)
        },
        [2] = {
            RoleName = "SASP Trooper I",
            DiscordRoleName = "SASP Trooper I",
            PayratePerMinute = 2.0
        },
        [3] = {
            RoleName = "SASP Trooper II",
            DiscordRoleName = "SASP Trooper II",
            PayratePerMinute = 3.0
        },
    },
}