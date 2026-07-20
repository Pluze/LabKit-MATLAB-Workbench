% App-owned implementation for flir_thermal.thermalSources.storeCurrentAnnotation within the flir_thermal product workflow.
function state=storeCurrentAnnotation(state,item)
index=state.session.selection.currentIndex;
if index<1||index>numel(state.project.inputs.sources),return,end
sourceId=state.project.inputs.sources(index).id;
annotation=flir_thermal.thermalAnnotations.fromItem(item,sourceId);
items=state.project.annotations.items;
old=find(string({items.sourceId})==string(sourceId),1);
if isempty(old),items(end+1,1)=annotation;else,items(old)=annotation;end
state.project.annotations.items=items;state.session.cache.currentItem=item;
end
