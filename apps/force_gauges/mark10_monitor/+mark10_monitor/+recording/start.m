function state = start(state, context)
%START Clear the recording buffer and begin retaining every sample attempt.
buffer = context.getResource("application", "mark10Buffer");
buffer("time_s") = zeros(0, 1);
buffer("force_N") = zeros(0, 1);
buffer("travel_mm") = zeros(0, 1);
buffer("forceRaw") = zeros(0, 1);
buffer("travelRaw") = zeros(0, 1);
buffer("forceUnit") = strings(0, 1);
buffer("travelUnit") = strings(0, 1);
buffer("valid") = false(0, 1);
buffer("mode") = strings(0, 1);
buffer("started") = tic;
buffer("recordingStartedAt") = datetime("now");
buffer("recording") = true;
state.session.acquisition.recording = true;
state.session.acquisition.validCount = 0;
state.session.acquisition.invalidCount = 0;
state.session.acquisition.recordedValidCount = 0;
state.session.export.status = "Recording in progress.";
end
