%CREATEDECODEDFRAMECACHE Create a bounded least-recently-used frame cache.
% Expected caller: Video Marker navigation. READFRAMEFCN accepts a 1-based
% frame index and returns an image. The returned contract exposes readFrame
% and reset callbacks; cached images remain private to this closure. The
% default four-frame capacity covers common back/forward review while bounding
% a 1080p RGB cache to roughly 25 MB.
function cache = createDecodedFrameCache(readFrameFcn, capacity)
    arguments
        readFrameFcn (1, 1) function_handle
        capacity (1, 1) double {mustBeInteger, mustBePositive} = 4
    end
    frameIndices = zeros(1, 0);
    frameImages = cell(1, 0);
    cache = struct('readFrame', @readFrameCached, 'reset', @resetCache);

    function frame = readFrameCached(frameIndex)
        frameIndex = round(double(frameIndex));
        position = find(frameIndices == frameIndex, 1);
        if ~isempty(position)
            frame = frameImages{position};
            moveToMostRecent(position, frameIndex, frame);
            return;
        end
        frame = readFrameFcn(frameIndex);
        storeFrame(frameIndex, frame);
    end

    function resetCache(frameIndex, frame)
        frameIndices = zeros(1, 0);
        frameImages = cell(1, 0);
        if nargin >= 2 && ~isempty(frame)
            storeFrame(frameIndex, frame);
        end
    end

    function storeFrame(frameIndex, frame)
        position = find(frameIndices == frameIndex, 1);
        if ~isempty(position)
            frameIndices(position) = [];
            frameImages(position) = [];
        end
        frameIndices(end + 1) = frameIndex;
        frameImages{end + 1} = frame;
        if numel(frameIndices) > capacity
            frameIndices(1) = [];
            frameImages(1) = [];
        end
    end

    function moveToMostRecent(position, frameIndex, frame)
        frameIndices(position) = [];
        frameImages(position) = [];
        frameIndices(end + 1) = frameIndex;
        frameImages{end + 1} = frame;
    end
end
