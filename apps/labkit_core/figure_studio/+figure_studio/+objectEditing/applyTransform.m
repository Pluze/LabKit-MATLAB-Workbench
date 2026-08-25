%APPLYTRANSFORM Apply numeric movement or scaling to editable selections.
function state = applyTransform(state, context)
before = state.session.editor.document;
draft = state.session.editor.transformDraft;
document = figure_studio.figureDocument.transformNodes( ...
    before, before.selection, "translate", draft);
document = figure_studio.figureDocument.transformNodes( ...
    document, before.selection, "scale", draft);
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    "Transform annotation");
context.log("info", "figure_studio.object.transform", ...
    "Transformed editable figure elements.");
end
