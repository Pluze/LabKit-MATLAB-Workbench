% Expected caller: labkit_ImageEnhance_app export callback and package tests.
% Inputs are either loaded image items plus committed enhancement steps and
% export options, or the app state plus export options. Output is an immutable
% task snapshot with a deterministic fingerprint; state-call outputs also
% return normalized opts and committed steps for the writer. This helper has no
% GUI, file, or image-processing side effects.
function [task, opts, steps] = exportTask(itemsOrState, stepsOrOpts, opts)
%EXPORTTASK Build the image-enhance export task snapshot.

    if isAppState(itemsOrState) && (nargin < 3 || isstruct(stepsOrOpts))
        [items, steps, opts] = stateExportInputs(itemsOrState, stepsOrOpts);
    else
        items = itemsOrState;
        steps = stepsOrOpts;
        if nargin < 3 || isempty(opts)
            opts = struct();
        end
    end

    task = struct();
    task.sourcePaths = string({items.path}).';
    task.outputFolder = string(optionValue(opts, 'outputFolder', ""));
    task.options = struct('format', string(optionValue(opts, 'format', "PNG")));
    task.steps = steps;
    task.itemSteps = optionValue(opts, 'itemSteps', {});
    task.fingerprint = taskFingerprint(items, steps, task);
end

function tf = isAppState(value)
    tf = isstruct(value) && isfield(value, 'items') && ...
        isfield(value, 'batchMode') && isfield(value, 'steps');
end

function [items, steps, opts] = stateExportInputs(S, opts)
    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    items = S.items;
    if S.batchMode
        steps = S.steps;
        itemSteps = {};
    else
        steps = vertcat(S.items.steps);
        itemSteps = {S.items.steps}.';
    end
    opts.itemSteps = itemSteps;
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
