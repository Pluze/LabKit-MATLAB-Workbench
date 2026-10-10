function applicationState = analyze(applicationState, callbackContext)
%ANALYZE Commit one ECGNExT result and report its actual extraction status.
if isempty(applicationState.session.cache.signal) || applicationState.session.importDirty, return; end
clockStart = tic; lastHeartbeat = 0;
try
    cache = ecg_print.analysisRun.analyzeSignal(applicationState.session.cache, ...
        applicationState.project.parameters,@progress);
catch cause
    applicationState = ecg_print.analysisRun.clearAnalysis(applicationState);
    applicationState.session.analysisStatus = string(cause.message);
    callbackContext.log("error","ecg_print.analysisrun.failed", ...
        "ECGNExT analysis failed.", Exception=cause);
    callbackContext.alert(cause.message,"Analysis failed");
    return;
end
cache.plotViewRevision = cache.plotViewRevision+1;
applicationState.session.cache = cache;
applicationState.session.analysisStatus = string(cache.ecgNext.status);
complete = cache.ecgNext.perBeat.Status == "complete";
applicationState.project.results = struct('measuredBeatCount',nnz(complete), ...
    'beatCount',height(cache.ecgNext.perBeat));
facts = struct('beatCount',height(cache.ecgNext.perBeat), ...
    'measuredBeatCount',nnz(complete),'windowCount',numel(cache.ecgNext.windows), ...
    'reason',cache.ecgNext.statusCode);
if cache.ecgNext.ok
    callbackContext.log("info","ecg_print.analysisrun.ecgnext.completed", ...
        string(cache.ecgNext.status),Attributes=facts);
else
    callbackContext.log("info","ecg_print.analysisrun.ecgnext.unavailable", ...
        "ECGNExT requires a suitable interval and reliable R peaks.",Attributes=facts);
end
    function progress(completed,total)
        elapsed = toc(clockStart);
        if elapsed-lastHeartbeat >= 20
            callbackContext.log("debug","ecg_print.analysisrun.progress", ...
                "ECGNExT extraction windows.",Audience="developer", ...
                Attributes=struct('completedCount',completed,'totalCount',total));
            lastHeartbeat = elapsed;
            drawnow limitrate nocallbacks
        end
    end
end
