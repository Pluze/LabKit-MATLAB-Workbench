function applicationState = analyze(applicationState, callbackContext)
    session = applicationState.session;
    try
        result = emg_review.analysisRun.measure(session.signal, session.band, ...
            session.pairs, session.windowSeconds);
    catch cause
        callbackContext.log("error", "emg_review.analysis.failed", ...
            "EMG analysis failed.", Exception=cause);
        applicationState.session.analysisStatus = string(cause.message);
        callbackContext.alert(cause.message, "Could not analyze EMG");
        return;
    end
    applicationState.session.result = result;
    valid = nnz(isfinite(result.metrics.SNR_dB));
    total = height(result.metrics);
    applicationState.session.analysisStatus = sprintf("%d pair(s) measured; %d with defined SNR.", total, valid);
    callbackContext.log("info", "emg_review.analysis.completed", ...
        sprintf("Measured %d EMG window pair(s).", total));
end
