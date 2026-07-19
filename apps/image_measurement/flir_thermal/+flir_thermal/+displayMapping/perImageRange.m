function state=perImageRange(state,context)
items=flir_thermal.sourceFiles.readImages(context.resolveSourcePaths(state.project.inputs.sources),struct("SkipInvalid",false));
for k=1:numel(items)
 v=double(items(k).values);r=[min(v,[],"all") max(v,[],"all")];if r(1)==r(2),r=r+[-.5 .5];end
 items(k).displayRange=r;items(k).rangeControlBounds=r;items(k).rangeAdjusted=true;state.session.selection.currentIndex=k;state=flir_thermal.thermalSources.storeCurrentAnnotation(state,items(k));
end
context.appendStatus("Applied individual auto ranges to "+string(numel(items))+" thermal images.");
end
