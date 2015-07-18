

function PlaylistController($scope, $timeout, $q){
  $scope.playlist = playlist;
  $scope.results = []
  $scope.query = "";
  var timeoutPromise;

  $scope.Search = function() {

  	var deferred = $q.defer();
	search.search($scope.query, {}, function (ret) {
		deferred.resolve(ret);
    });

    deferred.promise.then(function (ret) {
      if ($scope.query = ret.query) {
	      $scope.results = ret.results;
      }
    });
  }
  $scope.triggerSearch = function (enter) {
  	$timeout.cancel(timeoutPromise);
  	if (enter) {
  		$scope.Search;
  	} else {
  		console.log("HERE")
	  	timeoutPromise = $timeout($scope.Search, 500);
  	}
  }
}
