<a id="readme-top"></a>


<!-- PROJECT LOGO -->
<br />
<div align="center">

<h3 align="center">ERS-Paychecks</h3>

  <p align="center">
    A FiveM Lua script designed to pay players for going on-shift using Night's Emergency Response Simulator
    <br />
    <a href="https://docs.nights-software.com/resources/ers/"><strong>Explore Night's ERS Docs »</strong></a>
    <br />
    <br />
    <a href="https://discord.gg/vgrdrp">VanguardRP</a>
  </p>
</div>


## Description

<p>The <code>ers-paychecks</code> script is designed to automate and manage the payroll system for law enforcement or similar role-playing activities within the FiveM environment, particularly tailored for servers using frameworks like QB-Core, ESX, or running in standalone mode. This script provides a seamless integration for tracking, calculating, and paying salaries based on the time players spend in their shifts, with special attention to different roles and their corresponding pay rates.</p>

<p>This script is designed to be used with Night's Emergency Response Simulator however feel free to change the code to suit
your server setup.</p>

<h3>Key Features:</h3>
<ul>
  <li><strong>Multi-Framework Compatibility:</strong> Supports QB-Core, ESX, and Standalone setups, allowing servers to manage player paychecks regardless of the underlying framework.</li>
  <li><strong>Role-Based Pay Calculation:</strong> Implements a role hierarchy where each role has a defined pay rate per minute. This allows for automatic wage calculation based on the player's Discord roles or in-game positions.</li>
  <li><strong>Shift Tracking:</strong>
    <ul>
      <li><em>Start/End Shifts:</em> Players can initiate and conclude shifts, with the script logging the start time, end time, and calculating shift duration in real-time.</li>
      <li><em>Database Integration:</em> Utilizes a MySQL database to store shift data, ensuring persistence and data integrity across server restarts.</li>
    </ul>
  </li>
  <li><strong>Payment Automation:</strong>
    <ul>
      <li>Automatically calculates payment based on shift duration and the player's role pay rate.</li>
      <li>Supports bank deposit directly into the player's account within the server's economy system.</li>
      <li>If a player unexpectedly disconnects, on relogging in the script will automatically calculate previous shift payment(s).</li>
    </ul>
  </li>
  <li><strong>Notifications:</strong> Sends in-game notifications to players when shifts start, end, or if there are issues with payment logging or processing.</li>
  <li><strong>Configurable:</strong>
    <ul>
      <li>Easily configurable via a config file where roles and their pay rates can be defined.</li>
      <li>Debugging options to log information or errors for troubleshooting.</li>
    </ul>
  </li>
  <li><strong>Security and Integrity:</strong>
    <ul>
      <li>Implements checks to ensure only players with the appropriate roles can log shifts and receive payments.</li>
      <li>Prevents duplicate or overlapping shift entries through database constraints.</li>
    </ul>
  </li>
  <li><strong>Error Handling:</strong> Provides feedback mechanisms like server console logs or player notifications in case of database errors or other issues during shift management.</li>
</ul>

<h3>Use Cases:</h3>
<ul>
  <li>Ideal for servers running police, EMS, or other job-based RP where automatic salary calculation based on time worked is crucial.</li>
  <li>Can be extended for other job types by adjusting role definitions and pay rates.</li>
  <li>Ideal for servers that want to use a framework such as QB-Core or ESX and still have LEO players responding to AI callouts alongside Civilian player actions.</li>
</ul>

<h3>Dependencies:</h3>
<ul>
  <li>Requires a MySQL database setup for data persistence.</li>
  <li>The script uses the <b>oxmysql</b> resource (https://github.com/overextended/oxmysql)
  <li>The script uses Night's Discord API resource to obtain and read Discord member roles however feel free to change the script for another Discord API resource</li>
  <li>Needs configuration for your specific server framework and Discord roles.</li>
</ul>

<h3>Future Enhancements:</h3>
<ul>
  <li>Potential for adding overtime pay, special bonuses, or tax calculations.</li>
  <li>Integration with more detailed job management systems or with external HR management tools for larger RP communities.</li>
  <li>NUI interface to view stored shift data</li>
</ul>

<p>This script aims to simplify payroll management, enhancing the role-play experience by making in-game employment feel more structured and realistic.</p>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Changelog

<h3>1.0.5</h3>
<ul>
  <li>Added ability to toggle using Discord API entirely and just use a standard payrate for all players regardless of rank.</li>
</ul>

### Installation

1. Download the contents of this repo into a ZIP file and extract it as a folder
2. Drag and drop the folder into your `resources` folder for your FiveM server
3. Configure the config.lua file by adding your own preferences and Discord roles
   ```sh
   Config  = Config or {}

    Config = {
        Framework = "QB", -- "QB", "ESX", "Standalone"
        Debug = true,
        PaymentCurrency = "$", -- Choose whatever currency you'd like $, £, YEN
        DeleteRecordOnEndShift = false, -- Toggle deleting the shift record in MySQL when the player ends their shift.
        CacheRefreshInterval = 3600000, -- Interval for refreshing the cache for player wage rates (set at 1 hour in milliseconds as default)

        UseDiscordRoles = false,
        StaticPayratePerMinute = 1.0,
        
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
   ```
4. If you are using Night's MDT System, go to `client` -> `c_functions.lua` and replace the `OnUserStartedShift()` function
   ```sh
   function OnUserStartedShift()
      local ped = PlayerPedId()
      local playerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))

      TriggerServerEvent("ers-paychecks:startingShift", playerServerId) -- Ensure this is the server ID
   end
   ```
5. In the same file, do the same for the `OnUserEndedShift()` function
   ```sh
   function OnUserStartedShift()
      local ped = PlayerPedId()
      local playerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))

      TriggerServerEvent("ers-paychecks:endingShift", playerServerId) -- Ensure this is the server ID
   end
   ```
6. Make sure to restart `night_shifts` resource before running `ers-paychecks`
7. Note: If you are not using Night's MDT Software, you can still add the server event triggers to your own script
   ```sh
   -- Event when starting a shift
   TriggerServerEvent("ers-paychecks:startingShift", playerServerId)

   -- Event when ending a shift
   TriggerServerEvent("ers-paychecks:endingShift", playerServerId)
   ```
8. Ensure you run the `add_me_sql.sql` code into your database to create the appropriate table the script uses.
   ```sh
    CREATE TABLE `ers_shift_times` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `player_id` VARCHAR(30) NOT NULL,
        `start_time` VARCHAR(20) NOT NULL,
        `end_time` VARCHAR(20) DEFAULT NULL,
        `payment` INT DEFAULT NULL,
        `rate_per_minute` DECIMAL(10, 2) DEFAULT NULL,
        `shift_duration` INT DEFAULT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Night's Software](https://store.nights-software.com/)
* [London Studios](https://store.londonstudios.net/)
* [Vanguard Roleplay](https://discord.gg/vgrdrp)

<p align="right">(<a href="#readme-top">back to top</a>)</p>