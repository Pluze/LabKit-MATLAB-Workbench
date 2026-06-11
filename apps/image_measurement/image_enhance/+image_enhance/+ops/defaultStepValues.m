% Expected caller: labkit_ImageEnhance_app controls. Input is a user-facing
% step kind. Output defines the default amount/secondary values and labels.
function values = defaultStepValues(kind)

    key = normalizeKind(kind);
    values = struct();
    values.amountLabel = "Amount:";
    values.secondaryLabel = "Secondary:";
    values.amountLimits = [-100 100];
    values.secondaryLimits = [-100 100];
    values.amount = 0;
    values.secondary = 0;
    values.referenceEnabled = false;

    switch key
        case 'brightnesscontrast'
            values.amountLabel = "Brightness (%):";
            values.secondaryLabel = "Contrast (%):";
            values.amount = 0;
            values.secondary = 15;
        case 'localcontrast'
            values.amountLabel = "Clarity (%):";
            values.secondaryLabel = "Radius (px):";
            values.amountLimits = [0 100];
            values.secondaryLimits = [1 80];
            values.amount = 30;
            values.secondary = 12;
        case 'sharpen'
            values.amountLabel = "Sharpen (%):";
            values.secondaryLabel = "Radius (px):";
            values.amountLimits = [0 100];
            values.secondaryLimits = [0.5 20];
            values.amount = 35;
            values.secondary = 1.5;
        case 'huesaturation'
            values.amountLabel = "Hue (deg):";
            values.secondaryLabel = "Saturation (%):";
            values.amountLimits = [-180 180];
            values.amount = 0;
            values.secondary = 10;
        case 'whitebalance'
            values.amountLabel = "Strength (%):";
            values.secondaryLabel = "Temp (%):";
            values.amountLimits = [0 100];
            values.amount = 100;
            values.secondary = 0;
    end
end

function key = normalizeKind(kind)
    key = lower(regexprep(char(string(kind)), '[^a-zA-Z0-9]', ''));
end
