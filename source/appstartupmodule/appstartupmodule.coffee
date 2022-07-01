############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("appstartupmodule")
#endregion

import * as webRTC from "./webrtcmodule"
import * as WS from "./websocketmodule.js"

UUID = crypto.randomUUID()

############################################################
export startUp = ->
    log "startUp"
    log UUID
    try
        WS.sendMessage("setuuid #{UUID}")
        WS.sendMessage("getalluuids")
        await webRTC.startUp()
    catch err then log err