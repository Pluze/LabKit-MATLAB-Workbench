% DIC Postprocess ops helper. Expected caller: dic_postprocess.ops helpers.
% Input is a logical strain-validity mask and optional trim width in strain
% pixels. Output removes unreliable boundary pixels when doing so keeps at
% least one valid pixel. Side effects: none.
function trimmed = trimStrainEdgeMask(mask, trimPixels)
    if nargin < 2 || isempty(trimPixels)
        trimPixels = 1;
    end

    trimmed = logical(mask);
    trimPixels = max(0, round(trimPixels));
    for k = 1:trimPixels
        candidate = trimmed & (conv2(double(trimmed), ones(3), 'same') == 9);
        if ~any(candidate(:))
            return;
        end
        trimmed = candidate;
    end
end
