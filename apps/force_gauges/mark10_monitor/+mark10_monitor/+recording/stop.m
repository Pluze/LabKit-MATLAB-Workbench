function state = stop(state, context)
%STOP Stop retaining samples while live monitoring continues.
buffer = context.getResource("application", "mark10Buffer");
buffer("recording") = false;
state.session.acquisition.recording = false;
state.session.export.status = compose("Recording stopped: %d valid samples.", ...
    sum(buffer("valid")));
end
