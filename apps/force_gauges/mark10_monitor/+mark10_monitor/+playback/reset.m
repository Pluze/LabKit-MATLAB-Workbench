function state = reset(state, context)
%RESET Stop replay and restore the complete loaded recording plot.
context.removeResource("mark10PlaybackTimer");
playback = context.getResource("mark10Playback");
count = numel(playback("time_s"));
playback("index") = count;
state = mark10_monitor.playback.applyCursor(state, playback, count);
state.session.playback.playing = false;
state = mark10_monitor.livePlots.updateLimits(state, true);
state.session.playback.status = compose( ...
    "Reset to complete curve: %d samples.", count);
end
