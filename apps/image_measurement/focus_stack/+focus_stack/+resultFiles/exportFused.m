function state = exportFused(state, context)
%EXPORTFUSED Write the current fused image as a user-selected PNG.
if ~state.session.cache.result.ok
    context.alert("Run focus stack before exporting results.", "No result"); return
end
choice = context.chooseOutputFile(["*.png", "PNG image (*.png)"], pwd);
if choice.Cancelled, return, end
labkit.image.writeFile(state.session.cache.result.fused, choice.Value);
context.appendStatus("Exported fused image: " + string(choice.Value));
end
