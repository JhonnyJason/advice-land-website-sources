indexdomconnect = {name: "indexdomconnect"}

############################################################
indexdomconnect.initialize = () ->
    global.chat = document.getElementById("chat")
    global.chatMessages = document.getElementById("chat-messages")
    global.chatForm = document.getElementById("chat-form")
    global.chatInput = document.getElementById("chat-input")
    return
    
module.exports = indexdomconnect