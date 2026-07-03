% Expected caller: labkit_FocusStack_app run callback and package tests.
% Inputs are source paths, loaded images, fusion options, and the registration
% flag. Output is an immutable run task with a deterministic fingerprint; this
% helper has no GUI or image-processing side effects.
function task = runTask(paths, images, opts, registerStack)
%RUNTASK Build the focus-stack computation task snapshot.

    if nargin < 3 || isempty(opts)
        opts = struct();
    end
    if nargin < 4
        registerStack = false;
    end

    task = struct();
    task.sourcePaths = string(paths(:));
    task.options = normalizeOptions(opts);
    task.registerStack = logical(registerStack);
    task.fingerprint = taskFingerprint(task, images);
end

function optsOut = normalizeOptions(opts)
    optsOut = struct();
    optsOut.focusWindow = numericScalar(optionValue(opts, 'focusWindow', 0), 0);
    optsOut.smoothRadius = numericScalar(optionValue(opts, 'smoothRadius', 0), 0);
    optsOut.minConfidence = numericScalar(optionValue(opts, 'minConfidence', 0), 0);
end

function fingerprint = taskFingerprint(task, images)
    lines = [
        "app=focus_stack"
        "registerStack=" + string(task.registerStack)
        "focusWindow=" + numberToken(task.options.focusWindow)
        "smoothRadius=" + numberToken(task.options.smoothRadius)
        "minConfidence=" + numberToken(task.options.minConfidence)
        "imageCount=" + string(numel(images))];

    for k = 1:numel(images)
        pathValue = "";
        if k <= numel(task.sourcePaths)
            pathValue = task.sourcePaths(k);
        end
        lines(end + 1, 1) = "image[" + string(k) + "]=" + ...
            pathValue + "|image=" + imageToken(images{k});
    end

    fingerprint = strjoin(lines, sprintf('\n'));
end

function token = imageToken(imageData)
    token = "size=" + strjoin(string(size(imageData)), "x") + ...
        "|class=" + string(class(imageData));
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

function value = numericScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end
