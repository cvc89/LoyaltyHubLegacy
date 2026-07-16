using Toybox.Graphics;
using Toybox.WatchUi;

class GarminCardsGlanceView extends WatchUi.GlanceView {
    private var _backgroundColor = Graphics.COLOR_BLACK;

    public function initialize() {
        GlanceView.initialize();
    }

    public function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var imageSpec = pickGlanceImageSpec(width);
        var sourceWidth = imageSpec[:width];
        var sourceHeight = imageSpec[:height];
        var drawWidth = width;
        var drawHeight = toInt((drawWidth * sourceHeight) / sourceWidth);
        var drawLeft = 0;
        var drawTop = toInt((height - drawHeight) / 2);
        var glanceBitmap = WatchUi.loadResource(imageSpec[:rezId]);

        dc.setColor(_backgroundColor, _backgroundColor);
        dc.clear();

        if (dc has :drawScaledBitmap) {
            dc.drawScaledBitmap(drawLeft, drawTop, drawWidth, drawHeight, glanceBitmap);
        } else {
            dc.drawBitmap(drawLeft, drawTop, glanceBitmap);
        }
    }

    private function pickGlanceImageSpec(width) {
        if (width <= 240) {
            return {
                :rezId => Rez.Drawables.MiniFondo240_72,
                :width => 240,
                :height => 72
            };
        }

        if (width <= 320) {
            return {
                :rezId => Rez.Drawables.MiniFondo320_76,
                :width => 320,
                :height => 76
            };
        }

        return {
            :rezId => Rez.Drawables.MiniFondo360_89,
            :width => 360,
            :height => 89
        };
    }

    private function maxValue(a, b) {
        if (a > b) {
            return a;
        }

        return b;
    }

    private function minValue(a, b) {
        if (a < b) {
            return a;
        }

        return b;
    }

    private function toInt(value) {
        return value.toNumber();
    }
}
