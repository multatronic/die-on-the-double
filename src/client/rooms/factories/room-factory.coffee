angular
    .module 'rooms'
    .factory 'RoomFactory', [
        '$log'
        ($log) ->
            @getRoomList = () ->
                Rooms.find()
            return this
    ]
