using Toybox.Graphics;
using Toybox.Attention;
using Toybox.System;
using Toybox.WatchUi;

class GarminCardsView extends WatchUi.View {

    private var _cards;
    private var _currentIndex = 0;
    private var _isBrightnessMax = false;
    private var _isCodeFullscreen = false;
    private var _lastWidth = 0;
    private var _lastHeight = 0;
    private var _lastQrCode = null;
    private var _lastQrMatrix = null;
    private var _lastBarcodeCode = null;
    private var _lastBarcodeRenderType = null;
    private var _lastBarcodeRuns = null;
    private var _lastBarcodeTotalUnits = 0;
    private var _qrBuild = null;
    private var _allowQrExpansion = false;
    private var _gfExp = [
        1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38, 76, 152, 45, 90,
        180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192, 157, 39, 78, 156, 37, 74, 148, 53,
        106, 212, 181, 119, 238, 193, 159, 35, 70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210,
        185, 111, 222, 161, 95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, 60, 120, 240,
        253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163, 91, 182, 113, 226, 217, 175, 67, 134,
        17, 34, 68, 136, 13, 26, 52, 104, 208, 189, 103, 206, 129, 31, 62, 124, 248, 237, 199, 147,
        59, 118, 236, 197, 151, 51, 102, 204, 133, 23, 46, 92, 184, 109, 218, 169, 79, 158, 33, 66,
        132, 21, 42, 84, 168, 77, 154, 41, 82, 164, 85, 170, 73, 146, 57, 114, 228, 213, 183, 115,
        230, 209, 191, 99, 198, 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 227, 219, 171, 75,
        150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65, 130, 25, 50, 100, 200, 141, 7, 14,
        28, 56, 112, 224, 221, 167, 83, 166, 81, 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86,
        172, 69, 138, 9, 18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, 22,
        44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, 142
    ];
    private var _gfLog = [
        0, 0, 1, 25, 2, 50, 26, 198, 3, 223, 51, 238, 27, 104, 199, 75, 4, 100, 224, 14,
        52, 141, 239, 129, 28, 193, 105, 248, 200, 8, 76, 113, 5, 138, 101, 47, 225, 36, 15, 33,
        53, 147, 142, 218, 240, 18, 130, 69, 29, 181, 194, 125, 106, 39, 249, 185, 201, 154, 9, 120,
        77, 228, 114, 166, 6, 191, 139, 98, 102, 221, 48, 253, 226, 152, 37, 179, 16, 145, 34, 136,
        54, 208, 148, 206, 143, 150, 219, 189, 241, 210, 19, 92, 131, 56, 70, 64, 30, 66, 182, 163,
        195, 72, 126, 110, 107, 58, 40, 84, 250, 133, 186, 61, 202, 94, 155, 159, 10, 21, 121, 43,
        78, 212, 229, 172, 115, 243, 167, 87, 7, 112, 192, 247, 140, 128, 99, 13, 103, 74, 222, 237,
        49, 197, 254, 24, 227, 165, 153, 119, 38, 184, 180, 124, 17, 68, 146, 217, 35, 32, 137, 46,
        55, 63, 209, 91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190, 97, 242, 86, 211, 171,
        20, 42, 93, 158, 132, 60, 57, 83, 71, 109, 65, 162, 31, 45, 67, 216, 183, 123, 164, 118,
        196, 23, 73, 236, 127, 12, 111, 246, 108, 161, 59, 82, 41, 157, 85, 170, 251, 96, 134, 177,
        187, 204, 62, 90, 203, 89, 95, 176, 156, 169, 160, 81, 11, 245, 22, 235, 122, 117, 44, 215,
        79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168, 80, 88, 175
    ];

    public function initialize() {
        View.initialize();
        reloadCards();
    }

    public function onShow() {
        _isBrightnessMax = true;
        applyBrightnessState();
    }

    public function nextCard() {
        if (_cards.size() == 0) {
            return;
        }

        _currentIndex = (_currentIndex + 1) % _cards.size();
        prepareCurrentCard();
        applyDefaultZoomState();
        _isBrightnessMax = true;
        applyBrightnessState();
        WatchUi.requestUpdate();
    }

    public function previousCard() {
        if (_cards.size() == 0) {
            return;
        }

        _currentIndex = (_currentIndex + _cards.size() - 1) % _cards.size();
        prepareCurrentCard();
        applyDefaultZoomState();
        _isBrightnessMax = true;
        applyBrightnessState();
        WatchUi.requestUpdate();
    }

    public function toggleMode() {
        if (!isCurrentQrCard()) {
            return;
        }

        _isCodeFullscreen = !_isCodeFullscreen;
        _isBrightnessMax = true;
        applyBrightnessState();
        WatchUi.requestUpdate();
    }

    public function exitFullscreen() {
        if (!_isCodeFullscreen) {
            return;
        }

        _isCodeFullscreen = false;
        _isBrightnessMax = true;
        applyBrightnessState();
        WatchUi.requestUpdate();
    }

    public function isFullscreen() {
        return _isCodeFullscreen;
    }

    private function isCurrentQrCard() {
        if (_cards == null || _cards.size() == 0) {
            return false;
        }

        var card = _cards[_currentIndex];
        var codeType = getCardCodeType(card);
        return shouldRenderAsQr(card, codeType);
    }

    public function handleTap(x, y) {
        if (_cards == null || _cards.size() == 0) {
            return false;
        }

        if (_isCodeFullscreen) {
            exitFullscreen();
            return true;
        }

        var card = _cards[_currentIndex];
        var isQrCard = isActiveQrCard(card);

        if (isQrCard) {
            if (isPointInQrArea(x, y)) {
                toggleMode();
                return true;
            }
            return false;
        }

        return false;
    }

    public function onUpdate(dc) {
        ensureCardsLoaded();
        advanceQrBuild();

        var width = dc.getWidth();
        var height = dc.getHeight();
        _lastWidth = width;
        _lastHeight = height;

        var backgroundColor = (_isCodeFullscreen && isCurrentQrCard()) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(backgroundColor, backgroundColor);
        dc.clear();

        if (_cards.size() == 0) {
            drawLegacyEmptyState(dc, width, height);
            return;
        }

        var card = _cards[_currentIndex];
        var codeType = getCardCodeType(card);
        var isQrCard = isActiveQrCard(card);
        var isPhoneCard = GarminCardsData.stringEquals(codeType, "PHONE");
        log("[LH][View] onUpdate index=" + _currentIndex + " merchant=" + card[:merchant] + " codeType=" + codeType + " renderAsQr=" + safeCardValue(card, :renderAsQr) + " isQrCard=" + isQrCard);

        if (_isCodeFullscreen && isQrCard) {
            drawFullscreenQrCardScreen(dc, width, height, card);
        } else {
            drawLegacyCardScreen(dc, width, height, card, codeType, isQrCard, isPhoneCard);
        }

        if (_qrBuild != null) {
            WatchUi.requestUpdate();
        }
    }

    private function ensureCardsLoaded() {
        if (_cards == null) {
            reloadCards();
        }
    }

    private function reloadCards() {
        _cards = GarminCardsData.loadCards();
        primeQrCache();
        log("[LH][View] reloadCards size=" + _cards.size());

        if (_cards.size() == 0) {
            _currentIndex = 0;
        } else if (_currentIndex >= _cards.size()) {
            _currentIndex = 0;
        }

        prepareCurrentCard();
        applyDefaultZoomState();
    }

