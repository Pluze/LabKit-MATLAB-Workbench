% Expected caller: labkit_ImageEnhance_app and image_enhance tests. Inputs are
% the user-facing step kind, numeric controls, and optional reference image
% index. Output is a normalized step record with a stable display label.
function step = makeStep(kind, amount, secondary, referenceIndex)

    if nargin < 4
        referenceIndex = 0;
    end

    step = image_enhance.state.emptyStep();
    step.kind = string(kind);
    step.amount = double(amount);
    step.secondary = double(secondary);
    step.referenceIndex = double(referenceIndex);
    step.label = image_enhance.ops.describeStep(step);
end
