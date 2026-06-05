% Expected caller: CIC app plotting helpers. Inputs are an axes and CIC result
% struct. Side effects are limited to drawing baseline guides on the axes.
function addBaselineYLines(ax, A)
    cic.core.dispatch("addBaselineYLines", ax, A);
end
