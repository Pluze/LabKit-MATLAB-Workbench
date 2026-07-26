function calls = runtimeFactoryCalls(source)
%RUNTIMEFACTORYCALLS Parse executable RuntimeFactory calls from MATLAB source.
% Expected caller: repository test guardrails. Strings and comments are masked
% before matching, while balanced delimiters preserve complete multi-line calls.

source = char(join(string(source), newline));
masked = maskNonCode(source);
pattern = "RuntimeFactory\.(createHeadless|createMatlab)\s*\(";
[starts, ends, tokens] = regexp(masked, pattern, "start", "end", "tokens");
calls = repmat(struct("Method", "", "Line", 0, ...
    "Arguments", strings(1, 0), "JournalRoot", ""), 1, numel(starts));
for index = 1:numel(starts)
    opening = ends(index);
    closing = closingDelimiter(masked, opening);
    if closing == 0
        error("LabKit:TestJournal:UnbalancedCall", ...
            "RuntimeFactory call at source character %d is unbalanced.", starts(index));
    end
    arguments = splitArguments( ...
        source(opening + 1:closing - 1), masked(opening + 1:closing - 1));
    calls(index) = struct( ...
        "Method", string(tokens{index}{1}), ...
        "Line", numel(regexp(source(1:starts(index)), newline)) + 1, ...
        "Arguments", arguments, ...
        "JournalRoot", journalRootArgument(arguments));
end
end

function value = journalRootArgument(arguments)
value = "";
if numel(arguments) == 6
    expression = strtrim(arguments(6));
    equals = find(char(expression) == "=", 1);
    if ~isempty(equals) && normalizedName(extractBefore(expression, equals)) == ...
            "journalroot"
        value = nonemptyExpression(extractAfter(expression, equals));
    end
    return;
end
if numel(arguments) ~= 7 || normalizedName(arguments(6)) ~= "journalroot"
    return;
end
value = nonemptyExpression(arguments(7));
end

function value = normalizedName(value)
value = lower(erase(strtrim(string(value)), [char(39), char(34)]));
end

function value = nonemptyExpression(value)
value = strtrim(string(value));
if value == "[]"
    value = "";
end
end

function masked = maskNonCode(source)
masked = source;
singleQuote = char(39);
doubleQuote = char(34);
index = 1;
while index <= numel(source)
    value = source(index);
    if value == char(37)
        while index <= numel(source) && source(index) ~= newline
            masked(index) = char(32);
            index = index + 1;
        end
    elseif value == doubleQuote || ...
            (value == singleQuote && ~isTransposeOperator(source, index))
        quote = value;
        masked(index) = char(32);
        index = index + 1;
        while index <= numel(source)
            value = source(index);
            masked(index) = char(32);
            if value == quote
                if index < numel(source) && source(index + 1) == quote
                    masked(index + 1) = char(32);
                    index = index + 2;
                    continue;
                end
                index = index + 1;
                break;
            end
            index = index + 1;
        end
    else
        index = index + 1;
    end
end
end

function tf = isTransposeOperator(source, index)
previous = index - 1;
while previous >= 1 && isspace(source(previous))
    previous = previous - 1;
end
if previous == 0
    tf = false;
    return;
end
value = source(previous);
tf = isstrprop(value, "alphanum") || value == char(95) || ...
    any(value == [char(46), char(41), char(93), char(125)]);
end

function closing = closingDelimiter(masked, opening)
depth = 0;
closing = 0;
for index = opening:numel(masked)
    if masked(index) == char(40)
        depth = depth + 1;
    elseif masked(index) == char(41)
        depth = depth - 1;
        if depth == 0
            closing = index;
            return;
        end
    end
end
end

function arguments = splitArguments(source, masked)
if strlength(strtrim(string(source))) == 0
    arguments = strings(1, 0);
    return;
end
commas = zeros(1, numel(masked));
commaCount = 0;
depth = 0;
for index = 1:numel(masked)
    if any(masked(index) == [char(40), char(91), char(123)])
        depth = depth + 1;
    elseif any(masked(index) == [char(41), char(93), char(125)])
        depth = depth - 1;
    elseif masked(index) == char(44) && depth == 0
        commaCount = commaCount + 1;
        commas(commaCount) = index;
    end
end
boundaries = [1, commas(1:commaCount) + 1];
stops = [commas(1:commaCount) - 1, numel(source)];
arguments = strings(1, numel(boundaries));
for index = 1:numel(boundaries)
    arguments(index) = strtrim(string(source(boundaries(index):stops(index))));
end
end
