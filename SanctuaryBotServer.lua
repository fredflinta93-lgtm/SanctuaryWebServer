-- start botserver configuration
SanctuaryBotServer = {}

-- Din Railway-publik-URL (byt ut mot URL:en du får efter deployment)
local RAILWAY_URL = "your-project-name.up.railway.app"

-- Ändra till false om du vill testa lokalt
local isOnline = true

SanctuaryBotServer.Connection = {
    protocol = isOnline and "http" or "ws",   -- http för online, ws för lokalt
    host     = isOnline and RAILWAY_URL or "127.0.0.1",
    port     = 43661  -- används för lokal test, på Railway används URL-porten
}

-- Inits
SanctuaryBotServer.Members = {}

-- Storage
local panelName = "commander"
local configValues = {
    channel  = tostring(math.random(1, 99999)),
    mcFollow = false,
    mcTurn   = false,
}
local config = Plib.EnsureIntegrity(storage[panelName], configValues)
if config then
    storage[panelName] = config
else
    error("could not verify storage!")
end

-- Initiera BotServer
BotServer.url = SanctuaryBotServer.Connection.protocol ..
    "://" .. SanctuaryBotServer.Connection.host .. ":" .. SanctuaryBotServer.Connection.port .. "/send"
BotServer.init(playerName, config.channel)

-- Hjälpfunktioner
local save = function()
    storage[panelName] = config
end

local write = function() return BotServer._websocket end
local read = function(sender) return sender ~= playerName end

UpdateCommanderFunction = function(name, value)
    storage[panelName][name] = value
end

SanctuaryBotServer.IsMember = function(name)
    for _, member in pairs(SanctuaryBotServer.Members) do
        if member.name == name then
            return true
        end
    end
    return false
end


local topics = {
    direction = "1",
    wall      = "2",
    location  = "3",
    follow    = "4",
    chat      = "5",
    heal      = "6",
    combo     = "7",
    list      = "255"
}

local playerName = player:getName()
-- end botserver configuration

-- inits
SanctuaryBotServer.Members = {}

-- storage
local panelName = "commander"
local configValues = {
    channel  = tostring(math.random(1, 99999)),
    mcFollow = false,
    mcTurn   = false,
}
local config = Plib.EnsureIntegrity(storage[panelName], configValues)
if config then
    storage[panelName] = config
else
    error("could not verify storage!")
end

BotServer.url = SanctuaryBotServer.Connection.protocol ..
    "://" .. SanctuaryBotServer.Connection.host .. ":" .. SanctuaryBotServer.Connection.port .. "/send"
BotServer.init(playerName, config.channel)

local save = function()
    storage[panelName] = config
end

local write = function() return BotServer._websocket end
local read = function(sender) return sender ~= playerName end

UpdateCommanderFunction = function(name, value)
    storage[panelName][name] = value
end

SanctuaryBotServer.IsMember = function(name)
    for _, member in pairs(SanctuaryBotServer.Members) do
        if member.name == name then
            return true
        end
    end
    return false
end

-- graphical user interface
local tab = setDefaultTab("Main")
UI.Separator()
UI.Label("Sanctuary BotServer")

g_ui.loadUIFromString([[
ButtonListPanel < Panel
  margin-top: -1
  layout:
    type: verticalBox
    fit-children: true

  Panel
    id: commandButtons
    margin-left: -2
    margin-right: -2
    padding: 2
    layout:
      type: grid
      cell-size: 58 20
      cell-spacing: 1
      flow: true
      fit-children: true

]])

