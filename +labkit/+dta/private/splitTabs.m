function tok = splitTabs(line)
%SPLITTABS Split a Gamry DTA line on one or more tab characters.
%
% Inputs:
%   line - char/string scalar from a raw DTA text file.
%
% Output:
%   tok - cell array of non-empty tokens.
%
% Notes:
%   Empty tokens are discarded to match the existing permissive parser
%   behavior used by chrono, EIS, and CV/CT parsers.

    tok = regexp(char(line), '\t+', 'split');
    tok = tok(~cellfun(@isempty, tok));
end
