Rooms = new Mongo.Collection 'room'

if Meteor.isServer
    Rooms.remove {}
