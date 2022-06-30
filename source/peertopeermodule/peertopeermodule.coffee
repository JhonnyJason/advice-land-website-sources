############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("peertopeermodule")
#endregion

############################################################
#region funnyFix
# # NOISE tries to access process.env.DUMP_SESSION_KEYS, just hack it in
# if !window.process?
#     window.process = {
#         env: {}
#         nextTick: (f, a...) ->
#             c = ->
#                 f(a...)
#             setTimeout(c, 1)
#     }

# if (require './debugmodule').modulesToDebug["peertopeermodule"]
#   require('debug').save('*')
# else
#   require('debug').save('')

#endregion

############################################################
# Libp2p = require('libp2p')
# WStar = require('libp2p-webrtc-star')
# WebSockets = require('libp2p-websockets')
# { NOISE } = require('libp2p-noise')
# MPLEX = require('libp2p-mplex')
# PeerId = require('peer-id')
# Bootstrap = require('libp2p-bootstrap')
# GossipSub = require('libp2p-gossipsub')
# TransportManager = require('libp2p/src/transport-manager')

# { Buffer } = require('buffer')

import { createLibp2p } from 'libp2p'
import { WebRTCStar } from '@libp2p/webrtc-star'
import { WebSockets } from '@libp2p/websockets'
import { Noise } from '@chainsafe/libp2p-noise'
import { Mplex } from '@libp2p/mplex'
import { Bootstrap } from '@libp2p/bootstrap'

import { GossipSub } from '@chainsafe/libp2p-gossipsub'

# import { createFromPrivKey } from '@libp2p/peer-id-factory'
# import { marshalPrivateKey, unmarshalPrivateKey } from '@libp2p/crypto/keys'

# import *  as Libp2p from 'libp2p'
# import * as WStar from'libp2p-webrtc-star'
# import * as WebSockets from 'libp2p-websockets'
# import { NOISE } from 'libp2p-noise'
# import *  as MPLEX from 'libp2p-mplex'
# import *  as PeerId from 'peer-id'
# import *  as Bootstrap from 'libp2p-bootstrap'
# import * as GossipSub from 'libp2p-gossipsub'
# import * as TransportManager from 'libp2p/src/transport-manager'

# import { Buffer } from 'buffer'

import *  as S from "./statemodule.js"

############################################################
node = null
gossipLayer = null

