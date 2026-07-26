% App-owned implementation for flir_thermal.temperatureReadings.changeRegion within the flir_thermal product workflow.
function state=changeRegion(state,position,context)
%CHANGEREGION Store the chosen thermal ROI and its configured statistic.
item=state.session.cache.currentItem; position=double(position(:).');
if isempty(item)||numel(position)~=4,return,end
[item,reading]=flir_thermal.analysisRun.withRoiReading(item,state.project.parameters.roiMode,position(1:2),position(1:2)+position(3:4));
if ~isfinite(reading.temperatureC),return,end
state=flir_thermal.thermalSources.storeCurrentAnnotation(state,item);
state.project.results.lastExport=[];
state.project.results.resultManifestPath="";
context.log("info", ...
    "flir_thermal.temperaturereadings.changeregion.status", ...
    "Updated the temperature ROI.");
end
