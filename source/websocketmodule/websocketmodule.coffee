############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("websocketmodule")
#endregion

############################################################
import {websocketURL, reconnectTimeoutMS} from "./configmodule"

############################################################
socket = null
pendingReconnect = false

############################################################
export initialize = ->
    log "initialize"
    createSocket()
    return

############################################################
websocketCaughtError = (evnt) ->
    log "websocketCaughtError"
    olog evnt
    log evnt.reason
    return

websocketDisconnected = (evnt) ->
    return if pendingReconnect
    pendingReconnect = true
    setTimeout(reconnectSocket, reconnectTimeoutMS)
    return


websocketConnected = (evnt) -> 
    log "websocketConnected"
    return

websocketMessageReceived = (evnt) ->
    log "websocketMessageReceived"
    return

############################################################
reconnectSocket = ->
    pendingReconnect = false
    createSocket()
    return

############################################################
createSocket = ->
    log "createSocket"
    socket = new WebSocket(websocketURL)
    socket.onerror = websocketCaughtError
    socket.onclose = websocketDisconnected
    socket.onopen = websocketConnected
    socket.onmessage = websocketMessageReceived
    return
