%READFRAME Read one 1-based frame from an open VideoReader.
% Expected caller: frame navigation actions. The reader handle is transient;
% returned image data is the only frame payload stored in app state.
function frame = readFrame(reader, frameIndex)
    frameIndex = round(double(frameIndex));
    if frameIndex < 1
        error('labkit_VideoMarker_app:InvalidFrameIndex', 'Frame index must be positive.');
    end
    frame = read(reader, frameIndex);
end
