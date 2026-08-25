%ALIGN Apply one alignment or distribution operation to editable selections.
function state = align(state, operation, context)
before = state.session.editor.document;
document = figure_studio.figureDocument.transformNodes( ...
    before, before.selection, operation, struct());
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    operation + " objects");
context.log("info", "figure_studio.object.align", ...
    "Aligned editable figure elements.");
end
