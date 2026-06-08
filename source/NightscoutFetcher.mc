import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;


class NightscoutFetcher {

    private var _model    as BgModel;
    private var _callback as SugrMonView;

    function initialize(model as BgModel, callback as SugrMonView) {
        _model    = model;
        _callback = callback;
    }


    function fetch() as Void {
        //var url = _model.nightscoutUrl;
        var url = "https://glucose-anton.herokuapp.com";

        if (url == null || url.equals("")) {
            _model.isLoading = false;
            _callback.onNoUrl();
            return;
        }

        var fullUrl = url + "/api/v1/entries.json?count=2";
        var token   = _model.nightscoutToken;
        if (token != null && !token.equals("")) {
            fullUrl = fullUrl + "&token=" + token;
        }

        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Accept" => "application/json"
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        _model.isLoading = true;
        _model.hasError  = false;

        Communications.makeWebRequest(fullUrl, null, options, method(:onResponse));
    }
    
    function onResponse(responseCode as Number, data as Dictionary?) as Void {
        _model.isLoading = false;

        if (responseCode != 200) {
            _callback.onError("HTTP " + responseCode.toString());
            return;
        }

        var dataArray = data as Array;
        if (dataArray == null || data.size() == 0) {
            _callback.onError("No data");
            return;
        }

        var latest = dataArray[0] as Dictionary;

        // Extract SGV (sensor glucose value) in mg/dL
        var sgv = latest["sgv"];
        if (!(sgv instanceof Number)) {
            _callback.onError("Bad SGV");
            return;
        }
        var valueMgdl = sgv.toFloat();

        // Raw Nightscout direction string (passed straight to the renderer)
        var dir       = latest["direction"];
        var direction = (dir instanceof String) ? dir : "NONE";

        // Delta: difference between the two most recent readings
        var delta = 0.0f;
        if (data.size() >= 2) {
            var prev = data[1] as Dictionary;
            var prevSgv = prev["sgv"];
            if (prevSgv instanceof Number) {
                delta = valueMgdl - prevSgv.toFloat();
            }
        }

        // Age of the reading in seconds
        var nowSec  = Time.now().value();
        var readSec = nowSec;
        var dateVal = latest["date"];  // epoch milliseconds
        if (dateVal instanceof Number) {
            readSec = (dateVal / 1000).toNumber();
        } else if (dateVal instanceof Long) {
            readSec = (dateVal / 1000l).toNumber();
        }
        var age = (nowSec - readSec).toNumber();
        if (age < 0) { age = 0; }

        var bgData = new BgData(valueMgdl, direction, delta, age);
        _callback.onData(bgData);
    }
}

