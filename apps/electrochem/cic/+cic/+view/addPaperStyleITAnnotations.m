% Expected caller: CIC app plotting helpers. Inputs mirror the app-owned IT
% annotation helper. Side effects are limited to annotating the supplied axes.
function addPaperStyleITAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX)
    cic.core.dispatch("addPaperStyleITAnnotations", ax, A, xChoice, ...
        cathStartX, cathEndX, anodStartX, anodEndX);
end
