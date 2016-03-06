# Collections
Messages = new Mongo.Collection 'messages'
Nodes = new Mongo.Collection 'nodes'
# --

if Meteor.isClient
    console.log 'Loading application'

if Meteor.isServer
    # Helpers
    toType = (obj) ->
        return ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()

    getSetting = (key, def = null) ->
        setting = Meteor.settings[key]

        if (setting != null) and (setting != undefined)
            return setting

        return def
    # --
