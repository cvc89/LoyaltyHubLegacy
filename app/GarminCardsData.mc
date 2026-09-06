using Toybox.Application;
using Toybox.System;
using Toybox.StringUtil as StringUtil;

module GarminCardsData {
    var _asciiCacheChars = [];
    var _asciiCacheValues = [];

    function isCiq5OrNewer() {
        var major = getMonkeyMajorVersion();
        return major != null && major >= 5;
    }

    function isAmoledDisplay() {
        try {
            var settings = System.getDeviceSettings();
            if (settings != null && (settings has :requiresBurnInProtection)) {
                return settings.requiresBurnInProtection == true;
            }
        } catch(e) {
        }

        return false;
    }

    function getMonkeyMajorVersion() {
        try {
            var settings = System.getDeviceSettings();
            if (settings == null || settings.monkeyVersion == null || settings.monkeyVersion.size() == 0) {
                return null;
            }

            var version = settings.monkeyVersion;
            var major = version[0];
            if (major == null) {
                return null;
            }

            return major.toNumber();
        } catch(e) {
            return null;
        }
    }

    function loadCards() {
        var cards = [];

        try {
            addBulkCards(cards, getStringSetting("bulk_cards"));
        } catch(e) {
        }

        for (var i = 1; i <= 15; i += 1) {
            var index = formatIndex(i);
            var store = getStringSetting("card" + index + "_store");
            var value = getStringSetting("card" + index + "_value");
            var card = null;
            try {
                card = parseCard(
                    store,
                    value
                );
            } catch(e) {
            }

            if (card != null) {
                cards.add(card);
            }
        }
        return cards;
    }

    function addBulkCards(cards, value) {
        var decodedValue = decodeStoredValue(value);
        var cleanValue = trimString(decodedValue);
        if (isBlank(cleanValue)) {
            return;
        }

        var start = 0;
        while (start < cleanValue.length()) {
            var separatorIndex = indexOfString(cleanValue, "<|::|>", start);
            var finish = separatorIndex < 0 ? cleanValue.length() : separatorIndex;
            try {
                addBulkCard(cards, cleanValue.substring(start, finish));
            } catch(e) {
            }

            if (separatorIndex < 0) {
                return;
            }

            start = separatorIndex + 6;
        }
    }

    function addBulkCard(cards, entry) {
        var cleanEntry = trimString(entry);
        if (isBlank(cleanEntry)) {
            return;
        }

        var firstSeparatorIndex = indexOfString(cleanEntry, "<|:|>", 0);
        var lastSeparatorIndex = lastIndexOfString(cleanEntry, "<|:|>");
        if (firstSeparatorIndex <= 0 || lastSeparatorIndex <= firstSeparatorIndex || lastSeparatorIndex >= (cleanEntry.length() - 1)) {
            return;
        }

        var store = cleanEntry.substring(0, firstSeparatorIndex);
        var code = cleanEntry.substring(firstSeparatorIndex + 5, lastSeparatorIndex);
        var typeValue = cleanEntry.substring(lastSeparatorIndex + 5, cleanEntry.length());
        var value = code + "|" + typeValue;
        var card = parseCard(store, value);
        if (card != null) {
            cards.add(card);
        }
    }

    function parseCard(store, value) {
        var cleanStore = trimString(store);
        var parsedValue = parseStoredValue(value);
        if (parsedValue == null) {
            parsedValue = parseStoredValue(decodeStoredValue(value));
        }

        if (isBlank(cleanStore) || parsedValue == null) {
            return null;
        }

        var cleanCode = parsedValue[:code];
        var selectedType = parsedValue[:type];
        var renderAsQr = stringEquals(selectedType, "QR");
        var resolvedType = renderAsQr ? "QR" : resolveCodeType(cleanCode, selectedType);
        return {
            :title => cleanStore,
            :code => cleanCode,
            :selectedType => selectedType,
            :codeType => resolvedType,
            :renderAsQr => renderAsQr,
            :merchant => cleanStore,
            :category => categoryFromType(resolvedType),
            :benefit => benefitFromType(resolvedType)
        };
    }

    function decodeStoredValue(value) {
        var cleanValue = trimString(value);
        if (isBlank(cleanValue)) {
            return "";
        }

        try {
            var raw = StringUtil.convertEncodedString(cleanValue, {
                :fromRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
                :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY
            });

            if (raw == null || raw.size() == 0) {
                return "";
            }

            return StringUtil.convertEncodedString(raw, {
                :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
                :toRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
                :encoding => StringUtil.CHAR_ENCODING_UTF8
            });
        } catch(e) {
            return cleanValue;
        }
    }

