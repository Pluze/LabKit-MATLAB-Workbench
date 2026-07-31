% Expected caller: Image Enhance export callback and package tests.
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
    itemStepLineCount = 0;
    if ~isempty(task.itemSteps)
        itemStepLineCount = numel(task.itemSteps) + ...
            sum(cellfun(@numel, task.itemSteps));
    end
    lines = strings(5 + numel(items) + numel(steps) + itemStepLineCount, 1);
    lines(1:5) = [
        "app=image_enhance"
        "outputFolder=" + task.outputFolder
        "format=" + task.options.format
        "sourceCount=" + string(numel(items))
        "stepCount=" + string(numel(steps))];

    for k = 1:numel(items)
        lines(5 + k, 1) = "source[" + string(k) + "]=" + ...
            string(items(k).path) + "|image=" + imageToken(items(k).image);
    end

    for k = 1:numel(steps)
        lines(5 + numel(items) + k, 1) = ...
            "step[" + string(k) + "]=" + stepToken(steps(k));
    end
    if ~isempty(task.itemSteps)
        nextLine = 5 + numel(items) + numel(steps) + 1;
        for k = 1:numel(task.itemSteps)
            itemStepLines = itemStepTokens(k, task.itemSteps{k});
            destination = nextLine:nextLine + numel(itemStepLines) - 1;
            lines(destination) = itemStepLines;
            nextLine = destination(end) + 1;
        end
    end

    fingerprint = strjoin(lines, newline);
end

function lines = itemStepTokens(itemIndex, steps)
    lines = strings(numel(steps) + 1, 1);
    lines(1) = "itemStepCount[" + string(itemIndex) + "]=" + string(numel(steps));
    for k = 1:numel(steps)
        lines(k + 1, 1) = "itemStep[" + string(itemIndex) + "," + ...
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
