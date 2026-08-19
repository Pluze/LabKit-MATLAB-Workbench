function htmlFile = writeCodecheckReport(jsonFile, compatibilityJsonFile, htmlFile)
%WRITECODECHECKREPORT Write one HTML view for both code-analysis JSON files.
%
% Expected caller: tools/codecheck/runCodecheckReport.m. Inputs are the MATLAB
% codeIssues JSON, serialized CodeCompatibilityAnalysis JSON, and output HTML
% path. Output is the written HTML file path. Side effects are limited to
% writing that HTML file.

    jsonText = string(fileread(jsonFile));
    compatibilityJsonText = string(fileread(compatibilityJsonFile));
    payload = jsondecode(char(jsonText));
    compatibility = jsondecode(char(compatibilityJsonText));
    summary = summarizePayload(payload, compatibility);
    sources = collectSources(payload, compatibility);
    html = buildHtml(jsonText, compatibilityJsonText, summary, sources);
    writeUtf8(htmlFile, html);
end

function summary = summarizePayload(payload, compatibility)
    issues = fieldArray(payload, "Issues");
    suppressed = fieldArray(payload, "SuppressedIssues");
    files = strings(0, 1);
    if isfield(payload, "Files")
        files = string(payload.Files(:));
    end
    summary = struct();
    summary.date = stringField(payload, "Date");
    summary.release = stringField(payload, "Release");
    summary.fileCount = numel(files);
    summary.issueCount = numel(issues);
    summary.suppressedIssueCount = numel(suppressed);
    summary.errorCount = countSeverity(issues, "error");
    summary.warningCount = countSeverity(issues, "warning");
    summary.infoCount = countSeverity(issues, "info");
    summary.compatibilityCheckCount = ...
        numel(fieldArray(compatibility, "ChecksPerformed"));
    summary.compatibilityRecommendationCount = ...
        numel(fieldArray(compatibility, "Recommendations"));
end

function n = countSeverity(issues, severity)
    n = 0;
    for k = 1:numel(issues)
        if isfield(issues(k), "Severity") && strcmpi(string(issues(k).Severity), severity)
            n = n + 1;
        end
    end
end

function values = fieldArray(payload, name)
    values = struct([]);
    if isstruct(payload) && isfield(payload, name) && ~isempty(payload.(name))
        values = payload.(name);
    end
end

function value = stringField(payload, name)
    value = "";
    if isstruct(payload) && isfield(payload, name) && ~isempty(payload.(name))
        value = string(payload.(name));
    end
end

function sources = collectSources(payload, compatibility)
    paths = strings(0, 1);
    paths = [paths; sourcePaths(fieldArray(payload, "Issues"))];
    paths = [paths; sourcePaths(fieldArray(payload, "SuppressedIssues"))];
    paths = [paths; compatibilitySourcePaths( ...
        fieldArray(compatibility, "Recommendations"))];
    paths = unique(paths, "stable");
    sources = repmat(struct("path", "", "lines", {{}}), numel(paths), 1);
    for k = 1:numel(paths)
        filepath = char(paths(k));
        if exist(filepath, "file") ~= 2
            lines = {sprintf("Source file is not available: %s", filepath)};
        else
            lines = cellstr(splitlines(sanitizeSourceText(string(fileread(filepath)))));
        end
        sources(k, 1) = struct("path", filepath, "lines", {lines});
    end
end

function paths = compatibilitySourcePaths(recommendations)
    paths = strings(numel(recommendations), 1);
    pathCount = 0;
    for k = 1:numel(recommendations)
        if isfield(recommendations(k), "File") && ...
                ~isempty(recommendations(k).File)
            pathCount = pathCount + 1;
            paths(pathCount, 1) = string(recommendations(k).File);
        end
    end
    paths = paths(1:pathCount);
end

function text = sanitizeSourceText(text)
    chars = char(text);
    codes = double(chars);
    replace = codes < 32 & ~ismember(codes, [9 10 13]);
    chars(replace) = ' ';
    text = string(chars);
