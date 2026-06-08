import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SugrMonApp extends Application.AppBase {

    private var _view as SugrMonView?;


    function initialize() {
        AppBase.initialize();
    }


    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view = new SugrMonView();
        return [_view];
    }

}

function getApp() as SugrMonApp {
    return Application.getApp() as SugrMonApp;
}