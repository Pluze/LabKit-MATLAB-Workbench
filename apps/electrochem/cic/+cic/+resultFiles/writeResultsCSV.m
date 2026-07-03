% Expected caller: CIC app runner and export tests. Inputs are item structs,
% output filepath, and display unit label. Side effect is writing the stable CIC
% CSV file.

function [ok, msg] = writeResultsCSV(items, filepath, unitLabel)
%WRITERESULTSCSV Write CIC results in legacy CSV format.

    if nargin < 3
        unitLabel = 'mC/cm^2';
    end

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
        T = buildResultsTable(items, unitLabel);
        names = T.Properties.VariableNames;
        fprintf(fid, 'File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,%s,%s,%s,Safe,Detection\n', ...
            names{8}, names{9}, names{10});
        for i = 1:height(T)
            if strcmp(T.Detection{i}, 'failed')
                fprintf(fid, '"%s",,,,,,,,,,0,"failed"\n', T.File{i});
            else
                fprintf(fid, '"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%d,"%s"\n', ...
                    T.File{i}, T.Amp_A(i), T.Emc_V(i), T.Ema_V(i), T.Qc_C(i), T.Qa_C(i), T.Qt_C(i), ...
                    T.(names{8})(i), T.(names{9})(i), T.(names{10})(i), T.Safe(i), T.Detection{i});
            end
        end
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end

function T = buildResultsTable(items, unitLabel)
%BUILDRESULTSTABLE Build legacy CIC CSV result table.

    if nargin < 2
        unitLabel = 'mC/cm^2';
    end
    [scale, unitSuffix] = displayScaleSuffix(unitLabel);

    file = cell(numel(items), 1);
    amp_A = NaN(numel(items), 1);
    Emc_V = NaN(numel(items), 1);
    Ema_V = NaN(numel(items), 1);
    Qc_C = NaN(numel(items), 1);
    Qa_C = NaN(numel(items), 1);
    Qt_C = NaN(numel(items), 1);
    CICc = NaN(numel(items), 1);
    CICa = NaN(numel(items), 1);
    CICt = NaN(numel(items), 1);
    safe = zeros(numel(items), 1);
    detection = cell(numel(items), 1);

    for i = 1:numel(items)
        item = items(i);
        file{i} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            detection{i} = 'failed';
            continue;
        end

        amp_A(i) = A.ampEstimate_A;
        Emc_V(i) = A.Emc;
        Ema_V(i) = A.Ema;
        Qc_C(i) = A.Qc_C;
        Qa_C(i) = A.Qa_C;
        Qt_C(i) = A.Qt_C;
        CICc(i) = scale * A.CICc_mCcm2;
        CICa(i) = scale * A.CICa_mCcm2;
        CICt(i) = scale * A.CICt_mCcm2;
        safe(i) = A.safe;
        detection{i} = A.detectMode;
    end

    T = table(file, amp_A, Emc_V, Ema_V, Qc_C, Qa_C, Qt_C, CICc, CICa, CICt, safe, detection, ...
        'VariableNames', {'File', 'Amp_A', 'Emc_V', 'Ema_V', 'Qc_C', 'Qa_C', 'Qt_C', ...
        ['CICc_' unitSuffix], ['CICa_' unitSuffix], ['CICt_' unitSuffix], 'Safe', 'Detection'});
end

function [scale, unitSuffix] = displayScaleSuffix(unitLabel)
    [scale, unitLabel] = displayScale(unitLabel);
    unitSuffix = regexprep(unitLabel, '[\^/]', '');
end

function [scale, unitLabel] = displayScale(unitLabel)
    switch unitLabel
        case 'uC/cm^2'
            scale = 1e3;
        otherwise
            scale = 1;
            unitLabel = 'mC/cm^2';
    end
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
