using Toybox.Application;
using Toybox.WatchUi;

class GarminCardsApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state) {
    }

    public function onStop(state) {
    }

    public function getInitialView() {
        var introView = new GarminCardsIntroView();
        return [introView, new GarminCardsIntroDelegate(introView)];
    }

}

function getApp() {
    return Application.getApp();
}
