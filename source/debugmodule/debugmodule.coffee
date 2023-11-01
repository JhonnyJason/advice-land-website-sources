import { addModulesToDebug } from "thingy-debug"

############################################################
export modulesToDebug = 
    unbreaker: true
    # appstartupmodule: true
    # configmodule: true
    # statemodule: true

addModulesToDebug(modulesToDebug)