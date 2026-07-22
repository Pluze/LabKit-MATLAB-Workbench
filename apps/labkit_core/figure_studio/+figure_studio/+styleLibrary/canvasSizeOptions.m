function [choices, widths] = canvasSizeOptions()
%CANVASSIZEOPTIONS Return Figure Studio's selectable export canvas widths.
% The source-size entry preserves an imported FIG's recorded canvas until a
% fixed export width is selected.
choices = ["Source size", "640 px", "720 px", "960 px", "1200 px", ...
    "1237 px", "1364 px", "1600 px", "2400 px"];
widths = [NaN, 640, 720, 960, 1200, 1237, 1364, 1600, 2400];
end
