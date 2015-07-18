

function PlaylistController($scope, $timeout, $q, $window){
	$scope.results = [];
	$scope.query = "";
	$scope.expandSearch = null;
	$scope.mode = "playlist";
	var timeoutPromise;

	$scope.Search = function(options) {
		if (!options) {
			$scope.expandSearch = null
		}
		var deferred = $q.defer();
		search.search($scope.query, options, function (ret) {
			deferred.resolve(ret);
		});

		deferred.promise.then(function (ret) {
			if ($scope.query == ret.query) {
				console.log(ret.results);
				$scope.results = ret.results;
			}
		});
	}
	$scope.triggerSearch = function (enter) {
		$timeout.cancel(timeoutPromise);
		if (enter) {
			$scope.Search();
		} else {
		  	timeoutPromise = $timeout($scope.Search, 500);
		}
	}
	$scope.expandResults = function (type) {
		console.log(type);
		if ($scope.expandSearch) {
			$scope.expandSearch = null
			$scope.Search();
		} else {
			$scope.expandSearch = type
		  	$scope.Search({
		  		types: [type],
		  		next: true
		  	});
		}

	}
	$scope.playNow = function (item) {
		playlist.addFirst(item);
	}
	$scope.add = function (item) {
		playlist.add(item);
	}
	angular.element($window).bind("scroll", function() {
	    var windowHeight = "innerHeight" in window ? window.innerHeight : document.documentElement.offsetHeight;
	    var body = document.body, html = document.documentElement;
	    var docHeight = Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight,  html.scrollHeight, html.offsetHeight);
	    windowBottom = windowHeight + window.pageYOffset;
	    if (windowBottom + 5 >= docHeight && $scope.expandSearch) {
	        $scope.Search({
		  		types: [$scope.expandSearch],
		  		next: true
		  	});
	    }
	});
}
