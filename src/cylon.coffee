###
 * cylon
 * cylonjs.com
 *
 * Copyright (c) 2013 The Hybrid Group
 * Licensed under the Apache 2.0 license.
###

'use strict';

Robot = require("./robot")

require('./utils')
require('./logger')
require('./api')

readLine = require "readline"

Logger.setup()

# Cylon is the global namespace for the project, and also in charge of
# maintaining the Master singleton that controls all the robots.
class Cylon
  instance = null

  # Public: Fetches singleton instance of Master, or creates a new one if it
  # doesn't already exist
  #
  # Returns a Master instance
  @getInstance: (args...) ->
    instance ?= new Master(args...)

  # The Master class is our puppeteer that manages all the robots, as well as
  # starting them and the API.
  class Master
    robots = []
    api = null
    api_config = { host: '127.0.0.1', port: '3000' }

    # Public: Creates a new Master
    #
    # Returns a Master instance
    constructor: ->
      @self = this
      if process.platform is "win32"
        rl = readLine.createInterface
          input: process.stdin
          output: process.stdout

        rl.on "SIGINT", ->
          process.emit "SIGINT"

      process.on "SIGINT", ->
        Cylon.getInstance().stop()
        process.exit()

    # Public: Creates a new Robot
    #
    # opts - hash of Robot attributes
    #
    # Returns a shiny new Robot
    # Examples:
    #   Cylon.robot
    #     connection: { name: 'arduino', adaptor: 'firmata' }
    #     device: { name: 'led', driver: 'led', pin: 13 }
    #
    #     work: (me) ->
    #       me.led.toggle()
    robot: (opts) =>
      opts.master = this
      robot = new Robot(opts)
      robots.push robot
      robot

    # Public: Returns all Robots the Master knows about
    #
    # Returns an array of all Robot instances
    robots: -> robots

    # Public: Configures the API host and port based on passed options
    #
    # opts - object containing API options
    #   host - host address API should serve from
    #   port - port API should listen for requests on
    #
    # Returns the API configuration
    api: (opts) ->
      api_config.host = opts.host || "127.0.0.1"
      api_config.port = opts.port || "3000"
      api_config

    # Public: Finds a particular robot by name
    #
    # name - name of the robot to find
    # callback - optional callback to be executed
    #
    # Returns the found Robot or result of the callback if it's supplied
    findRobot: (name, callback) ->
      robot = null
      for bot in robots
        robot = bot if bot.name is name

      error = { error: "No Robot found with the name #{name}" } unless robot?

      if callback then callback(error, robot) else robot

    # Public: Finds a particular Robot's device by name
    #
    # robotid - name of the robot to find
    # deviceid - name of the device to find
    # callback - optional callback to be executed
    #
    # Returns the found Device or result of the callback if it's supplied
    findRobotDevice: (robotid, deviceid, callback) ->
      @findRobot robotid, (err, robot) ->
        callback(err, robot) if err

        device = robot.devices[deviceid] if robot.devices[deviceid]
        unless device?
          error = { error: "No device found with the name #{device}." }

        if callback then callback(error, device) else device

    # Public: Finds a particular Robot's connection by name
    #
    # robotid - name of the robot to find
    # connid - name of the device to find
    # callback - optional callback to be executed
    #
    # Returns the found Connection or result of the callback if it's supplied
    findRobotConnection: (robotid, connid, callback) ->
      @findRobot robotid, (err, robot) ->
        callback(err, robot) if err

        connection = robot.connections[connid] if robot.connections[connid]
        unless connection?
          error = { error: "No connection found with the name #{connection}." }

        if callback then callback(error, connection) else connection

    # Public: Starts up the API and the robots
    #
    # Returns nothing
    start: ->
      do @startAPI
      robot.start() for robot in robots


    # Public: Stops the API and the robots
    #
    # Returns nothing
    stop: ->
      #do @stopAPI
      robot.stop() for robot in robots


    # Creates a new instance of the Cylon API server, or returns the
    # already-existing one.
    #
    # Returns an Api.Server instance
    startAPI: ->
      api_config.master = @self
      api ?= new Api.Server(api_config)

module.exports = Cylon.getInstance()
