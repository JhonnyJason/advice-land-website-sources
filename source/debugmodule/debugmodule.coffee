import { addModulesToDebug } from "thingy-debug"

############################################################
export modulesToDebug = 
    unbreaker: true
    # appstartupmodule: true
    # chatframemodule: true
    # configmodule: true
    # peertopeermodule: true
    # statemodule: true
    websocketmodule: true
    # webrtcmodule: true

addModulesToDebug(modulesToDebug)