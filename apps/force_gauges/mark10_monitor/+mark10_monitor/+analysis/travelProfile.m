function profile = travelProfile(time, force, gap, settings, monitoring, kind)
%TRAVELPROFILE Fit constant-speed strokes in either observed travel direction.
% Time is in seconds, gap is in mm, and opening speed is positive.
if nargin<5, monitoring=false; end
if nargin<6, kind="Compression"; end
profile = struct("contact_s", NaN, "contactGap_mm", NaN, ...
    "modeledContactGap_mm", NaN, "strokes", [], ...
    "status", "Waiting for sustained travel. Showing measured travel.");
valid = isfinite(time) & isfinite(force) & isfinite(gap);
t = time(valid); x = gap(valid);
t = t(:); x = x(:);
if numel(t)<2 || any(diff(t)<=0), return; end

maximumGap_s = max(0.2, 3*median(diff(t)));
badTravel = mark10_monitor.analysis.detectGlitches([],x);
t = t(~badTravel); x = x(~badTravel);
contact = -1;
if kind=="Compression", contact=settings.contact_s; end
if contact>=0 && contact>=t(1) && contact<=t(end)
    left = find(t<=contact,1,"last");
    right = find(t>=contact,1);
    if t(right)-t(left)<=maximumGap_s
        profile.contact_s = contact;
        profile.contactGap_mm = interp1(t,x,contact,"linear");
        profile.modeledContactGap_mm = profile.contactGap_mm;
    end
end

if settings.mode=="Measured gap"
    motionStatus = "Showing measured travel.";
else
    profile.strokes = fitStrokes(t,x,maximumGap_s,settings,monitoring);
    motionStatus = profile.status;
    if ~isempty(profile.strokes)
        latest = profile.strokes(end);
        direction = "opening";
        if latest.speed_mm_min<0, direction="closing"; end
        motionStatus = compose("%d modeled stroke(s) | latest %.5g mm/min %s.", ...
            numel(profile.strokes),abs(latest.speed_mm_min),direction);
    end
end
if isfinite(profile.contact_s)
    motionStatus = compose("Surface zero %.4g s. %s",profile.contact_s,motionStatus);
    for stroke = profile.strokes
        if contact>=stroke.interval_s(1) && contact<=stroke.interval_s(2)
            profile.modeledContactGap_mm = stroke.anchorGap_mm + ...
                stroke.speed_mm_min/60*(contact-stroke.anchor_s);
            break;
        end
    end
elseif contact>=0
    motionStatus = "Contact time unresolved. "+motionStatus;
end
profile.status = motionStatus;
end

function strokes = fitStrokes(t,x,maximumGap_s,settings,monitoring)
strokes = struct("interval_s",{},"speed_mm_min",{},"anchor_s",{},"anchorGap_mm",{});
dx = diff(x);
breaks = diff(t)>maximumGap_s;
ticks = find(dx~=0 & ~breaks);
minimumTicks = 4; % Four transitions constrain a slope despite coarse travel.
if settings.mode=="Entered speed", minimumTicks=2; end
if numel(ticks)<minimumTicks, return; end
candidateStrokes = cell(1,floor(numel(ticks)/minimumTicks));
count = 0;
tickTime = (t(ticks)+t(ticks+1))/2;
direction = sign(dx(ticks));
block = cumsum([0; breaks]);
directionBounds = [1; find(diff(direction)~=0 | diff(block(ticks))~=0)+1; numel(ticks)+1];
for k = 1:numel(directionBounds)-1
    group = (directionBounds(k):directionBounds(k+1)-1).';
    if numel(group)<minimumTicks, continue; end
    tickGap = diff(tickTime(group));
    % Several expected transitions without motion indicate a pause.
    pauseFactor = 2.5;
    pauseBounds = [1; find(tickGap>pauseFactor*median(tickGap))+1; numel(group)+1];
    for j = 1:numel(pauseBounds)-1
        indices = group(pauseBounds(j):pauseBounds(j+1)-1);
        if numel(indices)<minimumTicks, continue; end
        interval = motionInterval(t,ticks,tickTime,indices,breaks,monitoring);
        stroke = fitStroke(tickTime(indices),x,dx,ticks(indices),settings,interval);
        if isfinite(stroke.speed_mm_min)
            count = count+1;
            candidateStrokes{count} = stroke;
        end
    end
end
strokes = [strokes, candidateStrokes{1:count}];
end

function interval = motionInterval(t,ticks,tickTime,indices,breaks,monitoring)
first = ticks(indices(1)); last = ticks(indices(end));
cadence = median(diff(tickTime(indices)));
previousBreak = find(breaks(1:first-1),1,"last");
nextBreak = find(breaks(last+1:end),1);
lower = t(1);
upper = t(end);
if ~isempty(previousBreak), lower=t(previousBreak+1); end
if ~isempty(nextBreak), upper=t(last+nextBreak); end
% Bound by neighboring transitions so opposite strokes cannot both project
% values at a reversal. A half tick after the last step accounts for rounding.
if indices(1)>1, lower=max(lower,mean(tickTime(indices(1)-1:indices(1)))); end
if indices(end)<numel(ticks), upper=min(upper,mean(tickTime(indices(end):indices(end)+1))); end
interval = [max(lower,tickTime(indices(1))-cadence), ...
    min(upper,tickTime(indices(end))+cadence/2)];
% Preview up to the latest live sample while another step is still expected.
previewIntervals = 1.5;
if monitoring && last==ticks(end) && isempty(nextBreak) && ...
        t(end)-tickTime(indices(end))<=previewIntervals*cadence
    interval(2) = t(end);
end
end

function stroke = fitStroke(tickTime,x,dx,ticks,settings,interval)
anchorTime = tickTime(1);
movingTime = tickTime-anchorTime;
movingGap = (x(ticks)+x(ticks+1))/2;
if settings.mode=="Entered speed"
    speed = sign(dx(ticks(1)))*settings.speed_mm_min;
else
    fit = polyfit(movingTime,movingGap,1);
    speed = 60*fit(1);
    % Inconsistent residuals beyond two observed steps indicate a speed
    % change or unstable travel. Keep the measured trace for this stroke.
    maximumResidualTicks = 2;
    tickSize = median(abs(dx(ticks)));
    if max(abs(polyval(fit,movingTime)-movingGap))>maximumResidualTicks*tickSize
        speed = NaN;
    end
end
% Reference the fit to the earliest moving samples as later ticks refine speed.
initial = 1:min(numel(movingGap),4);
anchorGap = median(movingGap(initial)-(speed/60)*movingTime(initial));
stroke = struct("interval_s",interval,"speed_mm_min",speed, ...
    "anchor_s",anchorTime,"anchorGap_mm",anchorGap);
end
