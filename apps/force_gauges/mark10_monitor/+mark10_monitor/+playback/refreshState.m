function state = refreshState(state, context)
%REFRESHSTATE Copy the current bounded replay prefix into visible state.
if ~state.session.playback.loaded
    return;
end
playback = context.getResource("application", "mark10Playback");
index = playback("index");
count = numel(playback("time_s"));
first = max(1, index - 1999);
indices = first:index;
if index == 0, indices = zeros(1, 0); end
a = state.session.acquisition;
a.plotTime_s = playback("time_s");
a.plotTime_s = a.plotTime_s(indices);
a.plotForce_N = playback("force_N");
a.plotForce_N = a.plotForce_N(indices);
a.plotTravel_mm = playback("travel_mm");
a.plotTravel_mm = a.plotTravel_mm(indices);
a.sampleCount = index;
a.validCount = index;
a.invalidCount = 0;
if index > 0
    time = playback("time_s");
    force = playback("force_N");
    travel = playback("travel_mm");
    a.elapsed_s = time(index);
    a.force_N = force(index);
    a.travel_mm = travel(index);
    if a.elapsed_s > 0, a.actualRate_Hz = index / a.elapsed_s; end
end
state.session.acquisition = a;
if index >= count
    state.session.playback.playing = false;
    state.session.playback.status = compose("Replay complete: %d samples.", count);
    context.removeResource("application", "mark10PlaybackTimer");
else
    state.session.playback.status = compose("Replaying sample %d of %d.", ...
        index, count);
end
end
