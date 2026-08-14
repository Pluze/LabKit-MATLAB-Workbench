function [time_s, force_N, travel_mm, description] = sourceData(state, context)
%SOURCEDATA Return the complete loaded replay or retained live recording.
source = "Live Recording";
if isfield(state.session.analysis, "dataSource")
    source = string(state.session.analysis.dataSource);
elseif state.session.playback.loaded
    source = "Loaded Recording";
end
if source == "Loaded Recording" && ...
        state.session.playback.loaded
    playback = context.getResource("application", "mark10Playback");
    time_s = playback("time_s");
    force_N = playback("force_N");
    travel_mm = playback("travel_mm");
    description = "loaded recording";
    return;
end
buffer = context.getResource("application", "mark10Buffer");
valid = buffer("valid");
time_s = buffer("time_s");
force_N = buffer("force_N");
travel_mm = buffer("travel_mm") - ...
    state.session.acquisition.travelZeroOffset_mm;
time_s = time_s(valid);
force_N = force_N(valid);
travel_mm = travel_mm(valid);
description = "retained live recording";
end
