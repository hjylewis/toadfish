var tfAppModule = angular.module('tfApp', ['dndLists'])
	.directive('modalView', function() {
		return {
			restrict: 'C',
			templateUrl: '/modal.html'
		};
	});