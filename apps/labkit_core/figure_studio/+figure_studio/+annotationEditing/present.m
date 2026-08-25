%PRESENT Build annotation editor values and availability.
function view = present(editor, hasFigure)
draft = editor.annotation;
view = labkit.app.view.Snapshot() ...
    .value("annotationKind", draft.kind) ...
    .value("annotationText", draft.text) ...
    .value("annotationX1", draft.x1).value("annotationY1", draft.y1) ...
    .value("annotationX2", draft.x2).value("annotationY2", draft.y2);
for id = ["annotationKind", "annotationText", "annotationX1", ...
        "annotationY1", "annotationX2", "annotationY2", "addAnnotation"]
    view = view.enabled(id, hasFigure);
end
view = view.enabled("deleteAnnotations", ...
    hasFigure && hasEditableSelection(editor.document));
end

function tf = hasEditableSelection(document)
tf = false;
for id = reshape(document.selection, 1, [])
    index = find(string({document.nodes.id}) == id, 1);
    if ~isempty(index) && ~document.nodes(index).dataLocked
        tf = true;
        return;
    end
end
end
