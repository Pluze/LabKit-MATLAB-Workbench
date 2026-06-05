% Expected caller: VT resistance app plotting helpers. Inputs mirror the
% app-owned current annotation helper. Side effects are limited to axes labels.
function addResistanceITAnnotations(ax, A, cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, cathStartX, cathEndX, anodStartX, anodEndX)
    vt_resistance.core.dispatch("addResistanceITAnnotations", ax, A, ...
        cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, ...
        cathStartX, cathEndX, anodStartX, anodEndX);
end
