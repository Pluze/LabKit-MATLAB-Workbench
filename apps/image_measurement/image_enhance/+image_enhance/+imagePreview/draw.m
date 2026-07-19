function draw(axesById,model)
ax=axesById.image;labkit.app.plot.clearAxes(ax);image=model.source;if ~isempty(model.result),image=model.result;end
if isempty(image),labkit.app.plot.showMessage(ax,"Load an image");else,imshow(image,Parent=ax);end
end
