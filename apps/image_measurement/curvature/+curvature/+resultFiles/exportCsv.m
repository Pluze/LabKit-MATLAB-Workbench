function state = exportCsv(state, context)
choice=context.chooseOutputFile(["*.csv","CSV files (*.csv)"],pwd); if choice.Cancelled,return,end
writetable(curvature.resultFiles.buildResultTable(state.project.results.fit,state.session.cache.imagePath,state.project.results.length),choice.Value);
end