end

function paths = sourcePaths(issues)
    paths = strings(numel(issues), 1);
    pathCount = 0;
    for k = 1:numel(issues)
        if isfield(issues(k), "FullFilename") && ~isempty(issues(k).FullFilename)
            pathCount = pathCount + 1;
            paths(pathCount, 1) = string(issues(k).FullFilename);
        end
    end
    paths = paths(1:pathCount);
end

function html = buildHtml(jsonText, compatibilityJsonText, summary, sources)
    jsonText = sanitizeEmbeddedJson(jsonText);
    compatibilityJsonText = sanitizeEmbeddedJson(compatibilityJsonText);
    summaryJson = sanitizeEmbeddedJson(string(jsonencode(summary)));
    sourcesJson = sanitizeEmbeddedJson(string(jsonencode(sources)));
    parts = [
        "<!doctype html><html><head><meta charset=""utf-8""><title>LabKit Code Analysis Report</title>"
        "<style>"
        ":root{color-scheme:light;--bg:#f5f7fb;--panel:#fff;--line:#dbe3ef;--text:#111827;--muted:#64748b;--error:#b91c1c;--warn:#b45309;--info:#2563eb}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font-family:system-ui,Segoe UI,Arial,sans-serif}.wrap{max-width:1760px;margin:0 auto;padding:20px;min-height:100vh}.hero,.panel,.card{background:var(--panel);border:1px solid var(--line);border-radius:8px;box-shadow:0 1px 2px rgba(15,23,42,.04)}.hero{padding:18px;margin-bottom:14px}h1{margin:0 0 6px;font-size:24px}h2{margin:0 0 10px;font-size:17px}.meta,.footer{color:var(--muted);font-size:12px;line-height:1.45}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:10px;margin-bottom:14px}.card{padding:12px}.label{font-size:12px;color:var(--muted)}.value{font-size:24px;font-weight:760}.layout{display:grid;grid-template-columns:minmax(760px,1.2fr) minmax(470px,.8fr);gap:14px;align-items:start}.panel{padding:14px;min-width:0;margin:0}.issuePanel{display:flex;flex-direction:column;min-height:900px}.sourcePanel{display:flex;flex-direction:column;min-height:0}.rightStack{display:flex;flex-direction:column;gap:14px;min-height:0}.controls{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin-bottom:10px;font-size:12px;flex:0 0 auto}input,select,button{font:inherit}input[type=search]{min-width:280px}.tableWrap{overflow:auto;border:1px solid #e5e7eb;border-radius:8px;flex:1 1 auto;min-height:0}table{width:100%;border-collapse:collapse;font-size:12px;table-layout:fixed}th,td{padding:7px 8px;border-bottom:1px solid #edf0f4;text-align:left;vertical-align:top;overflow:hidden;text-overflow:ellipsis}th{position:sticky;top:0;background:#f8fafc;z-index:1;cursor:pointer;white-space:nowrap}.num{text-align:right;font-variant-numeric:tabular-nums}.issueFile,.detailPath{overflow-wrap:anywhere}.badge{display:inline-block;max-width:100%;padding:2px 6px;border-radius:999px;font-size:11px;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;background:#e5e7eb;color:#374151}.sev-error{background:#fee2e2;color:var(--error)}.sev-warning{background:#fef3c7;color:var(--warn)}.sev-info{background:#dbeafe;color:var(--info)}.suppressed{background:#f1f5f9;color:#475569}.selected{background:#eff6ff}.desc{line-height:1.35}.sideList{overflow:auto;border:1px solid #e5e7eb;border-radius:8px;min-height:120px;max-height:240px}.sideItem{display:grid;grid-template-columns:1fr auto;gap:8px;padding:7px 8px;border-bottom:1px solid #edf0f4;font-size:12px;cursor:pointer}.sideItem:last-child{border-bottom:0}.sideItem:hover,.sideItem.active{background:#eff6ff}.detailTitle{font-weight:760;font-size:14px;line-height:1.35;overflow-wrap:anywhere}.kv{display:grid;grid-template-columns:96px minmax(0,1fr);gap:5px 10px;font-size:13px;margin:10px 0}.sourceBox{height:460px;overflow:auto;background:#0f172a;color:#dbeafe;border-radius:8px;padding:8px;font-family:ui-monospace,Consolas,monospace;font-size:12px;line-height:1.45}.sourceLine{display:grid;grid-template-columns:54px minmax(0,1fr);gap:10px}.sourceLine mark{display:block;background:#fef08a;color:#111827;padding:0 2px}.sourceNo{color:#93a4b8;text-align:right;user-select:none}.sourceCode{white-space:pre;overflow-wrap:normal}.empty{color:var(--muted);padding:14px;text-align:center}.footer{margin-top:10px}@media(max-width:1180px){.cards,.layout{grid-template-columns:1fr}.issuePanel{min-height:560px}.sourceBox{height:560px}table{min-width:980px}}"
        "</style></head><body><div class=""wrap"">"
        "<div class=""hero""><h1>LabKit Code Analysis Report</h1><div class=""meta""><div><b>Generated:</b> <span id=""generatedAt""></span> &nbsp; <b>MATLAB:</b> <span id=""matlabRelease""></span></div><div>Search and inspect MATLAB Code Analyzer issues and Code Compatibility Analyzer recommendations together.</div></div></div>"
        "<div class=""cards""><div class=""card""><div class=""label"">Analyzer Errors</div><div class=""value"" id=""errorCount""></div></div><div class=""card""><div class=""label"">Analyzer Warnings</div><div class=""value"" id=""warningCount""></div></div><div class=""card""><div class=""label"">Analyzer Info</div><div class=""value"" id=""infoCount""></div></div><div class=""card""><div class=""label"">Analyzer Issues</div><div class=""value"" id=""issueCount""></div></div><div class=""card""><div class=""label"">Analyzer Suppressed</div><div class=""value"" id=""suppressedCount""></div></div><div class=""card""><div class=""label"">Compatibility Recommendations</div><div class=""value"" id=""compatibilityRecommendationCount""></div></div><div class=""card""><div class=""label"">Compatibility Checks</div><div class=""value"" id=""compatibilityCheckCount""></div></div><div class=""card""><div class=""label"">Scanned Files</div><div class=""value"" id=""fileCount""></div></div></div>"
        "<div class=""layout""><div class=""panel issuePanel""><h2>Findings</h2><div class=""controls""><input id=""search"" type=""search"" placeholder=""Search description, file, CheckID, severity...""><label>Analysis <select id=""analysisSet""><option value=""all"">All</option><option value=""analyzer"">Code Analyzer</option><option value=""compatibility"">Compatibility</option></select></label><label>Set <select id=""issueSet""><option value=""active"">Active</option><option value=""suppressed"">Suppressed</option><option value=""all"">All</option></select></label><label>Severity <select id=""severity""><option value=""all"">All</option><option value=""error"">Error</option><option value=""warning"">Warning</option><option value=""info"">Info</option></select></label><label>CheckID <select id=""checkid""><option value=""all"">All</option></select></label><label>Rows <input id=""limit"" type=""number"" min=""20"" max=""5000"" value=""500"" style=""width:76px""></label><button id=""reset"">Reset</button></div><div class=""tableWrap""><table id=""issuesTable""><thead><tr><th style=""width:54px"" data-sort=""row"">#</th><th style=""width:110px"" data-sort=""analysis"">Analysis</th><th style=""width:88px"" data-sort=""set"">Set</th><th style=""width:94px"" data-sort=""severity"">Severity</th><th style=""width:94px"" data-sort=""checkid"">CheckID</th><th data-sort=""file"">File</th><th style=""width:70px"" data-sort=""line"">Line</th><th data-sort=""description"">Description</th></tr></thead><tbody></tbody></table></div></div>"
        "<div class=""rightStack""><div class=""panel sourcePanel""><h2>Source</h2><div id=""sourceView"" class=""sourceBox""></div></div><div class=""panel""><h2>Selected Issue</h2><div id=""detail"" class=""meta"">Click an issue row to inspect its full path, location, and source.</div></div><div class=""panel""><h2>Files</h2><div id=""fileList"" class=""sideList""></div></div><div class=""panel""><h2>CheckID Summary</h2><div id=""checkList"" class=""sideList""></div></div></div></div>"
        "<div class=""footer"">Generated by tools/codecheck/runCodecheckReport.m.</div></div>"
        "<script id=""summary-json"" type=""application/json"">" + summaryJson + "</script><script id=""source-json"" type=""application/json"">" + sourcesJson + "</script><script id=""codeissues-json"" type=""application/json"">" + jsonText + "</script><script id=""compatibility-json"" type=""application/json"">" + compatibilityJsonText + "</script><script>" + clientScript() + "</script></body></html>"
        ];
    html = strjoin(parts, newline);