############################################################
export initialize = ->
    log "initialize"
    c = allModules.configmodule
    
    # privateKeyMarshalled = S.load("privateKeyMarshalled")
    # olog { privateKeyMarshalled }

    # if privateKeyMarshalled
    #     privateKeyMarshalled = new Uint8Array(privateKeyMarshalled)
    #     privateKey = await unmarshalPrivateKey(privateKeyMarshalled)
    #     peerId = await createFromPrivKey(privateKey)
    # else peerId = undefined


    # if !peerIdObject then peerIdObject = await create(keyType:"Ed25519") 
    # olog { peerIdObject }
    # peerId = await createFromJSON(peerIdObject)
    # S.save("peerIdObject", peerIdObject)
    # peerId = await createEd25519PeerId()
    # olog peerId
    # log Object.keys(peerId)
        
    
    # createPeerId
    # peerIdStorage = localStorage.getItem('libp2pPeerId')

    # if not peerIdStorage
    #     peerId = await PeerId.create()
    #     peerIdStorage = Buffer.from(peerId.marshal(false)).toString('hex')
    #     localStorage.setItem('libp2pPeerId', peerIdStorage)
    # else
    #     peerId = await PeerId.createFromProtobuf(Buffer.from(peerIdStorage, 'hex'))

    # p2pConfig = allModules.configmodule.p2p || {}
    bootstrapPeers = c.p2pBootstrapPeers
    wRTCStarServers = c.p2pWRTCStarServers

    webSocketsHandle = new WebSockets()  
    webRtcStarHandle = new WebRTCStar()
    noiseHandle = new Noise()
    mplexHandle = new Mplex()
    bootstrapHandle = new Bootstrap({ list: bootstrapPeers })

    gossipOptions = {
        emitSelf: false, # default
        gossipIncoming: true, # default
        fallbackToFloodsub: false, # default is true
        floodPublish: true, # default
        doPX: true,  # default is false
        msgIdFn: (msg) -> msg.from + msg.seqno.toString('hex'), # default
        signMessages: true, # default
        strictSigning: true # default
        # scoreParams: optional
        # scoreThresholds: optional
        # directPeers: optional
    }

    gossipHandle = new GossipSub(gossipOptions)


    options = {
        peerId
        # peerId: peerIdObject
        addresses: {
        # Add the signaling server address, along with our PeerId to our multiaddrs list
        # libp2p will automatically attempt to dial to the signaling server so that it can
        # receive inbound connections from other peers
            listen: wRTCStarServers
        },
        transports: [webSocketsHandle, webRtcStarHandle]
        connectionEncryption: [noiseHandle]
        streamMuxers: [mplexHandle]
        peerDiscovery: [
            webRtcStarHandle.discovery
            # bootstrapHandle
        ],
        transportManager:{
            autoDial: true, # Auto connect to discovered peers (limited by ConnectionManager minConnections)
            # The `tag` property will be searched when creating the instance of your Peer Discovery service.
            # The associated object, will be passed to the service when it is instantiated.
        },
        pubsub: gossipHandle
    }

    node = await createLibp2p(options)



    # options = {
    #     peerId
    #     modules:
    #         transport: [new WebSockets()]
    #         connectionEncryption: [new Noise()]
    #         streamMuxers: [new Mplex()]
    #         # transport: [WebSockets, WStar]
    #         # connEncryption: [NOISE]
    #         # streamMuxer: [MPLEX]
    #     #     pubsub: GossipSub
    #     # addresses:
    #     #     listen: p2pConfig.listenAddrs || []
    #     # transportManager:
    #     #     faultTolerance: TransportManager.FaultTolerance.NO_FATAL
    #     # config:
    #     #     # pubsub:
    #     #     #     enabled: true
    #     #     #     emitSelf: false
    #     #     peerDiscovery:
    #     #         autoDial: true
    #     #         "#{Bootstrap.tag}":
    #     #             enabled: true
    #     #             list: p2pConfig.bootstrapPeers || []

    # }

    # node = new Libp2p(options)
    # await node.start()

    # debugging and stuff
    # window.p2p = node

    ####### inexplainably does not work!
    # node.on('peer:discovery', discoveredPeer)
    # node.connectionManager.on('peer:disconnect', renderPeers)
    # node.connectionManager.on('peer:connect', renderPeers)
    
    node.addEventListener('peer:discovery', discoveredPeer)
    node.connectionManager.addEventListener('peer:connect', renderPeers)
    node.connectionManager.addEventListener('peer:disconnect', renderPeers)
    
    # gossipLayer.
    
    log Object.keys(node)
    # olog node.peerId
    
    peerId = node.peerId
    setText('myid', peerId.toString())
    # olog peerId.privateKey

    # peerIdHex = peerId.toString("hex")
    # log peerIdHex
    # S.save({peerIdHex})
    # privateKeyMarshalled = await marshalPrivateKey(peerId.privateKey)
    # privateKeyMarshalled = peerId.privateKey.marshal()

    # olog { privateKeyMarshalled }
    # S.save("privateKeyMarshalled", privateKeyMarshalled)
    return

############################################################
discoveredPeer = (peer) ->
    # olog peer
    # log('Discovered %s', peer.id.toB58String())
    return

setText = (id, val) ->
    # safety first
    tnode = document.createTextNode(val)
    elem = document.getElementById('p2p-' + id)
    elem.innerHTML = ''
    elem.appendChild tnode
    return

renderPeers = ->
    elem = document.getElementById 'p2p-peers'
    elem.innerHTML = ''

    node.connectionManager.connections.forEach (conns, id) ->
        conns.forEach (conn) ->
            p = document.createElement('p')
            p.appendChild (
                document.createTextNode conn.remoteAddr.toString()
            )
            elem.appendChild p
    return

############################################################
export getNode = ->
    # TODO: return promise that will resolve to node        
    if !node then throw new Error('node was not set up yet!')
    return node

export startUp = ->
    await node.start()
    # await gossipLayer.start()
    # await node.start()
    # log('listening on addresses:')
    # node.getMultiaddrs().forEach((addr) -> log(addr.toString()))
    return

