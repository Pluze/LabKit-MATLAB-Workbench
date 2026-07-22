% Expected caller: Figure Studio style refresh. Inputs are one size label and
% a finite fallback width. Output is the selected fixed width or fallback;
% side effects are none.
function width = canvasWidthForSize(sizeChoice, fallback)
%CANVASWIDTHFORSIZE Return the selected fixed canvas width or a fallback.
arguments
    sizeChoice (1, 1) string
    fallback (1, 1) double
end
[choices, widths] = figure_studio.styleLibrary.canvasSizeOptions();
index = find(choices == sizeChoice, 1);
if isempty(index) || ~isfinite(widths(index))
    width = fallback;
else
    width = widths(index);
end
end
