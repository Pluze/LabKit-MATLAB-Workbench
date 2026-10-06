function range=contactEpisode(time,gap,hint,kind)
%CONTACTEPISODE Select the monotonic approach nearest a user contact hint.
% Median filtering is used only to locate turns; fitted measurements stay raw.
time=time(:);gap=gap(:);valid=isfinite(time)&isfinite(gap);time=time(valid);gap=gap(valid);
if numel(time)<16 || any(diff(time)<=0)
    error("mark10_monitor:analysis:InsufficientContactFit","Need at least 16 ordered samples around contact.");
end
if ~isscalar(hint)||~isfinite(hint)||hint<time(1)||hint>time(end)
    error("mark10_monitor:analysis:InvalidTimeRange","Approximate contact time must lie inside the recording.");
end
smooth=movmedian(gap,5);dx=diff(smooth);direction=sign(dx);
for k=2:numel(direction)
    if direction(k)==0,direction(k)=direction(k-1);end
end
for k=numel(direction)-1:-1:1
    if direction(k)==0,direction(k)=direction(k+1);end
end
cuts=find(direction(1:end-1).*direction(2:end)<0)+1;
breaks=find(diff(time)>max(.2,3*median(diff(time))))+1;
bounds=unique([1;cuts;breaks;numel(time)+1]);
candidates=zeros(numel(bounds)-1,2);distance=Inf(numel(bounds)-1,1);oppositeFound=false;
for k=1:numel(bounds)-1
    first=bounds(k);last=bounds(k+1)-1;motion=smooth(last)-smooth(first);
    if last-first<15 || motion==0,continue;end
    if (kind=="Compression"&&motion>0)||(kind=="Tension"&&motion<0)
        oppositeFound=true;continue;
    end
    candidates(k,:)=[time(first) time(last)];
    distance(k)=max([time(first)-hint,hint-time(last),0]);
end
[best,index]=min(distance);
if ~isfinite(best)
    if oppositeFound
        expected="increasing";suggested="Compression";observed="decreasing";
        if kind=="Compression",expected="decreasing";suggested="Tension";observed="increasing";end
        error("mark10_monitor:analysis:TestDirectionMismatch", ...
            "Selected test type is %s (expects %s gap), but sustained travel is %s. Check Test type in Analysis section 1; choose %s if that matches the experiment.", ...
            kind,expected,observed,suggested);
    end
    error("mark10_monitor:analysis:InvalidContactFit","No sustained loading approach found near the indicated time.");
end
range=candidates(index,:);
end
