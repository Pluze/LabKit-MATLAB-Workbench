% App workbook inspector; returns visible worksheet names without modifying the source.
function names = listWorkbookSheets(filepath)
%LISTWORKBOOKSHEETS List selectable sheets for one tabular source.
%
% Expected caller: T-Test Wizard source loading. filepath is a scalar CSV,
% TSV, XLSX, or XLS path. The output is a nonempty string column. Text tables
% expose one synthetic "Table" sheet; workbooks preserve their sheet names.
% The function reads workbook metadata but does not load cell values.

    filepath = string(filepath);
    assert(isscalar(filepath) && strlength(filepath) > 0 && isfile(filepath), ...
        'ttest_wizard:SourceNotFound', ...
        'The selected table file does not exist.');
    [~, ~, extension] = fileparts(filepath);
    extension = lower(string(extension));
    if ismember(extension, [".csv", ".tsv"])
        names = "Table";
        return;
    end
    assert(ismember(extension, [".xlsx", ".xls"]), ...
        'ttest_wizard:UnsupportedSource', ...
        'Choose a CSV, TSV, XLSX, or XLS table.');
    names = string(sheetnames(filepath));
    names = names(:);
    names = names(strlength(names) > 0);
    assert(~isempty(names), 'ttest_wizard:EmptyWorkbook', ...
        'The selected workbook does not contain a readable worksheet.');
end
