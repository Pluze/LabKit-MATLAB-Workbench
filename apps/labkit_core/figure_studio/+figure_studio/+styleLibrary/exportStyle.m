%EXPORTSTYLE Save the reusable Figure Studio style cascade base.
function state = exportStyle(state, context)
choice = context.chooseOutputFile( ...
    ["*.mat", "Figure Studio style (*.mat)"], ...
    fullfile(pwd, "figure_studio_style.mat"));
if choice.Cancelled, return; end
style = state.project.parameters.style;
schema = "figure-studio-style";
save(string(choice.Value), "style", "schema");
state.session.workflow.status = "Exported reusable figure style.";
context.log("info", "figure_studio.style.exported", ...
    state.session.workflow.status);
end
