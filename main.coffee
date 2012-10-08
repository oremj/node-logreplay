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

class Worker
    constructor: (@master) ->

    preRequest: ->
        @master.requests--

    postRequest: ->
        if @master.requests > 0
            @go()
        else
            @master.workerDone()

    go: ->
        self = @
        @preRequest()
        start =
        stat = {
            'res_time': null,
            'status': null
        }

        options = {
            host: 'addons-dev.allizom.org',
            path: '/media/updater.output.txt'
        }

        req = https.request options, (res) ->
                                res.on 'end', ->
                                    stat.res_time = Date.now() - start
                                    stat.status = res.statusCode
                                    self.master.stats(stat)
                                    self.postRequest()


        req.on 'socket', -> start = Date.now()

        req.end()


class LoadTest
    constructor: (@requests, @pool_size) ->
        @running = 0

    stats: (stat) ->
        @req_stats.push(stat)
        @good_requests++

    workerDone: ->
        @running--
        
        if @running <= 0
            @end()
         
    end: ->
        elapsed_s = (Date.now() - @start) / 1000

        sum = 0
        sum += stat.res_time for stat in @req_stats
        avg_req_time = sum / @good_requests

        console.info("%d conn/s (%d ms/conn)", @good_requests / elapsed_s, avg_req_time)

    run: ->
        @start = Date.now()
        @good_requests = 0
        @req_stats = []

        for i in [0..@pool_size]
            @running++
            w = new Worker(@)
            w.go()
        
        return


l = new LoadTest(requests, pool_size)
l.run()
