angular
    .module 'rooms'
    .controller 'RoomListCtrl', [
        'RoomFactory'
        (RoomFactory) ->
            @rooms = []

            @loadRoomList = () ->
                @rooms = RoomFactory.getRoomList()
                return

            @loadRoomList()
            return
    ]
