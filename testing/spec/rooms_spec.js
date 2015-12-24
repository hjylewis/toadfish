describe('Rooms', function() {
	var rand = Math.floor(Math.random() * 99999);
	it('should be created using name', function() {
		browser.get('http://localhost:8000/');
		element(by.id('createRoomName')).sendKeys(rand);
		element.all(by.css('.launch-button')).first().click();
		browser.sleep(1000).then(function () {
			expect(browser.getTitle()).toEqual(rand + " | Toadfish Room");
			expect(browser.getCurrentUrl()).toEqual('http://localhost:8000/host/'+rand);
		});
	});
	it('should fail when using the same name', function() {
		browser.get('http://localhost:8000/');
		element(by.id('createRoomName')).sendKeys(rand);
		element.all(by.css('.launch-button')).first().click();
		browser.sleep(1000).then(function () {
			expect(element(by.id('createWarning')).isDisplayed()).toEqual(true);
		});
	});
	it('should redirect to host room', function() {
		browser.get('http://localhost:8000/'+rand);
		expect(browser.getCurrentUrl()).toEqual('http://localhost:8000/host/'+rand);
	});
	it('should create a room without a name', function() {
		browser.get('http://localhost:8000/');
		element.all(by.css('.launch-button')).first().click();
		browser.sleep(1000).then(function () {
			expect(browser.getTitle()).toEqual("Toadfish Room");
		});
	});
});