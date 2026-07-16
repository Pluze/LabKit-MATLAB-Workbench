% Expected caller: DIC preprocess V2 presenter and unit tests. Input is the
% canonical state. Output summarizes durable sources and rebuildable cache.

function lines = buildSummary(state)
%BUILDSUMMARY Build DIC preprocess summary text from app state.

    project = state.project;
    cache = state.session.cache;
    annotations = project.annotations;
    lines = cell(0, 1);
    lines{end+1, 1} = sprintf('Reference: %s', ...
        displayPath(dic_preprocess.sourceFiles.pathForId( ...
        project.inputs.sources, "referenceImage")));
    lines{end+1, 1} = sprintf('Moving: %s', ...
        displayPath(dic_preprocess.sourceFiles.pathForId( ...
        project.inputs.sources, "movingImage")));
    lines{end+1, 1} = sprintf('Current pair: %s', currentPairSizeText(cache));
    lines{end+1, 1} = sprintf('Undo steps: %d', numel(annotations.history));
    lines{end+1, 1} = sprintf('Last aligned image: %s', ...
        ternary(any(string({annotations.editSteps.kind}) == "alignment"), ...
        'available', 'not generated'));
    lines{end+1, 1} = sprintf('ROI mask: %s', ...
        ternary(~isempty(annotations.maskImage), 'available', 'not drawn'));
end

function txt = currentPairSizeText(cache)
    if isempty(cache.currentReferenceImage) || ...
            isempty(cache.currentMovingImage)
        txt = 'not loaded';
        return;
    end
    txt = sprintf('reference %d x %d, moving %d x %d', ...
        size(cache.currentReferenceImage, 1), ...
        size(cache.currentReferenceImage, 2), ...
        size(cache.currentMovingImage, 1), ...
        size(cache.currentMovingImage, 2));
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
