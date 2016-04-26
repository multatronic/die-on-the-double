angular
    .module 'rooms'
    .controller 'RoomCtrl', [
        '$scope'
        '$stateParams'
        '$log'
        '$rootScope'
        '$timeout'
        '$mdToast'
        'DataSocket'
        ($scope, $stateParams, $log, $rootScope, $timeout, $mdToast, DataSocket) ->
            roomId = $stateParams.id
            clientType = 'display'
            level = null
            @remoteEntities = {}
            @localEntities = {}

            $timeout () ->
                DataSocket.sendClientInfo 'DISPLAY', clientType = clientType
                DataSocket.joinRoom roomId
            , 250

            $rootScope.$on DataSocket.options.events.roomPlayerJoin, (event, data) ->
                $mdToast.showSimple "Player '#{data.client.name}' has joined the room!"

            $rootScope.$on DataSocket.options.events.roomPlayerLeave, (event, data) ->
                $mdToast.showSimple "Player '#{data.client.name}' has left the room!"

            $rootScope.$on DataSocket.options.events.roomDisplayConnect, (event, data) ->
                $mdToast.showSimple "A display was connected."

            $rootScope.$on DataSocket.options.events.roomDisplayDisconnect, (event, data) ->
                $mdToast.showSimple "A display was disconnected."

            $rootScope.$on 'data_socket.events.status_update', (event, data) =>
                if level == null
                    initLevel data.level.size

                @remoteEntities = {}
                for remoteEntity in data.entities
                    @remoteEntities[remoteEntity.id] = remoteEntity

                spawnEntities()
                updateEntityPositions()

            # init crafty canvas
            Crafty.init 1800, 800, document.getElementById('crafty-canvas')

            # Crafty.sprite 128, "sprite.png",
            #     grass: [0,0,1,1],
            #     stone: [1,0,1,1]
            Crafty.sprite "test_sprites.png",
                blank: [0, 0, 130, 198]
                player: [131, 0, 130, 198]
                trophy: [261, 0, 130, 198]

            entitySpriteMap =
                AppleEntity: 'trophy'
                SnakeEntity: 'player'

            diffObjectKeys = (a, b) ->
                keysA = Object.keys(a)
                keysB = Object.keys(b)
                keysA.filter (i) ->
                    keysB.indexOf(i) < 0

            selectEntitiesByType = (entities, type) ->
                entities.filter (current) ->
                    current.type == type

            spawnEntities = () =>
                oldEntityIds = diffObjectKeys @localEntities, @remoteEntities
                newEntityIds = diffObjectKeys @remoteEntities, @localEntities

                # cleanup deprecated entities
                for id in oldEntityIds
                    @localEntities[id].craftyEntity.destroy()
                    delete @localEntities[id]

                # spawn new entities
                for id in newEntityIds
                    # $log.debug 'spawning entity with id', id
                    remoteEntity = @remoteEntities[id]
                    @localEntities[id] = remoteEntity
                    @localEntities[id].craftyEntity = placeTile remoteEntity.position, entitySpriteMap[remoteEntity.type]

            updateEntityPositions = () =>
                for id, entity of @localEntities
                    # grab id in remote and update position
                    remote = @remoteEntities[id]
                    entity.position = remote.position
                    entity.positionHistory = remote.positionHistory
                    # $log.debug 'here:', entity.craftyEntity
                    placeEntity entity.craftyEntity, entity.position

            initLevel = (levelDimensions) ->
                $log.debug 'Initializing level with dimensions', levelDimensions
                xSize = levelDimensions[0]
                ySize = levelDimensions[1]
                zSize = levelDimensions[2]
                level = Crafty.diamondIso.init 130, 130, xSize, ySize

                for x in [xSize...0] # back to front to prevent overlap
                    for y in [1...ySize + 1]
                        for z in [2...zSize + 2]
                            # which = Crafty.math.randomInt 0,10
                            # type = if which > 5 then "grass" else "stone"
                            tile = placeTile [x, y, z], 'blank'

                        # tile.bind "MouseUp", (e) ->
                        #     # when a tile is clicked stack a block on top of it
                        #     if e.mouseButton == Crafty.mouseButtons.LEFT
                        #         placeTile([this.gridX, this.gridY, this.gridZ + 2], 'stone')
                        #     return

                        # construct the back wall of the level (temp. disabled)
                        # if y == 0
                        #     for zs in [1...zSize]
                        #         $log.debug 'placing at',x,y,zs
                        #         tile = placeTile(x, y, zs, 'stone')
                        #         tile.attr 'z', x+1  * y+1 + 10

            placeEntity = (entity, position) ->
                level.place entity, position[0], position[1], position[2] / 2

            placeTile = (position, type) ->
                tile = Crafty.e "2D, DOM, #{type}, Mouse"
                            .attr 'gridX', position[0]
                            .attr 'gridY', position[1]
                            .attr 'gridZ', position[2]
                            .attr 'z',position[0]+1 * position[1]+1 # graphical layering ordering
                            # .areaMap 74,10,138,42,138,106,74,138,10,106,10,42
                            # .bind "MouseUp", (e) ->
                            #     # destroy on right click
                            #     if e.mouseButton == Crafty.mouseButtons.RIGHT
                            #         this.destroy()
                            #     return
                # x = position[0]
                # y = position[1]
                # z = position[2]
                # tile = Crafty.e "2D, DOM, #{type}, Mouse"
                #             .attr 'gridX', x
                #             .attr 'gridY', y
                #             .attr 'gridZ', z
                #             .attr 'z',x+1 * y+1 # graphical layering ordering
                #             .areaMap 74,10,138,42,138,106,74,138,10,106,10,42
                #             .bind "MouseUp", (e) ->
                #                 # destroy on right click
                #                 if e.mouseButton == Crafty.mouseButtons.RIGHT
                #                     this.destroy()
                #                 return
                            # .bind "MouseOver", () ->
                            #     if this.has "grass"
                            #         this.sprite 0,1,1,1
                            #         return
                            #     else
                            #         this.sprite 1,1,1,1
                            #         return
                            # .bind "MouseOut", () ->
                            #     if this.has "grass"
                            #         this.sprite 0,0,1,1
                            #         return
                            #     else
                            #         this.sprite 1,0,1,1
                            #         return

                placeEntity tile, position
                return tile

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
