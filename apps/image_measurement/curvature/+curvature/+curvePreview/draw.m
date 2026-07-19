function draw(axesById, model)
ax = axesById.image;
labkit.app.plot.clearAxes(ax);
if isempty(model.image), labkit.app.plot.showMessage(ax,"Choose an image"); return, end
imshow(model.image,Parent=ax); hold(ax,"on");
if ~isempty(model.path), plot(ax,model.path(:,1),model.path(:,2),"y-",LineWidth=1.5); end
if ~isempty(model.points), plot(ax,model.points(:,1),model.points(:,2),"ro"); end
end
