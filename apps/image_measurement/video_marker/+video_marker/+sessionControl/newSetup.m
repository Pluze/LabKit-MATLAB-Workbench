function state = newSetup(state, context)
%NEWSETUP Clear the current video, skeleton, and annotations after confirmation.
choice = context.chooseOption( ...
    ["Starting a new setup clears the current video, skeleton, and " ...
    "annotations. Save the project from the State menu first if needed."], ...
    ["Cancel", "Discard and start"]);
if choice.Cancelled || string(choice.Value) ~= "Discard and start"
    context.appendStatus("New setup cancelled.");
    return
end
context.clearResourceScope("session");
schema = video_marker.projectSpec();
state.project = schema.Create();
state.session = video_marker.createSession(state.project, context);
context.appendStatus("Started a new skeleton setup.");
end
