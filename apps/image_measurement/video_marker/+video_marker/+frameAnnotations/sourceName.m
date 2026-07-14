%SOURCENAME Return empty, manual, or predicted for one stored source code.
% Expected callers are navigation, rendering, and tests.
function name = sourceName(code)
    names = ["empty", "manual", "predicted"];
    index = double(code) + 1;
    if ~isscalar(index) || index < 1 || index > numel(names)
        error('labkit_VideoMarker_app:UnknownFrameSource', ...
            'Unknown stored frame-source code.');
    end
    name = names(index);
end
