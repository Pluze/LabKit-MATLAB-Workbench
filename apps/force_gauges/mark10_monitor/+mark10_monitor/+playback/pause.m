function state = pause(state, context)
%PAUSE Pause playback at the current sample.
context.removeResource("application", "mark10PlaybackTimer");
playback = context.getResource("application", "mark10Playback");
state.session.playback.playing = false;
state.session.playback.status = compose("Paused at sample %d of %d.", ...
    playback("index"), numel(playback("time_s")));
end
