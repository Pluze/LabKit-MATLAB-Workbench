% Expected caller: labkit_ImageEnhance_app export callback and package tests.
% Inputs are loaded image items, committed shared steps, and export options
% that may include per-image steps. Output is an immutable task snapshot with
% a deterministic fingerprint. This helper has no GUI, file, or processing
% side effects.
function task = exportTask(items, steps, opts)
%EXPORTTASK Build the image-enhance export task snapshot.

    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    task = struct();
    task.sourcePaths = string({items.path}).';
    task.outputFolder = string(optionValue(opts, 'outputFolder', ""));
    task.options = struct('format', string(optionValue(opts, 'format', "PNG")));
    task.steps = steps;
    task.itemSteps = optionValue(opts, 'itemSteps', {});
    task.fingerprint = taskFingerprint(items, steps, task);
end

function fingerprint = taskFingerprint(items, steps, task)
    lines = [
        "app=image_enhance"
        "outputFolder=" + task.outputFolder
        "format=" + task.options.format
        "sourceCount=" + string(numel(items))
        "stepCount=" + string(numel(steps))];

    for k = 1:numel(items)
        lines(end + 1, 1) = "source[" + string(k) + "]=" + ...
            string(items(k).path) + "|image=" + imageToken(items(k).image);
    end

    for k = 1:numel(steps)
        lines(end + 1, 1) = "step[" + string(k) + "]=" + stepToken(steps(k));
    end
    if ~isempty(task.itemSteps)
        for k = 1:numel(task.itemSteps)
            itemStepLines = itemStepTokens(k, task.itemSteps{k});
            lines = [lines; itemStepLines];
        end
    end

    fingerprint = strjoin(lines, sprintf('\n'));
end

function lines = itemStepTokens(itemIndex, steps)
    lines = "itemStepCount[" + string(itemIndex) + "]=" + string(numel(steps));
    for k = 1:numel(steps)
        lines(end + 1, 1) = "itemStep[" + string(itemIndex) + "," + ...
            string(k) + "]=" + stepToken(steps(k));
    end
end

function token = imageToken(imageData)
    token = "size=" + strjoin(string(size(imageData)), "x") + ...
        "|class=" + string(class(imageData));
end

function token = stepToken(step)
    token = "kind=" + string(step.kind) + ...
        "|amount=" + numberToken(step.amount) + ...
        "|secondary=" + numberToken(step.secondary) + ...
        "|referenceIndex=" + numberToken(step.referenceIndex);
end

function token = numberToken(value)
    token = string(mat2str(double(value), 17));
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    end
end
