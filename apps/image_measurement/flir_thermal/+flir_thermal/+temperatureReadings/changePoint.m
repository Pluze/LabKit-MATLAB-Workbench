function state=changePoint(state,points,context)
%CHANGEPOINT Store an app-owned manual temperature reading.
item=state.session.cache.currentItem;
if isempty(item)||isempty(points),return,end
[item,reading]=flir_thermal.analysisRun.withManualPoint(item,points(1,:));
if ~isfinite(reading.temperatureC),return,end
state=flir_thermal.thermalSources.storeCurrentAnnotation(state,item);
context.appendStatus(sprintf('Set manual point: %.2f C.',reading.temperatureC));
end
