function draw(axesById, model)
%DRAW Render the EXX and EYY overlays on framework-owned axes.
drawImage(axesById.exx, model.exx);
drawImage(axesById.eyy, model.eyy);
end

function drawImage(ax, model)
labkit.app.plot.clearAxes(ax, ResetScale=true);
if ~isempty(model.imageData)
    image(ax, model.imageData);
    axis(ax, "image");
    ax.YDir = "reverse";
end
title(ax, model.title);
xlabel(ax, "");
ylabel(ax, "");
box(ax, "on");
end
