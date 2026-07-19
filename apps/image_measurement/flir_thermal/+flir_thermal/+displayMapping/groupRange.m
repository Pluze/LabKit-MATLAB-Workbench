function state=groupRange(state,context)
items=loadItems(state,context);if isempty(items),return,end
ranges=zeros(numel(items),2);for k=1:numel(items),ranges(k,:)=auto(items(k));end
shared=[min(ranges(:,1)) max(ranges(:,2))];
for k=1:numel(items),items(k).displayRange=shared;items(k).rangeControlBounds=shared;items(k).rangeAdjusted=true;end
state=storeAll(state,items);context.appendStatus("Applied one shared range to "+string(numel(items))+" thermal images.");
end
function items=loadItems(state,context)
items=flir_thermal.sourceFiles.readImages(context.resolveSourcePaths(state.project.inputs.sources),struct("SkipInvalid",false));
for k=1:numel(items),id=state.project.inputs.sources(k).id;index=find(string({state.project.annotations.items.sourceId})==string(id),1);if ~isempty(index),items(k)=flir_thermal.thermalAnnotations.apply(items(k),state.project.annotations.items(index));end,end
end
function state=storeAll(state,items)
for k=1:numel(items),state.session.selection.currentIndex=k;state=flir_thermal.thermalSources.storeCurrentAnnotation(state,items(k));end
end
function r=auto(item)
v=double(item.values);r=[min(v,[],"all") max(v,[],"all")];if r(1)==r(2),r=r+[-.5 .5];end
end
