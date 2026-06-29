% Expected caller: Image Enhance runner. Dispatches small white-ROI UI/state
% helper operations without owning app workflow.
function out = whiteRoiHelpers(action, varargin)
    switch string(action)
        case "isTool"
            out = strcmpi(regexprep(char(string(varargin{1})), ...
                '[^a-zA-Z0-9]', ''), 'whiteroicalibration');
        case "hasRoi"
            roi = double(varargin{1}.whiteRoi);
            out = numel(roi) == 4 && all(isfinite(roi)) && all(roi(3:4) > 0);
        case "context"
            out = varargin{1};
            out.whiteRoi = out.whiteRoi .* double(varargin{2});
        case "defaultPosition"
            imageSize = varargin{1};
            imageHeight = max(1, double(imageSize(1)));
            imageWidth = max(1, double(imageSize(2)));
            width = min(imageWidth, max(8, round(imageWidth * 0.2)));
            height = min(imageHeight, max(8, round(imageHeight * 0.2)));
            x = min(max(1, round(imageWidth * 0.03)), ...
                max(1, imageWidth - width + 1));
            y = min(max(1, round(imageHeight * 0.03)), ...
                max(1, imageHeight - height + 1));
            out = [x, y, width, height];
        otherwise
            error('labkit_ImageEnhance_app:UnknownWhiteRoiHelper', ...
                'Unknown white ROI helper action: %s.', char(string(action)));
    end
end
