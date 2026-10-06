function result = fitWindows(curve, windows, kind)
%FITWINDOWS Fit one main loading segment, or every segment in Cyclic mode.
% Report signed slopes and all computable fits regardless of R-squared.
segments = unique(curve.segment);
if kind ~= "Cyclic" && ~isempty(segments)
    % Prefer the largest loading excursion; a deliberately isolated unloading
    % interval remains analyzable. Ties retain the first recorded segment.
    excursions=zeros(size(segments));
    for k=1:numel(segments)
        strain=curve.strain(curve.segment==segments(k));
        excursions(k)=strain(end)-strain(1);
    end
    candidates=find(excursions>0);
    if isempty(candidates),candidates=(1:numel(segments)).';end
    [~,index]=max(abs(excursions(candidates)));
    segments=segments(candidates(index));
end
capacity = numel(segments)*size(windows,1);
rows = cell(capacity,12); rowCount=0; lineCount=0;
% Descriptive review label only: never excludes or changes a computed slope.
linearityReviewR2 = 0.95;
lines = struct("strain_percent", [], "stress_MPa", [], "pointsX", [], "pointsY", [], "row", 0, "windowIndex", 0);
lines = repmat(lines,1,capacity);
for segment = segments.'
    branch = curve.segment == segment;
    branchStrain = 100*curve.strain(branch);
    phase = "increasing strain";
    if branchStrain(end)<branchStrain(1), phase="decreasing strain"; end
    for w=1:size(windows,1)
        if ~windows{w,1}, continue; end
        rowCount=rowCount+1;
        lo=windows{w,3}; hi=windows{w,4};
        if ~isscalar(lo) || ~isscalar(hi) || ~isfinite(lo) || ~isfinite(hi) || lo>=hi
            error("mark10_monitor:analysis:InvalidFitRange", "Each window needs finite increasing strain bounds.");
        end
        tolerance = 8*eps(max([1 abs(lo) abs(hi)]));
        selected = branch & 100*curve.strain>=lo-tolerance & 100*curve.strain<=hi+tolerance;
        x=curve.strain(selected); y=curve.stress_MPa(selected);
        actual=[NaN NaN]; coverage=0; slope=NaN; r2=NaN;
        note="No samples in window";
        if ~isempty(x)
            actual=100*[min(x) max(x)];
            coverage=min(100,100*max(0,actual(2)-actual(1))/(hi-lo));
            note="Need two distinct strain values";
        end
        if numel(unique(x))>=2
            % Centered least squares avoids ill-conditioned absolute coordinates.
            xc=x-mean(x); yc=y-mean(y);
            slope=sum(xc.*yc)/sum(xc.^2); intercept=mean(y)-slope*mean(x);
            predicted=slope*x+intercept;
            total=sum(yc.^2);
            if total>0, r2=1-sum((y-predicted).^2)/total; end
            note="Computed";
            if ~isfinite(r2), note=note+"; R2 undefined (constant stress)";
            elseif r2<linearityReviewR2, note=note+"; nonlinear / low R2"; end
            if numel(x)==2, note=note+"; two points only"; end
            if slope<0, note=note+"; negative slope"; end
            % Distinguish range truncation from normal discrete sample spacing.
            if min(branchStrain)>lo+tolerance || max(branchStrain)<hi-tolerance
                note=note+"; partial window";
            end
            ends=[min(x);max(x)];
            display=unique(round(linspace(1,numel(x),min(600,numel(x)))));
            lineCount=lineCount+1;
            lines(lineCount)=struct("strain_percent",100*ends, ...
                "stress_MPa",slope*ends+intercept,"pointsX",100*x(display), ...
                "pointsY",y(display),"row",rowCount,"windowIndex",w);
        end
        rows(rowCount,:)={segment,char(string(kind)+" / "+phase),windows{w,2},lo,hi, ...
            actual(1),actual(2),numel(x),slope,r2,coverage,char(note)};
    end
end
result=struct("rows",{rows(1:rowCount,:)},"fitLines",lines(1:lineCount));
end
