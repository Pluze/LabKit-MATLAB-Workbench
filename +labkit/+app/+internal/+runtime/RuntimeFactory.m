classdef (Hidden, Sealed) RuntimeFactory
    % Internal runtime construction boundary.

    methods (Static)
        function runtime = create( ...
                platform, definition, initialState, backend, journal)
            if nargin < 3
                initialState = [];
            end
            if nargin < 4
                backend = struct();
            end
            if nargin < 5
                journal = [];
            end
            if ~isa(definition, "labkit.app.Definition") || ...
                    ~isscalar(definition)
                error("labkit:app:runtime:InvariantFailure", ...
                    "RuntimeFactory requires one Definition.");
            end
            journal = prepareJournal(definition, journal);
            try
                stream = labkit.app.internal.diagnostics.SessionEventStream(definition, ...
                    SessionId=journal.sessionId(), ProjectionHook=@journal.append, ...
                    ProjectionHealthHook=@journal.drainHealth);
                recorder = labkit.app.internal.diagnostics.SessionDiagnostics( ...
                    stream, journal);
            catch cause
                try
                    journal.close();
                catch
                    % Journal teardown must not hide the construction failure.
                end
                rethrow(cause);
            end
            try
                runtime = labkit.app.internal.runtime.RuntimeKernel( ...
                    definition, definition.Compiled, initialState, ...
                    backend, platform, recorder);
            catch cause
                recorder.close();
                rethrow(cause);
            end
        end
    end
end

function journal = prepareJournal(definition, journal)
if isempty(journal)
    journal = labkit.app.internal.diagnostics.SessionJournal(definition);
    return;
end
if ~isa(journal, "labkit.app.internal.diagnostics.SessionJournal") || ~isscalar(journal)
    error("labkit:app:runtime:InvariantFailure", ...
        "RuntimeFactory journal seam requires one SessionJournal.");
end
end
