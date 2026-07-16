function [codeLines, physicalLines] = labkitEffectiveCodeLineCount(filepath)
%LABKITEFFECTIVECODELINECOUNT Count executable MATLAB source lines.
% Expected caller: repository effective-code-line guardrails.
% Input: path to one MATLAB source file. Outputs: nonblank lines excluding
% full-line and block comments, plus the physical line count for diagnostics.
% Side effects: reads the source file without evaluating it.

    lines = readlines(filepath, "EmptyLineRule", "read");
    physicalLines = numel(lines);
    codeLines = 0;
    inBlockComment = false;
    for k = 1:numel(lines)
        line = strip(lines(k));
        if inBlockComment
            if startsWith(line, "%}")
                inBlockComment = false;
            end
            continue;
        end
        if startsWith(line, "%{")
            inBlockComment = true;
            continue;
        end
        if strlength(line) == 0 || startsWith(line, "%")
            continue;
        end
        codeLines = codeLines + 1;
    end
end
