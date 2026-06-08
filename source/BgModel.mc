import Toybox.Lang;
import Toybox.Math;


enum BgLevel {
    LEVEL_CRITICAL_LOW,
    LEVEL_ACCEPTABLE_LOW,
    LEVEL_NORMAL_LOW,
    LEVEL_NORMAL,
    LEVEL_NORMAL_HIGH,
    LEVEL_ACCEPTABLE_HIGH,
    LEVEL_CRITICAL_HIGH,
    LEVEL_UNKNOWN        
}

class BgData {
    var value     as Float;   // mg/dL
    var direction as String;  // raw Nightscout direction string, e.g. "SingleUp"
    var delta     as Float;   // mg/dL change since last reading
    var age       as Number;  // seconds since this reading was taken

    function initialize(value as Float, direction as String, delta as Float, age as Number) {
        self.value     = value;
        self.direction = direction;
        self.delta     = delta;
        self.age       = age;
    }
}

class BgModel {

    const WHITE  = 0xFFFFFF; 
    const GRAY   = 0xAAAAAA;
    const RED    = 0xFE0000;
    const ORANGE = 0xFF5D00;
    const YELLOW = 0xFFA800; 
    const GREEN  = 0x00C201; 

    var current          as BgData?;
    var isLoading        as Boolean = false;
    var hasError         as Boolean = false;
    var errorMsg         as String  = "";
    
    var criticalMin      as Number  = 55;
    var acceptableMin    as Number  = 70;
    var normalMin        as Number  = 80;
    var normalMax        as Number  = 140;
    var acceptableMax    as Number  = 180;
    var criticalMax      as Number  = 250;

    var nightscoutUrl    as String  = "";
    var nightscoutToken  as String  = "";    
    var fetchIntervalMin as Number  = 5;

    var useMmol          as Boolean = false;
    var useMonochrome    as Boolean = false;


    function initialize() {
    }


    function loadSettings() as Void {    
        var url = Application.Properties.getValue("NightscoutUrl");        
        if (url instanceof String) { nightscoutUrl = url; }

        var token = Application.Properties.getValue("NightscoutToken");
        if (token instanceof String) { nightscoutToken = token; }

        var iv = Application.Properties.getValue("FetchIntervalMin");
        if (iv instanceof Number) { fetchIntervalMin = iv; }

        var cMin = Application.Properties.getValue("CriticalMin");
        if (cMin instanceof Number) { criticalMin = cMin; }

        var aMin = Application.Properties.getValue("AcceptableMin");
        if (aMin instanceof Number) { acceptableMin = aMin; }

        var nMin = Application.Properties.getValue("NormalMin");
        if (nMin instanceof Number) { normalMin = nMin; }

        var nMax = Application.Properties.getValue("NormalMax");
        if (nMax instanceof Number) { normalMax = nMax; }

        var aMax = Application.Properties.getValue("AcceptableMax");
        if (aMax instanceof Number) { acceptableMax = aMax; }

        var cMax = Application.Properties.getValue("CriticalMax");
        if (cMax instanceof Number) { criticalMax = cMax; }

        var mm = Application.Properties.getValue("UseMmol");
        if (mm instanceof Boolean) { useMmol = mm; }

        var um = Application.Properties.getValue("UseMonochrome");
        if (um instanceof Boolean) { useMonochrome = um; }
    }

    
    function getLevel(mgdl as Float) as BgLevel {
        if (mgdl < criticalMin)   { return LEVEL_CRITICAL_LOW;    }
        if (mgdl < acceptableMin) { return LEVEL_ACCEPTABLE_LOW;  }
        if (mgdl < normalMin)     { return LEVEL_NORMAL_LOW;      }
        if (mgdl <= normalMax)    { return LEVEL_NORMAL;          }
        if (mgdl <= acceptableMax){ return LEVEL_NORMAL_HIGH;     }
        if (mgdl <= criticalMax)  { return LEVEL_ACCEPTABLE_HIGH; }
        return LEVEL_CRITICAL_HIGH;
    }
    
    function getColorForLevel(level as BgLevel) as Number {
        if (useMonochrome)  {
            return WHITE;
        } else {
            switch (level) {
                case LEVEL_NORMAL: 
                    return GREEN;
                case LEVEL_NORMAL_LOW:
                case LEVEL_NORMAL_HIGH:
                    return YELLOW;
                case LEVEL_ACCEPTABLE_LOW:
                case LEVEL_ACCEPTABLE_HIGH:
                    return ORANGE;
                case LEVEL_CRITICAL_LOW:
                case LEVEL_CRITICAL_HIGH:
                default:
                    return RED;
            }
        }
    }

    function toMmol(mgdl as Float) as Float {
        return Math.round(mgdl / 18.0 * 10.0) / 10.0;
    }

    function formatValue(mgdl as Float) as String {
        if (useMmol) {
            var mmol = toMmol(mgdl);
            // Format to one decimal place manually (Monkey C has limited printf)
            var whole = mmol.toNumber();
            var frac  = ((mmol - whole) * 10).toNumber().abs();
            return whole.toString() + "." + frac.toString();
        } else {
            return mgdl.toNumber().toString();
        }
    }

    function formatDelta(delta as Float) as String {
        var prefix = (delta >= 0.0) ? "+" : "";
        if (useMmol) {
            var mmolDelta = toMmol(delta.abs()) * (delta >= 0.0 ? 1.0 : -1.0);
            var whole = mmolDelta.toNumber();
            var frac  = ((mmolDelta.abs() - whole.abs()) * 10).toNumber().abs();
            return prefix + whole.toString() + "." + frac.toString();
        } else {
            return prefix + delta.toNumber().toString();
        }
    }
        
    function directionToArrow(direction as String) as String {                
        if (direction.equals("DoubleUp"))      { return Application.loadResource(Rez.Strings.SingleUp)      as String + Application.loadResource(Rez.Strings.SingleUp) as String; }
        if (direction.equals("SingleUp"))      { return Application.loadResource(Rez.Strings.SingleUp)      as String; }
        if (direction.equals("FortyFiveUp"))   { return Application.loadResource(Rez.Strings.FortyFiveUp)   as String; }
        if (direction.equals("Flat"))          { return Application.loadResource(Rez.Strings.Flat)          as String; }
        if (direction.equals("FortyFiveDown")) { return Application.loadResource(Rez.Strings.FortyFiveDown) as String; }
        if (direction.equals("SingleDown"))    { return Application.loadResource(Rez.Strings.SingleDown)    as String; }
        if (direction.equals("DoubleDown"))    { return Application.loadResource(Rez.Strings.SingleDown)    as String + Application.loadResource(Rez.Strings.SingleDown) as String; }
        return "?";
    }
}