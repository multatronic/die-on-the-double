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
        '$window'
        ($scope, $stateParams, $log, $rootScope, $timeout, $mdToast, DataSocket, $window) ->
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

            # init crafty
            Crafty.init null, null, document.getElementById('crafty-canvas')

            # handle resizing
            angular.element $window
                .bind 'resize', -> correctLevelSizing()

            # Crafty.sprite 128, "sprite.png",
            #     grass: [0,0,1,1],
            #     stone: [1,0,1,1]
            Crafty.sprite 30, 45, "test_sprites_small.png",
                blank: [0, 0]
                player: [1, 0]
                trophy: [2, 0]

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
                    x.destroy() for x in @localEntities[id].craftyEntities
                    delete @localEntities[id]

                # spawn new entities
                for id in newEntityIds
                    # $log.debug 'spawning entity with id', id
                    entity = @remoteEntities[id]
                    @localEntities[id] = entity
                    entity.craftyEntities = []

            updateEntityPositions = () =>
                for id, entity of @localEntities
                    remote = @remoteEntities[id]
                    entity.position = remote.position
                    entity.positionHistory = remote.positionHistory

                    # Iterate over all positions for this entity (positionHistory.length + 1 [primary position])
                    # Ensure we have a crafty entity for each position we need to take up
                    # Correct positions of each crafty entity by index
                    for i in [0 .. entity.positionHistory.length]
                        # Determine position for this entity
                        position = switch i
                            when 0 then entity.position
                            else entity.positionHistory[i - 1]

                        # Ensure entity exists if it doesn't yet
                        if entity.craftyEntities.length < (i + 1)
                            entity.craftyEntities.push (placeTile position, entitySpriteMap[entity.type])
                        # If the entity exists, correct its positioning
                        else
                            placeEntity entity.craftyEntities[i], position

                    # Remove each crafty entity which no is no longer required
                    removed = entity.craftyEntities.splice (entity.positionHistory.length + 1)
                    x.destroy() for x in removed

            initLevel = (levelDimensions) ->
                $log.debug 'Initializing level with dimensions', levelDimensions
                xSize = levelDimensions[0]
                ySize = levelDimensions[1]
                zSize = levelDimensions[2]
                level = Crafty.diamondIso.init 30, 30, xSize, ySize

                for x in [xSize...0] # back to front to prevent overlap
                    for y in [1...ySize + 1]
                        for z in [1...zSize + 1]
                        # for z in [2...zSize + 2]
                            # which = Crafty.math.randomInt 0,10
                            # type = if which > 5 then "grass" else "stone"
                            tile = placeTile [x, y, z], 'blank'

                correctLevelSizing()

            correctLevelSizing = () ->
                Crafty.viewport.init $window.innerWidth, $window.innerHeight - 80, document.getElementById('crafty-canvas')

                if level
                    # @TODO Figure out why we need to do (x / 2) - 2, (y / 2) + 2
                    # in order to center the level properly
                    center = [(level._tiles.length / 2) - 2, (level._tiles[0].length / 2) + 2]
                    level.centerAt center[0], center[1]

            placeEntity = (entity, position) ->
                level.place entity, position[0], position[1], position[2] / 2

            placeTile = (position, type) ->
                tile = Crafty.e "2D, DOM, #{type}, Mouse"
                        # .attr 'z',position[0]+1 * position[1]+1 # graphical layering ordering

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
