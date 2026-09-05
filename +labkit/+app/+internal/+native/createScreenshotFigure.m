function canvas = createScreenshotFigure(sourceFigure)
%CREATESCREENSHOTFIGURE Capture the complete current App for image copying.
% The native clipboard action owns the returned hidden flat figure. exportapp
% captures controls and selected tabs; temporary pixels are always removed.
arguments
    sourceFigure (1, 1)
end
filename = string(tempname) + ".png";
fileCleanup = onCleanup(@() deleteFile(filename));
exportapp(sourceFigure, filename);
pixels = imread(filename);
canvasSize = [size(pixels, 2), size(pixels, 1)];
canvas = figure(Visible="off", HandleVisibility="off", Color="w", ...
    MenuBar="none", ToolBar="none", Units="pixels", ...
    Position=[1 1 canvasSize], Tag="labkitScreenshotCanvas");
try
    ax = axes(canvas, Units="normalized", Position=[0 0 1 1]);
    image(ax, pixels);
    axis(ax, "image");
    axis(ax, "off");
    ax.Position = [0 0 1 1];
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
