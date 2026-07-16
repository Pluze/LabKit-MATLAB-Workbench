% Private UI runtime helper. Expected callers are startup orchestration
% helpers. Inputs are an optional reporter and one phase message. Reporting is
% best-effort and must never change whether app startup succeeds.
function reportStartupProgress(reporter, message)
    if ~isa(reporter, 'function_handle')
        return;
    end
    try
        reporter(string(message));
    catch
    end
end