local updateStatusText = function(widget)
    local members = ""
    for _, member in pairs(SanctuaryBotServer.Members) do
        members = members .. member.name .. "[" .. member.level .. Globals.VocText[member.voc] .. "]\n"
    end
    widget:setTooltip(
        "Channel number 1-99999. Restart bot if you change this value.\nReserved channels with predefined commanders (including their MCs):\n1: Deathroar\n2: Gamer\n3: Hankk\n4: Caligula\n5: Siggy\n\n" ..
        "Members (" .. (#SanctuaryBotServer.Members) .. "):\n" .. members)
end

local btns = UI.createWidget("ButtonListPanel")

local followBtn = UI.Button("Follow", function(widget)
    config.mcFollow = not config.mcFollow
    widget:setColor(config.mcFollow and Globals.ActiveColor or Globals.InactiveColor)

    if write() then
        BotServer.send(topics.follow, json.encode({ follow = config.mcFollow }))
    end
    save()
end, btns.commandButtons)
followBtn:setColor(config.mcFollow and Globals.ActiveColor or Globals.InactiveColor)
followBtn:setTooltip("Toggle the follow macro for member characters.")

local turnBtn = UI.Button("Turn", function(widget)
    config.mcTurn = not config.mcTurn
    widget:setColor(config.mcTurn and Globals.ActiveColor or Globals.InactiveColor)
    save()
end, btns.commandButtons)
turnBtn:setColor(config.mcTurn and Globals.ActiveColor or Globals.InactiveColor)
turnBtn:setTooltip("Enable to make all characters face the same direction.")

local channelTxt = UI.TextEdit(config.channel, function(widget, newText)
    if tonumber(newText) < 1 then
        newText = "1"
    elseif tonumber(newText) > 99999 then
        newText = "99999"
    end
    widget:setText(newText)
    config.channel = newText
    save()
end)
channelTxt:setTooltip(
    "Channel number 1-99999. Restart bot if you change this value.\nReserved channels with predefined commanders (including their MCs):\n1: Deathroar\n2: Gamer\n3: Hankk\n4: Caligula\n5: Siggy")

-- send/read
local readDirection = function(name, msg)
    if read(name) and IsLocalClient(name) then
        local data = json.decode(msg)
        if data and data.doTurn then
            g_game.turn(data.direction)
        end
    end
end
local readFollow = function(name, msg)
    if read(name) and IsLocalClient(name) then
        local data = json.decode(msg)
        if data and FollowMacro.isOn() ~= data.follow then
            if data.follow and CaveBot.isOff() then
                FollowMacro.setOn()
            else
                FollowMacro.setOff()
            end
        end
    end
end
local readMarkers = function(name, msg)
    if read(name) then
        local data = json.decode(msg)
        SetMarkedPositions(data.mwall, data.wgrowth)
        WallholderMode(data.wallmode)
    end
end
local readChat = function(name, msg)
    if read(name) then
        local data = json.decode(msg)
        Plib.broadcastMessage(data.text)
    end
end
local readHeal = function(name, msg)
    if read(name) then
        local data = json.decode(msg)
        FriendHealerMode(data.healermode, false)
    end
end
local readCombo = function(name, msg)
    if read(name) then
        -- todo
    end
end

local lastTurn = now
onTurn(function(creature, direction)
    if write() and now - lastTurn > 200 then
        if storage[panelName].mcTurn and creature == player then
            local data = {
                doTurn    = storage[panelName].mcTurn,
                direction = direction,
            }
            BotServer.send(topics.direction, json.encode(data))
            lastTurn = now
        end
    end
end)

SanctuaryBotServer.SendMarkers = function(wallmode, mwalls, wgrowths)
    if write() then
        local data = {
            wallmode = wallmode,
            mwall = mwalls,
            wgrowth = wgrowths
        }
        BotServer.send(topics.wall, json.encode(data))
    end
end

SanctuaryBotServer.SendChat = function(message)
    if write() then
        message = "*Sanctuary* " .. player:getName() .. " [ " .. player:getLevel() .. "]: " .. message
        local data = { text = message }
        BotServer.send(topics.chat, json.encode(data))
    end
end

SanctuaryBotServer.SendHeal = function(healerMode)
    if write() then
        local data = {
            healermode = healerMode,
        }
        BotServer.send(topics.heal, json.encode(data))
    end
end

SanctuaryBotServer.SendCombo = function(comboMode, leader, time, target)
    if write() then
        local data = {
            combomode = comboMode,
            leader = leader,
            time = time,
            target = target
        }
        BotServer.send(topics.combo, json.encode(data))
    end
end

-- BotServer functions
BotServer.listen(topics.direction, function(name, msg) readDirection(name, msg) end)
BotServer.listen(topics.follow, function(name, msg) readFollow(name, msg) end)
BotServer.listen(topics.wall, function(name, msg) readMarkers(name, msg) end)
BotServer.listen(topics.chat, function(name, msg) readChat(name, msg) end)
BotServer.listen(topics.heal, function(name, msg) readHeal(name, msg) end)
BotServer.listen(topics.combo, function(name, msg) readCombo(name, msg) end)

onCreaturePositionChange(function(creature, newPos, oldPos)
    if creature:getName() ~= playerName then return end
    if g_game.getPing() < 150 then return end

    local jsonData = json.encode({ oldpos = oldPos, newpos = newPos, direction = player:getDirection() })
    BotServer.send(topics.location, jsonData)
end)

local walkLock = 0
BotServer.listen(topics.location, function(name, msg)
    if not FollowMacro.isOn() then return end
    if name ~= storage.followLeader then return end
    if not SanctuaryBotServer.IsMember(storage.followLeader) then return end
    if g_game.getPing() < 150 then return end

    local jsonData = json.decode(msg)
    local maxDist = 40
    local params = { ignoreNonPathable = true, precision = 1 }
    local targetPos = isInPz() and jsonData.newpos or jsonData.oldpos

    if math.abs(targetPos.x - jsonData.oldpos.x) >= 5
        or math.abs(targetPos.y - jsonData.oldpos.y) >= 5
        or math.abs(targetPos.z - jsonData.oldpos.z) >= 2 then
        walkLock = now + g_settings.getNumber('walkTeleportDelay')
    elseif math.abs(targetPos.z - jsonData.oldpos.z) == 1 then
        walkLock = now + g_settings.getNumber('walkTeleportDelay')
    end

    if now > walkLock then
        --[[local creature = getCreatureByName(storage.followLeader)
        if g_game.getPing() > 100 and isInPz() and creature then
            g_game.follow(creature)
        else
            g_game.cancelFollow()
            autoWalk(targetPos, maxDist, params)
        end]]
        autoWalk(targetPos, maxDist, params)
        schedule(2000, function()
            local z1 = jsonData.newpos.z
            local z2 = posz()
            if z1 ~= z2 then
                g_game.turn(jsonData.direction)
                say('exani hur "' .. (z1 < z2 and "up" or "down")) -- todo retry until floor matches
            end
        end)
    end
end)

-- administration
onPlayerHealthChange(function(healthPercent)
    if BotServer._websocket and healthPercent == 0 then
        BotServer.terminate() -- terminate on player death
    end
end)

macro(1000, function()
    if BotServer._websocket then
        BotServer._websocket.send({ type = "heartbeat" }) -- keep connection alive
    end
end)

macro(1000, function()
    if BotServer._websocket then
        BotServer.send(topics.list,
            json.encode({ name = playerName, voc = voc(), level = player:getLevel() }))
    end
    local timeout = now - 15000
    local i = 1
    while i <= #SanctuaryBotServer.Members do
        if timeout > SanctuaryBotServer.Members[i].lastSeen then
            table.remove(SanctuaryBotServer.Members, i)
        else
            i = i + 1
        end
    end

    modules.game_battle.MulticlientMembers = {}
    for _, member in pairs(SanctuaryBotServer.Members) do
        table.insert(modules.game_battle.MulticlientMembers, member.name)
    end
    updateStatusText(channelTxt)
    delay(5000)
end)
BotServer.listen(topics.list, function(name, msg)
    local update = false
    for _, member in pairs(SanctuaryBotServer.Members) do
        if member.name == name then
            member.lastSeen = now
            update = true
        end
    end
    if not update then
        local member = json.decode(msg)
        member.lastSeen = now
        table.insert(SanctuaryBotServer.Members, member)
    end
end)
