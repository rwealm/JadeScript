-- Jade Script (OFFICIAL) 
-- jadeee#4332 is the real jade
-- discord.gg/gpRXE3d2UU

-- DO NOT TOUCH UNLESS U R LUA RETARD
util.keep_running()
util.require_natives(1663599433)

-- Auto-Update
local response = false
local localVer = 0.3
async_http.init("raw.githubusercontent.com", "/rwealm/JadeScript/main/JadeScript.lua", function(output)
    currentVer = tonumber(output)
    response = true
    if localVer ~= currentVer then
        util.toast("This version is outdated but, functional. Please update to a more stable version.")
        menu.action(menu.my_root(), "Update JadeScript", {}, "", function()
            async_http.init('raw.githubusercontent.com', '/rwealm/JadeScript/main/JadeScript.lua',function(a)
                local err = select(2,load(a))
                if err then
                    util.toast("Script failed to download. Please try again later. If this continues to happen then manually update via github.")
                return end
                local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                f:write(a)
                f:close()
                util.toast("Successfully updated!")
                util.toast("Restarting JadeScript <3")
                util.restart_script()
            end)
            async_http.dispatch()
        end)
    end
end, function() response = true end)
async_http.dispatch()
repeat 
    util.yield()
until response

util.toast("Script made by jadeee#4332")
util.toast("Discord server: https://discord.gg/qE9vhN9T4F")
root = menu.my_root()

-- Me Options (Local)

local me = menu.list(menu.my_root(), "Me", {}, "List of local player options")
    me:action("Collect Pumpkins", {}, "Collects all pumpkins around the map", function ()
     for _, stat in pairs({34372, 34380, 34706}) do
        STATS.SET_PACKED_STAT_BOOL_CODE(stat, false, util.get_char_slot())
    end

    memory.write_int(memory.script_global(2788199 + 589), 9)
    util.trigger_script_event(1 << players.user(), {-1178972880, 1, 8, -1, 1, 1, 1})
    util.yield(100)
    memory.write_int(memory.script_global(2788199 + 589), 200)
    util.trigger_script_event(1 << players.user(), {-1178972880, 1, 8, -1, 1, 1, 1})

    util.toast("ur jackolantern stuff should be unlocked ;)")

end)

me:action("Remove Current Bounty", {}, "this removes any bounty placed on you", function()
    if memory.read_int(memory.script_global(1835502 + 4 + 1 + (players.user() * 3))) == 1 then 
        memory.write_int(memory.script_global(2815059 + 1856 + 17), -1)
        memory.write_int(memory.script_global(2359296 + 1 + 5149 + 13), 2880000)
        util.toast("Removed Bounty of " ..memory.read_int(memory.script_global(1835502 + 4 + 1 + (players.user() * 3) + 1)).. "$")
    else
        util.toast("You do not currently have a bounty")
    end
    end)

    

-- Online Options (Other Players)

local notifs = menu.list(menu.my_root(), "Send all notifs", {}, "Sends everyone a notification")
notifs:action("Send all enter notification", {"enternotifall"}, "", function ()
    menu.show_command_box("enternotifall".. "")
end, function(label)
    for _, pid in pairs(players.list(true, true, true)) do
    send_custom_notif(pid, label)
    end
    
end)

notifs:action("Send all job notification", {"joball"}, "", function ()
    menu.show_command_box("joball".. " ")
end, function(txt)
    for _, pid in pairs(players.list(true, true, true)) do
        send_job_notif(pid, txt)
    end
end)

notifs:action("ORG Remove", {"goonremoveall"}, "", function ()
for _, pid in pairs(players.list(true, true, true)) do
    util.trigger_script_event(1 << pid, {-1529596656, pid, -1874451036, 0, 0, 0, 0, 0, 0, 0, pid, 0, 0, 0})
end
end)

local misc = menu.list(menu.my_root(), "Misc", {}, "")
misc.hyperlink(menu.my_root(), "Join The Discord", "https://discord.gg/qE9vhN9T4F")
local credits = menu.list(misc, "Credits", {}, "")
menu.action(credits, "Jade", {}, "Created JadeScript", function()
end)
menu.action(credits, "Lance", {}, "Helped code JadeScript", function()
end)


 