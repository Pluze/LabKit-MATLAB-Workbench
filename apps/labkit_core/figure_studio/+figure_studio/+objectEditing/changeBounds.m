%CHANGEBOUNDS Move and resize selected annotations from the preview ROI.
function state = changeBounds(state, position, context)
position = double(position);
if numel(position) ~= 4 || any(~isfinite(position)) || any(position(3:4) <= 0)
    return;
end
before = state.session.editor.document;
[old, available] = figure_studio.figureDocument.selectionBounds( ...
    before, before.selection);
if ~available, return; end
scale = position(3:4) ./ max(old(3:4), eps);
document = figure_studio.figureDocument.transformNodes(before, ...
    before.selection, "scale", struct("sx", scale(1), "sy", scale(2)));
oldCenter = old(1:2) + old(3:4)/2;
newCenter = position(1:2) + position(3:4)/2;
delta = newCenter - oldCenter;
document = figure_studio.figureDocument.transformNodes(document, ...
    before.selection, "translate", struct("dx", delta(1), "dy", delta(2)));
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument(state, before, document, ...
    "Drag annotation bounds");
context.log("info", "figure_studio.object.bounds", ...
    "Moved or resized selected annotations in the preview.");
end
