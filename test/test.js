var assert = require('assert'),
    webdriverio = require('webdriverio');

// for now just trying to script a full flow for full regression
// obviously this should be broken up into customCommands later

describe('Full integration test', function () {
    var waitForTimeout = 10000;
    this.timeout(99999999);
    var client = {};

    before(function(done){
        client = webdriverio.remote({
            desiredCapabilities: {
                browserName: 'firefox'
            }
        });
        client.init(done);
    });

    it('it should work', function(done) {
        client
            .url(process.env.SALESFORCE_URL)
            .getTitle(function (err, title) {
                assert.equal(title, 'salesforce.com - Customer Secure Login Page');
            })
            .setValue('#username', process.env.SALESFORCE_USERNAME)
            .setValue('#password', process.env.SALESFORCE_PASSWORD)
            .submitForm('#theloginform form')
            
            // click on all tabs for now since we may not show this tab by default
            .waitFor('#AllTab_Tab', waitForTimeout)
            .click('li#AllTab_Tab a')
            .waitFor('#p1', waitForTimeout)

            // TODO: click through calendar and make sure it works

            .call(done);
    });

    after(function(done) {
        client.end(done);
    });

});
