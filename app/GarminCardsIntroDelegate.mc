using Toybox.WatchUi;

class GarminCardsIntroDelegate extends WatchUi.BehaviorDelegate {
    private var _view;

    public function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    public function onSelect() {
        _view.goToMainView();
        return true;
    }

    public function onTap(evt) {
        _view.goToMainView();
        return true;
    }

    public function onKey(evt) {
        _view.goToMainView();
        return true;
    }

    public function onBack() {
        _view.goToMainView();
        return true;
    }
}
