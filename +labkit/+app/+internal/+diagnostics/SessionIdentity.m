classdef (Hidden, Sealed) SessionIdentity
    %SESSIONIDENTITY Create private session identifiers without RNG side effects.

    methods (Static)
        function sessionId = create(appId)
            if nargin < 1
                appId = "";
            end
            temporaryPath = string(tempname);
            [~, leaf] = fileparts(temporaryPath);
            timestamp = string(datetime("now", TimeZone="UTC", ...
                Format="yyyyMMdd-HHmmss"));
            appId = string(appId);
            if strlength(appId) > 0
                stem = "session-" + appId + "-" + timestamp;
            else
                stem = "session-" + timestamp;
            end
            sessionId = labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                stem + "-" + string(leaf), "sessionId");
        end
    end
end
