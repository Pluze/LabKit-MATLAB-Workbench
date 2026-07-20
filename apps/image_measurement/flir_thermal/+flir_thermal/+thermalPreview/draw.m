function draw(axesById,model)
ax=axesById.thermal;labkit.app.plot.clearAxes(ax);
if isempty(model.item),labkit.app.plot.showMessage(ax,"Select a thermal image");return,end
imagesc(ax,model.item.temperatureC);axis(ax,"image");colormap(ax,model.parameters.palette);colorbar(ax);
end
