function artifacts = profileLabKitWriteReport(payload, htmlFile, opt)
%PROFILELABKITWRITEREPORT Write LabKit profile HTML and agent sidecars.
%
% Expected caller: tools/profiling/profileLabKitTarget.m. Inputs are the normalized profile
% payload, an HTML output path, and parsed report options. Output describes the
% generated artifacts for automation and handoff messages.

    [summaryText, summaryData] = agentSummary(payload, opt.SummaryTopN);
    html = buildHtml(payload, opt, summaryText, summaryData);
    writeUtf8(htmlFile, html);

    jsonFile = sidecarPath(htmlFile, opt);
    artifactJson = struct();
    artifactJson.metadata = payload.metadata;
    artifactJson.summaryText = summaryText;
    artifactJson.summary = summaryData;
    artifactJson.profilerInfo = payload.profilerInfo;
    artifactJson.functions = payload.functions;
    writeUtf8(jsonFile, jsonencode(artifactJson));

    artifacts = struct('htmlFile', string(htmlFile), ...
        'jsonFile', string(jsonFile), ...
        'functionCount', numel(payload.functions));

    fprintf('Saved profile report:\n  %s\n', htmlFile);
    fprintf('Saved agent JSON:\n  %s\n', artifacts.jsonFile);
    fprintf('Functions embedded: %d\n', artifacts.functionCount);
    if opt.PrintSummary
        fprintf('\n%s\n', summaryText);
    end
    if opt.OpenReport
        urlPath = strrep(htmlFile, filesep, '/');
        web(['file:///' urlPath], '-browser');
    end
end

function [summaryText, summaryData] = agentSummary(payload, topN)
    functions = payload.functions;
    topCapturedSelf = topRows(functions, 'SelfTime', topN, "captured");
    topCapturedTotal = topRows(functions, 'TotalTime', topN, "captured");
    topProjectSelf = topRows(functions, 'SelfTime', topN, "project");
    topProjectTotal = topRows(functions, 'TotalTime', topN, "project");
    topNonInternalSelf = topRows(functions, 'SelfTime', topN, "noninternal");
    topProfilerToolSelf = topRows(functions, 'SelfTime', topN, "profiler_tool");

    summaryData = struct();
    summaryData.metadata = payload.metadata;
    summaryData.topCapturedSelfTime = topCapturedSelf;
    summaryData.topCapturedTotalTime = topCapturedTotal;
    summaryData.topProjectSelfTime = topProjectSelf;
    summaryData.topProjectTotalTime = topProjectTotal;
    summaryData.topNonInternalSelfTime = topNonInternalSelf;
    summaryData.topProfilerToolSelfTime = topProfilerToolSelf;
    summaryData.topSelfTime = topCapturedSelf;
    summaryData.topTotalTime = topCapturedTotal;
    summaryData.topUserSelfTime = topNonInternalSelf;
    summaryData.readingHints = [ ...
        "Full profile rows are retained in jsonFile and embedded profile-json."; ...
        "Prefer topProjectSelfTime for LabKit-owned code that can be edited."; ...
        "Use sourceTag and tags fields for grep or agent filtering."; ...
        "Use topCapturedTotalTime to identify captured user actions, toolbox callbacks, app launches, or network calls."; ...
        "Check parent and child edges in profile-json before changing behavior." ...
        ];

    lines = [
        "AGENT_SUMMARY_BEGIN"
        "target: " + string(payload.metadata.Target)
        "generated_at: " + string(payload.metadata.GeneratedAt)
        "matlab_version: " + string(payload.metadata.MatlabVersion)
        "num_functions: " + string(payload.metadata.NumFunctions)
        "total_calls: " + string(payload.metadata.TotalCalls)
        "project_functions: " + string(payload.metadata.ProjectFunctions)
        "matlab_internal_functions: " + string(payload.metadata.MatlabInternalFunctions)
        "profiler_tool_functions: " + string(payload.metadata.ProfilerToolFunctions)
        "max_total_time_s: " + formatNumber(payload.metadata.MaxTotalTime)
        "sum_self_time_s: " + formatNumber(payload.metadata.SumSelfTime)
        "target_file: " + string(payload.metadata.TargetFile)
        "project_root: " + string(payload.metadata.RepoRoot)
        ""
        "reading_hints:"
        "- No profiler rows are dropped; profile-json and the JSON sidecar contain all captured functions."
        "- top_project_self_time is the first table to inspect for editable LabKit code."
        "- Use source_tag and tags columns for grep or agent-side filtering."
        "- top_captured_total_time can include deliberate clicks, app launches, network calls, GUI close cost, or MATLAB callbacks."
        ""
        "top_project_self_time:"
        rowHeader()
        formatRows(topProjectSelf)
        ""
        "top_project_total_time:"
        rowHeader()
        formatRows(topProjectTotal)
        ""
        "top_captured_self_time:"
        rowHeader()
        formatRows(topCapturedSelf)
        ""
        "top_captured_total_time:"
        rowHeader()
        formatRows(topCapturedTotal)
        ""
        "top_noninternal_self_time:"
        rowHeader()
        formatRows(topNonInternalSelf)
        ""
        "top_profiler_tool_self_time:"
        rowHeader()
        formatRows(topProfilerToolSelf)
        "AGENT_SUMMARY_END"
        ];

    if strlength(string(payload.metadata.RunError)) > 0
        insertAt = find(lines == "reading_hints:", 1);
        lines = [lines(1:insertAt-1); "run_error: present"; lines(insertAt:end)];
    else
        insertAt = find(lines == "reading_hints:", 1);
        lines = [lines(1:insertAt-1); "run_error: none"; lines(insertAt:end)];
    end
    summaryText = char(strjoin(lines, newline));
