

function PlaylistController($scope, $timeout){
  $scope.playlist = playlist;
  $scope.results = []
  $scope.query = "";
  var timeoutPromise;

  $scope.Search = function() {
    search.search($scope.query, {}, function (ret) {
      console.log(ret);
      $scope.results = ret.results;
    });
  }
  $scope.triggerSearch = function (enter) {
  	$timeout.cancel(timeoutPromise);
  	if (enter) {
  		$scope.Search;
  	} else {
	  	timeoutPromise = $timeout($scope.Search, 500);
  	}
  }
}