    private function primeQrCache() {
        _lastQrCode = null;
        _lastQrMatrix = null;
        _lastBarcodeCode = null;
        _lastBarcodeRenderType = null;
        _lastBarcodeRuns = null;
        _lastBarcodeTotalUnits = 0;

        for (var i = 0; i < _cards.size(); i += 1) {
            var card = _cards[i];
            if (!shouldRenderAsQr(card, getCardCodeType(card))) {
                continue;
            }
            card[:qrMatrix] = null;
        }
    }

    private function prepareCurrentCard() {
        if (_cards == null || _cards.size() == 0) {
            _qrBuild = null;
            return;
        }

        var card = _cards[_currentIndex];
        if ((_qrBuild != null) && (_qrBuild[:card] != card)) {
            _qrBuild = null;
        }

        prepareCardQr(card);
    }

    private function applyDefaultZoomState() {
        if (_cards != null && _cards.size() > 0) {
            var card = _cards[_currentIndex];
            var codeType = getCardCodeType(card);
            _isCodeFullscreen = shouldRenderAsQr(card, codeType);
            _isBrightnessMax = true;
            return;
        }

        _isCodeFullscreen = false;
        _isBrightnessMax = true;
    }

    private function prepareCardQr(card) {
        if (!shouldRenderAsQr(card, getCardCodeType(card))) {
            _qrBuild = null;
            card[:qrStatus] = null;
            return;
        }

        if (safeCardValue(card, :qrMatrix) != null) {
            card[:qrStatus] = "ready";
            return;
        }

        if (GarminCardsData.isBlank(safeCardValue(card, :code))) {
            card[:qrStatus] = "failed";
            return;
        }

        var qrCode = card[:code].toString();
        if (!GarminCardsData.isQrCompatible(qrCode)) {
            card[:qrStatus] = "failed";
            return;
        }

        if ((null != _lastQrCode) && GarminCardsData.stringEquals(_lastQrCode, qrCode) && _lastQrMatrix != null) {
            card[:qrMatrix] = _lastQrMatrix;
            card[:qrStatus] = "ready";
            return;
        }

        if ((_qrBuild != null) && (_qrBuild[:card] == card)) {
            return;
        }

        card[:qrStatus] = "building";
        _qrBuild = {
            :card => card,
            :code => qrCode,
            :stage => "ecc",
            :dataBytes => buildQrDataBytes(qrCode),
            :dataIndex => 0,
            :ecc => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        };
    }

    private function advanceQrBuild() {
        if (_qrBuild == null) {
            return;
        }

        if (GarminCardsData.stringEquals(_qrBuild[:stage], "ecc")) {
            advanceQrBuildEcc();
            return;
        }

        if (GarminCardsData.stringEquals(_qrBuild[:stage], "placeInit")) {
            initializeQrPlacement();
            return;
        }

        if (GarminCardsData.stringEquals(_qrBuild[:stage], "place")) {
            advanceQrBuildPlacement(4);
        }
    }

    private function advanceQrBuildEcc() {
        var dataBytes = _qrBuild[:dataBytes];
        var dataIndex = _qrBuild[:dataIndex];

        if (dataIndex >= dataBytes.size()) {
            _qrBuild[:stage] = "placeInit";
            return;
        }

        var ecc = _qrBuild[:ecc];
        var factor = dataBytes[dataIndex] ^ ecc[0];
        var next0 = ecc[1] ^ gfMultiply(251, factor);
        var next1 = ecc[2] ^ gfMultiply(67, factor);
        var next2 = ecc[3] ^ gfMultiply(46, factor);
        var next3 = ecc[4] ^ gfMultiply(61, factor);
        var next4 = ecc[5] ^ gfMultiply(118, factor);
        var next5 = ecc[6] ^ gfMultiply(70, factor);
        var next6 = ecc[7] ^ gfMultiply(64, factor);
        var next7 = ecc[8] ^ gfMultiply(94, factor);
        var next8 = ecc[9] ^ gfMultiply(32, factor);
        var next9 = gfMultiply(45, factor);

        _qrBuild[:ecc] = [next0, next1, next2, next3, next4, next5, next6, next7, next8, next9];
        _qrBuild[:dataIndex] = dataIndex + 1;
    }

    private function initializeQrPlacement() {
        var codewords = [];
        var dataBytes = _qrBuild[:dataBytes];
        var ecc = _qrBuild[:ecc];

        for (var i = 0; i < dataBytes.size(); i += 1) {
            codewords.add(dataBytes[i]);
        }

        for (var j = 0; j < ecc.size(); j += 1) {
            codewords.add(ecc[j]);
        }

        var size = 25;
        var modules = buildSquareMatrix(size, false);
        var functionModules = buildSquareMatrix(size, false);

        drawFinderPattern(modules, functionModules, 0, 0);
        drawFinderPattern(modules, functionModules, size - 7, 0);
        drawFinderPattern(modules, functionModules, 0, size - 7);
        drawAlignmentPattern(modules, functionModules, 18, 18);
        drawTimingPatterns(modules, functionModules);
        markFormatAreas(functionModules);
        setFunctionModule(modules, functionModules, 8, size - 8, true);

        _qrBuild[:modules] = modules;
        _qrBuild[:functionModules] = functionModules;
        _qrBuild[:bits] = buildCodewordBits(codewords);
        _qrBuild[:bitIndex] = 0;
        _qrBuild[:right] = size - 1;
        _qrBuild[:row] = 0;
        _qrBuild[:stage] = "place";
    }

    private function advanceQrBuildPlacement(stepRows) {
        var size = 25;
        var modules = _qrBuild[:modules];
        var functionModules = _qrBuild[:functionModules];
        var bits = _qrBuild[:bits];
        var bitIndex = _qrBuild[:bitIndex];
        var right = _qrBuild[:right];
        var row = _qrBuild[:row];

        for (var step = 0; step < stepRows; step += 1) {
            if (right < 1) {
                drawFormatBits(modules, functionModules);
                _qrBuild[:card][:qrMatrix] = modules;
                _qrBuild[:card][:qrStatus] = "ready";
                _lastQrCode = _qrBuild[:code];
                _lastQrMatrix = modules;
                _qrBuild = null;
                return;
            }

            if (right == 6) {
                right -= 1;
            }

            var upward = (((size - 1 - right) / 2) % 2) == 0;
            var y = upward ? (size - 1 - row) : row;

            for (var offset = 0; offset < 2; offset += 1) {
                var x = right - offset;

                if (functionModules[y][x]) {
                    continue;
                }

                if (bitIndex >= bits.size()) {
                    modules[y][x] = false;
                    continue;
                }

                var bit = bits[bitIndex];
                bitIndex += 1;

                if (((x + y) % 2) == 0) {
                    bit = !bit;
                }

                modules[y][x] = bit;
            }

            row += 1;
            if (row >= size) {
                row = 0;
                right -= 2;
            }
        }

        _qrBuild[:bitIndex] = bitIndex;
        _qrBuild[:right] = right;
        _qrBuild[:row] = row;
    }

    private function drawLegacyCardScreen(dc, width, height, card, codeType, isQrCard, isPhoneCard) {
        if (isQrCard) {
            drawLegacyQrCardScreen(dc, width, height, card);
            return;
        }

        if (isPhoneCard) {
            drawLegacyPhoneCardScreen(dc, width, height, card);
            return;
        }

        drawLegacyBarcodeCardScreen(dc, width, height, card, codeType);
    }

