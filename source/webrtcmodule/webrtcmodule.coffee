############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("webrtcmodule")
#endregion

############################################################
import *  as chatFrame from "./chatframemodule.js"
import *  as WS from "./websocketmodule.js"

############################################################
uuidToOutConnection = {}
uuidToInConnection = {}

ownMediaStream = null
ownDisplayStream = null


############################################################
export initialize = ->
    log "initialize"
    #Implement or Remove :-)
    return

############################################################
initiateConnectionForCall = (targetUUID) ->
    # log "startICEForCall"
    initiateConnectionForVideo(targetUUID)
    return

initiateConnectionForVideo = (targetUUID) ->
    log "initiateConnectionForVideo"
    conn = createRTCPeerConnection()
    uuidToOutConnection[targetUUID] = conn
    conn.adviceLandType = "outConnection"
    conn.adviceLandUUID = targetUUID

    constraints = {
        video: true
        audio: true
    }

    try
        if !ownMediaStream?
            ownMediaStream = await navigator.mediaDevices.getUserMedia(constraints)
            webCamBlock.srcObject = ownMediaStream
            
        trackList = ownMediaStream.getTracks()
        conn.addTrack(track, ownMediaStream) for track in trackList


        # we can get an audio track as well, when we use a browser tab
        # ownDisplayStream = await navigator.mediaDevices.getDisplayMedia(constraints)
        # desktopCaptureBlock.srcObject = ownDisplayStream
        # desktopCaptureBlock.play()

        # trackList = ownDisplayStream.getTracks()
        # log "ownDisplayStream tracks #{trackList.length}"

        offer = await conn.createOffer()
        descr = new RTCSessionDescription(offer) 
        await conn.setLocalDescription(descr)

        commObj = {
            type: "video-offer"
            sourceUUID: WS.getUUID()
            targetUUID: targetUUID
            offerObj: offer
        }

        commObjString = JSON.stringify(commObj)
        message = "sdp #{targetUUID} #{commObjString}"
        WS.sendMessage(message)
    catch err then log err

    return

############################################################
createRTCPeerConnection = ->
    log "createRTCPeerConnection"
    options = {
        iceServers: [
             {
                 urls: "stun:stun.advice.land"
             }
        ]
    }

    conn = new RTCPeerConnection(options)

    conn.onicecandidate = handleICECandidateEvent
    conn.ontrack = handleTrackEvent
    conn.onnegotiationneeded = handleNegotiationNeededEvent
    conn.onremovetrack = handleRemoveTrackEvent
    conn.oniceconnectionstatechange = handleICEConnectionStateChangeEvent
    conn.onicegatheringstatechange = handleICEGatheringStateChangeEvent
    conn.onsignalingstatechange = handleSignalingStateChangeEvent
    return conn
    
############################################################
#region RTCPeerconnectionEvents
handleICECandidateEvent = (evnt) ->
    log "handleICECandidateEvent"
    # log Object.keys(evnt) # always isTrusted
    olog evnt.candidate
    log evnt.target.adviceLandType
    log evnt.target.adviceLandUUID
    
    return unless evnt.candidate?

    candidate = evnt.candidate
    connType = evnt.target.adviceLandType
    connUUID = evnt.target.adviceLandUUID
    
    commObj = {
        type: "ice-candidate",
        candidate
    }

    if connType == "outConnection" 
        commObj.sourceUUID = WS.getUUID()
        commObj.targetUUID = connUUID
        commObj.youAreTarget = true
    else if connType ==  "inConnection"
        commObj.sourceUUID = connUUID
        commObj.targetUUID = WS.getUUID()

    commObjString = JSON.stringify(commObj)
    message = "sdp #{connUUID} #{commObjString}"
    WS.sendMessage(message)
    return


handleTrackEvent = (evnt) ->
    log "handleTrackEvent"
    # log Object.keys(evnt) # always isTrusted
    incomingVideoStreamsBlock.srcObject = event.streams[0]
    return


handleNegotiationNeededEvent = (evnt) ->
    log "handleNegotiationNeededEvent"
    # log Object.keys(evnt) # always isTrusted

    return


handleRemoveTrackEvent = (evnt) ->
    log "handleRemoveTrackEvent"
    # log Object.keys(evnt) # always isTrusted

    return


handleICEConnectionStateChangeEvent = (evnt) ->
    log "handleICEConnectionStateChangeEvent"
    # log Object.keys(evnt) # always isTrusted

    return


handleICEGatheringStateChangeEvent = (evnt) ->
    log "handleICEGatheringStateChangeEvent"
    # log Object.keys(evnt) # always isTrusted

    return


handleSignalingStateChangeEvent = (evnt) ->
    log "handleSignalingStateChangeEvent"
    # log Object.keys(evnt) # always isTrusted

    return

#endregion


############################################################
export handleSDP = (content) ->
    log "handleSDP"
    try
        commObj = JSON.parse(content)
        # olog commObj

        if commObj.type == "video-offer"
            log "video-offer received"
            constraints = {
                video: true
                audio: true
            }

            sourceUUID = commObj.sourceUUID
            conn = createRTCPeerConnection()

            uuidToInConnection[sourceUUID] = conn
            conn.adviceLandType = "inConnection"
            conn.adviceLandUUID = sourceUUID

            # create RTCSessionDescription
            descr = new RTCSessionDescription(commObj.offerObj) 
            await conn.setRemoteDescription(descr)

            if !ownMediaStream?
                ownMediaStream = await navigator.mediaDevices.getUserMedia(constraints)
                webCamBlock.srcObject = ownMediaStream
                        
            trackList = ownMediaStream.getTracks()
            conn.addTrack(track, ownMediaStream) for track in trackList

            answer = await conn.createAnswer()
            descr = new RTCSessionDescription(answer)
            await conn.setLocalDescription(descr)

            commObj = {
                type: "video-answer"                        
                sourceUUID: commObj.sourceUUID
                targetUUID: commObj.targetUUID
                answerObj: answer
            }

            commObjString = JSON.stringify(commObj)
            message = "sdp #{sourceUUID} #{commObjString}"
            WS.sendMessage(message)

        if commObj.type=="video-answer"
            log "video-answer received"
            targetUUID = commObj.targetUUID
            conn = uuidToOutConnection[targetUUID]

            descr = new RTCSessionDescription(commObj.answerObj)
            await conn.setRemoteDescription(descr)

            log " - > connection should be configured!"

        if commObj.type == "ice-candidate"
            log "ice-candidate received"
            candidateObj = new RTCIceCandidate(commObj.candidate)
            if commObj.youAreTarget then conn = uuidToInConnection[commObj.sourceUUID]
            else conn = uuidToOutConnection[commObj.targetUUID]
            
            await conn.addIceCandidate(candidateObj)
            log " - > added ICE Candidate"

    catch err then log err
    return

export initiateConnection = (targetUUID, mode) ->
    log "initiateConnection"
    switch mode
        when "call" then initiateConnectionForCall(targetUUID)
        when "video" then initiateConnectionForVideo(targetUUID)
    return




