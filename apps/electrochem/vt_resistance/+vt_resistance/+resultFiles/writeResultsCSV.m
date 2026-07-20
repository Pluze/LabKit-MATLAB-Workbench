% Expected caller: VT resistance export callback and tests. Inputs are item
% structs and output filepath. Side effect is writing the stable VT CSV file.

function [ok, msg] = writeResultsCSV(items, filepath)
%WRITERESULTSCSV Write VT resistance results in legacy CSV format.

    ok = true;
    msg = '';

    fid = fopen(filepath, 'w');
    if fid < 0
        ok = false;
        msg = 'Could not open file for writing.';
        if nargout == 0
            error(msg);
        end
        return;
    end
    cleaner = onCleanup(@() fclose(fid));

    try
        T = buildResultsTable(items);
        fprintf(fid, 'File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status\n');
        for i = 1:height(T)
            fprintf(fid, '"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,"%s","%s","%s"\n', ...
                csvEscape(T.File{i}), ...
                T.Ic_A(i), T.Ia_A(i), T.Vc_ss_V(i), T.Va_ss_V(i), ...
                T.Vc_baseline_V(i), T.Va_baseline_V(i), T.dVc_V(i), T.dVa_V(i), ...
                T.Rc_bc_ohm(i), T.Ra_bc_ohm(i), T.Ravg_bc_ohm(i), ...
                csvEscape(T.WindowMode{i}), ...
                csvEscape(T.Detection{i}), ...
                csvEscape(T.Status{i}));
        end
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end

function T = buildResultsTable(items)
%BUILDRESULTSTABLE Build VT resistance CSV result table.

    file = cell(numel(items), 1);
    Ic_A = NaN(numel(items), 1);
    Ia_A = NaN(numel(items), 1);
    Vc_ss_V = NaN(numel(items), 1);
    Va_ss_V = NaN(numel(items), 1);
    Vc_baseline_V = NaN(numel(items), 1);
    Va_baseline_V = NaN(numel(items), 1);
    dVc_V = NaN(numel(items), 1);
    dVa_V = NaN(numel(items), 1);
    Rc_bc_ohm = NaN(numel(items), 1);
    Ra_bc_ohm = NaN(numel(items), 1);
    Ravg_bc_ohm = NaN(numel(items), 1);
    windowMode = cell(numel(items), 1);
    detection = cell(numel(items), 1);
    status = cell(numel(items), 1);

    for i = 1:numel(items)
        item = items(i);
        file{i} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            windowMode{i} = '';
            detection{i} = 'failed';
            status{i} = analysisMessage(A);
            continue;
        end

        Ic_A(i) = A.Ic_est_A;
        Ia_A(i) = A.Ia_est_A;
        Vc_ss_V(i) = A.Vc_ss_V;
        Va_ss_V(i) = A.Va_ss_V;
        Vc_baseline_V(i) = A.Vc_baseline_V;
        Va_baseline_V(i) = A.Va_baseline_V;
        dVc_V(i) = A.dVc_V;
        dVa_V(i) = A.dVa_V;
        Rc_bc_ohm(i) = abs(A.Rc_dV_ohm);
        Ra_bc_ohm(i) = abs(A.Ra_dV_ohm);
        Ravg_bc_ohm(i) = mean([Rc_bc_ohm(i), Ra_bc_ohm(i)], 'omitnan');
        windowMode{i} = A.windowMode;
        detection{i} = A.detectMode;
        status{i} = A.message;
    end

    T = table(file, Ic_A, Ia_A, Vc_ss_V, Va_ss_V, Vc_baseline_V, Va_baseline_V, ...
        dVc_V, dVa_V, Rc_bc_ohm, Ra_bc_ohm, Ravg_bc_ohm, windowMode, detection, status, ...
        'VariableNames', {'File', 'Ic_A', 'Ia_A', 'Vc_ss_V', 'Va_ss_V', ...
        'Vc_baseline_V', 'Va_baseline_V', 'dVc_V', 'dVa_V', 'Rc_bc_ohm', ...
        'Ra_bc_ohm', 'Ravg_bc_ohm', 'WindowMode', 'Detection', 'Status'});
end

function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
    else
        name = '';
    end
end

function A = itemAnalysis(item)
    if isfield(item, 'analysis')
        A = item.analysis;
    else
        A = [];
    end
end

function msg = analysisMessage(A)
    msg = '';
    if ~isempty(A) && isfield(A, 'message')
        msg = A.message;
    end
end

function s = csvEscape(x)
    s = strrep(char(x), '"', '""');
end
