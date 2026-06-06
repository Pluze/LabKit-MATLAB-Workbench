% Expected caller: DIC preprocess runner. Inputs are the figure and preview axes
% handles. Output is the preview axes under the pointer or empty. Side effects:
% none beyond MATLAB hit testing.

function ax = previewAxesUnderPointer(fig, topAxes, bottomAxes)
%PREVIEWAXESUNDERPOINTER Return the DIC preview axes under the pointer.

    ax = [];
    try
        hit = hittest(fig);
        ax = ancestor(hit, 'matlab.ui.control.UIAxes');
    catch
        ax = [];
    end
    if isequal(ax, topAxes) || isequal(ax, bottomAxes)
        return;
    end
    ax = [];
end
