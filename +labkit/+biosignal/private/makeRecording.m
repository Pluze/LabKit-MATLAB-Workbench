function recording = makeRecording(filepath, sourceKind, signals)
%MAKERECORDING Build the private standard biosignal recording struct.
%
% Inputs:
%   filepath - source file path shown in recording.sourcePath/name.
%   sourceKind - short source label such as "mat" or "table".
%   signals - struct array created by makeSignalStruct.
%
% Output:
%   recording - struct with type, version, sourcePath, name, signals, and
%               metadata.sourceKind. Signal displayName fields are assigned
%               here and made unique when channel names collide.
%
% Notes:
%   App code should receive this only through labkit.biosignal.readRecording.

    [~, name, ext] = fileparts(filepath);
    signals = assignDisplayNames(signals);
    recording = struct();
    recording.type = "biosignalRecording";
    recording.version = 1;
    recording.sourcePath = filepath;
    recording.name = string([name ext]);
    recording.signals = signals;
    recording.metadata = struct('sourceKind', string(sourceKind));
end

function signals = assignDisplayNames(signals)
    if isempty(signals)
        return;
    end
    base = strings(1, numel(signals));
    for k = 1:numel(signals)
        if strlength(signals(k).sourceName) > 0 && signals(k).sourceName ~= "table"
            base(k) = signals(k).sourceName + " / " + signals(k).name;
        else
            base(k) = signals(k).name;
        end
    end
    for k = 1:numel(signals)
        displayName = base(k);
        if nnz(base == base(k)) > 1
            displayName = displayName + " #" + string(k);
        end
        signals(k).displayName = displayName;
    end
end
