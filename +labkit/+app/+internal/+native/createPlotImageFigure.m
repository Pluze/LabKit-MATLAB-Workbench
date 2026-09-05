function canvas = createPlotImageFigure(sourceAxes, options)
%CREATEPLOTIMAGEFIGURE Capture plotting surfaces into one flat image canvas.
% Native clipboard actions pass an ordered axes vector from one workspace
% page. Axes exports retain both rulers, legends, colorbars, and the current
% viewport. The returned hidden figure is caller-owned; sources stay intact.
arguments
    sourceAxes (:, 1)
    options.Layout (1, 1) string {mustBeMember(options.Layout, ["source", "grid"])} = "source"
end
if isempty(sourceAxes) || ~all(isgraphics(sourceAxes, "axes"))
    error("labkit:app:plot:InvalidAxes", "Select at least one valid plot.");
end
sourceFigure = ancestor(sourceAxes(1), "figure");
if options.Layout == "source" && sourceFigure.Visible == "off"
    % Native grid geometry is deferred for offscreen figures until rendered.
    filename = string(tempname) + ".png";
    settleCleanup = onCleanup(@() deleteFile(filename));
    exportapp(sourceFigure, filename);
    delete(settleCleanup);
end
drawnow nocallbacks;
rectangles = zeros(numel(sourceAxes), 4);
for k = 1:numel(sourceAxes)
    ax = sourceAxes(k);
    previousUnits = ax.Units;
    unitsCleanup = onCleanup(@() set(ax, "Units", previousUnits));
    ax.Units = "pixels";
    inner = getpixelposition(ax, true);
    rectangles(k, :) = inner + ax.OuterPosition - ax.Position;
    delete(unitsCleanup);
end
if options.Layout == "grid"
    columns = ceil(sqrt(numel(sourceAxes)));
    rows = ceil(numel(sourceAxes) / columns);
    for k = 1:numel(sourceAxes)
        rectangles(k, :) = [mod(k - 1, columns) * 500, ...
            (rows - 1 - floor((k - 1) / columns)) * 350, 500, 350];
    end
end
lower = min(rectangles(:, 1:2), [], 1);
upper = max(rectangles(:, 1:2) + rectangles(:, 3:4), [], 1);
canvasSize = max(1, upper - lower);
rectangles(:, 1:2) = rectangles(:, 1:2) - lower;
canvas = figure(Visible="off", HandleVisibility="off", Color="w", ...
    MenuBar="none", ToolBar="none", Units="pixels", ...
    Position=[1 1 canvasSize], Tag="labkitPlotImageCanvas");
try
    for k = 1:numel(sourceAxes)
        filename = string(tempname) + ".png";
        fileCleanup = onCleanup(@() deleteFile(filename));
        exportgraphics(sourceAxes(k), filename, Resolution=300, ...
            ContentType="image", BackgroundColor="white");
        pixels = imread(filename);
        rect = rectangles(k, :) ./ [canvasSize canvasSize];
        target = axes(canvas, Units="normalized", Position=rect, ...
            Tag=sourceAxes(k).Tag);
        image(target, pixels);
        axis(target, "image");
        axis(target, "off");
        target.Position = rect;
        target.Tag = sourceAxes(k).Tag;
        delete(fileCleanup);
    end
catch cause
    delete(canvas);
    rethrow(cause);
end
end

function deleteFile(filename)
if isfile(filename)
    delete(filename);
end
end
