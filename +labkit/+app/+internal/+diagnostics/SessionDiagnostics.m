classdef (Hidden, Sealed) SessionDiagnostics < handle
    %SESSIONDIAGNOSTICS Own one Runtime's canonical event and journal services.
    % RuntimeFactory is the production creator. RuntimeKernel uses this private
    % boundary for semantic operations, viewer snapshots, trace capture, and
    % orderly persistence teardown. App callbacks never receive this object.

    properties (Access = private)
        Stream
        Projection
        Journal
        Closed (1, 1) logical = false
    end

    methods
        function obj = SessionDiagnostics(stream, projection, journal)
            if ~isa(stream, "labkit.app.internal.diagnostics.SessionEventStream") || ...
                    ~isscalar(stream)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionDiagnostics requires one SessionEventStream.");
            end
            if ~isa(projection, ...
                    "labkit.app.internal.diagnostics.SessionJournalProjection") || ...
                    ~isscalar(projection)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionDiagnostics requires one journal projection.");
            end
            if ~isa(journal, "labkit.app.internal.diagnostics.SessionJournal") || ...
                    ~isscalar(journal)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionDiagnostics requires one SessionJournal.");
            end
            obj.Stream = stream;
            obj.Projection = projection;
            obj.Journal = journal;
        end

        function operation = begin(obj, category, eventName, message, varargin)
            operation = obj.Stream.begin( ...
                category, eventName, message, varargin{:});
            if strlength(operation.ParentId) == 0
                obj.Journal.flushDurably();
            end
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

        function checkpoint(obj, eventName, message, varargin)
            obj.Stream.log("debug", eventName, message, varargin{:});
            obj.Journal.flushDurably();
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
