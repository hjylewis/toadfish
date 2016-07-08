var tfAppModule = angular.module('tfApp', ['dndLists'])
	.directive('modalView', function() {
		return {
			restrict: 'C',
			templateUrl: '/modal.html'
		};
	})
	.config(['$compileProvider', function ($compileProvider) {
		$compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|ftp|file|blob):|data:image\//);
	}]);
