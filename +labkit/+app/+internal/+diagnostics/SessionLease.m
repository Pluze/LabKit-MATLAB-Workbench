classdef (Hidden, Sealed) SessionLease
    %SESSIONLEASE Private active-session ownership and recovery classifier.

    methods (Static)
        function marker = create(sessionId, appId, startedAtUtc, nowUtc, nonce, probe)
            if nargin < 5
                error("labkit:app:contract:InvalidValue", ...
                    "SessionLease requires one explicit LeaseNonce.");
            end
            nonce = labkit.app.internal.diagnostics.SessionLease.validateNonce(nonce);
            if nargin < 6 || isempty(probe)
                probe = labkit.app.internal.diagnostics.SessionLease.localProbe();
            end
            pid = -1;
            if isfield(probe, "pid") && isnumeric(probe.pid) && isscalar(probe.pid) && ...
                    isfinite(probe.pid) && probe.pid >= 0
                pid = double(probe.pid);
            end
            marker = struct("sessionId", string(sessionId), "appId", string(appId), ...
                "state", "active", "host", lower(string(probe.host)), ...
                "pid", pid, "nonce", string(nonce), ...
                "startedAtUtc", string(startedAtUtc), "heartbeatAtUtc", string(nowUtc), ...
                "leaseVersion", 1);
        end

        function nonce = createNonce()
            [~, leaf] = fileparts(tempname);
            nonce = labkit.app.internal.diagnostics.SessionLease.validateNonce("lease-" + string(leaf));
        end

        function nonce = validateNonce(nonce)
            if ~((isstring(nonce) && isscalar(nonce)) || (ischar(nonce) && isrow(nonce))) || ...
                    strlength(string(nonce)) == 0
                error("labkit:app:contract:InvalidValue", ...
                    "SessionLease LeaseNonce must be one nonempty semantic identifier.");
            end
            nonce = labkit.app.internal.diagnostics.SessionEventValidator.semanticIdentifier( ...
                nonce, "LeaseNonce");
        end

        function state = classify(marker, manifest, nowUtc, probe, freshSeconds)
            %CLASSIFY Total, conservative ownership decision for one marker.
            % Any malformed or incomplete input is uncertain rather than an
            % inspection failure or permission to reclaim a live journal.
            state = "uncertain";
            try
                if nargin < 5 || ~isPositiveScalar(freshSeconds)
                    return;
                end
                if nargin < 4 || isempty(probe)
                    probe = labkit.app.internal.diagnostics.SessionLease.localProbe();
                end
                fields = ["sessionId", "appId", "state", "host", "pid", "nonce", ...
                    "startedAtUtc", "heartbeatAtUtc", "leaseVersion"];
                if ~isstruct(marker) || ~isscalar(marker) || ~all(isfield(marker, fields)) || ...
                        ~isstruct(manifest) || ~isscalar(manifest) || ...
                        ~all(isfield(manifest, ["sessionId", "appId", "state", "lease"])) || ...
                        ~isstruct(manifest.lease) || ~isscalar(manifest.lease) || ...
                        ~all(isfield(manifest.lease, ["nonce", "leaseVersion"]))
                    return;
                end
                [markerSessionOk, markerSession] = scalarText(marker.sessionId, false);
                [markerAppOk, markerApp] = scalarText(marker.appId, false);
                [markerStateOk, markerState] = scalarText(marker.state, false);
                [markerHostOk, markerHost] = scalarText(marker.host, false);
                [markerNonceOk, markerNonce] = scalarText(marker.nonce, false);
                [manifestSessionOk, manifestSession] = scalarText(manifest.sessionId, false);
                [manifestAppOk, manifestApp] = scalarText(manifest.appId, false);
                [manifestStateOk, manifestState] = scalarText(manifest.state, false);
                [manifestNonceOk, manifestNonce] = scalarText(manifest.lease.nonce, false);
                if ~(markerSessionOk && markerAppOk && markerStateOk && markerHostOk && ...
                        markerNonceOk && manifestSessionOk && manifestAppOk && ...
                        manifestStateOk && manifestNonceOk) || ...
                        markerState ~= "active" || manifestState ~= "active" || ...
                        markerSession ~= manifestSession || markerApp ~= manifestApp || ...
                        markerNonce ~= manifestNonce || ...
                        ~isLeaseVersion(marker.leaseVersion) || ...
                        ~isLeaseVersion(manifest.lease.leaseVersion) || ...
                        marker.leaseVersion ~= manifest.lease.leaseVersion || ...
                        ~isPid(marker.pid)
                    return;
                end
                heartbeat = parseUtc(marker.heartbeatAtUtc);
                started = parseUtc(marker.startedAtUtc);
                observedNow = parseUtc(nowUtc);
                if isnat(heartbeat) || isnat(started) || isnat(observedNow) || ...
                        heartbeat < started || heartbeat > observedNow
                    return;
                end
                if seconds(observedNow - heartbeat) <= double(freshSeconds)
                    state = "live";
                    return;
                end
                if marker.pid < 0 || markerHost == "unknown" || ...
                        ~isstruct(probe) || ~isscalar(probe) || ...
                        ~all(isfield(probe, ["host", "targetPid", "processState"]))
                    return;
                end
                [probeHostOk, probeHost] = scalarText(probe.host, false);
                [probeStateOk, probeState] = scalarText(probe.processState, false);
                if ~probeHostOk || ~probeStateOk || lower(markerHost) ~= lower(probeHost) || ...
                        ~isPid(probe.targetPid) || probe.targetPid ~= marker.pid || ...
                        ~any(probeState == ["alive", "dead", "unknown"])
                    return;
                end
                if probeState == "dead"
                    state = "stale";
                end
            catch
                state = "uncertain";
            end
        end

        function probe = localProbe(targetPid)
            if nargin < 1
                targetPid = currentPid();
            end
            host = string(getenv("COMPUTERNAME"));
            if strlength(host) == 0
                host = string(getenv("HOSTNAME"));
            end
            if strlength(host) == 0
                host = "unknown";
            end
            pid = currentPid();
            probe = struct("host", lower(host), "pid", pid, "targetPid", targetPid, ...
                "processState", processState(targetPid));
        end
    end
