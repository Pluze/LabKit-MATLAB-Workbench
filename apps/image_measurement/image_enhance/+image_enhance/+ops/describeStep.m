% Expected caller: labkit_ImageEnhance_app, view helpers, and tests. Input is
% an enhancement step. Output is a concise reproducible history label.
function label = describeStep(step)

    kind = normalizeKind(step.kind);
    switch kind
        case 'brightnesscontrast'
            label = sprintf('Brightness %+g%%, contrast %+g%%', ...
                step.amount, step.secondary);
        case 'localcontrast'
            label = sprintf('Local contrast %+g%%, radius %.1f px', ...
                step.amount, max(1, step.secondary));
        case 'sharpen'
            label = sprintf('Sharpen %+g%%, radius %.1f px', ...
                step.amount, max(0.5, step.secondary));
        case 'huesaturation'
            label = sprintf('Hue %+g deg, saturation %+g%%', ...
                step.amount, step.secondary);
        case 'whitebalance'
            label = sprintf('Gray-world white balance %g%%, temp %+g%%', ...
                step.amount, step.secondary);
        otherwise
            label = sprintf('%s %+g %+g', char(step.kind), ...
                step.amount, step.secondary);
    end
    label = string(label);
end

function key = normalizeKind(kind)
    key = lower(regexprep(char(string(kind)), '[^a-zA-Z0-9]', ''));
end
