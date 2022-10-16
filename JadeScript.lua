-- Jade Script (OFFICIAL) 
-- jadeee#4332 is the real jade
-- discord.gg/gpRXE3d2UU

-- TURN THIS OFF BEFORE RELEASE
-- TURN. THIS. OFF. BEFORE RELEASE
-- TURN THIS OFF BEFORE RELEASE!!!
local dev_mode = false
-- ^^ OFF BEFORE U RELEASE


-- DO NOT TOUCH UNLESS U R LUA RETARD
util.keep_running()
util.require_natives(1663599433)
-- sound player system
local aalib = require("aalib")
local PlaySound = aalib.play_sound
local SND_ASYNC<const> = 0x0001
local SND_FILENAME<const> = 0x00020000

resources_dir = filesystem.resources_dir() .. '\\jadescript\\'
jadescript_logo = directx.create_texture(resources_dir .. 'jadescript_logo.png')

local function notify(text)
    util.toast("[JadeScript] " .. text)
end

if not filesystem.is_dir(resources_dir) then
    notify("JadeScript is not installed properly. Some things will fail to load or break.")
end

-- auto-updating system
-- credit to prism, i hope ur not mad at me <3 - lance

local response = false
local localVer = 0.4
if not dev_mode then
    async_http.init("raw.githubusercontent.com", "/rwealm/JadeScript/main/JadeScriptVersion", function(output)
        currentVer = tonumber(output)
        response = true
        if localVer ~= currentVer then
            notify("This version of JadeScript is outdated but functional. Please update to a more stable version.")
            menu.action(menu.my_root(), "Update JadeScript", {}, "", function()
                async_http.init('raw.githubusercontent.com', '/rwealm/JadeScript/main/JadeScript.lua',function(a)
                    local err = select(2,load(a))
                    if err then
                        notify("Script failed to download. Please try again later. If this continues to happen then manually update via github.")
                    return end
                    local f = io.open(filesystem.scripts_dir() .. SCRIPT_RELPATH, "wb")
                    f:write(a)
                    f:close()
                    notify("Successfully updated!")
                    notify("Restarting JadeScript <3")
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
end



if not SCRIPT_SILENT_START then 
    logo_alpha = 0
    logo_alpha_incr = 0.02
    logo_alpha_thread = util.create_thread(function (thr)
        while true do
            logo_alpha = logo_alpha + logo_alpha_incr
            if logo_alpha > 1 then
                logo_alpha = 1
            elseif logo_alpha < 0 then 
                logo_alpha = 0
                util.stop_thread()
            end
            util.yield()
        end
    end)

    logo_thread = util.create_thread(function (thr)
        starttime = os.clock()
        local alpha = 0
        while true do
            directx.draw_texture(jadescript_logo, 0.10, 0.10, 0.5, 0.5, 0.5, 0.5, 0, 1, 1, 1, logo_alpha)
            timepassed = os.clock() - starttime
            if timepassed > 1 then
                logo_alpha_incr = -0.01
            end
            if logo_alpha == 0 then
                util.stop_thread()
            end
            util.yield()
        end
    end)
    PlaySound(resources_dir .. "\\kitty.wav", SND_FILENAME | SND_ASYNC)
end

-- root setup
root = menu.my_root()

local me = root:list("Me", {}, "List of local player options")
local online = root:list("Online")
local world = root:list("World")
local game = root:list("Game")
--
local notifs = online:list("Send all notifs", {}, "Sends everyone a notification")
--
local misc = root:list( "Misc", {}, "")
local credits = root:list("Credits", {}, "")

root:divider("Version " .. localVer, {}, "", function() end)
root:hyperlink("Join Discord", "https://discord.gg/qE9vhN9T4F")

-- utility functions 

-- model load requesting, very important
local function request_model_load(hash)
    request_time = os.time()
    if not STREAMING.IS_MODEL_VALID(hash) then
        return
    end
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end


-- also credit to nowiry i believe
local function raycast_gameplay_cam(flag, distance)
    local ptr1, ptr2, ptr3, ptr4 = memory.alloc(), memory.alloc(), memory.alloc(), memory.alloc()
    local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
    local direction = v3.toDir(cam_rot)
    local destination = 
    { 
        x = cam_pos.x + direction.x * distance, 
        y = cam_pos.y + direction.y * distance, 
        z = cam_pos.z + direction.z * distance 
    }
    SHAPETEST.GET_SHAPE_TEST_RESULT(
        SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            cam_pos.x, 
            cam_pos.y, 
            cam_pos.z, 
            destination.x, 
            destination.y, 
            destination.z, 
            flag, 
            players.user_ped(), 
            1
        ), ptr1, ptr2, ptr3, ptr4)
    local p1 = memory.read_int(ptr1)
    local p2 = memory.read_vector3(ptr2)
    local p3 = memory.read_vector3(ptr3)
    local p4 = memory.read_int(ptr4)
    return {p1, p2, p3, p4}
end


local function get_model_size(hash)
    local minptr = memory.alloc(24)
    local maxptr = memory.alloc(24)
    local min = {}
    local max = {}
    MISC.GET_MODEL_DIMENSIONS(hash, minptr, maxptr)
    min.x, min.y, min.z = v3.get(minptr)
    max.x, max.y, max.z = v3.get(maxptr)
    local size = {}
    size.x = max.x - min.x
    size.y = max.y - min.y
    size.z = max.z - min.z
    size['max'] = math.max(size.x, size.y, size.z)
    return size
end

local function request_anim_dict(dict)
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
end

local function request_weapon_asset(hash)
    while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
        WEAPON.REQUEST_WEAPON_ASSET(hash, 31, 0)
        util.yield()
    end
end

function get_closest_veh(coords)
    local closest = nil
    local closest_dist = 1000000
    local this_dist = 0
    for _, veh in pairs(entities.get_all_vehicles_as_handles()) do 
        this_dist = v3.distance(coords, ENTITY.GET_ENTITY_COORDS(veh))
        if this_dist < closest_dist  and ENTITY.GET_ENTITY_HEALTH(veh) > 0 then
            closest = veh
            closest_dist = this_dist
        end
    end
    if closest ~= nil then 
        return {closest, closest_dist}
    else
        return nil 
    end
end

function get_closest_ped(coords)
    local closest = nil
    local closest_dist = 1000000
    local this_dist = 0
    for _, ped in pairs(entities.get_all_peds_as_handles()) do 
        this_dist = v3.distance(coords, ENTITY.GET_ENTITY_COORDS(ped))
        if this_dist < closest_dist and not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_FATALLY_INJURED(ped)  and not PED.IS_PED_IN_ANY_VEHICLE(ped, true) then
            closest = ped
            closest_dist = this_dist
        end
    end
    if closest ~= nil then 
        return {closest, closest_dist}
    else
        return nil 
    end
end

function get_closest_ped_to_ped(coords, init_ped)
    local coords = ENTITY.GET_ENTITY_COORDS(init_ped)
    local closest = nil
    local closest_dist = 1000000
    local this_dist = 0
    for _, ped in pairs(entities.get_all_peds_as_handles()) do 
        this_dist = v3.distance(coords, ENTITY.GET_ENTITY_COORDS(ped))
        if this_dist < closest_dist and not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_FATALLY_INJURED(ped) and not PED.IS_PED_IN_ANY_VEHICLE(ped, true) and ped ~= init_ped then
            closest = ped
            closest_dist = this_dist
        end
    end
    if closest ~= nil then 
        return {closest, closest_dist}
    else
        return nil 
    end
end

-- me options

local entity_held = 0
local are_hands_up = false
me:toggle_loop("Throw cars", {"throwcars"}, " Press E near a vehicle to use, press E while holding a vehicle to throw.", function(on)
    if PAD.IS_CONTROL_JUST_RELEASED(38, 38) then
        if entity_held == 0 then
            if not are_hands_up then 
                local closest = get_closest_veh(ENTITY.GET_ENTITY_COORDS(players.user_ped()))
                local veh = closest[1]
                local dist = closest[2]
                if dist <= 5 then 
                    request_anim_dict("missminuteman_1ig_2")
                    TASK.TASK_PLAY_ANIM(players.user_ped(), "missminuteman_1ig_2", "handsup_enter", 8.0, 0.0, -1, 50, 0, false, false, false)
                    util.yield(500)
                    are_hands_up = true
                    ENTITY.SET_ENTITY_ALPHA(veh, 100)
                    ENTITY.SET_ENTITY_HEADING(veh, ENTITY.GET_ENTITY_HEADING(players.user_ped()))
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(veh, players.user_ped(), 0, 0, 0, get_model_size(ENTITY.GET_ENTITY_MODEL(veh)).z / 2, 180, 180, -180, true, false, true, false, 0, true)
                    entity_held = veh
                end 
            else
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
                are_hands_up = false
            end
        else
            if ENTITY.IS_ENTITY_A_VEHICLE(entity_held) then
                ENTITY.DETACH_ENTITY(entity_held)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(entity_held, 100.0)
                VEHICLE.SET_VEHICLE_OUT_OF_CONTROL(entity_held, true, true)
                ENTITY.SET_ENTITY_ALPHA(entity_held, 255)
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
                ENTITY.FREEZE_ENTITY_POSITION(players.user_ped(), true)
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(entity_held, players.user_ped(), false)
                request_anim_dict("melee@unarmed@streamed_core")
                TASK.TASK_PLAY_ANIM(players.user_ped(), "melee@unarmed@streamed_core", "heavy_punch_a", 8.0, 8.0, -1, 0, 0.3, false, false, false)
                util.yield(500)
                ENTITY.FREEZE_ENTITY_POSITION(players.user_ped(), false)
                entity_held = 0
                are_hands_up = false
            end
            -- toss
        end
    end
end)

local ped_held = 0
me:toggle_loop("Throw peds", {"throwpeds"}, "Pick up and throw peds. Press E near a ped to use, press E while holding a ped to throw.", function(on)
    if PAD.IS_CONTROL_JUST_RELEASED(38, 38) then
        if entity_held == 0 then
            if not are_hands_up then 
                local closest = get_closest_ped(ENTITY.GET_ENTITY_COORDS(players.user_ped()))
                local ped = closest[1]
                local dist = closest[2]
                if dist <= 5 then 
                    request_anim_dict("missminuteman_1ig_2")
                    TASK.TASK_PLAY_ANIM(players.user_ped(), "missminuteman_1ig_2", "handsup_enter", 8.0, 0.0, -1, 50, 0, false, false, false)
                    util.yield(500)
                    are_hands_up = true
                    ENTITY.SET_ENTITY_ALPHA(ped, 100)
                    ENTITY.SET_ENTITY_HEADING(ped, ENTITY.GET_ENTITY_HEADING(players.user_ped()))
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, players.user_ped(), 0, 0, 0, 1.3, 180, 180, -180, true, false, true, true, 0, true)
                    entity_held = ped
                end 
            else
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
                are_hands_up = false
            end
        else
            if ENTITY.IS_ENTITY_A_PED(entity_held) then
                ENTITY.DETACH_ENTITY(entity_held)
                ENTITY.SET_ENTITY_ALPHA(entity_held, 255)
                PED.SET_PED_TO_RAGDOLL(entity_held, 10, 10, 0, false, false, false)
                --ENTITY.SET_ENTITY_VELOCITY(entity_held, 0, 100, 0)
                ENTITY.SET_ENTITY_MAX_SPEED(entity_held, 100.0)
                ENTITY.APPLY_FORCE_TO_ENTITY(entity_held, 1, 0, 100, 0, 0, 0, 0, 0, true, false, true, false, false)
                AUDIO.PLAY_PAIN(entity_held, 7, 0, 0)
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
                ENTITY.FREEZE_ENTITY_POSITION(players.user_ped(), true)
                ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(entity_held, players.user_ped(), false)
                request_anim_dict("melee@unarmed@streamed_core")
                TASK.TASK_PLAY_ANIM(players.user_ped(), "melee@unarmed@streamed_core", "heavy_punch_a", 8.0, 8.0, -1, 0, 0.3, false, false, false)
                util.yield(500)
                ENTITY.FREEZE_ENTITY_POSITION(players.user_ped(), false)
                entity_held = 0
                are_hands_up = false
            end
            -- toss
        end
    end
end)

me:toggle_loop("Laser eyes", {"lasereyes"}, "Hold E to use.", function(on)
    if PAD.IS_CONTROL_PRESSED(51, 51) then
        local ped_model = ENTITY.GET_ENTITY_MODEL(players.user_ped())
        local left_eye_id = 0
        local right_eye_id = 0
        pluto_switch ped_model do 
            case 1885233650:
            case -1667301416:
                left_eye_id = 25260
                right_eye_id = 27474
                break
            case 225514697:
                left_eye_id = 5956
                right_eye_id = 6468
                break
            -- imply they're using a story mode ped i guess. i dont know what else to do unless i have data on every single ped
            pluto_default:
                left_eye_id = 5956
                right_eye_id = 6468
        end
        local z_offset = 0.01
        if ped_model == util.joaat("mp_f_freemode_01") then 
            z_offset = 0.08
        end
        local left_eye = PED.GET_PED_BONE_COORDS(players.user_ped(), left_eye_id, 0, -0.001, z_offset)
        local right_eye = PED.GET_PED_BONE_COORDS(players.user_ped(), right_eye_id, 0, 0.001, z_offset)
        local raycast = raycast_gameplay_cam(-1, 10000.0)
        if raycast[1] == 1 then
            local shoot_pos = raycast_gameplay_cam(-1, 10000.0)[2]
            --local shoot_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, 3.0, 0.08)
            local laser_hash = util.joaat("WEAPON_RAYCARBINE")
            request_weapon_asset(laser_hash)
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(left_eye.x, left_eye.y, left_eye.z, shoot_pos.x, shoot_pos.y, shoot_pos.z, 1000.0, true, laser_hash, players.user_ped(), true, false, 100)
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(right_eye.x, right_eye.y, right_eye.z, shoot_pos.x, shoot_pos.y, shoot_pos.z, 1000.0, true, laser_hash, players.user_ped(), true, false, 100)
        end
    end
    --MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(right_eye.x, right_eye.y, right_eye.z, right_eye_f.x, right_eye_f.y, right_eye_f.z, 100.0, true, laser_hash, players.user_ped(), true, false, 100)
end)

