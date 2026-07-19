function state=changeRegion(state,position,context)
%CHANGEREGION Store the chosen thermal ROI and its configured statistic.
item=state.session.cache.currentItem; position=double(position(:).');
if isempty(item)||numel(position)~=4,return,end
[item,reading]=flir_thermal.analysisRun.withRoiReading(item,state.project.parameters.roiMode,position(1:2),position(1:2)+position(3:4));
if ~isfinite(reading.temperatureC),return,end
state=flir_thermal.thermalSources.storeCurrentAnnotation(state,item);
context.appendStatus(sprintf('Set temperature ROI: %.2f C.',reading.temperatureC));
end
