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

                Crafty.trigger 'socket_status_update', data

                @remoteEntities = {}
                for remoteEntity in data.entities
                    @remoteEntities[remoteEntity.id] = remoteEntity

                spawnEntities()
                updateEntityPositions()

            # init crafty canvas
            Crafty.init null, null, document.getElementById('crafty-canvas')

            Crafty.sprite 30, 45, "test_sprites_small_exploded.png",
                player: [0, 0]
                trophy: [1, 0],
                floor: [2, 0],
                left: [3, 0],
                right: [4, 0],
                floor_alt: [5, 0],
                left_alt: [6, 0],
                right_alt: [7, 0]

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
                level = Crafty.diamondIso.init 30, 30, xSize, ySize

                # using zSize + 1 here breaks the apple grabbing for some reason?
                for x in [xSize...0] # back to front to prevent overlap
                    for y in [1...ySize + 1]
                        for z in [2...zSize + 2]
                            if x == 1
                                placeTile [x, y, z], 'left'
                            if y == 1
                                placeTile [x, y, z], 'right'
                            if z == 2
                                placeTile [x, y, z], 'floor'

                            # tile = placeTile [x, y, z], 'floor'

                # center viewport middle of level
                centerX = parseInt xSize/2
                centerY = parseInt ySize/2
                $log.debug 'centering viewport at', centerX, centerY
                level.centerAt centerX, centerY

            placeEntity = (entity, position) ->
                level.place entity, position[0], position[1], position[2] / 2

            placeTile = (position, type) ->
                tile = Crafty.e "2D, DOM, #{type}, Mouse"
                       .attr 'z', 0
                       .bind 'socket_status_update', (e) ->
                          updatePosition = e.entities[0].position
                          if updatePosition[0] == position[0] and updatePosition[1] == position[1] and this.has 'floor'
                            this.sprite 5, 0
                          if updatePosition[1] == position[1] and updatePosition[2] == position[2] and this.has 'left'
                            $log.debug 'left alt', e.entities[0].position, position
                            this.sprite 6, 0
                          if updatePosition[0] == position[0] and updatePosition[2] == position[2] and this.has 'right'
                            this.sprite 7, 0

                placeEntity tile, position
                return tile
    ]
