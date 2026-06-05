% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function T = colorbarLevelsTable(opts)
    n = size(opts.colormap, 1);
    strainLevel = linspace(opts.colorRange(1), opts.colorRange(2), n).';
    red = opts.colormap(:, 1);
    green = opts.colormap(:, 2);
    blue = opts.colormap(:, 3);
    T = table(strainLevel, red, green, blue, ...
        'VariableNames', {'StrainLevel', 'Red', 'Green', 'Blue'});
end
