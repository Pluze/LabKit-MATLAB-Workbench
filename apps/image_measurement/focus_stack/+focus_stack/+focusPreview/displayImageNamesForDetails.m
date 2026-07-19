% App-owned focus-stack display-name helper. Expected caller:
% details. Inputs are source paths and expected count. Output is a
% cell column of display names with synthetic fallbacks for missing paths.
function names = displayImageNamesForDetails(paths, count)
%DISPLAYIMAGENAMESFORDETAILS Return detail display names for stack sources.

    paths = string(paths(:));
    names = cell(count, 1);
    for k = 1:count
        if k <= numel(paths)
            names{k} = char(labkit.image.displayName(paths(k)));
        else
            names{k} = sprintf('slice_%03d', k);
        end
    end
end