    function parseStoredValue(decodedValue) {
        var cleanValue = trimString(decodedValue);
        if (isBlank(cleanValue)) {
            return null;
        }

        var separatorIndex = lastIndexOfChar(cleanValue, "|");
        if (separatorIndex < 0 || separatorIndex >= (cleanValue.length() - 1)) {
            return null;
        }

        var cleanCode = trimString(cleanValue.substring(0, separatorIndex));
        var typeToken = trimString(cleanValue.substring(separatorIndex + 1, cleanValue.length()));
        if (isBlank(cleanCode)) {
            return null;
        }

        return {
            :code => cleanCode,
            :type => typeFromToken(typeToken)
        };
    }

    function categoryFromType(cardType) {
        if (stringEquals(cardType, "PHONE")) {
            return "Phones";
        }

        return "General";
    }

    function benefitFromType(cardType) {
        if (stringEquals(cardType, "PHONE")) {
            return "Quick phone access on your Garmin.";
        }

        return "Ready to view on your Garmin.";
    }

    function getStringSetting(key) {
        try {
            var value = Application.Properties.getValue(key);
            if (value == null) {
                return "";
            }

            return value.toString();
        } catch(e) {
            return "";
        }
    }

    function formatIndex(numberValue) {
        if (numberValue < 10) {
            return "0" + numberValue.toString();
        }

        return numberValue.toString();
    }

    function defaultString(value, fallback) {
        if (isBlank(value)) {
            return fallback;
        }

        return value;
    }

    function isBlank(value) {
        return value == null || trimString(value.toString()).length() == 0;
    }

    function trimString(value) {
        var start = 0;
        var finish = value.length() - 1;

        while (start < value.length() && isWhitespace(value.substring(start, start + 1))) {
            start += 1;
        }

        while (finish >= start && isWhitespace(value.substring(finish, finish + 1))) {
            finish -= 1;
        }

        if (finish < start) {
            return "";
        }

        return value.substring(start, finish + 1);
    }

    function isWhitespace(ch) {
        return stringEquals(ch, " ") || stringEquals(ch, "\t") || stringEquals(ch, "\n") || stringEquals(ch, "\r");
    }

    function typeFromValue(value) {
        if (value == 1) {
            return "EAN8";
        }

        if (value == 2) {
            return "UPCA";
        }

        if (value == 3) {
            return "EAN13";
        }

        if (value == 4) {
            return "ITF";
        }

        if (value == 5) {
            return "CODE39";
        }

        if (value == 6) {
            return "CODE128";
        }

        if (value == 7) {
            return "QR";
        }

        if (value == 8) {
            return "PHONE";
        }

        return "";
    }

    function typeFromToken(token) {
        var cleanToken = trimString(token);

        if (isBlank(cleanToken)) {
            return "";
        }

        if (isDigitsOnly(cleanToken)) {
            return typeFromValue(cleanToken.toNumber());
        }

        var upper = normalizeTypeToken(cleanToken);
        if (stringEquals(upper, "EAN8")) {
            return "EAN8";
        }

        if (stringEquals(upper, "UPCA")) {
            return "UPCA";
        }

        if (stringEquals(upper, "EAN13")) {
            return "EAN13";
        }

        if (stringEquals(upper, "ITF")) {
            return "ITF";
        }

        if (stringEquals(upper, "CODE39")) {
            return "CODE39";
        }

        if (stringEquals(upper, "CODE128")) {
            return "CODE128";
        }

        if (stringEquals(upper, "QR")) {
            return "QR";
        }

        if (stringEquals(upper, "QRCODE")) {
            return "QR";
        }

        if (stringEquals(upper, "PHONE")) {
            return "PHONE";
        }

        return "";
    }

    function normalizeTypeToken(token) {
        var upper = trimString(token).toUpper();
        var normalized = "";

        for (var i = 0; i < upper.length(); i += 1) {
            var ch = upper.substring(i, i + 1);
            if (!stringEquals(ch, "_") && !stringEquals(ch, "-") && !stringEquals(ch, " ")) {
                normalized += ch;
            }
        }

        normalized = removeTypeQualifier(normalized, "SIMPLIFICADO");
        normalized = removeTypeQualifier(normalized, "SIMPLIFIED");
        normalized = removeTypeQualifier(normalized, "SIMPLE");

        return normalized;
    }

    function removeTypeQualifier(value, qualifier) {
        if (endsWith(value, qualifier)) {
            return value.substring(0, value.length() - qualifier.length());
        }

        return value;
    }

