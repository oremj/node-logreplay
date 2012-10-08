https = require('https')
util = require('util')
Worker = require('./workers').Worker

argv = require('optimist')
        .usage('Usage: $0 -c [concurrent users] -n [num of reqs] -w [num of workers]')
        .demand(['c', 'n', 'w'])
        .argv;


pool_size = argv.c;
requests = argv.n;
workers = argv.w;
https.globalAgent.maxSockets = pool_size * workers;


class LoadTest
    constructor: (@requests, @pool_size, @workers) ->
        @running_workers = []

    stats: (stat) ->
        @req_stats.push(stat)
        @good_requests++

    workerDone: ->
        for w in @running_workers
            if not w.done
                return

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

        for i in [1..@workers]
            w = new Worker(@, @pool_size)
            @running_workers.push w
            w.go()
        
        return


l = new LoadTest(requests, pool_size, workers)
l.run()
