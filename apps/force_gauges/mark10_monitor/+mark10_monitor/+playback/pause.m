function state = pause(state, context)
%PAUSE Toggle pause and resume at the current replay cursor.
playback = context.getResource("mark10Playback");
index = playback("index");
count = numel(playback("time_s"));
if state.session.playback.playing
    context.removeResource("mark10PlaybackTimer");
    state = mark10_monitor.playback.applyCursor( ...
        state, playback, index);
    state.session.playback.playing = false;
    state.session.playback.status = compose( ...
        "Paused at sample %d of %d.", index, count);
else
    mark10_monitor.playback.startTimer(playback, context);
    state.session.playback.playing = true;
    state.session.playback.status = compose( ...
        "Resumed at sample %d of %d.", index, count);
end
end
