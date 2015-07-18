

function PlaylistController($scope, $timeout, $q){
  $scope.playlist = playlist;
  $scope.results = []
  $scope.query = "";
  $scope.expandSearch = false;
  var timeoutPromise;

  $scope.Search = function(options) {

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
  		$scope.expandSearch = false
  		$scope.Search();
  	} else {
  		$scope.expandSearch = true
	  	$scope.Search({
	  		types: [type],
	  		next: true
	  	});
	}

  }
}
