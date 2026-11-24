function [force, measured, reconstructed] = plotCoordinates(time, force, gap, analysis)
%PLOTCOORDINATES Keep measured and reconstructed travel on the same reference.
[force, measured] = mark10_monitor.analysis.shiftPlotData(force,gap,analysis);
excluded = false(size(time));
if isfield(analysis,"excludeGlitches") && analysis.excludeGlitches
    excluded = mark10_monitor.analysis.detectGlitches(force,measured);
end
profile = analysis.travelProfile;
modeled = mark10_monitor.analysis.reconstructTravel(time,profile);
reconstructed = modeled-analysis.travelZero_mm;
if isfinite(profile.contact_s)
    measured = profile.contactGap_mm-gap;
    reconstructed = profile.modeledContactGap_mm-modeled;
end
force(excluded) = NaN;
measured(excluded) = NaN;
reconstructed(excluded) = NaN;
end
