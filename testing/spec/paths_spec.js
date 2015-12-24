describe('Toadfish', function() {
  it('should load the homepage', function() {
    browser.get('http://localhost:8000/');
	expect(browser.getTitle()).toEqual('Toadfish');
  });
});