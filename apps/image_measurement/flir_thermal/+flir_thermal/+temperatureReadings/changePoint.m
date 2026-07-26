% App-owned implementation for flir_thermal.temperatureReadings.changePoint within the flir_thermal product workflow.
function state=changePoint(state,points,context)
%CHANGEPOINT Store an app-owned manual temperature reading.
item=state.session.cache.currentItem;
if isempty(item)||isempty(points),return,end
[item,reading]=flir_thermal.analysisRun.withManualPoint(item,points(1,:));
if ~isfinite(reading.temperatureC),return,end
state=flir_thermal.thermalSources.storeCurrentAnnotation(state,item);
state.project.results.lastExport=[];
state.project.results.resultManifestPath="";
context.log("info", ...
    "flir_thermal.temperaturereadings.changepoint.status", ...
    "Updated the manual temperature point.");
end
