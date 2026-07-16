using Toybox.WatchUi;

class GarminCardsDelegate extends WatchUi.BehaviorDelegate {

    private var _view;

    public function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    public function onNextPage() {
        _view.nextCard();
        return true;
    }

    public function onPreviousPage() {
        _view.previousCard();
        return true;
    }

    public function onSelect() {
        _view.toggleMode();
        return true;
    }

    public function onTap(evt) {
        var coords = evt.getCoordinates();
        if (coords == null || coords.size() < 2) {
            return false;
        }

        return _view.handleTap(coords[0], coords[1]);
    }

    public function onKey(evt) {
        var key = evt.getKey();

        if (key == WatchUi.KEY_DOWN) {
            _view.nextCard();
            return true;
        }

        if (key == WatchUi.KEY_UP) {
            _view.previousCard();
            return true;
        }

        if (key == WatchUi.KEY_ENTER) {
            _view.toggleMode();
            return true;
        }

        return false;
    }

    public function onBack() {
        if (!_view.isFullscreen()) {
            return false;
        }

        _view.exitFullscreen();
        return true;
    }
}
