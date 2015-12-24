// npm install -g protractor
// webdriver-manager update
// webdriver-manager start
// protractor conf.js

// conf.js
exports.config = {
  framework: 'jasmine2',
  seleniumAddress: 'http://localhost:4444/wd/hub',
  specs: ['spec/*_spec.js'],
  multiCapabilities: [{
    browserName: 'firefox'
  }, {
    browserName: 'chrome'
  }, {
    browserName: 'safari'
  }]
}