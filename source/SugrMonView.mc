import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Activity;


class SugrMonView extends WatchUi.DataField {    
    private const GRAY   = 0xAAAAAA;

    private var _model         as BgModel;
    private var _fetcher       as NightscoutFetcher;    
    private var _lastFetchSec  as Number = 0;        // Epoch-seconds timestamp of the last completed fetch (0 = never).    
    private var _fetchInFlight as Boolean = false;   // True while an HTTP request is already in flight, to avoid overlap.    
    private var _noUrl         as Boolean = false;   // Set when the URL is not yet configured.    
    private var _fontMini      as Graphics.FontType?;
    

    function initialize() {
        DataField.initialize();

        _model    = new BgModel();
        _model.loadSettings();

        _fetcher  = new NightscoutFetcher(_model, self);
       
        _fontMini = WatchUi.loadResource(Rez.Fonts.SugrFontMini)  as Graphics.FontType;        
    }

    
    function onShow() as Void {
        _model.loadSettings();
    }

    function onData(data as BgData) as Void {
        _noUrl          = false;
        _fetchInFlight  = false;
        _model.current  = data;
        _model.hasError = false;
        _model.errorMsg = "";
        _lastFetchSec   = Time.now().value().toNumber();
        WatchUi.requestUpdate();
    }

    function onError(msg as String) as Void {
        _noUrl          = false;
        _fetchInFlight  = false;
        _model.hasError = true;
        _model.errorMsg = msg;        
        WatchUi.requestUpdate();
    }

    function onNoUrl() as Void {
        _noUrl          = true;
        _fetchInFlight  = false;
        _model.hasError = false;
        WatchUi.requestUpdate();
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        if (!_fetchInFlight) {
            var nowSec      = Time.now().value().toNumber();
            var intervalSec = _model.fetchIntervalMin * 60;
            var firstFetch  = (_lastFetchSec == 0);
            var due         = (nowSec - _lastFetchSec) >= intervalSec;

            if (firstFetch || due) {
                _model.loadSettings();
                _fetchInFlight = true;
                _fetcher.fetch();
            }
        }
        return null;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Background
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();

        // Determine what to draw
        if (_noUrl) {
            drawCentred(dc, w, h / 2, "Set NS URL", Graphics.COLOR_LT_GRAY, Graphics.FONT_XTINY);
            return;
        }

        if (_model.isLoading && _model.current == null) {
            drawCentred(dc, w, h / 2, "Loading...", Graphics.COLOR_LT_GRAY, Graphics.FONT_XTINY);
            return;
        }

        if (_model.hasError && _model.current == null) {
            drawCentred(dc, w, h / 2, _model.errorMsg, Graphics.COLOR_RED, Graphics.FONT_XTINY);
            return;
        }

        var bg = _model.current;
        if (bg == null) {
            drawCentred(dc, w, h / 2, "---", Graphics.COLOR_LT_GRAY, Graphics.FONT_XTINY);
            return;
        }
        
        var level   = _model.getLevel(bg.value);
        var fgColor = _model.getColorForLevel(level);

        var row0Y = (h * 0.45).toNumber();
        var row1Y = row0Y + 20;
        //var row2Y = row1Y + 18;
        
        var valueStr = _model.formatValue(bg.value);
        var arrowStr = _model.directionToArrow(bg.direction);
        var mainStr  = valueStr + " " + arrowStr;

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, row0Y, _fontMini, mainStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        var deltaStr = _model.formatDelta(bg.delta);
        if (_model.useMmol) {
            deltaStr = deltaStr + " mmol";
        } else {
            deltaStr = deltaStr + " mg/dL";
        }
        dc.setColor(GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, row1Y, _fontMini, deltaStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        /*
        var ageColor = GRAY;
        var ageStr   = formatAge(bg.age);

        if (bg.age > 900) {
            ageColor = 0xFF8800;
            ageStr   = "!" + ageStr;
        }

        if (_model.hasError) {
            ageStr   = ageStr + " ERR";
            ageColor = Graphics.COLOR_RED;
        }        

        dc.setColor(ageColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, row2Y, _fontMini, ageStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        */
    }

    
    private function drawCentred(dc as Dc, w as Number, y as Number, text as String, color as Number, font as Graphics.FontType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Convert an age in seconds to a short human-readable string.
    // e.g. 65 → "1m", 125 → "2m", 3700 → "1h"
    private function formatAge(ageSeconds as Number) as String {
        if (ageSeconds < 60) { return ageSeconds.toString() + "s"; }
        
        var mins = (ageSeconds / 60).toNumber();
        if (mins < 60) { return mins.toString() + "m"; }
        
        var hrs = (mins / 60).toNumber();        
        return hrs.toString() + "h";
    }
}
