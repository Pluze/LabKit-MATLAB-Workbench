% Expected callers are the Image Match export action and package tests.
% Inputs are loaded source items, one reference item, committed match steps,
% and export options. Output is an immutable task snapshot with a
% deterministic fingerprint; this helper has no GUI, file, or image-processing
% side effects.
function task = exportTask(items, referenceItem, steps, opts)
%EXPORTTASK Build the image-match export task snapshot.

    if nargin < 4 || isempty(opts)
        opts = struct();
    end

    task = struct();
    task.sourcePaths = string({items.path}).';
    task.referencePath = referencePath(referenceItem);
    task.outputFolder = string(optionValue(opts, 'outputFolder', ""));
    task.options = struct('format', string(optionValue(opts, 'format', "PNG")));
    task.steps = steps;
    task.fingerprint = taskFingerprint(items, referenceItem, steps, task);
end

function fingerprint = taskFingerprint(items, referenceItem, steps, task)
    lines = strings(6 + numel(items) + numel(steps), 1);
    lines(1:6) = [
        "app=image_match"
        "outputFolder=" + task.outputFolder
        "format=" + task.options.format
        "reference=" + task.referencePath + "|image=" + referenceImageToken(referenceItem)
        "sourceCount=" + string(numel(items))
        "stepCount=" + string(numel(steps))];

    for k = 1:numel(items)
        lines(6 + k, 1) = "source[" + string(k) + "]=" + ...
            string(items(k).path) + "|image=" + imageToken(items(k).image);
    end

    for k = 1:numel(steps)
        lines(6 + numel(items) + k, 1) = ...
            "step[" + string(k) + "]=" + stepToken(steps(k));
    end

    fingerprint = strjoin(lines, newline);
end

function pathValue = referencePath(referenceItem)
    pathValue = "";
    if isstruct(referenceItem) && isfield(referenceItem, 'path')
        pathValue = string(referenceItem.path);
    end
end

function token = referenceImageToken(referenceItem)
    token = "empty";
    if isstruct(referenceItem) && isfield(referenceItem, 'image') && ...
            ~isempty(referenceItem.image)
        token = imageToken(referenceItem.image);
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
        "|colorStrength=" + numberToken(step.colorStrength) + ...
        "|matchMethod=" + string(step.matchMethod);
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
