function state=roundRanges(state,context)
annotations=state.project.annotations.items;count=0;
for k=1:numel(annotations)
 if annotations(k).rangeAdjusted
  range=annotations(k).displayRange;annotations(k).displayRange=[floor(range(1)) ceil(range(2))];
  annotations(k).rangeControlBounds=annotations(k).displayRange;count=count+1;
 end
end
state.project.annotations.items=annotations;context.appendStatus("Rounded "+string(count)+" thermal ranges.");
end
