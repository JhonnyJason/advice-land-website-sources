############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("websocketmodule")
#endregion

############################################################
import { websocketURL, reconnectTimeoutMS } from "./configmodule.js"
import * as chatFrame from "./chatframemodule.js"
import * as webRTC from "./webrtcmodule.js"

import * as S from "./statemodule.js"

############################################################
socket = null
pendingReconnect = false
keepDisconnected = true

############################################################
websocketReady = null
websocketReadySignal = null

############################################################
knownUUIDS = []

############################################################
UUID = null

############################################################
export initialize = ->
    log "initialize"
    UUID = S.load("UUID")
    olog {UUID}
    if !UUID then UUID = crypto.randomUUID()
    S.save({UUID})


    return

############################################################
websocketCaughtError = (evnt) ->
    log "websocketCaughtError"
    olog evnt
    log evnt.reason
    return

websocketDisconnected = (evnt) ->
    return if keepDisconnected
    return if pendingReconnect
    pendingReconnect = true
    setTimeout(reconnectSocket, reconnectTimeoutMS)
    return
websocketConnected = (evnt) -> 
    log "websocketConnected"
    if websocketReadySignal?
        websocketReadySignal()
        websocketReadySignal = null
        webSocketReady = null
    sendMessage("setuuid #{UUID}")
    return

websocketMessageReceived = (evnt) ->
    log "websocketMessageReceived"
    log evnt.data

    keyEnd = evnt.data.indexOf(" ")
    if keyEnd < 0 then key = evnt.data.trim()
    else 
        key = evnt.data.substring(0, keyEnd)
        # log typeof key
        # log key
        content = evnt.data.substring(keyEnd).trim()
        # log typeof content
        # log content

    switch key
        when "alluids" then applyAllUUIDS(content)
        when "chat" then handleChat(content)
        when "sdp" then webRTC.handleSDP(content)
        else log "unknown key #{key}"

    return

############################################################
applyAllUUIDS = (content) ->
    log "applyAllUUIDS"
    knownUUIDS = content.split(",")
    chatFrame.displayPeers(knownUUIDS)
    return

handleChat = (content) ->
    log "handleChat"
    log content
    chatFrame.addChatMessage(content)
    return

############################################################
reconnectSocket = ->
    pendingReconnect = false
    createSocket()
    return

############################################################
createSocket = ->
    log "createSocket"
    if !webSocketReady? then websocketReady = new Promise (resolve, reject) ->
        websocketReadySignal = resolve
    socket = new WebSocket(websocketURL)
    socket.onerror = websocketCaughtError
    socket.onclose = websocketDisconnected
    socket.onopen = websocketConnected
    socket.onmessage = websocketMessageReceived
    return

############################################################
export sendMessage = (message) ->
    log "sendMessage #{message}"
    return if keepDisconnected
    await websocketReady
    socket.send(message)
    return

export connect = ->
    keepDisconnected = false
    createSocket()
    return

export disconnect = ->
    return if socket == null
    keepDisconnected = true
    socket.close()
    socket = null
    return

export getUUID = -> UUID