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

                Crafty.trigger 'socket_status_update', data

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
                            entity.craftyEntities[i].attr 'z', 1000
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

                for x in [0...xSize]
                    for y in [0...ySize]
                        for z in [0...zSize]
                            if x == 0
                                placeTile [x, y, z], 'left'
                            if y == 0
                                placeTile [x, y, z], 'right'
                            if z == 0
                                placeTile [x, y, z], 'floor'

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
                       .attr 'z', -1000
                       .attr 'alt', false
                       .bind 'socket_status_update', (e) ->
                          merged = []
                          for entity in e.entities
                            merged = merged.concat entity.positionHistory
                            merged.push entity.position

                          matchesFloor = false
                          matchesLeft = false
                          matchesRight = false
                          isAlt = this.attr 'alt'

                          for updatePosition in merged
                            if updatePosition[0] == position[0] and updatePosition[1] == position[1]
                              matchesFloor = true
                              break
                            if updatePosition[1] == position[1] and updatePosition[2] == position[2]
                              matchesLeft = true
                              break
                            if updatePosition[0] == position[0] and updatePosition[2] == position[2]
                              matchesRight = true
                              break

                          # change the tile to an alternate version if it's on two of the entity's axis'
                          # and flip it back to normal if it's not anymore
                          if this.has 'floor'
                            if matchesFloor
                              if not isAlt
                                this.sprite 5, 0 # floor alt
                                this.attr 'alt', true
                            else if isAlt
                              this.attr 'alt', false
                              this.sprite 2, 0

                          if this.has 'left'
                            if matchesLeft
                              if not isAlt
                                this.sprite 6, 0 # left alt
                                this.attr 'alt', true
                            else if isAlt
                              this.attr 'alt', false
                              this.sprite 3, 0

                          if this.has 'right'
                            if matchesRight
                              if not isAlt
                                this.sprite 7, 0 # right alt
                                this.attr 'alt', true
                            else if isAlt
                              this.attr 'alt', false
                              this.sprite 4, 0

                placeEntity tile, position
                return tile
    ]
