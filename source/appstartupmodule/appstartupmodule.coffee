############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("appstartupmodule")
#endregion

import * as webRTC from "./webrtcmodule"

############################################################
export startUp = ->
    log "startUp"
    try
        await webRTC.startUp()

    catch err then log err