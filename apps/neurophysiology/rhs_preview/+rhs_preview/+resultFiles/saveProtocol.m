function state = saveProtocol(state, context)
chosen = context.chooseOutputFile(["*.json", "JSON files"], "rhs_protocol.json"); if chosen.Cancelled, return; end
rhs_preview.resultFiles.writeProtocolJson(state.project.annotations.protocol, chosen.Value);
end
