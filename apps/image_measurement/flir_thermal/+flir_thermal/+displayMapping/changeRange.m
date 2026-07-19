function state=changeRange(state,range,~)
item=state.session.cache.currentItem;range=double(range(:).');
if isempty(item)||numel(range)~=2||any(~isfinite(range)),return,end
range=sort(range);if range(1)==range(2),range=range+[-.5 .5];end
item.displayRange=range;item.rangeControlBounds=range;item.rangeAdjusted=true;
state=flir_thermal.thermalSources.storeCurrentAnnotation(state,item);
end
