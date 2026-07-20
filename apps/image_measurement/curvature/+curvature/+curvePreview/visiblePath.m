% App-owned implementation for curvature.curvePreview.visiblePath within the curvature product workflow.
function path = visiblePath(points, imageData)
path = points;
if size(points,1)>=2 && ~isempty(imageData)
    path = labkit.app.interaction.interpolateAnchorPath(points,size(imageData),Style="Curve",Closed=false);
end
end