end

function value = parseUtc(value)
try
    value = datetime(string(value), InputFormat="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", ...
        TimeZone="UTC");
catch
    value = NaT(TimeZone="UTC");
end
end

function value = currentPid()
value = -1;
try
    candidate = feature("getpid");
    if isPid(candidate)
        value = double(candidate);
    end
catch
end
end

function value = processState(targetPid)
value = "unknown";
if ~isPid(targetPid) || targetPid < 0
    return;
end
try
    if ispc
        [status, output] = system(sprintf('tasklist /FI "PID eq %d" /NH', targetPid));
        if status ~= 0
            return;
        end
        if ~isempty(regexp(char(output), ...
                ['(^|\\s)' num2str(targetPid) '(\\s|$)'], "once"))
            value = "alive";
        elseif contains(lower(string(output)), "no tasks")
            value = "dead";
        end
    else
        [status, output] = system(sprintf('kill -0 %d 2>&1', targetPid));
        if status == 0
            value = "alive";
        elseif contains(lower(string(output)), "no such process")
            value = "dead";
        end
    end
catch
end
end

function tf = isPositiveScalar(value)
tf = isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value) && value > 0;
end

function tf = isLeaseVersion(value)
tf = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value == 1;
end

function tf = isPid(value)
tf = isnumeric(value) && isreal(value) && isscalar(value) && ...
    isfinite(value) && value == fix(value) && value >= -1;
end

function [ok, value] = scalarText(input, allowEmpty)
ok = false;
value = "";
if (isstring(input) && isscalar(input)) || (ischar(input) && isrow(input))
    value = string(input);
    ok = allowEmpty || strlength(value) > 0;
end
end