-- online options

online:action("Collect Pumpkins", {}, "Collects all pumpkins around the map", function ()
    if util.is_session_started() then
        for _, stat in pairs({34372, 34380, 34706}) do
            STATS.SET_PACKED_STAT_BOOL_CODE(stat, false, util.get_char_slot())
        end

        memory.write_int(memory.script_global(2788199 + 589), 9)
        util.trigger_script_event(1 << players.user(), {-1178972880, 1, 8, -1, 1, 1, 1})
        util.yield(100)
        memory.write_int(memory.script_global(2788199 + 589), 200)
        util.trigger_script_event(1 << players.user(), {-1178972880, 1, 8, -1, 1, 1, 1})
        notify("ur jackolantern stuff should be unlocked ;)")
    end
end)

online:action("Remove Current Bounty", {}, "this removes any bounty placed on you", function()
    if util.is_session_started() then
        if memory.read_int(memory.script_global(1835502 + 4 + 1 + (players.user() * 3))) == 1 then
            memory.write_int(memory.script_global(2815059 + 1856 + 17), -1)
            memory.write_int(memory.script_global(2359296 + 1 + 5149 + 13), 2880000)
            notify("Removed Bounty of " ..memory.read_int(memory.script_global(1835502 + 4 + 1 + (players.user() * 3) + 1)).. "$")
        else
            notify("You do not currently have a bounty")
        end
    end
end)

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

