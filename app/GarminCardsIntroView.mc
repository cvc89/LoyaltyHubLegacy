using Toybox.Graphics;
using Toybox.WatchUi;

class GarminCardsIntroView extends WatchUi.View {
    private var _cards = [];
    private var _introFramesRemaining = 2;
    private var _switchPending = false;
    private var _transitioned = false;

    public function initialize() {
        View.initialize();
    }

    public function onShow() {
        _cards = GarminCardsData.loadCards();
        _introFramesRemaining = 2;
        _switchPending = false;
        _transitioned = false;
    }

    public function onHide() {
        View.onHide();
    }

    public function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var font = pickTitleFont(width, height);
        var titleY = centeredTextBaseline(dc, height, font);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            width / 2,
            titleY,
            font,
            "Loyalty Hub",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (_switchPending) {
            goToMainView();
            return;
        }

        if (_introFramesRemaining > 0) {
            _introFramesRemaining -= 1;
            if (_introFramesRemaining == 0) {
                _switchPending = true;
            }
            WatchUi.requestUpdate();
        }
    }

    public function goToMainView() {
        if (_transitioned) {
            return;
        }

        _transitioned = true;

        var mainView = new GarminCardsView();
        WatchUi.switchToView(mainView, new GarminCardsDelegate(mainView), WatchUi.SLIDE_BLINK);
    }

    public function isTransitioned() {
        return _transitioned;
    }

    private function pickTitleFont(width, height) {
        var shortSide = minValue(width, height);

        if (shortSide < 54) {
            return Graphics.FONT_TINY;
        }

        if (shortSide < 70) {
            return Graphics.FONT_XTINY;
        }

        if (shortSide < 88) {
            return Graphics.FONT_SMALL;
        }

        return Graphics.FONT_SMALL;
    }

    private function minValue(a, b) {
        if (a < b) {
            return a;
        }

        return b;
    }

    private function centeredTextBaseline(dc, height, font) {
        return toInt((height / 2) + (dc.getFontHeight(font) / 3));
    }

    private function toInt(value) {
        return value.toNumber();
    }
}