end

function rows = topRows(functions, metric, topN, filterMode)
    if isempty(functions)
        rows = repmat(emptySummaryRow(), 1, 0);
        return;
    end
    switch string(filterMode)
        case "captured"
            functions = functions(~[functions.IsProfilerTool]);
        case "project"
            functions = functions([functions.IsRepoFile] & ~[functions.IsProfilerTool]);
        case "noninternal"
            functions = functions(~[functions.IsMatlabInternal] & ~[functions.IsProfilerTool]);
        case "profiler_tool"
            functions = functions([functions.IsProfilerTool]);
    end
    if isempty(functions)
        rows = repmat(emptySummaryRow(), 1, 0);
        return;
    end
    values = arrayfun(@(f) double(f.(metric)), functions);
    [~, order] = sort(values, 'descend');
    order = order(1:min(topN, numel(order)));
    functions = functions(order);
    rows = repmat(emptySummaryRow(), 1, numel(functions));
    for k = 1:numel(functions)
        rows(k).rank = k;
        rows(k).index = functions(k).Index;
        rows(k).functionName = string(functions(k).FunctionName);
        rows(k).selfTime = functions(k).SelfTime;
        rows(k).totalTime = functions(k).TotalTime;
        rows(k).numCalls = functions(k).NumCalls;
        rows(k).isMatlabInternal = functions(k).IsMatlabInternal;
        rows(k).isRepoFile = functions(k).IsRepoFile;
        rows(k).isProfilerTool = functions(k).IsProfilerTool;
        rows(k).sourceTag = string(functions(k).SourceTag);
        rows(k).tags = string(functions(k).Tags);
        rows(k).file = string(functions(k).FileName);
        rows(k).shortFile = string(functions(k).ShortFileName);
    end
end

function row = emptySummaryRow()
    row = struct('rank', 0, 'index', 0, 'functionName', "", ...
        'selfTime', 0, 'totalTime', 0, 'numCalls', 0, ...
        'isMatlabInternal', false, 'isRepoFile', false, ...
        'isProfilerTool', false, 'sourceTag', "", 'tags', "", ...
        'file', "", 'shortFile', "");
end

function text = rowHeader()
    text = "rank|source_tag|tags|self_s|total_s|calls|internal|project|profiler_tool|function|file";
end