    function resolveCodeType(code, selectedType) {
        if (isBlank(selectedType)) {
            return detectCodeType(code);
        }

        if (stringEquals(selectedType, "QR")) {
            return "QR";
        }

        if (stringEquals(selectedType, "PHONE")) {
            return "PHONE";
        }

        var compactType = detectCompactGs1CodeType(code);
        if (!isBlank(compactType)) {
            return compactType;
        }

        if (isCompatibleWithType(code, selectedType)) {
            return selectedType;
        }

        return detectCodeType(code);
    }

    function detectCompactGs1CodeType(code) {
        var normalized = normalizeCode(code);
        var length = normalized.length();
        if (!isDigitsOnly(normalized)) {
            return "";
        }

        if (length == 8 && isValidEan8(normalized)) {
            return "EAN8";
        }

        if (length == 12 && isValidUpca(normalized)) {
            return "UPCA";
        }

        if (length == 13 && isValidEan13(normalized)) {
            return "EAN13";
        }

        return "";
    }

    function detectCodeType(code) {
        var normalized = normalizeCode(code);
        var length = normalized.length();
        if (isDigitsOnly(normalized)) {
            if (length == 8 && isValidEan8(normalized)) {
                return "EAN8";
            }

            if (length == 12) {
                return "UPCA";
            }

            if (length == 13 && isValidEan13(normalized)) {
                return "EAN13";
            }

            if ((length % 2) == 0 && length >= 14) {
                return "ITF";
            }
        }

        if (isCode39Compatible(normalized)) {
            return "CODE39";
        }

        return "CODE128";
    }

    function isCompatibleWithType(code, codeType) {
        var normalized = normalizeCode(code);
        var length = normalized.length();

        if (stringEquals(codeType, "EAN8")) {
            return isDigitsOnly(normalized) && length == 8 && isValidEan8(normalized);
        }

        if (stringEquals(codeType, "UPCA")) {
            return isDigitsOnly(normalized) && length == 12;
        }

        if (stringEquals(codeType, "EAN13")) {
            return isDigitsOnly(normalized) && length == 13 && isValidEan13(normalized);
        }

        if (stringEquals(codeType, "ITF")) {
            return isDigitsOnly(normalized) && length >= 14 && ((length % 2) == 0);
        }

        if (stringEquals(codeType, "CODE39")) {
            return isCode39Compatible(normalized);
        }

        if (stringEquals(codeType, "CODE128")) {
            return normalized.length() > 0;
        }

        if (stringEquals(codeType, "QR")) {
            return isQrCompatible(code);
        }

        if (stringEquals(codeType, "PHONE")) {
            return trimString(code.toString()).length() > 0;
        }

        return false;
    }

    function isValidEan8(value) {
        return isValidWeightedCheckDigit(value, 7, 3);
    }

    function isValidUpca(value) {
        return isValidWeightedCheckDigit(value, 11, 3);
    }

    function isValidEan13(value) {
        return isValidWeightedCheckDigit(value, 12, 3);
    }

    function isValidWeightedCheckDigit(value, dataLength, rightmostWeight) {
        if (!isDigitsOnly(value) || value.length() != (dataLength + 1)) {
            return false;
        }

        var sum = 0;
        var useRightmostWeight = true;

        for (var i = dataLength - 1; i >= 0; i -= 1) {
            var digit = digitCharValue(value.substring(i, i + 1));
            sum += digit * (useRightmostWeight ? rightmostWeight : 1);
            useRightmostWeight = !useRightmostWeight;
        }

        var expected = (10 - (sum % 10)) % 10;
        return digitCharValue(value.substring(dataLength, dataLength + 1)) == expected;
    }

    function digitCharValue(ch) {
        return getAsciiValue(ch) - 48;
    }

    function isQrCompatible(code) {
        var value = trimString(code.toString());

        if (value.length() == 0 || value.length() > 32) {
            return false;
        }

        for (var i = 0; i < value.length(); i += 1) {
            var ch = value.substring(i, i + 1);
            if (!isBasicQrChar(ch)) {
                return false;
            }
        }

        return true;
    }

    function isLikelyQrContent(code) {
        var value = trimString(code.toString());
        var lower = value.toLower();

        if (!isQrCompatible(value)) {
            return false;
        }

        if (startsWith(lower, "http://") || startsWith(lower, "https://")) {
            return true;
        }

        if (containsString(value, "@") || containsString(value, "://")) {
            return true;
        }

        return false;
    }

    function normalizeCode(code) {
        var value = code.toString();
        var normalized = "";

        for (var i = 0; i < value.length(); i += 1) {
            var ch = value.substring(i, i + 1);
            if (!stringEquals(ch, " ") && !stringEquals(ch, "-")) {
                normalized += ch;
            }
        }

        return normalized;
    }

    function isDigitsOnly(value) {
        for (var i = 0; i < value.length(); i += 1) {
            var ch = value.substring(i, i + 1);
            if (!isDigitChar(ch)) {
                return false;
            }
        }

        return value.length() > 0;
    }

