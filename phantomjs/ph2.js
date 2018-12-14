"use strict";
var page = require('webpage').create();
var args = require('system').args;
var address = args[1];
page.settings.userAgent = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0';
page.open(address, function (status) {
    if (status !== 'success') {
        console.log('Unable to load the address!');
        phantom.exit();
    } else {
        window.setTimeout(function () {
            //page.render(output);
	    console.log(page.content)
            phantom.exit();
        }, 1000); // Change timeout as required to allow sufficient time 
    }
});
