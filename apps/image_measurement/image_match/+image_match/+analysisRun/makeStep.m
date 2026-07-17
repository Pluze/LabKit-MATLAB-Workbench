% Expected caller: labkit_ImageMatch_app and image_match tests. Inputs are the
% method and strength controls. Output is a normalized match history step with a
% stable display label.
function step = makeStep(method, strength, toneStrength, colorStrength)

    if nargin < 4
        colorStrength = 100;
    end
    if nargin < 3
        toneStrength = 100;
    end
    if nargin < 2
        strength = 100;
    end
    if nargin < 1
        method = "Balanced";
    end

    step = image_match.analysisRun.emptyStep();
    step.kind = "Reference match";
    step.amount = numericScalar(strength, 100);
    step.secondary = numericScalar(toneStrength, 100);
    step.colorStrength = numericScalar(colorStrength, 100);
    step.matchMethod = string(method);
    step.label = image_match.analysisRun.describeStep(step);
end

function value = numericScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end
