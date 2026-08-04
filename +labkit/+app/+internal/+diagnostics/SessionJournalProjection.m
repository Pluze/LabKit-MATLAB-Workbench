classdef (Hidden, Sealed) SessionJournalProjection < handle
    %SESSIONJOURNALPROJECTION Private non-recursive Journal health boundary.
    % RuntimeFactory owns this adapter; Apps never call it.

    properties (Access = private)
        Journal
        LastAvailable (1, 1) logical = true
        LastInvalidCanonicalRecordDropCount (1, 1) double = 0
        LastWriteFailureDropCount (1, 1) double = 0
        ProjectionAvailable (1, 1) logical = true
        ProjectionDegradationPending (1, 1) logical = false
        ProjectionDropCount (1, 1) double = 0
        LastReportedProjectionDropCount (1, 1) double = 0
        HealthUnavailableReported (1, 1) logical = false
        ProjectionFaultInjector = []
    end

    methods
        function obj = SessionJournalProjection(journal, projectionFaultInjector)
            if ~isa(journal, "labkit.app.internal.diagnostics.SessionJournal") || ~isscalar(journal)
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionJournalProjection requires one SessionJournal.");
            end
            if nargin < 2
                projectionFaultInjector = [];
            end
            if ~isempty(projectionFaultInjector) && ...
                    ~isa(projectionFaultInjector, "function_handle")
                error("labkit:app:runtime:InvariantFailure", ...
                    "SessionJournalProjection fault injector must be a function handle.");
            end
            obj.Journal = journal;
            obj.ProjectionFaultInjector = projectionFaultInjector;
        end

        function project(obj, record)
            try
                if ~isempty(obj.ProjectionFaultInjector)
                    obj.ProjectionFaultInjector("project");
                end
                obj.Journal.append(record);
                obj.ProjectionAvailable = true;
            catch
                if obj.ProjectionAvailable
                    obj.ProjectionDegradationPending = true;
                end
                obj.ProjectionAvailable = false;
                obj.ProjectionDropCount = obj.ProjectionDropCount + 1;
            end
        end

        function close(obj)
            try
                if ~isempty(obj.ProjectionFaultInjector)
                    obj.ProjectionFaultInjector("close");
                end
                obj.Journal.close();
            catch
                if obj.ProjectionAvailable
                    obj.ProjectionDegradationPending = true;
                end
                obj.ProjectionAvailable = false;
            end
        end

        function notifications = drainHealth(obj)
            notifications = emptyNotifications();
            if obj.ProjectionDegradationPending
                notifications(end + 1, 1) = notification( ...
                    "journal.degraded", "projection-failure", 0);
                obj.ProjectionDegradationPending = false;
            end
            projectionDropDelta = obj.ProjectionDropCount - ...
                obj.LastReportedProjectionDropCount;
            if projectionDropDelta > 0
                notifications(end + 1, 1) = notification( ...
                    "journal.records_dropped", "projection-failure", projectionDropDelta);
                obj.LastReportedProjectionDropCount = obj.ProjectionDropCount;
            end
            try
                snapshot = obj.Journal.healthSnapshot();
                snapshot = validateSnapshot(snapshot);
            catch
                if ~obj.HealthUnavailableReported
                    notifications(end + 1, 1) = notification( ...
                        "journal.degraded", "health-unavailable", 0);
                    obj.HealthUnavailableReported = true;
                end
                return;
            end
            if obj.LastAvailable && ~snapshot.available
                reason = snapshot.degradationReason;
                if strlength(reason) == 0
                    reason = "journal-unavailable";
                end
                notifications(end + 1, 1) = notification( ...
                    "journal.degraded", reason, 0);
            end
            invalidDelta = snapshot.invalidCanonicalRecordDropCount - ...
                obj.LastInvalidCanonicalRecordDropCount;
            if invalidDelta > 0
                notifications(end + 1, 1) = notification( ...
                    "journal.records_dropped", "invalid-canonical-record", invalidDelta);
            end
            writeFailureDelta = snapshot.writeFailureDropCount - ...
                obj.LastWriteFailureDropCount;
            if writeFailureDelta > 0
                notifications(end + 1, 1) = notification( ...
                    "journal.records_dropped", "write-failure", writeFailureDelta);
            end
            obj.LastAvailable = snapshot.available;
            obj.LastInvalidCanonicalRecordDropCount = ...
                snapshot.invalidCanonicalRecordDropCount;
            obj.LastWriteFailureDropCount = snapshot.writeFailureDropCount;
        end
    end
end

function notifications = emptyNotifications()
notifications = repmat(notification("", "", 0), 0, 1);
end

function value = notification(eventName, reason, count)
value = struct("eventName", string(eventName), "reason", string(reason), ...
    "count", double(count));
end

function snapshot = validateSnapshot(snapshot)
fields = ["state", "available", "droppedRecordCount", ...
    "invalidCanonicalRecordDropCount", "writeFailureDropCount", ...
    "writeFailureCount", "lastFailureReason", "degradationReason"];
if ~isstruct(snapshot) || ~isscalar(snapshot) || ...
        ~isequal(string(fieldnames(snapshot)), fields.')
    error("labkit:app:runtime:InvariantFailure", "Journal health snapshot is invalid.");
end
snapshot.state = string(snapshot.state);
snapshot.lastFailureReason = string(snapshot.lastFailureReason);
snapshot.degradationReason = string(snapshot.degradationReason);
if ~isscalar(snapshot.state) || ~any(snapshot.state == ["healthy", "unavailable", "closed"]) || ...
        ~isscalar(snapshot.lastFailureReason) || ismissing(snapshot.lastFailureReason) || ...
        ~isscalar(snapshot.degradationReason) || ismissing(snapshot.degradationReason) || ...
        ~(islogical(snapshot.available) && isscalar(snapshot.available))
    error("labkit:app:runtime:InvariantFailure", "Journal health snapshot is invalid.");
end
for name = ["droppedRecordCount", "invalidCanonicalRecordDropCount", ...
        "writeFailureDropCount", "writeFailureCount"]
    value = snapshot.(name);
    if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
            isfinite(value) && value >= 0 && value == fix(value))
        error("labkit:app:runtime:InvariantFailure", "Journal health snapshot is invalid.");
    end
    snapshot.(name) = double(value);
end
end
