############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("eventexchangemodule")
#endregion

############################################################
import *  as PeerId from 'peer-id'
import  {Buffer}  from 'buffer'

import * as p2p from "./peertopeermodule.js"
import *  as cfg from "./configmodule.js"

############################################################
channels = {}

class Channel
    constructor: (channelId) ->
        
############################################################
createChannel = (channelId, node) ->
    handlers = {}
    
    topic = "#{cfg.appId}.#{channelId}"

    await node.pubsub.subscribe(topic)
    node.pubsub.on(topic, handler)

    return {
        # echoSelf -> whether we get our own events
        emit: (type, value, echoSelf = true) -> 
            if echoSelf then safeHandle(node.peerId, type, value)
            node.pubsub.publish(topic, new TextEncoder().encode(JSON.stringify({type, value})))
        handle: (type, handler) -> handlers[type] = handler
        id: channelId
    }



############################################################
handleData = (event) ->
    data = null
    type = null
    value = null
    try
        data = JSON.parse(event.data.toString())
        type = data.type
        value = data.value
        if typeof type != "string" then throw new Error("No valid type")
        if typeof value != "object" then throw new Error("No valid value")
    catch error
        console.error("eventexchangemodule.handler readError %s %s %o", topic, error, data)

    safeHandle(PeerId.createFromB58String(msg.from), type, value)



############################################################
export getChannel = (channelId) ->

    if !channels[channelId]? 
        channels[channelId] = await createChannel(channelId, p2p.getNode())

    return channels[channelId]

############################################################
# # API
# - `channel(channelId: String)`: Subscribes to given channel and returns object with following properties
#   - `.handle(type: String, handler: Function)`: Handle event with type using provided function
#     - Function gets called with `(sender: PeerId, value: Object)`
#   - `.emit(type: String, value: Object, echoSelf = true: Boolean)`
#     - `echoSelf`: Emit this event locally aswell
