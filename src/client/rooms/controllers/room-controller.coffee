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

            @init = (element) ->
                PI      = Math.PI
                scene   = new voxelcss.Scene()
                # lightSource = new voxelcss.LightSource 300, 300, 300, 750, 0.3, 1
                world       = new voxelcss.World scene
                editor      = new voxelcss.Editor world

                scene.rotate -PI / 8, PI / 4, 0
                scene.attach element
                # scene.addLightSource lightSource

                editor.enableAutoSave()
                editor.load()

                if world.getVoxels().length == 0
                    editor
                        .add new voxelcss.Voxel 0, 0, 0, 100,
                            mesh: voxelcss.Meshes.grass

            @init document.getElementById 'voxel_canvas';
            return
    ]
