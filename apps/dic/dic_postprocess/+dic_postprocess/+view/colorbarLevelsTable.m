% DIC Postprocess view helper. Expected caller: labkit_DICPostprocess_app.
% Input is the overlay options struct. Output is the colorbar level table.
% Side effects: none.
function T = colorbarLevelsTable(opts)
    n = size(opts.colormap, 1);
    strainLevel = linspace(opts.colorRange(1), opts.colorRange(2), n).';
    red = opts.colormap(:, 1);
    green = opts.colormap(:, 2);
    blue = opts.colormap(:, 3);
    T = table(strainLevel, red, green, blue, ...
        'VariableNames', {'StrainLevel', 'Red', 'Green', 'Blue'});
end
