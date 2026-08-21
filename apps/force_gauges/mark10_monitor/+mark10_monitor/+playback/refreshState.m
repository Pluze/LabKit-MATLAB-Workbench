function state = refreshState(state, context)
%REFRESHSTATE Copy the current bounded replay prefix into visible state.
if ~state.session.playback.loaded
    return;
end
playback = context.getResource("mark10Playback");
index = playback("index");
count = numel(playback("time_s"));
state = mark10_monitor.playback.applyCursor(state, playback, index);
if index >= count
    state.session.playback.playing = false;
    state.session.playback.status = compose("Replay complete: %d samples.", count);
    context.removeResource("mark10PlaybackTimer");
else
    state.session.playback.status = compose("Replaying sample %d of %d.", ...
        index, count);
end
end
