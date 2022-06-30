############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("chatmodule")
#endregion

############################################################
# TODO: peer id based user color for spoofing and shit and put nick in message
# TODO: friends list?
# TODO: append msgs as nodes directly, store nodes in array for poppin

############################################################
import dayjs from 'dayjs'
import relativeTime  from 'dayjs/plugin/relativeTime'
import * as S from "./statemodule.js"

import * as cfg from "./configmodule.js"

############################################################
# self state
nickName = null
us = null

# channel state - init everything as null so we detect uninitialized changes
channel = null
messages = null
present = null
id2nick = null
# unique session id for checking if a message is from "back then" or from this session
session = null

showPresenceIntervalId = null 


############################################################
commandMap = {
    help:
        desc: 'This helptext'
        execute: executeHelpCommand
 
    nick:
        param: '<nick>'
        desc: 'Change nick'
        execute: executeNickCommand
}

############################################################
export initialize = ->
    log "initialize"
    nickName = S.load("nickName")

    dayjs.extend(relativeTime)
    chatForm.onsubmit = onChatSubmit

    showPresenceIntervalId = setInterval(showPresence, 5000)
    return

############################################################
#region internalFunctions

############################################################
#region commandExecutionFunctions
executeHelpCommand = ->
    sysmsg("Help:")
    for cmd, cval of commandMap
        sysmsg(" - /#{cmd}#{if cval.param then " #{cval.param}" else ""}: #{cval.desc}")
    return

executeNickCommand = (name) ->
    setNickName(name)
    if name then sysmsg("Nick is now #{name}")
    else sysmsg("Nick has been cleared")
    return

#endregion

############################################################
#region stateFunctions
saveState = (key, value, persistent = true) ->
    realKey = "#{channel.id}.#{key}"
    if persistent then S.save(realKey, value, true)
    else S.set(realKey, value, true)
    return

loadState = (key, def) ->
    realKey = "#{channel.id}.#{key}"
    return S.load(realKey) || def

listenState = (key, fnc) ->
    realKey = "#{channel.id}.#{key}"
    trueFnc = () -> true
    S.setChangeDetectionFunction(realKey, trueFnc)
    S.addOnChangeListener(realKey, fnc)
    return

#endregion

############################################################
#region eventHandlers
onChatSubmit = (evnt) ->
    evnt.preventDefault()
    chatkeypress()
    return

chatkeypress = ->
    return unless chatInput.value
    chat(chatInput.value)
    chatInput.value = ''
    return

############################################################
handler = (sender, data) ->
    id2nick[sender.toB58String()] = data.nick

    messageObject = {
        sender: sender.toB58String()
        msg: data.msg
        ts: Date.now()
        session
    }

    messages.push(messageObject)
    messages = messages.slice(0, 1024)

    saveState('messages', messages)
    saveState('id2nick', id2nick)
    return

handlerPresence = (sender, data) ->
    id2nick[sender.toB58String()] = data.nick

    if not present[sender.toB58String()] or present[sender.toB58String()].inactive then sysmsg("#{getDisplayNameForId sender.toB58String()} has #{if present[sender.toB58String()] then 'returned' else 'joined'}")

    present[sender.toB58String()] = { lastSeen: Date.now() }

    saveState('present', present, false)
    saveState('id2nick', id2nick)
    return

#endregion

############################################################
sysmsg = (msg) ->
    messages.push {
        system: true
        msg
        ts: Date.now()
        session
    }
    saveState('messages', messages)
    return

############################################################
#region renderingFunctions
showPresence = -> if channel then channel.emit("chat.presence", { nickName })

getDisplayNameForId = (id) -> "#{id2nick[id] || '(unnamed)'} #{id.substr(2, 18)}"

############################################################
render = ->
    chatMessages.innerHTML = ''

    for msg in messages
        ##TODO maybe transform to setting innerHTML of chatMessages
        txt = document.createTextNode("<#{if msg.system then '#system#' else getDisplayNameForId(msg.sender)} @ #{dayjs(msg.ts).fromNow()}> #{msg.msg}")
        p = document.createElement("p")
        p.appendChild(txt)

        if msg.session != session
            p.classList.add('inactive')

        chatMessages.appendChild(p)
    return

renderPresence = ->
    pOut = document.getElementById("chat-present")
    pOut.innerHTML = ''

    for id,state of present
        # clear out old presences
        if Date.now() - state.lastSeen > 60 * 60 * 1000
            delete present[id]
            continue

        if Date.now() - state.lastSeen > 10 * 1000 and not state.inactive
            state.inactive = true
            sysmsg("#{getDisplayNameForId id} has left")

        txt = document.createTextNode("#{getDisplayNameForId id}")
        p = document.createElement("p")
        p.appendChild(txt)
        p.classList.add('present')
        if state.inactive then p.classList.add('inactive')

        txt = document.createTextNode("#{dayjs(state.lastSeen).fromNow()}")
        seen = document.createElement("p")
        seen.appendChild(txt)
        seen.classList.add('seen')
        p.appendChild(seen)

        pOut.appendChild(p)

    return

#endregion

#endregion

############################################################
#region exposed Functions
export chat = (msg) ->
    if !channel? then throw new Error("Not started")

    if msg.startsWith('/')
        tokens = msg.split(' ')
        cmd = tokens[0].substr(1)
        params = tokens.slice(1).join(' ')

        if commandMap[cmd]? then commandMap[cmd].execute(params)
        else sysmsg("Unknown command /#{cmd}. /help for help") 
       
    else channel.emit("chat", {msg, nickName})
    # this will trigger rendering aswell
    return

export startUp = () ->
    channelId = cfg.defaultChannelId
    channel = await allModules.eventexchangemodule.channel(channelId)

    session = String(Math.random())
    messages = loadState('messages', [])
    present = {}
    id2nick = loadState('id2nick', {})

    us = allModules.peertopeermodule.getNode().peerId.toB58String()

    channel.handle("chat", handler)
    channel.handle("chat.presence", handlerPresence)

    chatInput.disabled = false

    sysmsg("Connected via pubsub to #{channelId} as #{nickName || '(unnamed)'}")

    renderAll = ->
        render()
        renderPresence()
        return

    listenState('messages', render)
    listenState('present', renderPresence)
    listenState('id2nick', renderAll)

    # call immediatly to display self right away, this looks better
    showPresence()
    # render everything the first time
    render()
    renderPresence()
    return

export stopChat = ->
  # TODO: teardown channel
  sysmsg("Disconnected from #{channel.id}")
  channel = null
  present = {}
  chatInput.disabled = true
  return

export setNickName = (name) ->
    S.save('nickName', name)
    id2nick[us] = name
    nickName = name

    saveState('id2nick', id2nick)
    return

export getPresent = -> present

#endregion