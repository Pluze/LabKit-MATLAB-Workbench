function state = exportFocusMap(state, context)
%EXPORTFOCUSMAP Write the current focus-depth index map as PNG.
if ~state.session.cache.result.ok
    context.alert("Run focus stack before exporting results.", "No result"); return
end
choice = context.chooseOutputFile(["*.png", "PNG image (*.png)"], pwd);
if choice.Cancelled, return, end
result = state.session.cache.result;
image = focus_stack.focusPreview.focusIndexRgb(result.focusIndex, result.inputCount);
labkit.image.writeFile(image, choice.Value);
context.appendStatus("Exported focus map: " + string(choice.Value));
end
