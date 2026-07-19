function state = exportOverlay(state, context)
choice=context.chooseOutputFile(["*.png","PNG image (*.png)"],pwd); if choice.Cancelled,return,end
fig=figure(Visible="off"); cleanup=onCleanup(@() close(fig)); ax=axes(fig);
curvature.curvePreview.draw(struct("image",ax),struct("image",state.session.cache.image,"points",state.project.annotations.curvePoints,"path",curvature.curvePreview.visiblePath(state.project.annotations.curvePoints,state.session.cache.image)));
exportgraphics(ax,choice.Value);
end
