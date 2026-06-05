% Expected caller: CIC app plotting helpers. Inputs mirror the app-owned VT
% annotation helper. Side effects are limited to annotating the supplied axes.
function addPaperStyleVTAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX)
    cic.core.dispatch("addPaperStyleVTAnnotations", ax, A, xChoice, ...
        cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX);
end
