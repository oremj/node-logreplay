events = require('events')
https = require('https')
util = require('util')

argv = require('optimist')
        .usage('Usage: $0 -c [concurrent users] -n [num of reqs]')
        .demand(['c', 'n'])
        .argv;


pool_size = argv.c;
requests = argv.n;
https.globalAgent.maxSockets = pool_size;


class LoadTest
    constructor: (@requests, @pool_size) ->
        @running = 0

    doRequest: (callback) ->
        start =
        stats = {
            'res_time': null,
            'status': null
        }

        options = {
            host: 'addons-dev.allizom.org',
            path: '/en-US/firefox/'
        }

        req = https.request options, (res) ->
                                res.on 'end', ->
                                    stats.res_time = Date.now() - start
                                    stats.status = res.statusCode
                                    callback(stats)


        req.on('socket', ->
            start = Date.now()
        )

        req.end()
        
    end: ->
        elapsed_s = (Date.now() - @start) / 1000
        console.info("%d Reqs/sec", @good_requests / elapsed_s)

    run: ->
        @start = Date.now()
        @good_requests = 0

        for i in [0..@pool_size]
            @next()

    
    next: ->
        self = @
        if @requests <= 0
            if @running == 0
                @end()
            return

        @requests--
        @running++

        @doRequest((stats) ->
            console.info("Request took: %dms and returned %s", stats.res_time, stats.status)
            self.good_requests++
            self.running--
            self.next()
        )


l = new LoadTest(requests, pool_size)
l.run()