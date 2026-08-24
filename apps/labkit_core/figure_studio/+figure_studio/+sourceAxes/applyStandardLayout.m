% Expected callers: Figure Studio axes handoff and source-selection actions.
% Inputs are the active editable style and optional portable plot data. Output
% retains the active explicit style while restoring the publication reference
% frame. It never rewrites tick labels or infers a layout transformation from
% their content.
function [style, aspectPreset] = applyStandardLayout(style, ~)
%APPLYSTANDARDLAYOUT Restore the calibrated Studio layout for an import.

reference = figure_studio.styleLibrary.goldStandard();
aspectPreset = "Published";
style.canvasWidth = reference.canvasWidth;
style.canvasHeight = reference.canvasHeight;
style.referenceCanvasWidth = reference.canvasWidth;
style.referenceCanvasHeight = reference.canvasHeight;
style.xTickLabelAngle = "Source";
style.wrapXTickLabels = false;
end
