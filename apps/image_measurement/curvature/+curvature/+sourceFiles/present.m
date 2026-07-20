function view = present(imagePath, hasImage, pointCount)
%PRESENT Describe the image-source status and curve point count.
status = "No image loaded";
if hasImage && strlength(string(imagePath)) > 0
    status = "Image loaded";
end
view = labkit.app.view.Snapshot() ...
    .text("imageFile", status) ...
    .value("pointCount", "Points: " + string(pointCount));
end
