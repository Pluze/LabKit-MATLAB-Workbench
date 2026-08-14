function value = exportTable(rows, parameters)
%EXPORTTABLE Add specimen and fit provenance to per-branch result rows.
value = mark10_monitor.analysis.resultTable(rows);
count = height(value);
value.GaugeLength_mm = repmat(parameters.gaugeLength_mm, count, 1);
value.Width_mm = repmat(parameters.width_mm, count, 1);
value.Thickness_mm = repmat(parameters.thickness_mm, count, 1);
value.FitMode = repmat(string(parameters.fitMode), count, 1);
end
