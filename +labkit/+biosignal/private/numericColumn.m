% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function [values, ok] = numericColumn(raw)
%NUMERICCOLUMN Convert a parsed table column to numeric values when possible.
%
% Expected caller:
%   readCsvRecording and private CSV time-inference helpers.
%
% Inputs/outputs:
%   Raw table column data. Returns a numeric column vector and a boolean that
%   is true when at least half of the entries parse as finite numeric values,
%   with a minimum of two finite values.
%
% Side effects:
%   None.

    ok = false;
    values = [];
    if isnumeric(raw) || islogical(raw)
        values = double(raw(:));
        finiteCount = nnz(isfinite(values));
        ok = finiteCount >= max(2, ceil(0.5 * numel(values)));
        return;
    end

    if iscell(raw) || iscategorical(raw) || isstring(raw) || ischar(raw)
        try
            tokens = string(raw);
        catch
            return;
        end
        tokens = strip(tokens(:));
        tokens = erase(tokens, '"');
        values = nan(size(tokens));
        for k = 1:numel(tokens)
            token = tokens(k);
            if ismissing(token) || strlength(token) == 0
                values(k) = NaN;
            else
                values(k) = str2double(token);
            end
        end
        finiteCount = nnz(isfinite(values));
        ok = finiteCount >= max(2, ceil(0.5 * numel(values)));
    end
end
