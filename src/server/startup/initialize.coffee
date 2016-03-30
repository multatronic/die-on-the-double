Meteor
    .startup () ->
        console.log 'Initializing application'

        console.log 'Defining client methods'
        # Meteor
        #     .methods
        #         myMethod: myMethod

        console.log 'Removing all outdated rooms'
        Streamy.Rooms.model.remove({})