function lines = formatRows(rows)
    if isempty(rows)
        lines = "none";
        return;
    end
    lines = strings(numel(rows), 1);
    for k = 1:numel(rows)
        lines(k) = string(sprintf('%d|%s|%s|%.6f|%.6f|%d|%d|%d|%d|%s|%s', ...
            rows(k).rank, cleanCell(rows(k).sourceTag), cleanCell(rows(k).tags), ...
            rows(k).selfTime, rows(k).totalTime, rows(k).numCalls, ...
            rows(k).isMatlabInternal, rows(k).isRepoFile, rows(k).isProfilerTool, ...
            cleanCell(rows(k).functionName), cleanCell(rows(k).shortFile)));
    end
end

function text = cleanCell(text)
    text = char(string(text));
    text = strrep(text, newline, ' ');
    text = strrep(text, '|', '/');
end

function html = buildHtml(payload, opt, summaryText, summaryData)
    json = jsonencode(payload);
    json = strrep(json, '</', '<\/');
    summaryJson = jsonencode(summaryData);
    summaryJson = strrep(summaryJson, '</', '<\/');
    parts = [
        "<!doctype html><html><head><meta charset=""utf-8""><title>MATLAB Profile Report</title>"
        "<style>body{font-family:system-ui,Segoe UI,Arial,sans-serif;margin:0;background:#f6f7fb;color:#111827}.wrap{max-width:1700px;margin:0 auto;padding:22px}.hero,.panel,.card{background:#fff;border:1px solid #dbe1ea;border-radius:8px;box-shadow:0 1px 2px rgba(15,23,42,.04)}.hero{padding:18px;margin-bottom:14px}h1{margin:0 0 8px;font-size:24px}h2{margin:0 0 10px;font-size:17px}.meta,.path,.footer{color:#64748b;font-size:12px;line-height:1.45}.path,.detailTitle,.linklike{overflow-wrap:anywhere}.cards{display:grid;grid-template-columns:repeat(5,minmax(130px,1fr));gap:10px;margin-bottom:14px}.card{padding:12px}.label{font-size:12px;color:#64748b}.value{font-size:22px;font-weight:750}.layout{display:grid;grid-template-columns:minmax(720px,1.35fr) minmax(430px,.75fr);gap:14px}.panel{padding:14px;min-width:0;margin-bottom:14px}.wide{grid-column:1/-1}.controls{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin-bottom:10px;font-size:12px}input,select,button{font:inherit}.tableWrap,.miniTable{overflow:auto;border:1px solid #e5e7eb;border-radius:8px}.tableWrap{max-height:650px;overflow-x:hidden}table{width:100%;border-collapse:collapse;font-size:12px}#mainTable{table-layout:fixed}th,td{padding:7px 8px;border-bottom:1px solid #edf0f4;text-align:left;vertical-align:top;overflow:hidden;text-overflow:ellipsis}th{position:sticky;top:0;background:#f8fafc;z-index:1;cursor:pointer;white-space:nowrap}#mainTable th:nth-child(1),#mainTable td:nth-child(1){width:44px}#mainTable th:nth-child(3),#mainTable td:nth-child(3){width:104px}#mainTable th:nth-child(4),#mainTable td:nth-child(4){width:64px}#mainTable th:nth-child(5),#mainTable td:nth-child(5){width:76px}#mainTable th:nth-child(6),#mainTable td:nth-child(6){width:76px}#mainTable th:nth-child(7),#mainTable td:nth-child(7){width:60px}#mainTable th:nth-child(8),#mainTable td:nth-child(8){width:82px}.num{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}.fname{font-weight:650;line-height:1.25}.userfile{color:#1d4ed8}.internal{color:#6b7280}.source{font-family:ui-monospace,Consolas,monospace;white-space:nowrap}.badge{display:inline-block;max-width:100%;padding:2px 6px;border-radius:999px;font-size:11px;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;background:#e5e7eb;color:#374151}.tag-project{background:#dbeafe;color:#1e40af}.tag-matlab_internal{background:#e5e7eb;color:#374151}.tag-external{background:#fef3c7;color:#92400e}.tag-profiler_tool{background:#ede9fe;color:#5b21b6}.bar{height:5px;background:#e5e7eb;border-radius:99px;margin:2px 0}.bar span{display:block;height:100%;background:#2563eb;border-radius:99px}.selected{background:#fff7ed}.detailTitle{font-weight:750;font-size:14px;line-height:1.35}.kv{display:grid;grid-template-columns:110px minmax(0,1fr);gap:5px 10px;font-size:13px;margin:9px 0}.sectionLabel{font-weight:750;margin:12px 0 6px}.linklike{color:#1d4ed8;cursor:pointer;text-decoration:underline}.flameWrap{height:420px;overflow:auto;background:#f8fafc;border:1px solid #e5e7eb;border-radius:8px;padding:8px}.flameRow{position:relative;height:22px}.flameFrame{position:absolute;top:1px;height:18px;border-radius:4px;border:1px solid rgba(0,0,0,.15);background:#2563eb;color:#fff;font-size:11px;line-height:18px;padding:0 4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;cursor:pointer}.flameFrame.internal{background:#7b8494}.flameFrame.selected{background:#f97316}.errorBox{background:#fff1f2;border:1px solid #fecdd3;color:#881337;border-radius:8px;padding:10px}pre{font-family:ui-monospace,Consolas,monospace;white-space:pre-wrap;word-break:break-word;font-size:12px;background:#0f172a;color:#e2e8f0;border-radius:8px;padding:12px;max-height:360px;overflow:auto}@media(max-width:1200px){.layout,.cards{grid-template-columns:1fr}.tableWrap{overflow-x:auto}#mainTable{min-width:820px}}</style></head>"
        "<body><div class=""wrap""><div class=""hero""><h1>MATLAB Profile Report</h1><div class=""meta""><div><b>Target:</b> <span id=""targetText""></span></div><div><b>Generated:</b> <span id=""generatedAt""></span> &nbsp; <b>MATLAB:</b> <span id=""matlabVersion""></span></div><div>Self-contained flame graph, function table, and agent-readable summary generated from MATLAB profile data.</div></div><div id=""errorBox""></div></div>"
        "<div class=""cards""><div class=""card""><div class=""label"">Functions</div><div class=""value"" id=""cardFunctions"">0</div></div><div class=""card""><div class=""label"">Total calls</div><div class=""value"" id=""cardCalls"">0</div></div><div class=""card""><div class=""label"">Max total time</div><div class=""value"" id=""cardMaxTotal"">0 s</div></div><div class=""card""><div class=""label"">Sum self time</div><div class=""value"" id=""cardSumSelf"">0 s</div></div><div class=""card""><div class=""label"">Rows shown</div><div class=""value"" id=""cardRows"">0</div></div></div>"
        "<div class=""panel wide"" id=""agent-summary""><h2>Agent summary</h2><div class=""meta"">The block below is delimited for text extraction. Full JSON payloads are embedded as profile-json and agent-summary-json.</div><pre>" + htmlEscape(summaryText) + "</pre></div>"
        "<div class=""layout""><div class=""panel wide""><h2>Flame graph</h2><div class=""controls""><label>Source <select id=""flameSource""><option value=""project"" selected>Project</option><option value=""captured"">Captured</option><option value=""matlab_internal"">MATLAB internal</option><option value=""external"">External</option><option value=""profiler_tool"">Profiler tool</option><option value=""all"">All</option></select></label><label>Roots <select id=""flameMode""><option value=""roots"">Top-level roots</option><option value=""top"">Top total-time functions</option></select></label><label>Max depth <input id=""flameDepth"" type=""number"" value=""18"" min=""2"" max=""80"" style=""width:70px""></label><label>Min width <input id=""flameMinWidth"" type=""number"" value=""0.15"" min=""0"" step=""0.01"" style=""width:70px""> %</label><label>Roots shown <input id=""flameRootN"" type=""number"" value=""__CHART_TOP_N__"" min=""1"" max=""500"" style=""width:70px""></label><button onclick=""renderFlame()"">Update flame</button></div><div id=""flame"" class=""flameWrap""></div><div class=""meta"">Root frames are at the bottom. Click a frame or table row to inspect function details.</div></div>"
        "<div class=""panel""><h2>Function table</h2><div class=""controls""><label>Source <select id=""sourceFilter""><option value=""project"" selected>Project</option><option value=""captured"">Captured</option><option value=""matlab_internal"">MATLAB internal</option><option value=""external"">External</option><option value=""profiler_tool"">Profiler tool</option><option value=""all"">All</option></select></label><input id=""searchBox"" type=""search"" placeholder=""Search function, source tag, or file path..."" style=""min-width:220px""><label><input id=""hideInternal"" type=""checkbox""> Hide MATLAB internal</label><label>Min self <input id=""minSelf"" type=""number"" value=""0"" step=""0.001"" style=""width:72px""> s</label><label>Rows <input id=""rowLimit"" type=""number"" value=""__INITIAL_ROWS__"" min=""20"" max=""100000"" style=""width:78px""></label><button onclick=""renderTable()"">Apply</button></div><div class=""tableWrap""><table id=""mainTable""><thead><tr><th onclick=""setSort('Index')"">#</th><th onclick=""setSort('FunctionName')"">Function</th><th onclick=""setSort('SourceTag')"">Source</th><th onclick=""setSort('NumCalls')"" class=""num"">Calls</th><th onclick=""setSort('SelfTime')"" class=""num"">Self</th><th onclick=""setSort('TotalTime')"" class=""num"">Total</th><th onclick=""setSort('ExecutedLineTime')"" class=""num"">Lines</th><th>Plot</th></tr></thead><tbody></tbody></table></div></div>"
        "<div class=""panel""><h2>Selected function</h2><div id=""detail""><div class=""meta"">Click any row to inspect parents, children, and executed lines.</div></div></div></div><div class=""footer"">Generated by tools/profiling/profileLabKitTarget.m.</div></div>"
        "<script id=""agent-summary-json"" type=""application/json"">__SUMMARY_JSON__</script><script id=""profile-json"" type=""application/json"">__JSON__</script><script>__SCRIPT__</script></body></html>"
        ];
    html = strjoin(parts, newline);
    html = strrep(html, '__INITIAL_ROWS__', num2str(opt.InitialRows));
    html = strrep(html, '__CHART_TOP_N__', num2str(opt.ChartTopN));
    html = strrep(html, '__SUMMARY_JSON__', summaryJson);
    html = strrep(html, '__JSON__', json);
    html = strrep(html, '__SCRIPT__', clientScript(opt.SortBy));
