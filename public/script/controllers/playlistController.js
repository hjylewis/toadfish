

function PlaylistController($scope, $timeout, $q, $window, $document){
	$scope.results = [];
	$scope.query = "";
	$scope.expandSearch = null;
	$scope.mode = "playlist";
	$scope.isLoading = true;
	$scope.volumeShow = false;
	$scope.viewModal = false;
	$scope.firstModal = true;
	$scope.rdio_user = null;
	$scope.from = {
		index: null
	};

	if (host) {
		$scope.playlist = new Playlist();
	} else {
		$scope.playlist = new Playlist(playlistSettings.currentIndex, playlistSettings.playlist, playlistSettings.volume, playlistSettings.state)
		$scope.isLoading = false;
	}
	$scope.playerColor = {'background-color': 'rgba(0,0,0,0.5)'}
	var timeoutPromise;

	$scope.Search = function(options) {
		$scope.isSearchLoading = true;
		if (!options) {
			$scope.expandSearch = null
		}
		var deferred = $q.defer();
		search.search($scope.query, options, function (ret) {
			deferred.resolve(ret);
		});

		deferred.promise.then(function (ret) {
			if ($scope.query == ret.query) {
				$scope.results = ret.results;
				$scope.isSearchLoading = false;
			}
		});
	}
	$scope.triggerSearch = function (enter) {
		if ($scope.query.length > 0) {
			$scope.mode = "search";
		} else {
			$scope.mode = "playlist";
		}
		$timeout.cancel(timeoutPromise);
		if (enter) {
			$scope.Search();
		} else {
		  	timeoutPromise = $timeout($scope.Search, 500);
		}
	}
	$scope.expandResults = function (type) {
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
		var playlist = $scope.playlist.playlist

		for (var i = 0; i < playlist.length; i++) {
			if (playlist[i].song_details.id === item.id) {
				$scope.playlist.goTo(i);
				$scope.mode = "playlist";
				return;
			}
		};

		$scope.playlist.addFirst(item);
		$scope.mode = "playlist";
	}
	$scope.add = function (item) {
		$scope.playlist.add(item);
		$scope.mode = "playlist";
	}

	$scope.addAutoplay = function () {
		$scope.playlist.add($scope.playlist.autoplay);
	}

	$scope.play = function () {
		if ($scope.playlist.state == 1) {
			$scope.playlist.pause();
		} else if ($scope.playlist.state == 2) {
			$scope.playlist.play();
		}
	}
	$scope.next = function () {
		$scope.playlist.next();
	}
	$scope.prev = function () {
		$scope.playlist.prev();
	}
	$scope.seek = function (e) {
		var el = angular.element(document.getElementById('seekbar'))[0];
	    var x = e.pageX - (el.offsetLeft || e.offsetX)
	        clickedValue = x * 100 / el.clientWidth
    	$scope.playlist.seek(clickedValue);
	}
	$scope.remove = function (index, e) {
		e.stopPropagation();
		$scope.playlist.remove(index);
	}
	$scope.stopPropagation = function (e) {
		e.stopPropagation();
	}
	$scope.openModal = function (e) {
		e.stopPropagation();
		$scope.viewModal = true;
		$scope.firstModal = false;
	}
	$scope.changeColor = function(enter) {
		if (enter && $scope.mode == "search") {
			$scope.playerColor = {'background-color': 'rgba(0,0,0,0.8)'}
		} else {
			$scope.playerColor = {'background-color': 'rgba(0,0,0,0.5)'}
		}
	}

	$scope.dropCallback = function(to, item) {
		var from = $scope.from.index
		if (from < to)
			to = to - 1
		$scope.playlist.move(from, to);
        return false;
    };

    $scope.shortcut = function (e) {

  		if (e.keyCode == 27) {
			if ($scope.viewModal){
				$scope.viewModal = false;
				return
			} 
			if ($scope.mode == "search") {
				$scope.query = "";
				$scope.mode = "playlist";
				return
			}
		}

    	// if search bar is focused
    	if (document.activeElement.id === 'first_search') {
    		return
    	}

    	if (e.keyCode == 32) {
    		$scope.play();
    	} else if (e.keyCode == 39) {
			$scope.next();
    	} else if (e.keyCode == 37) {
			$scope.prev();
    	}
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
