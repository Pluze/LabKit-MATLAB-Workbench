function buffer = createBuffer()
%CREATEBUFFER Create the handle-semantic transient recording store.
buffer = containers.Map("KeyType", "char", "ValueType", "any");
buffer("timestampUTC") = NaT(0, 1, "TimeZone", "UTC");
buffer("receivedAtUTC") = NaT(0, 1, "TimeZone", "UTC");
buffer("elapsed_s") = zeros(0, 1);
buffer("value") = zeros(0, 1);
buffer("valid") = false(0, 1);
buffer("timeUncertainty_s") = zeros(0, 1);
buffer("sampleCount") = 0;
buffer("validCount") = 0;
buffer("invalidCount") = 0;
buffer("lastElapsed_s") = 0;
buffer("lastValue") = NaN;
buffer("lastUnit") = "";
buffer("lastFailure") = "";
buffer("plotTime_s") = zeros(0, 1);
buffer("plotValue") = zeros(0, 1);
buffer("plotTimestampUTC") = NaT(0, 1, "TimeZone", "UTC");
buffer("lastRefresh_s") = -Inf;
buffer("refreshPending") = false;
buffer("startedAtUTC") = NaT(1, "TimeZone", "UTC");
buffer("configuration") = struct();
end
