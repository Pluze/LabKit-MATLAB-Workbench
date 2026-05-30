function summary = dta_only_script_template(inputPath, expectedKind)
%DTA_ONLY_SCRIPT_TEMPLATE Minimal non-GUI workflow using only the DTA surface.

    if nargin < 1 || isempty(inputPath)
        error('dta_only_script_template:MissingInput', ...
            'Provide a DTA file or folder path.');
    end
    if nargin < 2
        expectedKind = "auto";
    end

    if isfolder(inputPath)
        [items, report] = gamrywb.dta.loadFolder(inputPath, expectedKind);
    else
        [item, status] = gamrywb.dta.loadFile(inputPath, expectedKind);
        if status.ok
            items = {item};
            loaded = {status.filepath};
            failed = struct('filepath', {}, 'kind', {}, 'message', {});
        else
            items = {};
            loaded = {};
            failed = struct( ...
                'filepath', status.filepath, ...
                'kind', status.kind, ...
                'message', status.message);
        end
        report = struct( ...
            'folder', '', ...
            'nRequested', 1, ...
            'nLoaded', double(status.ok), ...
            'nFailed', double(~status.ok), ...
            'loaded', {loaded}, ...
            'failed', {failed}, ...
            'statuses', {status});
    end

    summary = summarizeItems(items, report);
end

function summary = summarizeItems(items, report)
    names = strings(numel(items), 1);
    kinds = strings(numel(items), 1);
    for i = 1:numel(items)
        names(i) = string(items{i}.name);
        kinds(i) = string(items{i}.type);
    end

    summary = struct();
    summary.nLoaded = report.nLoaded;
    summary.nFailed = report.nFailed;
    summary.names = names;
    summary.kinds = kinds;
    summary.report = report;
end