    function isCode39Compatible(value) {
        if (value.length() == 0) {
            return false;
        }

        var upper = value.toUpper();

        for (var i = 0; i < upper.length(); i += 1) {
            var ch = upper.substring(i, i + 1);
            if (!isCode39Char(ch)) {
                return false;
            }
        }

        return true;
    }

    function containsChar(haystack, needle) {
        for (var i = 0; i < haystack.length(); i += 1) {
            if (stringEquals(haystack.substring(i, i + 1), needle)) {
                return true;
            }
        }

        return false;
    }

    function lastIndexOfChar(haystack, needle) {
        for (var i = haystack.length() - 1; i >= 0; i -= 1) {
            if (stringEquals(haystack.substring(i, i + 1), needle)) {
                return i;
            }
        }

        return -1;
    }

    function lastIndexOfString(haystack, needle) {
        if (needle.length() == 0 || haystack.length() < needle.length()) {
            return -1;
        }

        for (var i = haystack.length() - needle.length(); i >= 0; i -= 1) {
            if (stringEquals(haystack.substring(i, i + needle.length()), needle)) {
                return i;
            }
        }

        return -1;
    }

    function containsString(haystack, needle) {
        return indexOfString(haystack, needle, 0) >= 0;
    }

    function indexOfString(haystack, needle, startIndex) {
        if (needle.length() == 0) {
            return startIndex;
        }

        if (haystack.length() < needle.length()) {
            return -1;
        }

        for (var i = startIndex; i <= (haystack.length() - needle.length()); i += 1) {
            if (stringEquals(haystack.substring(i, i + needle.length()), needle)) {
                return i;
            }
        }

        return -1;
    }

    function startsWith(value, prefix) {
        if (value.length() < prefix.length()) {
            return false;
        }

        return stringEquals(value.substring(0, prefix.length()), prefix);
    }

    function endsWith(value, suffix) {
        if (value.length() < suffix.length()) {
            return false;
        }

        return stringEquals(value.substring(value.length() - suffix.length(), value.length()), suffix);
    }

    function stringEquals(left, right) {
        if (left == null || right == null) {
            return left == null && right == null;
        }

        return left.toString().equals(right.toString());
    }

    function getAsciiValue(ch) {
        var key = ch.toString();

        for (var cacheIndex = 0; cacheIndex < _asciiCacheChars.size(); cacheIndex += 1) {
            if (stringEquals(_asciiCacheChars[cacheIndex], key)) {
                return _asciiCacheValues[cacheIndex];
            }
        }

        var ascii = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

        for (var i = 0; i < ascii.length(); i += 1) {
            if (stringEquals(ascii.substring(i, i + 1), key)) {
                var asciiValue = i + 32;
                _asciiCacheChars.add(key);
                _asciiCacheValues.add(asciiValue);
                return asciiValue;
            }
        }

        return -1;
    }

    function isBasicQrChar(ch) {
        var value = ch.toString();

        var ascii = getAsciiValue(value);
        return ascii >= 32 && ascii <= 126;
    }

    function isDigitChar(ch) {
        var ascii = getAsciiValue(ch);
        return ascii >= 48 && ascii <= 57;
    }

    function isUpperAlphaChar(ch) {
        var ascii = getAsciiValue(ch);
        return ascii >= 65 && ascii <= 90;
    }

    function isCode39Char(ch) {
        if (isDigitChar(ch) || isUpperAlphaChar(ch)) {
            return true;
        }

        return stringEquals(ch, "-") || stringEquals(ch, ".") || stringEquals(ch, " ") ||
               stringEquals(ch, "$") || stringEquals(ch, "/") || stringEquals(ch, "+") ||
               stringEquals(ch, "%");
    }

    function isAllowedQrSymbol(ch) {
        return stringEquals(ch, " ") || stringEquals(ch, "-") || stringEquals(ch, ".") ||
               stringEquals(ch, "_") || stringEquals(ch, ":") || stringEquals(ch, "/") ||
               stringEquals(ch, "?") || stringEquals(ch, "&") || stringEquals(ch, "=") ||
               stringEquals(ch, "%") || stringEquals(ch, "+") || stringEquals(ch, "#") ||
               stringEquals(ch, "@") || stringEquals(ch, "!") || stringEquals(ch, "$") ||
               stringEquals(ch, ",") || stringEquals(ch, ";") || stringEquals(ch, "*") ||
               stringEquals(ch, "(") || stringEquals(ch, ")") || stringEquals(ch, "[") ||
               stringEquals(ch, "]") || stringEquals(ch, "{") || stringEquals(ch, "}");
    }
}
