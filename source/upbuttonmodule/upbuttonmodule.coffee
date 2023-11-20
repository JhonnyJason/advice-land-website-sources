############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("upbuttonmodule")
#endregion

############################################################
threshold = 500
isShown = false

############################################################
export initialize = ->
    log "initialize"
    document.addEventListener("scroll", onScroll)
    return

############################################################
onScroll = ->
    
    if isShown and document.documentElement.scrollTop < threshold
        isShown = false
        upbutton.classList.remove("shown")
    
    if !isShown and document.documentElement.scrollTop > threshold
        isShown = true
        upbutton.classList.add("shown")

    return
