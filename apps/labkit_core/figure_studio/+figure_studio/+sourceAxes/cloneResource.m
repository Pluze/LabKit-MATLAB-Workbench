% Expected caller: Figure Studio source import and handoff actions. Input is
% one valid native axes. Output owns an invisible figure and cloned axes;
% side effects are creation of that transient graphics resource.
function resource = cloneResource(sourceAxes)
%CLONERESOURCE Clone source axes into a private native Figure Studio figure.
% The cloned hierarchy is transient runtime state, not durable project data.
arguments
    sourceAxes (1, 1)
end
if isempty(sourceAxes) || ~isvalid(sourceAxes)
    error("figure_studio:sourceAxes:InvalidAxes", ...
        "Figure Studio requires valid source axes.");
end
sourceFigure = figure("Visible", "off", "HandleVisibility", "off");
try
    clonedAxes = copyobj(sourceAxes, sourceFigure);
catch cause
    deleteIfValid(sourceFigure);
    rethrow(cause);
end
resource = struct("figure", sourceFigure, "axes", clonedAxes);
end

function deleteIfValid(fig)
if isvalid(fig)
    delete(fig);
end
end
