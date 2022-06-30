############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("appstartupmodule")
#endregion

import * as p2p from "./peertopeermodule.js"
import * as chat from "./chatmodule.js"

############################################################
export startUp = ->
    log "startUp"
    try
        await p2p.startUp()
        await chat.startUp()
    catch err then log err