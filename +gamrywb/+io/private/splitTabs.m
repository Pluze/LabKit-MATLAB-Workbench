function tok = splitTabs(line)
%SPLITTABS Split a Gamry DTA line on one or more tab characters.

    tok = regexp(char(line), '\t+', 'split');
    tok = tok(~cellfun(@isempty, tok));
end
