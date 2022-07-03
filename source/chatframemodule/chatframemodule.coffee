############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("chatframemodule")
#endregion

############################################################
import * as webRTC from "./webrtcmodule"
import * as WS from "./websocketmodule.js"
import M from "mustache"

############################################################
peerTemplate = null
chatTemplate = null


allChatMessages = []
maxMessageNr = 64

############################################################
export initialize = ->
    log "initialize"
    locationHashChanged()
    window.onhashchange = locationHashChanged
    
    chatInput.addEventListener("keydown", inputKeyDowned)
    chatInput.addEventListener("blur", inputBlurred)

    peerTemplate = peerDisplayTemplate.innerHTML
    log peerTemplate
    chatTemplate = chatElementTemplate.innerHTML
    log chatTemplate
    return

############################################################
locationHashChanged = ->
    log "locationHashChanged"
    if location.hash == "#chat" then pullChatIn()
    else pushChatOut()
    return

inputKeyDowned = (evnt) ->
    if evnt.keyCode == 13 
        if chatInput.value 
            sendInputAsMessage()
            chatInput.value = ""
    return

inputBlurred = (evnt) ->
    if chatInput.value 
        sendInputAsMessage()
        chatInput.value = ""
    return

############################################################
sendInputAsMessage = ->
    text = chatInput.value
    message = "to all #{text}"
    WS.sendMessage(message)
    return








############################################################
pullChatIn = ->
    log "pullChatIn"
    document.body.style.height = "100vh"
    document.body.style.overflow = "hidden"
    chatframe.classList.add("here")
    WS.connect()
    return

pushChatOut = ->
    log "pushChatOut"
    document.body.style.height = "auto"
    document.body.style.overflow = "scroll"
    chatframe.classList.remove("here")
    WS.disconnect()
    chatHistoryBlock.innerHTML = ""
    peerDisplayBlock.innerHTML = ""
    allChatMessages = []
    return







############################################################
getUUIDFromTree = (node) ->
    counter = 0
    while !node.classList.contains("peer-display-element")
        node = node.parentNode
        counter++
        if counter > 3 then throw new Error("No nearby parent having class peer-display-element")
    return node.getAttribute("uuid")
############################################################
peerCallClicked = (evnt) ->
    log "peerCallClicked"
    uuid = getUUIDFromTree(evnt.target)
    log uuid
    webRTC.initiateConnection(uuid, "call")
    return

peerVideoClicked = (evnt) ->
    log "peerVideoClicked"
    uuid = getUUIDFromTree(evnt.target)
    log uuid
    webRTC.initiateConnection(uuid, "video")
    return

############################################################
renderChatMessages = ->
    chatHTML = ""
    for cObj in allChatMessages
        chatHTML += M.render(chatTemplate, cObj)
    chatHistoryBlock.innerHTML = chatHTML
    return

############################################################
export displayPeers = (uuids) ->
    peersHTML = ""
    for uuid in uuids
        cObj = {uuid}
        peersHTML += M.render(peerTemplate, cObj)
    peerDisplayBlock.innerHTML = peersHTML

    ownDisplayBlock = peerDisplayBlock.querySelector("[uuid='#{WS.getUUID()}']")
    if ownDisplayBlock? then ownDisplayBlock.classList.add("self")

    callButtons = peerDisplayBlock.getElementsByClassName("peer-call-button")
    btn.addEventListener("click", peerCallClicked) for btn in callButtons

    videoButtons = peerDisplayBlock.getElementsByClassName("peer-video-button")
    btn.addEventListener("click", peerVideoClicked) for btn in videoButtons
    return



export addChatMessage = (message) ->
    log message
    now = new Date()
    hours = "#{now.getHours()}"
    minutes = "#{now.getMinutes()}"
    if hours.length < 2 then hours = "0"+hours
    if minutes.length < 2 then minutes = "0"+minutes
    timeNow = "#{hours}:#{minutes}"
    cObj = {
        text: message
        time: timeNow
    }
    allChatMessages.unshift(cObj)
    if allChatMessages.length > maxMessageNr then allChatMessages.length = maxMessageNr
    log allChatMessages.length
    renderChatMessages()
    return