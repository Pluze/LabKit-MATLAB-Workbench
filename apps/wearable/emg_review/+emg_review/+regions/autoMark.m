function applicationState = autoMark(applicationState, callbackContext)
    session = applicationState.session;
    otherPairs = session.pairs;
    otherPairs(session.pairIndex, :) = [];
    try
        [values, edge] = emg_review.analysisRun.prepare(session.signal, session.band);
        starts = emg_review.regions.suggest(values, session.signal.fs, ...
            edge, session.windowSeconds, otherPairs);
    catch cause
        callbackContext.log("error", "emg_review.automark.failed", ...
            "Automatic window selection failed.", Exception=cause);
        callbackContext.alert(cause.message, "Could not mark windows");
        return;
    end
    applicationState.session.pairs(session.pairIndex, :) = starts;
    applicationState = emg_review.regions.settingsChanged(applicationState, [], []);
    applicationState.session.analysisStatus = "Automatic marks applied. Review both windows before analyzing.";
    callbackContext.log("info", "emg_review.automark.completed", ...
        "Suggested a baseline and activity window.");
end
