function state = saveFilterRecord(state, context)
chosen = context.chooseOutputFile(["*.json", "JSON files"], "rhs_filter_record.json"); if chosen.Cancelled, return; end
rhs_preview.resultFiles.writeFilterRecordJson(state.session.cache.filterRows, chosen.Value);
end
