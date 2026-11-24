function applicationState = exportMetrics(applicationState, callbackContext)
    session = applicationState.session;
    if isempty(session.result)
        return;
    end
    choice = callbackContext.chooseOutputFile( ...
        ["*.csv", "CSV files (*.csv)"], "emg_pair_metrics.csv");
    if choice.Cancelled
        return;
    end
    metrics = session.result.metrics;
    pairCount = height(metrics);
    metrics.Channel = repmat(session.channel, pairCount, 1);
    metrics.Unit = repmat(session.signal.unit, pairCount, 1);
    metrics.SampleRate_Hz = repmat(session.signal.fs, pairCount, 1);
    metrics.MeasurementBand = repmat(session.band, pairCount, 1);
    try
        writetable(metrics, string(choice.Value));
    catch cause
        callbackContext.log("error", "emg_review.export.failed", ...
            "Writing EMG pair metrics failed.", Exception=cause);
        callbackContext.alert(cause.message, "Could not export pair metrics");
        return;
    end
    callbackContext.log("info", "emg_review.export.completed", "Exported EMG pair metrics.");
end
