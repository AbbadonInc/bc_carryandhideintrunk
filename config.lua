Config = {
    stopCarryKeybind = "G",          -- Key for carrier to cancel carry
    leaveTrunkKeybind = "E",         -- Key to leave trunk
    carryDistance = 1.5,             -- Maximum distance for target interactions
    trunkDistance = 1.5,             -- Maximum distance for trunk interactions
    showPlayerInTrunk = false,
    allowBlackout = true,
    allowCarryAsCommand = true,      -- Allow command-based carry (/carry)
    enableTargetCarry = false,       -- Set to false to disable target-based carry prompts
    targetScript = "ox",             -- Use "ox" or "qb" for your target system
    -- Other config variables…
}
        -- Set to "ox" if you're using ox_target, "qb" if you're using qb-target
        -- (For qb-target, ensure you set Config.EnableDefaultOptions to false in qb-target/init.lua)
 