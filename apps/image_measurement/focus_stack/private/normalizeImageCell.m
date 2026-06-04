function images = normalizeImageCell(images)
%NORMALIZEIMAGECELL Normalize focus-stack input image containers.
%
% Expected caller:
%   labkit_FocusStack_app private fusion and registration helpers.
%
% Inputs/outputs:
%   Numeric image, numeric stack, or cell array. Returns a column cell array
%   of numeric image arrays.
%
% Side effects:
%   None. Throws app-owned identifiers for invalid image containers.

    if isnumeric(images)
        if ndims(images) == 4
            imageCount = size(images, 4);
            out = cell(imageCount, 1);
            for k = 1:imageCount
                out{k} = images(:, :, :, k);
            end
            images = out;
        elseif ndims(images) == 3
            imageCount = size(images, 3);
            out = cell(imageCount, 1);
            for k = 1:imageCount
                out{k} = images(:, :, k);
            end
            images = out;
        else
            images = {images};
        end
    end

    if ~iscell(images)
        error('labkit_FocusStack_app:InvalidImages', ...
            'Images must be provided as a cell array or numeric stack.');
    end
    images = images(:);
    for k = 1:numel(images)
        if ~isnumeric(images{k}) || ndims(images{k}) < 2
            error('labkit_FocusStack_app:InvalidImages', ...
                'Each focus stack image must be a numeric image array.');
        end
    end
end
