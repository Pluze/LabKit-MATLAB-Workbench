function drawDiagnostics(axesById, model)
%DRAWDIAGNOSTICS Explain contact time, then read effective length at zero load.
% This view owns only length estimation; window fitting stays on Modulus Analysis.
e=model.estimate; timeAxes=axesById.contactTime; gapAxes=axesById.contact;
for ax=[timeAxes gapAxes]
    delete(findall(ax,'Type','constantline'));delete(findall(ax,'Type','patch'));cla(ax);legend(ax,'off');hold(ax,'on');grid(ax,'on');
end
sampleColor=[.35 .35 .35];fitColor=[.9 .4 .05];contactColor=[.55 .15 .7];
if ~isempty(e)
    t=e.referenceTime_s;used=e.fitIndices;
    visible=used; bounds=paddedLimits([e.observedForce_N(visible);e.fullFit_N(visible)]);
    window=t(used([1 end]));
    patch(timeAxes,window([1 2 2 1]),bounds([1 1 2 2]),[1 .85 .6], ...
        FaceAlpha=.18,EdgeColor='none',HandleVisibility='off',Tag="mark10ContactFitBand");
    plot(timeAxes,t,e.observedForce_N,'.',Color=sampleColor,DisplayName="Recording (gray)");
    plot(timeAxes,t,e.baselineFit_N,'--',Color=[.1 .45 .7],LineWidth=1.5,DisplayName="Unloaded baseline (may drift)");
    plot(timeAxes,t(used),e.fullFit_N(used),'-',Color=fitColor,LineWidth=2,DisplayName="Fitted baseline + loading");
    xline(timeAxes,e.time_s,'-',Color=contactColor,LineWidth=2,HandleVisibility='off');
    plot(timeAxes,t(e.baselineIndices),e.observedForce_N(e.baselineIndices),'.',Color=[.1 .45 .7],DisplayName="Baseline samples");
    xlim(timeAxes,paddedLimits(window));ylim(timeAxes,bounds);
    title(timeAxes,{"1. Find when loading begins",char(compose("Contact: %.4g s  |  your input: %.4g s",e.time_s,model.contactTime_s))},Interpreter="none");
    ylabel(timeAxes,"Force in loading direction (N)");
    xlabel(timeAxes,{"Recorded time (s)","Orange band: automatic local fit; purple line: contact"});
    legend(timeAxes,'show',Location="southoutside",FontSize=9);

    plot(gapAxes,e.referenceGap_mm,e.referenceForce_N,'.',Color=sampleColor,DisplayName="Measured force minus fitted baseline");
    plot(gapAxes,e.modelGap_mm,e.modelForce_N,'-',Color=fitColor,LineWidth=2,DisplayName="Fitted loading response");
    yline(gapAxes,0,'-',"Zero load",LabelHorizontalAlignment="left",Color=[.3 .3 .3],HandleVisibility="off");
    xline(gapAxes,e.length_mm,':',Color=contactColor,LineWidth=1.5,HandleVisibility='off');
    plot(gapAxes,e.length_mm,0,'o',MarkerSize=10,MarkerFaceColor='white',Color=contactColor,LineWidth=2,DisplayName="Estimated initial length L0");
    label="Your length (not confirmed)";if model.geometryConfirmed,label="Your confirmed length";end
    xline(gapAxes,model.gaugeLength_mm,'--',Color=[.35 .35 .35], ...
        DisplayName=label,Tag="mark10ReviewedLength");
    xlim(gapAxes,paddedLimits([e.modelGap_mm;model.gaugeLength_mm]));
    ylim(gapAxes,paddedLimits([e.referenceForce_N(used);e.modelForce_N;0]));
    title(gapAxes,{"2. Read specimen length at zero load",char(compose("L0: %.5g mm | window spread: %.3g%%",e.length_mm,e.spread_percent))},Interpreter="none");
    ylabel(gapAxes,"Force after baseline subtraction (N)");
    xlabel(gapAxes,{"Fixture gap (mm); 0 mm = fully closed", "Purple circle: L0; fitted points are within the orange time band"});
    legend(gapAxes,'show',Location="southoutside",FontSize=9);
else
    r=model.contactReview;
    plot(timeAxes,r.time_s,r.force_N,'.-',Color=sampleColor);
    xline(timeAxes,model.contactTime_s,':',"Your approximate contact",LabelOrientation="horizontal",Color=contactColor);
    title(timeAxes,{"1. Choose a contact interval","Include unloaded data, then clear loading"});
    xlabel(timeAxes,"Recorded time (s)");ylabel(timeAxes,"Recorded force (N)");
    message="Enter one approximate contact time, then estimate. The recording must contain an unloaded approach and clear initial loading.";
    if strlength(model.lengthFailure)>0,message=model.lengthFailure;end
    text(gapAxes,.03,.9,wrapMessage(message),Units="normalized",VerticalAlignment="top",Interpreter="none",FontSize=11);
    title(gapAxes,{"2. Review the contact hint and recording","No initial-length estimate yet"});
    xlabel(gapAxes,"A failed estimate does not change your length input.");
end
hold(timeAxes,'off');hold(gapAxes,'off');
end

function bounds=paddedLimits(values)
values=values(isfinite(values));
if isempty(values),bounds=[0 1];return;end
bounds=[min(values),max(values)];margin=.1*diff(bounds);
if margin==0,margin=.1*max(1,max(abs(bounds)));end
bounds=bounds+[-margin margin];
end

function lines=wrapMessage(message)
words=split(string(message));lines=strings(numel(words)+1,1);current="";count=0;
for k=1:numel(words)
    if strlength(current)+strlength(words(k))>48
        count=count+1;lines(count)=current;current="";
    end
    current=strtrim(current+" "+words(k));
end
count=count+1;lines(count)=current;lines=lines(1:count);
end
