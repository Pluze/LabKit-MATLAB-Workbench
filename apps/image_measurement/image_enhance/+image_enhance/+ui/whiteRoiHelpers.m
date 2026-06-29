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
            width = max(8, round(imageSize(2) * 0.2));
            height = max(8, round(imageSize(1) * 0.2));
            out = [round((imageSize(2) - width) / 2), ...
                round((imageSize(1) - height) / 2), width, height];
        otherwise
            error('labkit_ImageEnhance_app:UnknownWhiteRoiHelper', ...
                'Unknown white ROI helper action: %s.', char(string(action)));
    end
end
