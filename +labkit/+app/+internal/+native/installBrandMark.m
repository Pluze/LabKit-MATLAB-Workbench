function installBrandMark(parent)
% Rasterize the four contours of the LabKit perspective mark in Base MATLAB.
% Subpixel coverage keeps the L cutout and K diagonals legible at icon size.
persistent topCoverage inkCoverage
if isempty(topCoverage)
    samples = 4;
    sizePx = 96;
    centers = ((1:sizePx*samples)-0.5) * 256/(sizePx*samples);
    [x,y] = meshgrid(centers);
    top = [19.079 39.275; 131.945 18; 236.921 44.884; 110.502 90.133];
    face = [19.079 39.275; 110.502 90.133; 114.678 238; 41.325 156.563];
    cutout = [39.072 75.23; 50.75 83.276; 59.907 146.761; 89.089 174.888; 90.692 193.824; 51.97 153.68];
    letter = [143.048 111.046; 164.93 101.285; 161.512 143.491; 198.622 86.256; 218.29 77.482; 179.081 137.33; 204.02 156.749; 185.806 169.18; 160.64 154.261; 157.889 188.233; 139.683 200.658];
    inside = @(p) inpolygon(x,y,p(:,1),p(:,2));
    topCoverage = coverage(inside(top), samples, sizePx);
    inkCoverage = coverage((inside(face) & ~inside(cutout)) | inside(letter), samples, sizePx);
end
paper = reshape(parent.BackgroundColor,1,1,3);
rgb = (1-topCoverage-inkCoverage).*paper + topCoverage.*reshape([119 152 207]/255,1,1,3) ...
    + inkCoverage.*reshape([36 75 131]/255,1,1,3);
uiimage(parent,ImageSource=uint8(255*rgb),ScaleMethod="fit",Tag="labkitBrandMark");
end

function alpha = coverage(mask,samples,sizePx)
alpha = reshape(mean(mean(reshape(mask,samples,sizePx,samples,sizePx),1),3),sizePx,sizePx);
end
