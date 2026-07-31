% App-owned focus-stack summary text helper. Expected caller:
% labkit_FocusStack_app result refresh. Inputs are result, source paths, and
% registration lines. Output is a cell row of detail strings.
function lines = details(result, paths, registrationLines)
%DETAILS Return user-facing focus-stack detail lines.

    lines = cell(1, 5 + result.inputCount + 1 + numel(registrationLines));
    lines(1:5) = { ...
        sprintf('Method: %s', result.method), ...
        sprintf('Fused size: %d x %d px, channels: %d', ...
        result.imageWidth, result.imageHeight, result.channelCount), ...
        sprintf('Images resized to first image: %d', result.resizedCount), ...
        sprintf('Detail scale: %d px; blend radius: %d px; uncertain blend: %.1f%%', ...
        result.focusWindow, result.smoothRadius, 100 * result.minConfidence), ...
        'Selected pixel coverage by source:'};
    names = focus_stack.focusPreview.displayImageNamesForDetails(paths, result.inputCount);
    for k = 1:result.inputCount
        lines{5 + k} = sprintf('  %d. %s: %.2f%%', ...
            k, names{k}, 100 * result.focusCoverage(k));
    end
    if ~isempty(registrationLines)
        lines{6 + result.inputCount} = 'Registration:';
        lines(7 + result.inputCount:end) = registrationLines(:).';
    else
        lines = lines(1:5 + result.inputCount);
    end
end
