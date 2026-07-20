function state=autoRange(state,context)
item=state.session.cache.currentItem;if isempty(item),return,end
range=automaticRange(item);item.displayRange=range;item.rangeControlBounds=range;item.rangeAdjusted=true;
state=flir_thermal.thermalSources.storeCurrentAnnotation(state,item);
context.appendStatus("Set selected thermal image to auto range.");
end

function range=automaticRange(item)
values=double(item.temperatureC);range=[min(values,[],"all") max(values,[],"all")];
if range(1)==range(2),range=range+[-0.5 0.5];end
end
