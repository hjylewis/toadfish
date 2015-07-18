

function PlaylistController($scope){
  $scope.playlist = playlist;
  $scope.results = []
  $scope.query = "";
  $scope.Search = function() {
    search.search($scope.query, {}, function (ret) {
      console.log(ret);
      $scope.results = ret.results;
    });
  }
}
