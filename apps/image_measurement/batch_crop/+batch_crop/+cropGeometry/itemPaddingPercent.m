% App-owned crop-geometry helper. Expected caller: batch-crop runner, export,
% and plan helpers. Input is one crop item and an optional default percent.
% Output is a finite padding percentage clamped to the supported app range.
function percent = itemPaddingPercent(item, defaultPercent)
%ITEMPADDINGPERCENT Return a normalized per-item padding percentage.

    if nargin < 2 || isempty(defaultPercent)
        defaultPercent = 0;
    end
    percent = double(defaultPercent);
    if isstruct(item) && isfield(item, 'paddingPercent') && ...
            ~isempty(item.paddingPercent)
        percent = double(item.paddingPercent(1));
    end
    if ~isfinite(percent)
        percent = double(defaultPercent);
    end
    percent = min(max(percent, 0), 200);
end
