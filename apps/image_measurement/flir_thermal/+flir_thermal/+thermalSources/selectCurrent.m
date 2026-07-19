function state=selectCurrent(state,selection,context)
if isempty(selection.Indices),return,end
index=selection.Indices(1); source=state.project.inputs.sources(index);
loaded=flir_thermal.sourceFiles.readImages(context.resolveSourcePaths(source),struct("SkipInvalid",false));
if ~isempty(loaded),state.session.cache.currentItem=loaded(1);state.session.selection.currentIndex=index;end
end
