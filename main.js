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

function doRequest(callback) {
    var self = this;
    var start;
    var stats = {
        'res_time': null,
        'status': null
    }
    var req = https.request({host: 'addons-dev.allizom.org',
                             path: '/media/updater.output.txt'}, function(res) {
                    res.on('end', function() {
                        stats.res_time = Date.now() - start;
                        stats.status = res.statusCode;
                        callback(stats);
                    });
              });

    req.on('socket', function() {
        start = Date.now();
    });
    req.end();
}

function next() {
    requests--;
    if(requests < 0) {
        return;
    }
    doRequest(function(stats) {
        console.info("Request took: %dms and returned %s", stats.res_time, stats.status);
        next();
    });
}


for(i=0; i< pool_size; i++) {
    next();
}
