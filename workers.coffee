https = require('https')

class Worker
    constructor: (@master, @concurrency) ->
        @running = 0
        @done = false

    preRequest: ->
        @master.requests--

    postRequest: (stat) ->
        @master.stats(stat)
        if @master.requests > 0
            @loop()
        else
            @running--
            if @running <= 0
                @done = true
                @master.workerDone()

    go: ->
        for i in [1..@concurrency]
            @running++
            @loop()

        return

    loop: ->
        @preRequest()
        start =
        stat = {
            'res_time': null,
            'status': null
        }

        options = {
            host: 'addons.allizom.org',
            path: '/en-US/firefox/'
        }
        req = https.request options, (res) =>
                                res.on 'end', =>
                                    stat.res_time = Date.now() - start
                                    stat.status = res.statusCode
                                    @postRequest(stat)


        req.on 'socket', -> start = Date.now()

        req.end()


exports.Worker = Worker
