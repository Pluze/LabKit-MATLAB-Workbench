%SOURCECODE Map annotation provenance names to compact storage codes.
% Expected callers are current annotation editing and prediction.
function code = sourceCode(name)
    names = ["empty", "manual", "predicted"];
    index = find(names == string(name), 1);
    if isempty(index)
        error('labkit_VideoMarker_app:UnknownFrameSource', ...
            'Unknown frame source "%s".', string(name));
    end
    code = uint8(index - 1);
end
