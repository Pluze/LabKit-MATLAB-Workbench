function spec = resultTable(id, titleText, varargin)
%RESULTTABLE Create a titled result table spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.resultTable(id, title, "columns", columns, ...)
%
% Inputs:
%   id - globally unique result table id.
%   titleText - table panel title.
%   columns - cell array of column names, default {}.
%   data - initial table data, default empty cell array.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('resultTable', id, props, {}, struct());
end
