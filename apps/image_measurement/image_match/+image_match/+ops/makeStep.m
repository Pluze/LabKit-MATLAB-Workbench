% Expected caller: labkit_ImageMatch_app and image_match tests. Inputs are the
% reference index, method, and strength controls. Output is a normalized match
% history step with a stable display label.
function step = makeStep(referenceIndex, method, strength, toneStrength, colorStrength)

    if nargin < 5
        colorStrength = 100;
    end
    if nargin < 4
        toneStrength = 100;
    end
    if nargin < 3
        strength = 100;
    end
    if nargin < 2
        method = "Balanced";
    end

    step = image_match.state.emptyStep();
    step.kind = "Reference match";
    step.amount = double(strength);
    step.secondary = double(toneStrength);
    step.colorStrength = double(colorStrength);
    step.matchMethod = string(method);
    step.referenceIndex = double(referenceIndex);
    step.label = image_match.ops.describeStep(step);
end
