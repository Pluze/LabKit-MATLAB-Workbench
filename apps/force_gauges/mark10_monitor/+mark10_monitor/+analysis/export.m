function applicationState = export(applicationState, context)
%EXPORT Write the current full-resolution selected curve in acquisition order.
a=applicationState.session.analysis;
if ~a.curveReady
    context.alert("Update the stress-strain curve before exporting.","Export Stress-Strain"); return;
end
name="stress_strain.csv";
if applicationState.session.playback.loaded && a.dataSource=="Loaded Recording"
    [~,stem]=fileparts(applicationState.session.playback.source);
    name=string(stem)+"_stress_strain.csv";
end
choice=context.chooseOutputFile(["*.csv","CSV files"],name);
if choice.Cancelled, return; end
path=string(choice.Value); [folder,stem,extension]=fileparts(path);
if lower(string(extension))~=".csv", path=string(fullfile(folder,string(stem)+".csv")); end
writetable(mark10_monitor.analysis.exportTable(a.curve),path);
applicationState.session.analysis.exportStatus="Exported stress-strain: "+path;
end
