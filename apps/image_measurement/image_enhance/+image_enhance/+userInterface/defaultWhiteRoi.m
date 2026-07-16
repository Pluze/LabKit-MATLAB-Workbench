% Expected caller: Image Enhance ROI action and tests. Input is an image
% size. Output is a bounded top-left ROI covering about 20 percent per axis.
function position = defaultWhiteRoi(imageSize)
    height = max(1, double(imageSize(1)));
    width = max(1, double(imageSize(2)));
    roiWidth = min(width, max(8, round(width * 0.2)));
    roiHeight = min(height, max(8, round(height * 0.2)));
    x = min(max(1, round(width * 0.03)), max(1, width - roiWidth + 1));
    y = min(max(1, round(height * 0.03)), max(1, height - roiHeight + 1));
    position = [x, y, roiWidth, roiHeight];
end
