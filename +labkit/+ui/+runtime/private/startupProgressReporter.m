% Private UI runtime helper. Expected callers are Runtime V2 launch and the
% compatibility create path. Input is a launch request that may carry a
% launcher-owned startupProgress callback. Output is a best-effort progress
% reporter; hidden/minimized GUI tests remain silent.
function reporter = startupProgressReporter(request)
    reporter = [];
    if isstruct(request) && isfield(request, 'startupProgress') && ...
            isa(request.startupProgress, 'function_handle')
        reporter = request.startupProgress;
        return;
    end
    mode = lower(strtrim(string(getenv('LABKIT_GUI_TEST_MODE'))));
    if mode == "hidden" || mode == "minimized"
        return;
    end
    reporter = @writeProgress;
end

function writeProgress(message)
    fprintf('[LabKit startup] %s\n', char(string(message)));
end
