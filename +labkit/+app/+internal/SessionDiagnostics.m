classdef (Hidden, Sealed) SessionDiagnostics < handle
    %SESSIONDIAGNOSTICS Own one Runtime's canonical event and journal services.
    % RuntimeFactory is the production creator. RuntimeKernel uses this private
    % boundary for semantic operations, viewer snapshots, trace capture, and
    % orderly persistence teardown. App callbacks never receive this object.

    properties (Access = private)
        Application
        Stream
        Projection
        Journal
        Closed (1, 1) logical = false
    end

    methods
        function obj = SessionDiagnostics( ...
                application, stream, projection, journal)
            if ~isa(application, "labkit.app.Definition") || ...
                    ~isscalar(application)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionDiagnostics requires one Definition.");
            end
            if ~isa(stream, "labkit.app.internal.SessionEventStream") || ...
                    ~isscalar(stream)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionDiagnostics requires one SessionEventStream.");
            end
            if ~isa(projection, ...
                    "labkit.app.internal.SessionJournalProjection") || ...
                    ~isscalar(projection)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionDiagnostics requires one journal projection.");
            end
            if ~isa(journal, "labkit.app.internal.SessionJournal") || ...
                    ~isscalar(journal)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionDiagnostics requires one SessionJournal.");
            end
            obj.Application = application;
            obj.Stream = stream;
            obj.Projection = projection;
            obj.Journal = journal;
        end

        function operation = begin(obj, category, eventName, message, varargin)
            operation = obj.Stream.begin( ...
                category, eventName, message, varargin{:});
        end

        function finish(obj, operation, operationResult, ...
                stateDisposition, exception)
            if nargin < 5
                exception = [];
            end
            obj.Stream.finish( ...
                operation, operationResult, stateDisposition, exception);
        end

        function log(obj, severity, eventName, message, varargin)
            obj.Stream.log(severity, eventName, message, varargin{:});
        end

        function events = events(obj)
            events = obj.Stream.records();
        end

        function snapshot = captureSnapshot(obj)
            streamSnapshot = obj.Stream.captureSnapshot();
            manifest = obj.Journal.manifest();
            health = obj.Journal.healthSnapshot();
            degradation = manifest.degradation;
            snapshot = struct( ...
                "events", streamSnapshot.events, ...
                "traceEnabled", streamSnapshot.traceEnabled, ...
                "inMemoryTruncated", streamSnapshot.inMemoryTruncated, ...
                "retainedRecordCount", ...
                    streamSnapshot.retainedRecordCount, ...
                "totalRecordCount", streamSnapshot.totalRecordCount, ...
                "journalAvailable", health.available, ...
                "journalState", string(health.state), ...
                "droppedRecordCount", ...
                    double(degradation.droppedRecordCount), ...
                "coalescedRecordCount", ...
                    double(degradation.coalescedRecordCount), ...
                "expiredSegmentCount", ...
                    double(degradation.expiredSegmentCount), ...
                "degradationReason", ...
                    string(health.degradationReason));
        end

        function token = subscribe(obj, callback)
            token = obj.Stream.subscribe(callback);
        end

        function unsubscribe(obj, token)
            obj.Stream.unsubscribe(token);
        end

        function setTraceEnabled(obj, enabled)
            obj.Stream.setTraceEnabled(enabled);
        end

        function destination = exportBundle( ...
                obj, destination, excludeOperationId, ...
                privateState, stateMode)
            if nargin < 3
                excludeOperationId = "";
            end
            if nargin < 4
                privateState = [];
            end
            if nargin < 5
                stateMode = "exact";
            end
            obj.Journal.flush();
            streamSnapshot = obj.Stream.captureSnapshot();
            manifest = obj.Journal.manifest();
            events = streamSnapshot.events;
            degradation = manifest.degradation;
            try
                archived = ...
                    labkit.app.internal.SessionJournalArchive.snapshot( ...
                    obj.Journal.rootFolder(), ...
                    obj.Journal.sessionId());
                events = mergeEvents( ...
                    archived.events, streamSnapshot.events);
                degradation = archived.degradation;
            catch
                % A surviving in-memory stream remains exportable when the
                % persistent journal is unavailable or unreadable.
            end
            if strlength(string(excludeOperationId)) > 0 && ...
                    ~isempty(events)
                events = events( ...
                    string({events.operationId}) ~= ...
                        string(excludeOperationId));
            end
            capture = struct( ...
                "traceEnabled", streamSnapshot.traceEnabled, ...
                "inMemoryTruncated", ...
                    streamSnapshot.inMemoryTruncated, ...
                "retainedRecordCount", ...
                    streamSnapshot.retainedRecordCount, ...
                "totalRecordCount", ...
                    streamSnapshot.totalRecordCount);
            snapshot = struct( ...
                "manifest", manifest, "events", events, ...
                "degradation", degradation, "capture", capture);
            destination = ...
                labkit.app.internal.SessionDiagnosticBundle.write( ...
                snapshot, destination, privateState, stateMode);
        end

        function destination = exportTextFallback( ...
                obj, preferredDestination, failure, stateMode)
            if nargin < 4
                stateMode = "exact";
            end
            % Keep this path independent of the journal and ZIP staging so a
            % failure in either subsystem cannot consume the last evidence.
            try
                streamSnapshot = obj.Stream.captureSnapshot();
                events = streamSnapshot.events;
                capture = struct( ...
                    "traceEnabled", streamSnapshot.traceEnabled, ...
                    "inMemoryTruncated", ...
                        streamSnapshot.inMemoryTruncated);
            catch
                events = [];
                capture = struct( ...
                    "traceEnabled", false, ...
                    "inMemoryTruncated", true);
            end
            sdk = labkit.app.version();
            application = struct( ...
                "title", obj.Application.Title, ...
                "appId", obj.Application.AppId, ...
                "appVersion", obj.Application.AppVersion, ...
                "labkitAppVersion", string(sdk.current));
            failureIdentifier = "unknown";
            if isa(failure, "MException") && ...
                    strlength(string(failure.identifier)) > 0
                failureIdentifier = string(failure.identifier);
            end
            snapshot = struct( ...
                "application", application, ...
                "events", events, ...
                "capture", capture, ...
                "failureIdentifier", failureIdentifier);
            destination = ...
                labkit.app.internal.SessionDiagnosticBundle.writeFallback( ...
                snapshot, preferredDestination, stateMode);
        end

        function close(obj)
            if obj.Closed
                return;
            end
            try
                obj.Stream.close();
            catch
                % Stream teardown must not prevent projection cleanup.
            end
            try
                obj.Projection.close();
            catch
                % Journal teardown must not change Runtime close semantics.
            end
            try
                obj.Stream.refreshProjectionHealth();
            catch
                % Health refresh must not change Runtime close semantics.
            end
            obj.Closed = true;
        end

        function delete(obj)
            obj.close();
        end
    end
end

function value = mergeEvents(archived, retained)
if isempty(archived)
    value = retained(:);
    return;
end
if isempty(retained)
    value = archived(:);
    return;
end
combined = [archived(:); retained(:)];
sequences = double([combined.sequence]);
[~, last] = unique(sequences, "last");
value = combined(last);
[~, order] = sort(double([value.sequence]));
value = value(order);
end
