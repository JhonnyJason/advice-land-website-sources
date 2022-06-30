import { addModulesToDebug } from "thingy-debug"

############################################################
export modulesToDebug = 
    unbreaker: true
    appstartupmodule: true
    # configmodule: true
    peertopeermodule: true
    # statemodule: true


addModulesToDebug(modulesToDebug)