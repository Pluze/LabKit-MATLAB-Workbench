% Expected caller: DIC preprocess runner and direct unit tests. Input is the
% runner state struct with reference/moving paths, current image arrays, history,
% aligned image, and mask image fields. Output is the summary text cell array
% shown in the app. Side effects: none.

function lines = buildSummary(S)
%BUILDSUMMARY Build DIC preprocess summary text from app state.

    lines = {};
    lines{end+1} = sprintf('Reference: %s', displayPath(S.referencePath));
    lines{end+1} = sprintf('Moving: %s', displayPath(S.movingPath));
    lines{end+1} = sprintf('Current pair: %s', currentPairSizeText(S));
    lines{end+1} = sprintf('Undo steps: %d', numel(S.history));
    lines{end+1} = sprintf('Last aligned image: %s', ...
        ternary(~isempty(S.alignedImage), 'available', 'not generated'));
    lines{end+1} = sprintf('ROI mask: %s', ...
        ternary(~isempty(S.maskImage), 'available', 'not drawn'));
end

function txt = currentPairSizeText(S)
    if isempty(S.currentReferenceImage) || isempty(S.currentMovingImage)
        txt = 'not loaded';
        return;
    end
    txt = sprintf('reference %d x %d, moving %d x %d', ...
        size(S.currentReferenceImage, 1), size(S.currentReferenceImage, 2), ...
        size(S.currentMovingImage, 1), size(S.currentMovingImage, 2));
end

function txt = displayPath(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        txt = 'none';
        return;
    end
    txt = char(pathValue);
end

function out = ternary(condition, trueValue, falseValue)
    if condition
        out = trueValue;
    else
        out = falseValue;
    end
end
