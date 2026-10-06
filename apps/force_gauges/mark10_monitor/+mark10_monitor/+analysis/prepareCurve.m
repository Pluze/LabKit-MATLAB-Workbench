function curve = prepareCurve(time, force, gap, p, kind)
%PREPARECURVE Convert selected full-resolution measurements to engineering data.
% Zero-referenced gap uses fixture closure in all modes; compression positive.
time = double(time(:)); force = double(force(:)); gap = double(gap(:));
if numel(time) ~= numel(force) || numel(time) ~= numel(gap)
    error("mark10_monitor:analysis:MismatchedData", "Data columns must have equal lengths.");
end
if ~isscalar(p.gaugeLength_mm) || ~isfinite(p.gaugeLength_mm) || p.gaugeLength_mm <= 0
    error("mark10_monitor:analysis:InvalidGeometry", "Initial length must be positive and finite.");
end
if ~p.geometryConfirmed
    error("mark10_monitor:analysis:GeometryNotConfirmed", "Confirm specimen dimensions first.");
end
if ~any(string(kind) == mark10_monitor.analysis.experimentTypes())
    error("mark10_monitor:analysis:InvalidExperimentType", "Choose a supported test type.");
end
range = [p.timeStart_s p.timeEnd_s];
if any(~isfinite(range)) || range(1) >= range(2)
    error("mark10_monitor:analysis:InvalidTimeRange", "Analysis start time must precede end time.");
end
finite = isfinite(time) & isfinite(force) & isfinite(gap);
if any(diff(time(finite)) <= 0)
    error("mark10_monitor:analysis:InvalidTimeOrder", "Recording time must increase strictly.");
end
excluded = false(size(time));
if p.excludeGlitches
    excluded(finite) = mark10_monitor.analysis.detectGlitches(force(finite), gap(finite));
end
selected = finite & time >= range(1) & time <= range(2);
sourceIndex = find(selected & ~excluded);
if numel(sourceIndex) < 2
    error("mark10_monitor:analysis:InsufficientData", "Select at least two valid samples.");
end
[f0,x0] = mark10_monitor.analysis.appliedZeroLevels(p);
f = force(sourceIndex)-f0; x = gap(sourceIndex)-x0;
polarity = 1;
if kind == "Compression", polarity = -1; end
curve = struct("time_s", time(sourceIndex), ...
    "strain", polarity*(x-p.gaugeLength_mm)/p.gaugeLength_mm, ...
    "stress_MPa", polarity*f/mark10_monitor.analysis.crossSectionArea(p), ...
    "gap_mm", x, "force_N", f, "segment", zeros(numel(x),1), ...
    "sourceIndex", sourceIndex, "excludedCount", nnz(excluded & selected));
% A removed isolated glitch does not create another loading branch. Longer
% acquisition gaps do: allow normal cadence jitter, bounded below by 0.2 s.
minimumGapBreak_s = 0.2; cadenceGapFactor = 3;
cut = [true; diff(curve.time_s)>max(minimumGapBreak_s,cadenceGapFactor*median(diff(curve.time_s)))];
block = cumsum(cut); next = 0;
for b = unique(block).'
    indices = find(block == b);
    dx = diff(x(indices)); direction = sign(dx);
    for k=2:numel(direction)
        if direction(k)==0, direction(k)=direction(k-1); end
    end
    for k=numel(direction)-1:-1:1
        if direction(k)==0, direction(k)=direction(k+1); end
    end
    turns = find(direction(1:end-1).*direction(2:end)<0)+1;
    bounds = [1; turns(:); numel(indices)+1];
    for k=1:numel(bounds)-1
        next=next+1;
        curve.segment(indices(bounds(k):bounds(k+1)-1))=next;
    end
end
end
