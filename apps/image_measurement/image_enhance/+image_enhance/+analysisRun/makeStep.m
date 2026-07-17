% Expected caller: labkit_ImageEnhance_app and image_enhance tests. Inputs are
% the user-facing step kind, numeric controls, and optional reference image
% index. Output is a normalized step record with a stable display label.
function step = makeStep(kind, amount, secondary, referenceIndex)

    if nargin < 4
        referenceIndex = 0;
    end

    step = image_enhance.analysisRun.emptyStep();
    step.kind = string(kind);
    step.amount = numericScalar(amount, 0);
    step.secondary = numericScalar(secondary, 0);
    step.referenceIndex = numericScalar(referenceIndex, 0);
    step.label = image_enhance.analysisRun.describeStep(step);
end

function value = numericScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end