end

function text = sanitizeEmbeddedJson(text)
    text = strrep(string(text), "</", "<\/");
    chars = char(text);
    codes = double(chars);
    chars(codes < 32) = ' ';
    text = string(chars);
end

function script = clientScript()
    lines = [
        "const payload=JSON.parse(document.getElementById('codeissues-json').textContent);const compatibility=JSON.parse(document.getElementById('compatibility-json').textContent);const summary=JSON.parse(document.getElementById('summary-json').textContent);const sourceRows=asArray(JSON.parse(document.getElementById('source-json').textContent));const sourceMap=new Map(sourceRows.map(s=>[text(s.path),asArray(s.lines).map(text)]));const rawIssues=asArray(payload.Issues).map((x,i)=>normIssue(x,i,false));const rawSuppressed=asArray(payload.SuppressedIssues).map((x,i)=>normIssue(x,i,true));const rawCompatibility=asArray(compatibility.Recommendations).map((x,i)=>normCompatibility(x,i));const allFindings=rawIssues.concat(rawSuppressed,rawCompatibility);let sortKey='severity',sortDir=1,selected=null;"
        "function asArray(v){if(!v)return[];return Array.isArray(v)?v:[v]}function text(v){return v===undefined||v===null?'':String(v)}function basename(p){p=text(p).replace(/\\/g,'/');return p.split('/').filter(Boolean).pop()||p}function firstNumber(v){v=asArray(v);return Number(v.length?v[0]:0)}function normIssue(x,i,suppressed){return{row:i+1,analysis:'analyzer',analysisLabel:'Code Analyzer',suppressed,severity:text(x.Severity).toLowerCase(),checkid:text(x.CheckID),file:basename(x.FullFilename||x.Location),path:text(x.FullFilename||x.Location),line:Number(x.LineStart||0),endLine:Number(x.LineEnd||x.LineStart||0),column:Number(x.ColumnStart||0),description:text(x.Description),guidance:text(x.Fixability),suppression:suppressed?'suppressed':'none'}}function normCompatibility(x,i){const suppression=text(x.Suppression).toLowerCase();const path=text(x.File);return{row:i+1,analysis:'compatibility',analysisLabel:'Compatibility',suppressed:!!suppression&&suppression!=='none',severity:text(x.Severity).toLowerCase(),checkid:text(x.Identifier),file:basename(path),path,line:Number(x.LineNumber||0),endLine:Number(x.LineNumber||0),column:firstNumber(x.ColumnRange),description:text(x.Description),guidance:text(x.Documentation),suppression:suppression||'none'}}function sevRank(s){return s==='error'?0:s==='warning'?1:s==='info'?2:3}"
        "function setText(id,v){document.getElementById(id).textContent=v}function init(){setText('generatedAt',summary.date||payload.Date||compatibility.Date||'');setText('matlabRelease',summary.release||payload.Release||compatibility.MATLABVersion||'');setText('errorCount',summary.errorCount||0);setText('warningCount',summary.warningCount||0);setText('infoCount',summary.infoCount||0);setText('issueCount',summary.issueCount||0);setText('suppressedCount',summary.suppressedIssueCount||0);setText('compatibilityRecommendationCount',summary.compatibilityRecommendationCount||0);setText('compatibilityCheckCount',summary.compatibilityCheckCount||0);setText('fileCount',summary.fileCount||asArray(payload.Files).length);populateCheckIds();bind();renderAll();selectInitialIssue()}"
        "function populateCheckIds(){const ids=[...new Set(allFindings.map(x=>x.checkid).filter(Boolean))].sort();const sel=document.getElementById('checkid');ids.forEach(id=>{const o=document.createElement('option');o.value=id;o.textContent=id;sel.appendChild(o)})}function bind(){['search','analysisSet','issueSet','severity','checkid','limit'].forEach(id=>document.getElementById(id).addEventListener('input',renderAll));document.getElementById('reset').onclick=()=>{search.value='';analysisSet.value='all';issueSet.value='active';severity.value='all';checkid.value='all';limit.value=500;renderAll()};document.querySelectorAll('th[data-sort]').forEach(th=>th.onclick=()=>{const k=th.dataset.sort;if(sortKey===k)sortDir*=-1;else{sortKey=k;sortDir=1}renderTable(filtered())})}"
        "function filtered(){const q=search.value.trim().toLowerCase();const analysis=analysisSet.value;const set=issueSet.value;const sev=severity.value;const cid=checkid.value;return allFindings.filter(r=>(analysis==='all'||r.analysis===analysis)&&(set==='all'||(set==='suppressed')===r.suppressed)&&(sev==='all'||r.severity===sev)&&(cid==='all'||r.checkid===cid)&&(!q||[r.analysisLabel,r.suppressed?'suppressed':'active',r.severity,r.checkid,r.file,r.path,r.description,r.guidance,r.suppression].join(' ').toLowerCase().includes(q)))}function cmp(a,b){let av=sortKey==='set'?(a.suppressed?1:0):a[sortKey],bv=sortKey==='set'?(b.suppressed?1:0):b[sortKey];if(sortKey==='severity'){av=sevRank(a.severity);bv=sevRank(b.severity)}if(sortKey==='line'||sortKey==='row'||sortKey==='set'){av=Number(av);bv=Number(bv)}return (av>bv?1:av<bv?-1:0)*sortDir}function sortedRows(rows){return rows.slice().sort(cmp)}"
        "function renderAll(){const rows=filtered();renderTable(rows);renderFiles(rows);renderChecks(rows)}function renderTable(rows){rows=sortedRows(rows);const max=Math.max(1,Number(limit.value)||500);const tb=document.querySelector('#issuesTable tbody');tb.innerHTML='';rows.slice(0,max).forEach(r=>{const tr=document.createElement('tr');if(selected&&selected.analysis===r.analysis&&selected.path===r.path&&selected.line===r.line&&selected.checkid===r.checkid&&selected.suppressed===r.suppressed)tr.className='selected';tr.onclick=()=>selectIssue(r);tr.innerHTML='<td class=num>'+r.row+'</td><td><span class=badge>'+esc(r.analysisLabel)+'</span></td><td><span class=""badge '+(r.suppressed?'suppressed':'')+'"">'+(r.suppressed?'suppressed':'active')+'</span></td><td><span class=""badge sev-'+escAttr(r.severity)+'"">'+esc(r.severity||'unknown')+'</span></td><td>'+esc(r.checkid)+'</td><td class=issueFile title=""'+escAttr(r.path)+'"">'+esc(r.file)+'</td><td class=num>'+esc(r.line||'')+'</td><td class=desc>'+esc(r.description)+'</td>';tb.appendChild(tr)});if(!tb.children.length){tb.innerHTML='<tr><td colspan=8 class=empty>No matching findings.</td></tr>'}}function selectIssue(r){selected=r;renderDetail(r);renderSource(r);renderTable(filtered())}function selectInitialIssue(){const rows=sortedRows(filtered());if(rows.length)selectIssue(rows[0]);else sourceView.innerHTML='<div class=empty>No source selected.</div>'}"
        "function countsBy(rows,key){const m=new Map();rows.forEach(r=>m.set(r[key]||'(blank)',(m.get(r[key]||'(blank)')||0)+1));return [...m.entries()].sort((a,b)=>b[1]-a[1]||String(a[0]).localeCompare(String(b[0])))}function renderFiles(rows){const box=document.getElementById('fileList');box.innerHTML='';const q=search.value.trim();countsBy(rows,'path').slice(0,200).forEach(([path,n])=>{const d=document.createElement('div');d.className='sideItem'+(q===path?' active':'');d.innerHTML='<span title=""'+escAttr(path)+'"">'+esc(basename(path))+'</span><b>'+n+'</b>';d.onclick=()=>{search.value=(search.value.trim()===path?'':path);renderAll()};box.appendChild(d)});if(!box.children.length)box.innerHTML='<div class=empty>No files.</div>'}function renderChecks(rows){const box=document.getElementById('checkList');box.innerHTML='';const current=checkid.value;countsBy(rows,'checkid').forEach(([id,n])=>{const d=document.createElement('div');d.className='sideItem'+(current===id?' active':'');d.innerHTML='<span>'+esc(id)+'</span><b>'+n+'</b>';d.onclick=()=>{checkid.value=(checkid.value===id?'all':id);renderAll()};box.appendChild(d)});if(!box.children.length)box.innerHTML='<div class=empty>No CheckID values.</div>'}"
        "function renderDetail(r){document.getElementById('detail').innerHTML='<div class=detailTitle>'+esc(r.description)+'</div><div class=kv><div>Analysis</div><div>'+esc(r.analysisLabel)+'</div><div>Set</div><div>'+esc(r.suppressed?'suppressed':'active')+'</div><div>Severity</div><div><span class=""badge sev-'+escAttr(r.severity)+'"">'+esc(r.severity)+'</span></div><div>CheckID</div><div>'+esc(r.checkid)+'</div><div>Guidance</div><div>'+esc(r.guidance)+'</div><div>Location</div><div>'+esc(r.line)+(r.endLine&&r.endLine!==r.line?'-'+esc(r.endLine):'')+', column '+esc(r.column)+'</div></div><div class=detailPath>'+esc(r.path)+'</div>'}function renderSource(r){const lines=sourceMap.get(r.path)||['Source file not embedded.'];let start=1,end=lines.length;const html=[];for(let i=start;i<=end;i++){let code=esc(lines[i-1]||'');const hit=i>=r.line&&i<=(r.endLine||r.line);if(hit)code='<mark>'+code+'</mark>';html.push('<div class=sourceLine id=""src-'+i+'""><span class=sourceNo>'+i+'</span><span class=sourceCode>'+code+'</span></div>')}sourceView.innerHTML=html.join('');const el=document.getElementById('src-'+r.line);const first=sourceView.querySelector('.sourceLine');if(el&&first){const target=el.offsetTop-first.offsetTop;sourceView.scrollTop=Math.max(0,target-sourceView.clientHeight*.42)}}function esc(s){return text(s).replace(/[&<>""']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','""':'&quot;',""'"":'&#39;'}[c]))}function escAttr(s){return esc(s).replace(/`/g,'&#96;')}init();"
        ];
    script = strjoin(lines, newline);
end

function writeUtf8(filepath, text)
    ensureFolder(fileparts(filepath));
    fid = fopen(filepath, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:Codecheck:WriteFailed", ...
            "Could not write Code Analyzer HTML report: %s", filepath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
    clear cleanup;
end

function ensureFolder(folder)
    if strlength(string(folder)) > 0 && exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end
