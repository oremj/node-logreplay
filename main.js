var events = require('events');
var https = require('https');
var util = require('util');

var argv = require('optimist')
            .usage('Usage: $0 -c [concurrent users] -n [num of reqs]')
            .demand(['c', 'n'])
            .argv;


var pool_size = argv.c;
var requests = argv.n;
https.globalAgent.maxSockets = pool_size;

function LoadTest(requests, pool_size) {
    var self = this;
    self.requests = requests;
    self.pool_size = pool_size;
    self.running = 0;
}

LoadTest.prototype.doRequest = function(callBack) {
    var start;
    var stats = {
        'res_time': null,
        'status': null
    }
    var req = https.request({host: 'addons-dev.allizom.org',
                             path: '/en-US/firefox/'}, function(res) {
                    res.on('end', function() {
                        stats.res_time = Date.now() - start;
                        stats.status = res.statusCode;
                        callBack(stats);
                    });
              });

    req.on('socket', function() {
        start = Date.now();
    });
    req.end();
}

LoadTest.prototype.end = function() {
    elapsed_s = (Date.now() - this.start) / 1000;
    console.info("%d Reqs/sec", this.good_requests / elapsed_s);
}

LoadTest.prototype.run = function() {
    this.start = Date.now();
    this.good_requests = 0;

    for(i=0; i < this.pool_size; i++) {
        this.next();
    }
}

LoadTest.prototype.next = function() {
    var self = this;
    if(self.requests <= 0) {
        if(self.running == 0) {
            self.end();
        }
        return;
    }

    self.requests--;
    self.running++;
    self.doRequest(function(stats) {
        console.info("Request took: %dms and returned %s", stats.res_time, stats.status);
        self.good_requests++;
        self.running--;
        self.next();
    });
}

l = new LoadTest(requests, pool_size);
l.run();
