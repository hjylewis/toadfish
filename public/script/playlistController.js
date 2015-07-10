

function PlaylistController($scope){
  $scope.playlist = playlist;
  $scope.results = []
  $scope.query = "";
  $scope.Search = function() {
    search($scope.query, {}, function (results) {
      console.log(results);
      $scope.results = results;
    });
  }
}
