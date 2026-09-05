function drawOverview(axesById, model)
%DRAWOVERVIEW Show each source on its original Nyquist and Bode coordinates.
% Called by the EIS workspace with decoded items and display options. No
% interpolation, frequency matching, fitting, or numerical export is performed.
axesIds = ["nyquist" "magnitude" "phase"];
xNames = ["Zreal" "Freq (Hz)" "Freq (Hz)"];
yNames = ["-Zimag" "Zmod" "Zphz (deg)"];
titles = ["Nyquist" "Impedance magnitude" "Phase"];
for k = 1:numel(axesIds)
    if ~isfield(axesById, axesIds(k)), continue; end
    ax = axesById.(axesIds(k));
    options = model.options;
    options.xName = xNames(k);
    options.yName = yNames(k);
    options.logX = k > 1;
    options.logY = k == 2;
    panel = model;
    panel.options = options;
    panel.viewAction = "";
    eis.overlayPlot.draw(struct("main", ax), panel);
    title(ax, titles(k));
end
if model.hasItems && isfield(axesById, "nyquist")
    labkit.app.plot.fitAxesToGraphics(axesById.nyquist, EqualDataUnits=true);
end
end
