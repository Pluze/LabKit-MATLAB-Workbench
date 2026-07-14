%SOURCECODE Map annotation provenance names to compact storage codes.
% Expected callers are annotation storage and compatibility normalization.
function code = sourceCode(name)
    names = ["empty", "manual", "predicted"];
    index = find(names == string(name), 1);
    if isempty(index)
        error('labkit_VideoMarker_app:UnknownFrameSource', ...
            'Unknown frame source "%s".', string(name));
    end
    code = uint8(index - 1);
end
