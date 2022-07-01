indexdomconnect = {name: "indexdomconnect"}

############################################################
indexdomconnect.initialize = () ->
    global.chatframe = document.getElementById("chatframe")
    global.chatHistoryBlock = document.getElementById("chat-history-block")
    global.peerDisplayBlock = document.getElementById("peer-display-block")
    global.chatInput = document.getElementById("chat-input")
    global.peerDisplayTemplate = document.getElementById("peer-display-template")
    global.chatElementTemplate = document.getElementById("chat-element-template")
    return
    
module.exports = indexdomconnect