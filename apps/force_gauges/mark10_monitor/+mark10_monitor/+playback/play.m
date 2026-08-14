function state = play(state, context)
%PLAY Restart fixed-speed recording playback from the first sample.
playback = context.getResource("application", "mark10Playback");
count = numel(playback("time_s"));
playback("index") = 0;
mark10_monitor.playback.startTimer(playback, context);
state.session.playback.playing = true;
state = mark10_monitor.playback.applyCursor(state, playback, 0);
state.session.playback.status = compose( ...
    "Playing from the beginning: sample 0 of %d.", count);
end
