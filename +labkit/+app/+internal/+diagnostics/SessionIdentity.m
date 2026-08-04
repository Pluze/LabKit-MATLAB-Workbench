classdef (Hidden, Sealed) SessionIdentity
    %SESSIONIDENTITY Create private session identifiers without RNG side effects.

    methods (Static)
        function sessionId = create()
            temporaryPath = string(tempname);
            [~, leaf] = fileparts(temporaryPath);
            sessionId = labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                "session-" + string(leaf), "sessionId");
        end
    end
end
