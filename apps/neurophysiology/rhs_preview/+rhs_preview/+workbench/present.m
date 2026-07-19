function view = present(state)
context = struct("preview", state.session.cache.preview, "roiSec", state.session.view.roiSec, "statusMessage", state.session.workflow.statusMessage, "info", state.session.cache.info, "index", state.session.cache.index, "previewChannelRows", state.session.cache.previewChannelRows, "filterRows", state.session.cache.filterRows);
view = labkit.app.view.Snapshot().text("details", string(state.session.workflow.statusMessage)).tableData("summaryTable", rhs_preview.analysisRun.summaryTableData(context)).renderPlot("preview", context).interval("previewRange", state.session.view.roiSec);
end
