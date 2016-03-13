Meteor
    .startup () ->
        console.log 'Initializing application'

        console.log 'Defining client methods'
        # Meteor
        #     .methods
        #         myMethod: myMethod

        console.log 'Clearing empty rooms'
        Streamy.Rooms.clearEmpty()