    private function drawLegacyEmptyState(dc, width, height) {
        var titleFont = Graphics.FONT_XTINY;
        var bodyFont = pickBodyFont(height);

        dc.setColor(getPrimaryTextColor(), Graphics.COLOR_BLACK);
        dc.drawText(width / 2, height * 0.20, titleFont, "LOYALTY HUB", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.50, bodyFont, "No cards", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawLegacyBarcodeCardScreen(dc, width, height, card, codeType) {
        var titleFont = pickBodyFont(height);
        var metaFont = Graphics.FONT_XTINY;
        var titleY = maxValue(10, height * 0.12);
        var barcodeSideInset = getBarcodeInset(width, height, 0);
        var barcodeTop = height * 0.27;
        var barcodeHeight = getFullscreenBarcodeHeight(height, codeType);
        var barcodeBackgroundHeight = getBarcodeBackgroundHeight(barcodeHeight, codeType);
        var barcodeWidth = width - (barcodeSideInset * 2);
        var codeY = height * 0.84;

        dc.setColor(getPrimaryTextColor(), Graphics.COLOR_BLACK);
        dc.drawText(width / 2, titleY, titleFont, fitText(dc, card[:merchant], titleFont, width - (barcodeSideInset * 2)), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(toInt(barcodeSideInset), toInt(barcodeTop), toInt(barcodeWidth), toInt(barcodeBackgroundHeight));
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        drawBarcode(dc, barcodeSideInset, barcodeTop, barcodeWidth, barcodeHeight, card[:code], codeType);

        dc.setColor(getPrimaryTextColor(), Graphics.COLOR_BLACK);
        dc.drawText(width / 2, codeY, metaFont, fitText(dc, formatBarcodeHumanReadable(card[:code], codeType), metaFont, width - (barcodeSideInset * 2)), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawLegacyQrCardScreen(dc, width, height, card) {
        var titleFont = pickBodyFont(height);
        var sideInset = width * 0.10;
        var titleY = height * 0.20;
        var qrTop = height * 0.30;
        var qrHeight = height * 0.54;
        var qrWidth = width - (sideInset * 2);

        dc.setColor(getPrimaryTextColor(), Graphics.COLOR_BLACK);
        dc.drawText(width / 2, titleY, titleFont, fitText(dc, card[:merchant], titleFont, width - 24), Graphics.TEXT_JUSTIFY_CENTER);

        _allowQrExpansion = false;
        drawQrArea(dc, width, height, card, sideInset, qrTop, qrWidth, qrHeight, Graphics.FONT_XTINY);
    }

    private function drawLegacyPhoneCardScreen(dc, width, height, card) {
        var titleFont = pickBodyFont(height);
        var valueFont = Graphics.FONT_TINY;
        var titleY = height * 0.20;
        var valueY = height * 0.52;
        var value = card[:code].toString();

        dc.setColor(getPrimaryTextColor(), Graphics.COLOR_BLACK);
        dc.drawText(width / 2, titleY, titleFont, fitText(dc, card[:merchant], titleFont, width - 24), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, valueY, valueFont, fitText(dc, value, valueFont, width - 24), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawFullscreenQrCardScreen(dc, width, height, card) {
        var titleFont = Graphics.FONT_XTINY;
        var titleY = maxValue(8, height * 0.08);
        var qrTop = height * 0.14;
        var qrHeight = height * 0.74;
        var sideInset = width * 0.04;
        var qrWidth = width - (sideInset * 2);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(width / 2, titleY, titleFont, fitText(dc, card[:merchant], titleFont, width - 24), Graphics.TEXT_JUSTIFY_CENTER);

        _allowQrExpansion = true;
        drawQrArea(dc, width, height, card, sideInset, qrTop, qrWidth, qrHeight, Graphics.FONT_XTINY);
    }

    private function clampMetaTextY(dc, height, proposedY, font) {
        var footerY = height * 0.92;
        var maxY = footerY - dc.getFontHeight(font) - 8;
        if (proposedY > maxY) {
            return maxY;
        }

        return proposedY;
    }

    private function getCardCodeType(card) {
        log("[LH][View] getCardCodeType merchant=" + card[:merchant]);
        if (safeCardValue(card, :renderAsQr) == true) {
            log("[LH][View] getCardCodeType -> renderAsQr QR");
            return "QR";
        }

        var compactType = GarminCardsData.detectCompactGs1CodeType(card[:code]);
        if (!GarminCardsData.isBlank(compactType)) {
            log("[LH][View] getCardCodeType -> compact " + compactType);
            return compactType;
        }

        if (!GarminCardsData.isBlank(safeCardValue(card, :codeType))) {
            log("[LH][View] getCardCodeType -> existing " + card[:codeType]);
            return card[:codeType];
        }

        var detected = GarminCardsData.detectCodeType(card[:code]);
        log("[LH][View] getCardCodeType -> detected " + detected);
        return detected;
    }

    private function isActiveQrCard(card) {
        log("[LH][View] isActiveQrCard merchant=" + card[:merchant] + " code=" + card[:code]);
        if (safeCardValue(card, :renderAsQr) == true) {
            log("[LH][View] isActiveQrCard -> true (renderAsQr)");
            return true;
        }

        var codeType = getCardCodeType(card);
        if (GarminCardsData.stringEquals(codeType, "QR")) {
            log("[LH][View] isActiveQrCard -> true (codeType)");
            return true;
        }

        log("[LH][View] isActiveQrCard -> false");
        return false;
    }

    private function pickTitleFont(width, height) {
        if (width < 190 || height < 190) {
            return Graphics.FONT_MEDIUM;
        }

        return Graphics.FONT_LARGE;
    }

    private function pickBodyFont(height) {
        if (height < 190) {
            return Graphics.FONT_XTINY;
        }

        return Graphics.FONT_TINY;
    }

    private function fitText(dc, text, font, maxWidth) {
        if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
            return text;
        }

        var ellipsis = "...";
        var truncated = text;

        while (truncated.length() > 0) {
            truncated = truncated.substring(0, truncated.length() - 1);
            if (dc.getTextWidthInPixels(truncated + ellipsis, font) <= maxWidth) {
                return truncated + ellipsis;
            }
        }

        return ellipsis;
    }

    private function getAccentColor(seed) {
        var palette = [
            Graphics.COLOR_BLUE,
            Graphics.COLOR_GREEN,
            Graphics.COLOR_DK_GRAY,
            Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_WHITE,
            Graphics.COLOR_YELLOW,
            Graphics.COLOR_RED
        ];

        return palette[seed % palette.size()];
    }

    private function getPrimaryTextColor() {
        return Graphics.COLOR_WHITE;
    }

    private function pickPhoneNumberFont(dc, phoneText, maxWidth, height) {
        var fonts = [
            Graphics.FONT_LARGE,
            Graphics.FONT_MEDIUM,
            Graphics.FONT_SMALL,
            Graphics.FONT_TINY,
            Graphics.FONT_XTINY
        ];

        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getTextWidthInPixels(phoneText, fonts[i]) <= maxWidth) {
                return fonts[i];
            }
        }

        if (height < 200) {
            return Graphics.FONT_XTINY;
        }

        return Graphics.FONT_TINY;
    }

    private function drawBarcode(dc, left, top, maxWidth, barHeight, code, codeType) {
        var renderType = getBarcodeRenderType(code, codeType);
        var barcodeData = getCachedBarcodeData(code, renderType);
        var runs = barcodeData[:runs];
        log("[LH][1D] drawBarcode type=" + codeType + " renderType=" + renderType + " code=" + code + " runs=" + ((runs == null) ? "null" : runs.size().toString()) + " blackBars=" + ((runs == null) ? "null" : countBlackBars(runs).toString()));
        if (runs == null || runs.size() == 0) {
            drawBarcodeFallback(dc, left, top, maxWidth, barHeight);
            return;
        }

        var totalUnits = barcodeData[:totalUnits];
        if (totalUnits <= 0) {
            drawBarcodeFallback(dc, left, top, maxWidth, barHeight);
            return;
        }

        if (isGs1LinearType(renderType)) {
            drawGs1BarcodeRuns(dc, left, top, maxWidth, barHeight, runs, totalUnits, renderType);
            return;
        }

        drawLinearBarcodeRuns(dc, left, top, maxWidth, barHeight, runs, totalUnits, renderType);
    }

    private function getCachedBarcodeData(code, renderType) {
        var barcodeCode = code.toString();

        if (_lastBarcodeRuns != null &&
            _lastBarcodeCode != null &&
            _lastBarcodeRenderType != null &&
            GarminCardsData.stringEquals(_lastBarcodeCode, barcodeCode) &&
            GarminCardsData.stringEquals(_lastBarcodeRenderType, renderType)) {
            return {
                :runs => _lastBarcodeRuns,
                :totalUnits => _lastBarcodeTotalUnits
            };
        }

        var runs = buildBarcodeRuns(code, renderType);
        var totalUnits = 0;
        if (runs != null && runs.size() > 0) {
            totalUnits = sumRuns(runs);
        }

        _lastBarcodeCode = barcodeCode;
        _lastBarcodeRenderType = renderType;
        _lastBarcodeRuns = runs;
        _lastBarcodeTotalUnits = totalUnits;

        return {
            :runs => runs,
            :totalUnits => totalUnits
        };
    }

    private function getBarcodeRenderType(code, codeType) {
        if (GarminCardsData.stringEquals(codeType, "QR") || GarminCardsData.stringEquals(codeType, "PHONE")) {
            return codeType;
        }

        var compactType = GarminCardsData.detectCompactGs1CodeType(code);
        if (!GarminCardsData.isBlank(compactType)) {
            return compactType;
        }

        return codeType;
    }

    private function drawLinearBarcodeRuns(dc, left, top, maxWidth, barHeight, runs, totalUnits, codeType) {
        var quietLeft = getLinearQuietZoneLeft(codeType);
        var quietRight = getLinearQuietZoneRight(codeType);
        var symbolUnits = totalUnits + quietLeft + quietRight;
        var availableWidth = maxValue(20, toInt(maxWidth));
        var startX = toInt(left);
        var bottom = toInt(top + barHeight);
        var drawBar = true;
        var consumedUnits = 0;

        for (var i = 0; i < runs.size(); i += 1) {
            var nextUnits = consumedUnits + runs[i];
            var currentX = startX + scaleBarcodeUnits(quietLeft + consumedUnits, availableWidth, symbolUnits);
            var nextX = startX + scaleBarcodeUnits(quietLeft + nextUnits, availableWidth, symbolUnits);
            var segmentWidth = nextX - currentX;

            if (segmentWidth <= 0) {
                segmentWidth = 1;
            }

            if (drawBar) {
                drawBarBlock(dc, currentX, toInt(top), maxValue(1, segmentWidth), bottom);
            }

            consumedUnits = nextUnits;
            drawBar = !drawBar;
        }
    }

    private function scaleBarcodeUnits(units, targetWidth, totalUnits) {
        return toInt(((units * targetWidth) + (totalUnits / 2)) / totalUnits);
    }

    private function buildBarcodeRuns(code, codeType) {
        log("[LH][1D] buildBarcodeRuns type=" + codeType + " normalized=" + GarminCardsData.normalizeCode(code));
        if (GarminCardsData.stringEquals(codeType, "EAN13")) {
            return buildEan13Runs(GarminCardsData.normalizeCode(code));
        }

        if (GarminCardsData.stringEquals(codeType, "UPCA")) {
            return buildUpcaRuns(GarminCardsData.normalizeCode(code));
        }

        if (GarminCardsData.stringEquals(codeType, "EAN8")) {
            return buildEan8Runs(GarminCardsData.normalizeCode(code));
        }

        if (GarminCardsData.stringEquals(codeType, "ITF")) {
            return buildItfRuns(GarminCardsData.normalizeCode(code));
        }

        if (GarminCardsData.stringEquals(codeType, "CODE39")) {
            return buildCode39Runs(GarminCardsData.normalizeCode(code).toUpper());
        }

        if (GarminCardsData.stringEquals(codeType, "CODE128")) {
            return buildCode128Runs(code.toString());
        }

        return null;
    }

    private function buildEan13Runs(code) {
        if (code.length() != 13 || !isDigitsText(code) || !GarminCardsData.isValidEan13(code)) {
            return null;
        }

        var leftParity = [
            "LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
            "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"
        ];
        var lPatterns = ["0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011"];
        var gPatterns = ["0100111", "0110011", "0011011", "0100001", "0011101", "0111001", "0000101", "0010001", "0001001", "0010111"];
        var rPatterns = ["1110010", "1100110", "1101100", "1000010", "1011100", "1001110", "1010000", "1000100", "1001000", "1110100"];
        var firstDigit = digitValue(code.substring(0, 1));
        var parity = leftParity[firstDigit];
        var bits = "101";

        for (var i = 1; i <= 6; i += 1) {
            var digit = digitValue(code.substring(i, i + 1));
            var encType = parity.substring(i - 1, i);
            bits += GarminCardsData.stringEquals(encType, "L") ? lPatterns[digit] : gPatterns[digit];
        }

        bits += "01010";

        for (var j = 7; j < 13; j += 1) {
            bits += rPatterns[digitValue(code.substring(j, j + 1))];
        }

        bits += "101";
        return bitStringToRuns(bits);
    }

    private function buildUpcaRuns(code) {
        if (code.length() != 12 || !isDigitsText(code) || !GarminCardsData.isValidUpca(code)) {
            return null;
        }

        var lPatterns = ["0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011"];
        var rPatterns = ["1110010", "1100110", "1101100", "1000010", "1011100", "1001110", "1010000", "1000100", "1001000", "1110100"];
        var bits = "101";

        for (var i = 0; i < 6; i += 1) {
            bits += lPatterns[digitValue(code.substring(i, i + 1))];
        }

        bits += "01010";

        for (var j = 6; j < 12; j += 1) {
            bits += rPatterns[digitValue(code.substring(j, j + 1))];
        }

        bits += "101";
        return bitStringToRuns(bits);
    }

    private function buildEan8Runs(code) {
        if (code.length() != 8 || !isDigitsText(code) || !GarminCardsData.isValidEan8(code)) {
            return null;
        }

        var lPatterns = ["0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011"];
        var rPatterns = ["1110010", "1100110", "1101100", "1000010", "1011100", "1001110", "1010000", "1000100", "1001000", "1110100"];
        var bits = "101";

        for (var i = 0; i < 4; i += 1) {
            bits += lPatterns[digitValue(code.substring(i, i + 1))];
        }

        bits += "01010";

        for (var j = 4; j < 8; j += 1) {
            bits += rPatterns[digitValue(code.substring(j, j + 1))];
        }

        bits += "101";
        return bitStringToRuns(bits);
    }

    private function buildItfRuns(code) {
        if (code.length() < 2 || ((code.length() % 2) != 0) || !isDigitsText(code)) {
            return null;
        }

        var patterns = ["nnwwn", "wnnnw", "nwnnw", "wwnnn", "nnwnw", "wnwnn", "nwwnn", "nnnww", "wnnwn", "nwnwn"];
        var runs = [1, 1, 1, 1];

        for (var i = 0; i < code.length(); i += 2) {
            var leftPattern = patterns[digitValue(code.substring(i, i + 1))];
            var rightPattern = patterns[digitValue(code.substring(i + 1, i + 2))];

            for (var j = 0; j < 5; j += 1) {
                runs.add(widthFromNarrowWide(leftPattern.substring(j, j + 1)));
                runs.add(widthFromNarrowWide(rightPattern.substring(j, j + 1)));
            }
        }

        runs.add(3);
        runs.add(1);
        runs.add(1);
        return runs;
    }

    private function buildCode39Runs(code) {
        if (code.length() == 0) {
            return null;
        }

        var alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%*";
        var patterns = [
            "nnnwwnwnn", "wnnwnnnnw", "nnwwnnnnw", "wnwwnnnnn", "nnnwwnnnw",
            "wnnwwnnnn", "nnwwwnnnn", "nnnwnnwnw", "wnnwnnwnn", "nnwwnnwnn",
            "wnnnnwnnw", "nnwnnwnnw", "wnwnnwnnn", "nnnnwwnnw", "wnnnwwnnn",
            "nnwnwwnnn", "nnnnnwwnw", "wnnnnwwnn", "nnwnnwwnn", "nnnnwwwnn",
            "wnnnnnnww", "nnwnnnnww", "wnwnnnnwn", "nnnnwnnww", "wnnnwnnwn",
            "nnwnwnnwn", "nnnnnnwww", "wnnnnnwwn", "nnwnnnwwn", "nnnnwnwwn",
            "wwnnnnnnw", "nwwnnnnnw", "wwwnnnnnn", "nwnnwnnnw", "wwnnwnnnn",
            "nwwnwnnnn", "nwnnnnwnw", "wwnnnnwnn", "nwwnnnwnn", "nwnwnwnnn",
            "nwnwnnnwn", "nwnnnwnwn", "nnnwnwnwn", "nwnnwnwnn"
        ];
        var wrapped = "*" + code + "*";
        var runs = [];

        for (var i = 0; i < wrapped.length(); i += 1) {
            var ch = wrapped.substring(i, i + 1);
            var index = indexOfChar(alphabet, ch);
            if (index < 0) {
                return null;
            }

            appendPatternRuns(runs, patterns[index]);
            if (i < wrapped.length() - 1) {
                runs.add(1);
            }
        }

        return runs;
    }

    private function buildCode128Runs(code) {
        if (code.length() == 0) {
            return null;
        }

        var patterns = [
            "212222", "222122", "222221", "121223", "121322", "131222", "122213", "122312", "132212", "221213",
            "221312", "231212", "112232", "122132", "122231", "113222", "123122", "123221", "223211", "221132",
            "221231", "213212", "223112", "312131", "311222", "321122", "321221", "312212", "322112", "322211",
            "212123", "212321", "232121", "111323", "131123", "131321", "112313", "132113", "132311", "211313",
            "231113", "231311", "112133", "112331", "132131", "113123", "113321", "133121", "313121", "211331",
            "231131", "213113", "213311", "213131", "311123", "311321", "331121", "312113", "312311", "332111",
            "314111", "221411", "431111", "111224", "111422", "121124", "121421", "141122", "141221", "112214",
            "112412", "122114", "122411", "142112", "142211", "241211", "221114", "413111", "241112", "134111",
            "111242", "121142", "121241", "114212", "124112", "124211", "411212", "421112", "421211", "212141",
            "214121", "412121", "111143", "111341", "131141", "114113", "114311", "411113", "411311", "113141",
            "114131", "311141", "411131", "211412", "211214", "211232", "2331112"
        ];
        var values = [];

        for (var i = 0; i < code.length(); i += 1) {
            var value = GarminCardsData.getAsciiValue(code.substring(i, i + 1)) - 32;
            if (value < 0 || value > 94) {
                return null;
            }
            values.add(value);
        }

        var checksum = 104;
        for (var j = 0; j < values.size(); j += 1) {
            checksum += values[j] * (j + 1);
        }
        checksum = checksum % 103;

        var runs = stringDigitsToRuns(patterns[104]);
        for (var k = 0; k < values.size(); k += 1) {
            appendRuns(runs, stringDigitsToRuns(patterns[values[k]]));
        }
        appendRuns(runs, stringDigitsToRuns(patterns[checksum]));
        appendRuns(runs, stringDigitsToRuns(patterns[106]));
        return runs;
    }

    private function bitStringToRuns(bits) {
        if (bits.length() == 0) {
            return null;
        }

        var runs = [];
        var current = bits.substring(0, 1);
        var count = 1;

        for (var i = 1; i < bits.length(); i += 1) {
            var bit = bits.substring(i, i + 1);
            if (GarminCardsData.stringEquals(bit, current)) {
                count += 1;
            } else {
                runs.add(count);
                current = bit;
                count = 1;
            }
        }

        runs.add(count);
        return runs;
    }

    private function stringDigitsToRuns(pattern) {
        var runs = [];
        for (var i = 0; i < pattern.length(); i += 1) {
            runs.add(digitValue(pattern.substring(i, i + 1)));
        }
        return runs;
    }

    private function appendPatternRuns(runs, pattern) {
        for (var i = 0; i < pattern.length(); i += 1) {
            runs.add(widthFromNarrowWide(pattern.substring(i, i + 1)));
        }
    }

    private function appendRuns(target, source) {
        for (var i = 0; i < source.size(); i += 1) {
            target.add(source[i]);
        }
    }

    private function widthFromNarrowWide(ch) {
        return GarminCardsData.stringEquals(ch, "w") ? 3 : 1;
    }

    private function sumRuns(runs) {
        var total = 0;
        for (var i = 0; i < runs.size(); i += 1) {
            total += runs[i];
        }
        return total;
    }

    private function countBlackBars(runs) {
        var total = 0;
        for (var i = 0; i < runs.size(); i += 2) {
            total += 1;
        }

        return total;
    }

    private function isDigitsText(value) {
        if (value.length() == 0) {
            return false;
        }

        for (var i = 0; i < value.length(); i += 1) {
            var ch = value.substring(i, i + 1);
            if (GarminCardsData.getAsciiValue(ch) < 48 || GarminCardsData.getAsciiValue(ch) > 57) {
                return false;
            }
        }

        return true;
    }

    private function indexOfChar(haystack, needle) {
        for (var i = 0; i < haystack.length(); i += 1) {
            if (GarminCardsData.stringEquals(haystack.substring(i, i + 1), needle)) {
                return i;
            }
        }

        return -1;
    }

    private function digitValue(ch) {
        var value = GarminCardsData.getAsciiValue(ch) - 48;
        if (value < 0 || value > 9) {
            return 0;
        }

        return value;
    }

    private function drawGs1BarcodeRuns(dc, left, top, maxWidth, barHeight, runs, totalUnits, codeType) {
        var availableWidth = maxValue(20, toInt(maxWidth));
        var quietPadding = getGs1QuietPadding(availableWidth);
        var moduleWidth = maxValue(1, toInt((availableWidth - (quietPadding * 2)) / totalUnits));
        var renderedWidth = moduleWidth * totalUnits;
        var startX = toInt(left + ((availableWidth - renderedWidth) / 2));
        var bottom = toInt(top + barHeight);
        var guardBottom = bottom + getGs1GuardExtension(barHeight);
        var drawBar = true;
        var consumedUnits = 0;

        for (var i = 0; i < runs.size(); i += 1) {
            var runUnits = runs[i];
            var currentX = startX + (consumedUnits * moduleWidth);
            var segmentWidth = runUnits * moduleWidth;

            if (drawBar) {
                var barBottom = isGs1GuardBar(consumedUnits, consumedUnits + runUnits, codeType) ? guardBottom : bottom;
                drawBarBlock(dc, currentX, toInt(top), maxValue(1, segmentWidth), barBottom);
            }

            consumedUnits += runUnits;
            drawBar = !drawBar;
        }
    }

    private function isGs1LinearType(codeType) {
        return GarminCardsData.stringEquals(codeType, "EAN13") ||
               GarminCardsData.stringEquals(codeType, "UPCA") ||
               GarminCardsData.stringEquals(codeType, "EAN8");
    }

    private function formatGs1HumanReadable(code, codeType) {
        var value = GarminCardsData.normalizeCode(code);

        if (GarminCardsData.stringEquals(codeType, "EAN13") && value.length() == 13) {
            return value.substring(0, 1) + " " +
                   value.substring(1, 7) + " " +
                   value.substring(7, 13);
        }

        if (GarminCardsData.stringEquals(codeType, "UPCA") && value.length() == 12) {
            return value.substring(0, 1) + " " +
                   value.substring(1, 6) + " " +
                   value.substring(6, 11) + " " +
                   value.substring(11, 12);
        }

        if (GarminCardsData.stringEquals(codeType, "EAN8") && value.length() == 8) {
            return value.substring(0, 4) + " " + value.substring(4, 8);
        }

        return value;
    }

    private function formatBarcodeHumanReadable(code, codeType) {
        if (isGs1LinearType(codeType)) {
            return formatGs1HumanReadable(code, codeType);
        }

        return GarminCardsData.normalizeCode(code);
    }

    private function getGs1QuietZoneLeft(codeType) {
        if (GarminCardsData.stringEquals(codeType, "EAN8")) {
            return 7;
        }

        if (GarminCardsData.stringEquals(codeType, "UPCA")) {
            return 9;
        }

        return 11;
    }

    private function getGs1QuietZoneRight(codeType) {
        if (GarminCardsData.stringEquals(codeType, "EAN8")) {
            return 7;
        }

        if (GarminCardsData.stringEquals(codeType, "UPCA")) {
            return 9;
        }

        return 7;
    }

    private function getGs1GuardExtension(barHeight) {
        return maxValue(4, toInt(barHeight * 0.12));
    }

    private function getGs1QuietPadding(availableSize) {
        return maxValue(6, toInt(availableSize * 0.02));
    }

    private function isGs1GuardBar(startUnits, endUnits, codeType) {
        if (GarminCardsData.stringEquals(codeType, "EAN8")) {
            return isUnitRangeInside(startUnits, endUnits, 0, 3) ||
                   isUnitRangeInside(startUnits, endUnits, 31, 36) ||
                   isUnitRangeInside(startUnits, endUnits, 64, 67);
        }

        return isUnitRangeInside(startUnits, endUnits, 0, 3) ||
               isUnitRangeInside(startUnits, endUnits, 45, 50) ||
               isUnitRangeInside(startUnits, endUnits, 92, 95);
    }

    private function isUnitRangeInside(startUnits, endUnits, guardStart, guardEnd) {
        return startUnits >= guardStart && endUnits <= guardEnd;
    }

    private function getLinearQuietZoneLeft(codeType) {
        if (GarminCardsData.stringEquals(codeType, "CODE39")) {
            return 10;
        }

        if (GarminCardsData.stringEquals(codeType, "CODE128")) {
            return 10;
        }

        if (GarminCardsData.stringEquals(codeType, "ITF")) {
            return 10;
        }

        return 8;
    }

    private function getLinearQuietZoneRight(codeType) {
        return getLinearQuietZoneLeft(codeType);
    }

    private function drawBarcodeFallback(dc, left, top, maxWidth, barHeight) {
        var width = toInt(maxWidth);
        var height = toInt(barHeight);
        log("[LH] Barcode fallback triggered");
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(toInt(left + (width / 2)), toInt(top + (height / 2)), Graphics.FONT_XTINY, "No compatible", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawBarBlock(dc, x, top, width, bottom) {
        for (var dx = 0; dx < width; dx += 1) {
            dc.drawLine(x + dx, top, x + dx, bottom);
        }
    }

    private function maxValue(a, b) {
        if (a > b) {
            return a;
        }

        return b;
    }

    private function getBarcodeInset(width, height, extraPadding) {
        var inset = (width / 26) + extraPadding;

        if (width < 220 || height < 220) {
            inset = (width / 22) + extraPadding;
        }

        return toInt(maxValue(6, inset));
    }

    private function isPointInQrArea(x, y) {
        if (_lastWidth <= 0 || _lastHeight <= 0) {
            return false;
        }

        var sideInset = _lastWidth * 0.12;
        var qrTop = _lastHeight * 0.28;
        var qrHeight = _lastHeight * 0.48;

        return x >= sideInset && x <= (_lastWidth - sideInset) && y >= qrTop && y <= (qrTop + qrHeight);
    }

    private function getCodeVisualHeight(height, codeType) {
        if (GarminCardsData.stringEquals(codeType, "QR")) {
            var qrHeight = height * 0.46;
            return toInt(maxValue(74, qrHeight));
        }

        var barcodeHeight = height * 0.22;

        if (height >= 260) {
            barcodeHeight = height * 0.25;
        }

        return toInt(maxValue(32, barcodeHeight));
    }

    private function getFullscreenBarcodeHeight(height, codeType) {
        var barcodeHeight = height * 0.43;

        if (isGs1LinearType(codeType)) {
            barcodeHeight = height * 0.40;
        }

        return toInt(maxValue(52, barcodeHeight));
    }

    private function getBarcodeBackgroundHeight(barcodeHeight, codeType) {
        if (isGs1LinearType(codeType)) {
            return barcodeHeight + getGs1GuardExtension(barcodeHeight);
        }

        return barcodeHeight;
    }

    private function shouldRenderAsQr(card, codeType) {
        if (GarminCardsData.stringEquals(safeCardValue(card, :codeType), "QR")) {
            return true;
        }

        if (GarminCardsData.stringEquals(codeType, "QR")) {
            return true;
        }

        return false;
    }

    private function drawQrArea(dc, width, height, card, left, top, maxWidth, maxHeight, metaFont) {
        var matrix = safeCardValue(card, :qrMatrix);

        if (matrix == null) {
            if (GarminCardsData.stringEquals(safeCardValue(card, :qrStatus), "building")) {
                drawQrLoading(dc, left, top, maxWidth, maxHeight, metaFont);
                return;
            }
            drawQrFallback(dc, left, top, maxWidth, maxHeight, metaFont);
            return;
        }

        drawQrMatrix(dc, left, top, maxWidth, maxHeight, matrix, _allowQrExpansion);
    }

    private function drawQrLoading(dc, left, top, maxWidth, maxHeight, font) {
        var centerX = toInt(left + (maxWidth / 2));
        var lineHeight = dc.getFontHeight(font);
        var centerY = toInt(top + (maxHeight / 2) - lineHeight);
        var helpY = centerY + lineHeight + 4;
        var textWidth = maxValue(20, toInt(maxWidth) - 12);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(centerX, centerY, font, fitText(dc, "Generating QR...", font, textWidth), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, helpY, font, fitText(dc, "Please wait", font, textWidth), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawQrFallback(dc, left, top, maxWidth, maxHeight, font) {
        var centerX = toInt(left + (maxWidth / 2));
        var lineHeight = dc.getFontHeight(font);
        var centerY = toInt(top + (maxHeight / 2) - lineHeight);
        var helpY = centerY + lineHeight + 4;
        var textWidth = maxValue(20, toInt(maxWidth) - 12);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.drawText(centerX, centerY, font, fitText(dc, "QR unsupported", font, textWidth), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, helpY, font, fitText(dc, "Use 32 chars or less", font, textWidth), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawQrMatrix(dc, left, top, maxWidth, maxHeight, matrix, allowExpansion) {
        var quietZone = pickQrQuietZone(maxWidth, maxHeight, matrix.size(), allowExpansion);
        var size = matrix.size();
        var totalModules = size + (quietZone * 2);
        var moduleSize = minValue(maxValue(2, toInt(maxWidth / totalModules)), maxValue(2, toInt(maxHeight / totalModules)));
        var drawWidth = totalModules * moduleSize;
        var drawHeight = totalModules * moduleSize;
        var startX = toInt(left + ((maxWidth - drawWidth) / 2));
        var startY = toInt(top + ((maxHeight - drawHeight) / 2));

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(startX, startY, drawWidth, drawHeight);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);

        for (var y = 0; y < size; y += 1) {
            for (var x = 0; x < size; x += 1) {
                if (matrix[y][x]) {
                    dc.fillRectangle(startX + ((x + quietZone) * moduleSize), startY + ((y + quietZone) * moduleSize), moduleSize, moduleSize);
                }
            }
        }
    }

    private function pickQrQuietZone(maxWidth, maxHeight, size, allowExpansion) {
        var defaultQuietZone = 2;

        if (!allowExpansion) {
            return defaultQuietZone;
        }

        var expandedQuietZone = 1;
        var defaultModuleSize = getQrModuleSize(maxWidth, maxHeight, size, defaultQuietZone);
        var expandedModuleSize = getQrModuleSize(maxWidth, maxHeight, size, expandedQuietZone);

        if (expandedModuleSize > defaultModuleSize) {
            return expandedQuietZone;
        }

        return defaultQuietZone;
    }

    private function getQrModuleSize(maxWidth, maxHeight, size, quietZone) {
        var totalModules = size + (quietZone * 2);
        return minValue(maxValue(2, toInt(maxWidth / totalModules)), maxValue(2, toInt(maxHeight / totalModules)));
    }

    private function buildQrMatrix(code) {
        var qrCode = code.toString();

        if ((null != _lastQrCode) && GarminCardsData.stringEquals(_lastQrCode, qrCode)) {
            return _lastQrMatrix;
        }

        if (!GarminCardsData.isQrCompatible(qrCode)) {
            return null;
        }

        var dataBytes = buildQrDataBytes(qrCode);
        var eccBytes = buildQrErrorCorrection(dataBytes);
        var codewords = [];

        for (var i = 0; i < dataBytes.size(); i += 1) {
            codewords.add(dataBytes[i]);
        }

        for (var j = 0; j < eccBytes.size(); j += 1) {
            codewords.add(eccBytes[j]);
        }

        var matrix = placeQrModules(codewords);
        _lastQrCode = qrCode;
        _lastQrMatrix = matrix;
        return matrix;
    }

    private function buildQrDataBytes(code) {
        var bits = [];
        appendBits(bits, 4, 4);
        appendBits(bits, code.length(), 8);

        for (var i = 0; i < code.length(); i += 1) {
            appendBits(bits, asciiByteForChar(code.substring(i, i + 1)), 8);
        }

        var capacityBits = 34 * 8;
        var terminatorLength = minValue(4, capacityBits - bits.size());
        appendBits(bits, 0, terminatorLength);

        while ((bits.size() % 8) != 0) {
            bits.add(false);
        }

        var bytes = [];
        for (var bitIndex = 0; bitIndex < bits.size(); bitIndex += 8) {
            var value = 0;
            for (var offset = 0; offset < 8; offset += 1) {
                value *= 2;
                if (bits[bitIndex + offset]) {
                    value += 1;
                }
            }
            bytes.add(value);
        }

        var useFirstPad = true;
        while (bytes.size() < 34) {
            bytes.add(useFirstPad ? 236 : 17);
            useFirstPad = !useFirstPad;
        }

        return bytes;
    }

    private function appendBits(bits, value, length) {
        for (var i = length - 1; i >= 0; i -= 1) {
            bits.add((((value / pow2(i)).toNumber()) % 2) == 1);
        }
    }

    private function asciiByteForChar(ch) {
        return GarminCardsData.getAsciiValue(ch);
    }

    private function buildQrErrorCorrection(dataBytes) {
        var ecc0 = 0;
        var ecc1 = 0;
        var ecc2 = 0;
        var ecc3 = 0;
        var ecc4 = 0;
        var ecc5 = 0;
        var ecc6 = 0;
        var ecc7 = 0;
        var ecc8 = 0;
        var ecc9 = 0;

        for (var i = 0; i < dataBytes.size(); i += 1) {
            var factor = dataBytes[i] ^ ecc0;

            var next0 = ecc1 ^ gfMultiply(251, factor);
            var next1 = ecc2 ^ gfMultiply(67, factor);
            var next2 = ecc3 ^ gfMultiply(46, factor);
            var next3 = ecc4 ^ gfMultiply(61, factor);
            var next4 = ecc5 ^ gfMultiply(118, factor);
            var next5 = ecc6 ^ gfMultiply(70, factor);
            var next6 = ecc7 ^ gfMultiply(64, factor);
            var next7 = ecc8 ^ gfMultiply(94, factor);
            var next8 = ecc9 ^ gfMultiply(32, factor);
            var next9 = gfMultiply(45, factor);

            ecc0 = next0;
            ecc1 = next1;
            ecc2 = next2;
            ecc3 = next3;
            ecc4 = next4;
            ecc5 = next5;
            ecc6 = next6;
            ecc7 = next7;
            ecc8 = next8;
            ecc9 = next9;
        }

        return [ecc0, ecc1, ecc2, ecc3, ecc4, ecc5, ecc6, ecc7, ecc8, ecc9];
    }

    private function placeQrModules(codewords) {
        var size = 25;
        var modules = buildSquareMatrix(size, false);
        var functionModules = buildSquareMatrix(size, false);
        var bits = buildCodewordBits(codewords);
        var bitIndex = 0;

        drawFinderPattern(modules, functionModules, 0, 0);
        drawFinderPattern(modules, functionModules, size - 7, 0);
        drawFinderPattern(modules, functionModules, 0, size - 7);
        drawAlignmentPattern(modules, functionModules, 18, 18);
        drawTimingPatterns(modules, functionModules);
        markFormatAreas(functionModules);
        setFunctionModule(modules, functionModules, 8, size - 8, true);

        for (var right = size - 1; right >= 1; right -= 2) {
            if (right == 6) {
                right -= 1;
            }

            var upward = (((size - 1 - right) / 2) % 2) == 0;
            for (var row = 0; row < size; row += 1) {
                var y = upward ? (size - 1 - row) : row;

                for (var offset = 0; offset < 2; offset += 1) {
                    var x = right - offset;

                    if (functionModules[y][x]) {
                        continue;
                    }

                    if (bitIndex >= bits.size()) {
                        modules[y][x] = false;
                        continue;
                    }

                    var bit = bits[bitIndex];
                    bitIndex += 1;

                    if (((x + y) % 2) == 0) {
                        bit = !bit;
                    }

                    modules[y][x] = bit;
                }
            }
        }

        drawFormatBits(modules, functionModules);
        return modules;
    }

    private function buildCodewordBits(codewords) {
        var bits = [];

        for (var i = 0; i < codewords.size(); i += 1) {
            appendBits(bits, codewords[i], 8);
        }

        return bits;
    }

    private function buildSquareMatrix(size, fillValue) {
        var matrix = [];

        for (var y = 0; y < size; y += 1) {
            var row = [];
            for (var x = 0; x < size; x += 1) {
                row.add(fillValue);
            }
            matrix.add(row);
        }

        return matrix;
    }

    private function drawFinderPattern(modules, functionModules, left, top) {
        for (var y = -1; y <= 7; y += 1) {
            for (var x = -1; x <= 7; x += 1) {
                var xPos = left + x;
                var yPos = top + y;

                if (!isInsideMatrix(modules, xPos, yPos)) {
                    continue;
                }

                var isBorder = (x == -1 || x == 7 || y == -1 || y == 7);
                var isOuter = (x == 0 || x == 6 || y == 0 || y == 6);
                var isInner = (x >= 2 && x <= 4 && y >= 2 && y <= 4);
                setFunctionModule(modules, functionModules, xPos, yPos, !isBorder && (isOuter || isInner));
            }
        }
    }

    private function drawAlignmentPattern(modules, functionModules, centerX, centerY) {
        for (var y = -2; y <= 2; y += 1) {
            for (var x = -2; x <= 2; x += 1) {
                var distance = maxValue(absValue(x), absValue(y));
                setFunctionModule(modules, functionModules, centerX + x, centerY + y, distance != 1);
            }
        }
    }

    private function drawTimingPatterns(modules, functionModules) {
        var size = modules.size();

        for (var i = 8; i < size - 8; i += 1) {
            var value = (i % 2) == 0;
            setFunctionModule(modules, functionModules, i, 6, value);
            setFunctionModule(modules, functionModules, 6, i, value);
        }
    }

    private function markFormatAreas(functionModules) {
        var size = functionModules.size();

        for (var i = 0; i < 9; i += 1) {
            functionModules[8][i] = true;
            functionModules[i][8] = true;
        }

        for (var j = 0; j < 8; j += 1) {
            functionModules[size - 1 - j][8] = true;
            functionModules[8][size - 1 - j] = true;
        }
    }

    private function drawFormatBits(modules, functionModules) {
        var format = 0x77C4;
        var size = modules.size();

        for (var i = 0; i <= 5; i += 1) {
            setFunctionModule(modules, functionModules, 8, i, getFormatBit(format, i));
        }
        setFunctionModule(modules, functionModules, 8, 7, getFormatBit(format, 6));
        setFunctionModule(modules, functionModules, 8, 8, getFormatBit(format, 7));
        setFunctionModule(modules, functionModules, 7, 8, getFormatBit(format, 8));

        for (var j = 9; j < 15; j += 1) {
            setFunctionModule(modules, functionModules, 14 - j, 8, getFormatBit(format, j));
        }

        for (var k = 0; k < 8; k += 1) {
            setFunctionModule(modules, functionModules, size - 1 - k, 8, getFormatBit(format, k));
        }

        for (var m = 8; m < 15; m += 1) {
            setFunctionModule(modules, functionModules, 8, size - 15 + m, getFormatBit(format, m));
        }
    }

    private function getFormatBit(format, bitIndex) {
        return (((format / pow2(bitIndex)).toNumber()) % 2) == 1;
    }

    private function setFunctionModule(modules, functionModules, x, y, value) {
        if (!isInsideMatrix(modules, x, y)) {
            return;
        }

        modules[y][x] = value;
        functionModules[y][x] = true;
    }

    private function isInsideMatrix(modules, x, y) {
        return y >= 0 && y < modules.size() && x >= 0 && x < modules[y].size();
    }

    private function gfMultiply(a, b) {
        if (a == 0 || b == 0) {
            return 0;
        }

        var index = _gfLog[a] + _gfLog[b];
        if (index >= 255) {
            index -= 255;
        }

        return _gfExp[index];
    }

    private function absValue(value) {
        if (value < 0) {
            return 0 - value;
        }

        return value;
    }

    private function pow2(exponent) {
        var result = 1;

        for (var i = 0; i < exponent; i += 1) {
            result *= 2;
        }

        return result;
    }

    private function sqrtApprox(value) {
        if (value <= 0) {
            return 0;
        }

        var low = 0.0;
        var high = value;
        if (high < 1.0) {
            high = 1.0;
        }

        for (var i = 0; i < 12; i += 1) {
            var mid = (low + high) / 2.0;
            if ((mid * mid) > value) {
                high = mid;
            } else {
                low = mid;
            }
        }

        return low;
    }

    private function containsText(value, needle) {
        if (needle.length() == 0) {
            return true;
        }

        if (value.length() < needle.length()) {
            return false;
        }

        for (var i = 0; i <= (value.length() - needle.length()); i += 1) {
            if (GarminCardsData.stringEquals(value.substring(i, i + needle.length()), needle)) {
                return true;
            }
        }

        return false;
    }

    private function applyBrightnessState() {
        if (!(Attention has :backlight)) {
            _isBrightnessMax = false;
            return;
        }

        try {
            if (GarminCardsData.isCiq5OrNewer()) {
                Attention.backlight(_isBrightnessMax ? 1.0 : 0.0);
            } else {
                Attention.backlight(_isBrightnessMax);
            }
        } catch(e) {
            try {
                Attention.backlight(_isBrightnessMax);
            } catch(inner) {
                _isBrightnessMax = false;
            }
        }
    }

    private function safeCardValue(card, key) {
        try {
            return card[key];
        } catch(e) {
            return null;
        }
    }

    private function log(message) {
    }

    private function minValue(a, b) {
        if (a < b) {
            return a;
        }

        return b;
    }

    public function onHide() {
        _isBrightnessMax = false;
        _isCodeFullscreen = false;
        applyBrightnessState();
        View.onHide();
    }

    private function toInt(value) {
        return value.toNumber();
    }
}