end

function script = clientScript(sortBy)
    lines = [
        "const payload=JSON.parse(document.getElementById('profile-json').textContent);const DATA=Array.isArray(payload.functions)?payload.functions:(payload.functions?[payload.functions]:[]);const meta=payload.metadata||{};const INDEX=new Map(DATA.map(r=>[Number(r.Index),r]));let sortKey='__SORT_BY__';let sortDesc=true;let selectedIndex=null;let flameVisible=new Set();"
        "function byId(id){return document.getElementById(id)}function fmt(x,d=6){x=Number(x)||0;if(Math.abs(x)>=100)return x.toFixed(2);if(Math.abs(x)>=10)return x.toFixed(3);return x.toFixed(d).replace(/0+$/,'').replace(/\.$/,'')}function fmtInt(x){return(Number(x)||0).toLocaleString()}function esc(s){return String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/""/g,'&quot;').replace(/'/g,'&#39;')}function asArray(x){return Array.isArray(x)?x:(x==null?[]:[x])}"
        "function initMeta(){byId('targetText').textContent=meta.Target||'';byId('generatedAt').textContent=meta.GeneratedAt||'';byId('matlabVersion').textContent=meta.MatlabVersion||'';byId('cardFunctions').textContent=fmtInt(meta.NumFunctions||DATA.length);byId('cardCalls').textContent=fmtInt(meta.TotalCalls||DATA.reduce((s,r)=>s+(Number(r.NumCalls)||0),0));byId('cardMaxTotal').textContent=fmt(meta.MaxTotalTime||0)+' s';byId('cardSumSelf').textContent=fmt(meta.SumSelfTime||0)+' s';if(meta.RunError){byId('errorBox').innerHTML='<div class=""errorBox""><b>Target ended with an error, but profile data was exported.</b><pre>'+esc(meta.RunError)+'</pre></div>'}}"
        "function sourceOk(r,m){const tag=String(r.SourceTag||'unknown');if(!m||m==='all')return true;if(m==='captured')return tag!=='profiler_tool';return tag===m}function sourceRows(m){return DATA.filter(r=>sourceOk(r,m))}function sourceBadge(tag){tag=String(tag||'unknown');return '<span class=""badge tag-'+esc(tag).replace(/[^a-zA-Z0-9_-]/g,'_')+'"">'+esc(tag)+'</span>'}"
        "function compareRows(a,b,k){let av=a[k],bv=b[k];if(typeof av==='string'||typeof bv==='string'){av=String(av||'').toLowerCase();bv=String(bv||'').toLowerCase()}else{av=Number(av)||0;bv=Number(bv)||0}if(av<bv)return sortDesc?1:-1;if(av>bv)return sortDesc?-1:1;return 0}function getFiltered(){const q=byId('searchBox').value.trim().toLowerCase();const sourceMode=byId('sourceFilter').value;const hideInternal=byId('hideInternal').checked;const minSelf=Number(byId('minSelf').value)||0;let rows=sourceRows(sourceMode).filter(r=>(Number(r.SelfTime)||0)>=minSelf);if(hideInternal)rows=rows.filter(r=>!r.IsMatlabInternal);if(q)rows=rows.filter(r=>[r.FunctionName,r.CompleteName,r.Type,r.SourceTag,r.Tags,r.FileName,r.ShortFileName].some(v=>String(v||'').toLowerCase().includes(q)));rows.sort((a,b)=>compareRows(a,b,sortKey));return rows}function setSort(k){if(sortKey===k){sortDesc=!sortDesc}else{sortKey=k;sortDesc=true}renderTable()}"
        "function renderTable(){const limit=Math.max(1,Number(byId('rowLimit').value)||500);const rows=getFiltered().slice(0,limit);const maxTotal=Math.max(...DATA.map(r=>Number(r.TotalTime)||0),1e-12);const maxSelf=Math.max(...DATA.map(r=>Number(r.SelfTime)||0),1e-12);const tbody=document.querySelector('#mainTable tbody');tbody.innerHTML=rows.map(r=>{const st=100*(Number(r.SelfTime)||0)/maxSelf;const tt=100*(Number(r.TotalTime)||0)/maxTotal;const cls=r.IsMatlabInternal?'internal':'userfile';const sel=selectedIndex===Number(r.Index)?' class=""selected""':'';return '<tr'+sel+' onclick=""selectFunction('+r.Index+')""><td class=""num"">'+r.Index+'</td><td><div class=""fname '+cls+'"">'+esc(r.FunctionName)+'</div><div class=""path"">'+esc(r.ShortFileName||r.FileName||r.CompleteName)+'</div></td><td class=""source"">'+sourceBadge(r.SourceTag)+'</td><td class=""num"">'+fmtInt(r.NumCalls)+'</td><td class=""num"">'+fmt(r.SelfTime)+'</td><td class=""num"">'+fmt(r.TotalTime)+'</td><td class=""num"">'+fmt(r.ExecutedLineTime)+'</td><td><div class=""bar""><span style=""width:'+Math.min(100,st)+'%""></span></div><div class=""bar""><span style=""width:'+Math.min(100,tt)+'%""></span></div></td></tr>'}).join('');byId('cardRows').textContent=fmtInt(rows.length)}"
        "function findByIndex(idx){return INDEX.get(Number(idx))}function selectFunction(idx){selectedIndex=Number(idx);renderDetail(findByIndex(idx));renderTable();highlightFlame()}function edgeTable(edges,title){edges=asArray(edges);if(!edges.length)return '<div class=""sectionLabel"">'+title+'</div><div class=""meta"">None</div>';return '<div class=""sectionLabel"">'+title+'</div><div class=""miniTable""><table><thead><tr><th>#</th><th>Function</th><th class=""num"">Calls</th><th class=""num"">Total</th></tr></thead><tbody>'+edges.slice().sort((a,b)=>(Number(b.TotalTime)||0)-(Number(a.TotalTime)||0)).map(e=>'<tr><td class=""num"">'+(e.Index||'')+'</td><td><span class=""linklike"" onclick=""selectFunction('+e.Index+')"">'+esc(e.FunctionName||'')+'</span></td><td class=""num"">'+fmtInt(e.NumCalls)+'</td><td class=""num"">'+fmt(e.TotalTime)+'</td></tr>').join('')+'</tbody></table></div>'}"
        "function lineTable(lines){lines=asArray(lines);if(!lines.length)return '<div class=""sectionLabel"">Executed lines</div><div class=""meta"">No executed line information available.</div>';return '<div class=""sectionLabel"">Executed lines</div><div class=""miniTable""><table><thead><tr><th class=""num"">Line</th><th class=""num"">Calls</th><th class=""num"">Time</th><th class=""num"">Time/call</th></tr></thead><tbody>'+lines.slice().sort((a,b)=>(Number(b.Time)||0)-(Number(a.Time)||0)).map(l=>'<tr><td class=""num"">'+l.Line+'</td><td class=""num"">'+fmtInt(l.Calls)+'</td><td class=""num"">'+fmt(l.Time)+'</td><td class=""num"">'+fmt(l.TimePerCall)+'</td></tr>').join('')+'</tbody></table></div>'}function extraTable(extra){const keys=extra?Object.keys(extra):[];if(!keys.length)return '';return '<div class=""sectionLabel"">Extra profiler fields</div><div class=""miniTable""><table><tbody>'+keys.map(k=>'<tr><td>'+esc(k)+'</td><td class=""source"">'+esc(typeof extra[k]==='object'?JSON.stringify(extra[k]):extra[k])+'</td></tr>').join('')+'</tbody></table></div>'}"
        "function renderDetail(r){if(!r){byId('detail').innerHTML='<div class=""meta"">No function selected.</div>';return}byId('detail').innerHTML='<div class=""detailTitle"">'+esc(r.FunctionName)+'</div><div class=""path"">'+esc(r.CompleteName||'')+'<br>'+esc(r.FileName||'')+'</div><div class=""kv""><div>Index</div><div>'+r.Index+'</div><div>Source</div><div>'+sourceBadge(r.SourceTag)+'</div><div>Tags</div><div>'+esc(r.Tags||'')+'</div><div>Type</div><div>'+esc(r.Type||'')+'</div><div>Location</div><div>'+(r.IsMatlabInternal?'MATLAB internal/toolbox':'user or external path')+'</div><div>Calls</div><div>'+fmtInt(r.NumCalls)+'</div><div>Self time</div><div>'+fmt(r.SelfTime)+' s</div><div>Total time</div><div>'+fmt(r.TotalTime)+' s</div><div>Executed lines</div><div>'+fmtInt(r.ExecutedLineCount||0)+'</div></div>'+extraTable(r.Extra)+edgeTable(r.Parents,'Parents')+edgeTable(r.Children,'Children')+lineTable(r.ExecutedLines)}"
        "function flameRoots(){const mode=byId('flameMode').value;const rootN=Math.max(1,Number(byId('flameRootN').value)||80);const rows=sourceRows(byId('flameSource').value);flameVisible=new Set(rows.map(r=>Number(r.Index)));if(mode==='top')return rows.slice().sort((a,b)=>(Number(b.TotalTime)||0)-(Number(a.TotalTime)||0)).slice(0,rootN);const childSet=new Set();rows.forEach(r=>asArray(r.Children).forEach(c=>{if(flameVisible.has(Number(c.Index)))childSet.add(Number(c.Index))}));let roots=rows.filter(r=>!childSet.has(Number(r.Index)));if(!roots.length)roots=rows.slice().sort((a,b)=>(Number(b.TotalTime)||0)-(Number(a.TotalTime)||0));return roots.sort((a,b)=>(Number(b.TotalTime)||0)-(Number(a.TotalTime)||0)).slice(0,rootN)}function addFlame(rows,node,x,w,depth,maxDepth,minWidth,seen){if(!node||w<minWidth||depth>=maxDepth)return;if(!rows[depth])rows[depth]=[];rows[depth].push({x,w,idx:Number(node.Index),name:node.FunctionName||'',total:Number(node.TotalTime)||0,self:Number(node.SelfTime)||0,calls:Number(node.NumCalls)||0,internal:!!node.IsMatlabInternal});if(seen.has(Number(node.Index)))return;seen.add(Number(node.Index));let kids=asArray(node.Children).map(e=>({edge:e,node:INDEX.get(Number(e.Index))})).filter(k=>k.node&&flameVisible.has(Number(k.node.Index))).sort((a,b)=>(Number(b.edge.TotalTime)||0)-(Number(a.edge.TotalTime)||0)).slice(0,80);const denom=Math.max(Number(node.TotalTime)||0,kids.reduce((s,k)=>s+(Number(k.edge.TotalTime)||0),0),1e-12);let cx=x;kids.forEach(k=>{const ew=Number(k.edge.TotalTime)||Number(k.node.TotalTime)||0;const cw=w*ew/denom;if(cw>=minWidth)addFlame(rows,k.node,cx,cw,depth+1,maxDepth,minWidth,new Set(seen));cx+=cw})}"
        "function renderFlame(){const wrap=byId('flame');const maxDepth=Math.max(2,Number(byId('flameDepth').value)||18);const minWidth=Math.max(0,Number(byId('flameMinWidth').value)||0.15);const roots=flameRoots();const total=roots.reduce((s,r)=>s+(Number(r.TotalTime)||0),0)||1;let rows=[];let x=0;roots.forEach(r=>{const w=100*(Number(r.TotalTime)||0)/total;if(w>=minWidth)addFlame(rows,r,x,w,0,maxDepth,minWidth,new Set());x+=w});const contentWidth=Math.max(1000,wrap.clientWidth-20);wrap.innerHTML=rows.filter(Boolean).slice().reverse().map(row=>'<div class=""flameRow"" style=""width:'+contentWidth+'px"">'+row.map(f=>{const left=f.x*contentWidth/100;const width=Math.max(2,f.w*contentWidth/100);return '<div class=""flameFrame '+(f.internal?'internal':'')+(selectedIndex===f.idx?' selected':'')+'"" data-idx=""'+f.idx+'"" onclick=""selectFunction('+f.idx+')"" title=""'+esc(f.name)+' | total '+fmt(f.total)+' s | self '+fmt(f.self)+' s | calls '+fmtInt(f.calls)+'"" style=""left:'+left+'px;width:'+width+'px"">'+esc(f.name)+'</div>'}).join('')+'</div>').join('')||'<div class=""meta"">No flame frames available.</div>';wrap.scrollTop=wrap.scrollHeight}function highlightFlame(){document.querySelectorAll('.flameFrame').forEach(el=>el.classList.toggle('selected',Number(el.dataset.idx)===selectedIndex))}"
        "function selectFirstVisible(){const rows=getFiltered();if(rows.length){selectFunction(rows[0].Index)}else{selectedIndex=null;renderDetail(null);renderTable();highlightFlame()}}byId('searchBox').addEventListener('input',()=>renderTable());byId('sourceFilter').addEventListener('change',()=>selectFirstVisible());byId('hideInternal').addEventListener('change',()=>selectFirstVisible());byId('flameSource').addEventListener('change',()=>renderFlame());initMeta();renderTable();renderFlame();selectFirstVisible();"
        ];
    script = strjoin(lines, newline);
    script = strrep(script, '__SORT_BY__', char(sortBy));
end

function jsonFile = sidecarPath(htmlFile, opt)
    [folderName, baseName] = fileparts(htmlFile);
    jsonFile = char(string(opt.JsonFile));
    if isempty(jsonFile)
        jsonFile = fullfile(folderName, [baseName '.json']);
    end
end

function text = formatNumber(value)
    text = string(sprintf('%.6f', double(value)));
end

function text = htmlEscape(text)
    text = char(string(text));
    text = strrep(text, '&', '&amp;');
    text = strrep(text, '<', '&lt;');
end

function writeUtf8(fileName, text)
    [folderName, ~, ~] = fileparts(fileName);
    if strlength(string(folderName)) > 0 && exist(folderName, 'dir') ~= 7
        mkdir(folderName);
    end
    fid = fopen(fileName, 'w', 'n', 'UTF-8');
    if fid < 0
        error('profileLabKitWriteReport:WriteFailed', ...
            'Unable to open output file: %s', fileName);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', text);
    clear cleanup;
end
