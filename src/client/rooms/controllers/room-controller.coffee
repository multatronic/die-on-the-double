angular
    .module 'rooms'
    .controller 'RoomCtrl', [
        '$scope'
        '$stateParams'
        '$log'
        '$rootScope'
        '$mdToast'
        'DataSocket'
        ($scope, $stateParams, $log, $rootScope, $mdToast, DataSocket) ->
            roomId = $stateParams.id
            clientType = 'display'

            DataSocket
                .joinRoom roomId, 'DISPLAY', clientType = clientType

            $rootScope.$on DataSocket.options.events.roomPlayerJoin, (event, data) ->
                $mdToast.showSimple "Player '#{data.player.name}' has joined the room!"

            $rootScope.$on DataSocket.options.events.roomPlayerLeave, (event, data) ->
                $mdToast.showSimple "Player '#{data.player.name}' has left the room!"

            $rootScope.$on DataSocket.options.events.roomDisplayConnect, (event, data) ->
                $mdToast.showSimple "A display was connected."

            $rootScope.$on DataSocket.options.events.roomDisplayDisconnect, (event, data) ->
                $mdToast.showSimple "A display was disconnected."

            # init crafty canvas
            Crafty.init 1800, 800, document.getElementById('crafty-canvas')

            Crafty.sprite 128, "http://craftyjs.com/demos/isometric/images/sprite.png",
                grass: [0,0,1,1],
                stone: [1,0,1,1]


            placeTile = (i, y, z, type) ->
                tile = Crafty.e "2D, DOM, #{type}, Mouse"
                            .attr 'z',i+1 * y+1
                            .areaMap 74,10,138,42,138,106,74,138,10,106,10,42
                            .bind "MouseUp", (e) ->
                                # destroy on right click
                                if e.mouseButton == Crafty.mouseButtons.RIGHT
                                    this.destroy()
                                return
                            .bind "MouseOver", () ->
                                if this.has "grass"
                                    this.sprite 0,1,1,1
                                    return
                                else
                                    this.sprite 1,1,1,1
                                    return
                            .bind "MouseOut", () ->
                                if this.has "grass"
                                    this.sprite 0,0,1,1
                                    return
                                else
                                    this.sprite 1,0,1,1
                                    return

                    iso.place i,y,0,tile
                    return tile

            iso = Crafty.isometric.size 128
            z = 0
            for x in [20...0]
                for y in [0...20]
                    which = Crafty.math.randomInt 0,10
                    type = if which > 5 then "grass" else "stone"
                    placeTile(x, y, z, type)

            # these are dom events (not crafty.js ones) so don't capitalize them
            Crafty.addEvent this, Crafty.stage.elem, "mousedown", (e) ->
                return if e.button > 1
                base = x: e.clientX, y: e.clientY

                scroll = (e) ->
                    dx = base.x - e.clientX
                    dy = base.y - e.clientY
                    base = x: e.clientX, y: e.clientY
                    Crafty.viewport.x -= dx;
                    Crafty.viewport.y -= dy;


                Crafty.addEvent this, Crafty.stage.elem, "mousemove", scroll;
                Crafty.addEvent this, Crafty.stage.elem, "mouseup", () ->
                    Crafty.removeEvent this, Crafty.stage.elem, "mousemove", scroll
    ]