notifs:action("Send organization remove message", {"goonremoveall"}, "", function ()
    for _, pid in pairs(players.list(true, true, true)) do
        util.trigger_script_event(1 << pid, {-1529596656, pid, -1874451036, 0, 0, 0, 0, 0, 0, 0, pid, 0, 0, 0})
    end
end)

-- world options
world:action("No russian", {"norussian"}, "Spawns a ped that will constantly kill and hunt nearby peds", function()
    util.toast("Remember: No Russian.")
    local terror_model = util.joaat("s_m_y_xmech_02")
    request_model_load(terror_model)
    local terrorist = entities.create_ped(28, terror_model, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, 1.0, 0.0), math.random(270))
    WEAPON.GIVE_WEAPON_TO_PED(terrorist, 171789620, 1000, false, true)
    PED.SET_PED_COMBAT_ABILITY(terrorist, 2)
    PED.SET_PED_AS_ENEMY(terrorist, true)
    PED.SET_PED_COMBAT_ATTRIBUTES(terrorist,13, true)
    while true do
        if PED.IS_PED_FATALLY_INJURED(terrorist) or not ENTITY.DOES_ENTITY_EXIST(terrorist) then 
            break 
        end
        local nearest = get_closest_ped_to_ped(ENTITY.GET_ENTITY_COORDS(terrorist), terrorist)
        TASK.TASK_COMBAT_PED(terrorist, nearest[1])
        util.yield(2000)
    end
end)

-- game tweaks 

local vis_tweaks_options = {"Off", "Champagne", "Zombify", "Burple", "Jade"}
local vis_tweak_index = {"Off", "INT_streetlighting", "DRUG_2_drive", "drug_flying_02", "NG_filmic08"}
game:list_select("Visual tweaks", {"jadevistweaks"}, "Make your game look epik", vis_tweaks_options, 1, function(index, value)
    menu.trigger_commands("shader " .. vis_tweak_index[index])
end)

-- credits 
menu.action(credits, "Jade", {}, "Created JadeScript", function() end)
menu.action(credits, "Lance", {}, "Helped code JadeScript", function() end)
menu.action(credits, "Prism", {}, "Auto-updater snippet", function() end)

-- misc 
misc:hyperlink("Buy thigh-highs", "https://www.amazon.com/Womens-Striped-Cosplay-Custume-Stockings/dp/B07F823XMQ/")
