% Expected caller: labkit_ImageMatch_app, view helpers, and tests. Input is a
% reference-match step. Output is a concise reproducible history label.
function label = describeStep(step)

    method = string(step.matchMethod);
    if strlength(method) == 0
        method = "Balanced";
    end
    label = sprintf('%s reference #%d, strength %g%%, tone %g%%, color %g%%', ...
        char(method), max(1, round(step.referenceIndex)), ...
        step.amount, step.secondary, step.colorStrength);
    label = string(label);
end
