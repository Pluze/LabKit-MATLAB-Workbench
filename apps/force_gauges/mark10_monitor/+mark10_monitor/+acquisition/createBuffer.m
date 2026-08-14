function buffer = createBuffer()
%CREATEBUFFER Create the handle-semantic transient acquisition store.
buffer = containers.Map("KeyType", "char", "ValueType", "any");
buffer("started") = tic;
buffer("recordingStartedAt") = datetime("now");
buffer("recording") = false;
buffer("time_s") = zeros(0, 1);
buffer("force_N") = zeros(0, 1);
buffer("travel_mm") = zeros(0, 1);
buffer("forceRaw") = zeros(0, 1);
buffer("travelRaw") = zeros(0, 1);
buffer("forceUnit") = strings(0, 1);
buffer("travelUnit") = strings(0, 1);
buffer("valid") = false(0, 1);
buffer("mode") = strings(0, 1);
buffer("plotTime_s") = zeros(0, 1);
buffer("plotForce_N") = zeros(0, 1);
buffer("plotTravel_mm") = zeros(0, 1);
buffer("sampleCount") = 0;
buffer("validCount") = 0;
buffer("invalidCount") = 0;
buffer("lastTime_s") = 0;
buffer("lastForce_N") = NaN;
buffer("lastTravel_mm") = NaN;
buffer("lastFailure") = "";
buffer("lastRefresh_s") = -Inf;
end
