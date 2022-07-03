############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("appstartupmodule")
#endregion

############################################################
export startUp = ->
    log "startUp"
    try
    catch err then log err