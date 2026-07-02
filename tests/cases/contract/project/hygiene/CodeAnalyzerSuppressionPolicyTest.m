classdef CodeAnalyzerSuppressionPolicyTest < matlab.unittest.TestCase
    %CODEANALYZERSUPPRESSIONPOLICYTEST Ensure no MATLAB Code Analyzer suppression pragmas remain.

    methods (Test, TestTags = {'Integration', 'Style'})
        function noCodeAnalyzerSuppressionPragmas(testCase)
            root = testRepoRoot();
            files = collectTrackedMFiles(root);
            findings = findSuppressionPragmas(root, files);

            testCase.verifyEmpty(findings, ...
                "MATLAB Code Analyzer suppression pragmas found: " + strjoin(cellstr(findings), ", "));
        end

        function suppressionPatternMatchesExpectedAndNonExpectedLines(testCase)
            matchingLines = { ...
                "%#ok<AGROW>", ...
                "%#OK<AGROW>", ...
                "%#ok <AGROW>", ...
                "%#ok" + sprintf('\t') + "<AGROW>", ...
                "x = 1; %#ok<NASGU> % keep line", ...
                "y = x'; %#ok<NASGU>", ...
                "z = x.'; %#ok<NASGU>", ...
                "  %#ok<*TRYNC>  " ...
            };
            nonMatchingLines = { ...
                "title = ""%#ok<AGROW>"";", ...
                "title = '%#ok<AGROW>';", ...
                "title = 'can''t %#ok<AGROW>';", ...
                "title = ""quoted """" %#ok<AGROW> """" text"";", ...
                "title = ""not comment % %#ok<AGROW>"";", ...
                "% no pragma: %#OK <FOO", ...
                "% documentation mentions %#ok<FOO>", ...
                "% almost: %#ok>FOO<", ...
                "fprintf('not a pragma %#ok<FOO> string in text')", ...
                "helpText = ""Only documentation: %#ok<DEFN> may appear in text"";" ...
            };

            for k = 1:numel(matchingLines)
                line = string(matchingLines{k});
                testCase.verifyTrue(hasSuppressionPragma(line), ...
                    "Expected match for line: " + line);
            end

            for k = 1:numel(nonMatchingLines)
                line = string(nonMatchingLines{k});
                testCase.verifyFalse(hasSuppressionPragma(line), ...
                    "Expected no match for line: " + line);
            end
        end
    end
end

function files = collectTrackedMFiles(root)
    command = "git -C " + shellDoubleQuote(root) + " ls-files " + shellDoubleQuote("*.m");
    [status, output] = system(char(command));
    assert(status == 0, "Could not list tracked MATLAB files with git.");
    relativeFiles = splitlines(string(output));
    relativeFiles = relativeFiles(strlength(relativeFiles) > 0);
    files = strings(numel(relativeFiles), 1);
    for k = 1:numel(relativeFiles)
        files(k) = string(fullfile(root, char(relativeFiles(k))));
    end
    files = files(isfile(files));
end

function findings = findSuppressionPragmas(root, files)
    findings = strings(1, 0);

    for k = 1:numel(files)
        filepath = files(k);
        text = fileread(filepath);
        if ~contains(text, "%#")
            continue;
        end
        lines = splitlines(string(text));
        hit = false(1, numel(lines));
        for j = 1:numel(lines)
            hit(j) = hasSuppressionPragma(lines(j));
        end
        if any(hit)
            relFile = relativePathFromRoot(root, filepath);
            for j = find(hit(:).')
                findings(end+1) = relFile + " (line " + string(j) + ")";
            end
        end
    end
end

function quoted = shellDoubleQuote(value)
    quoted = string(value);
    if contains(quoted, """")
        error("LabKit:CodeAnalyzerPolicy:InvalidShellValue", ...
            "Shell-quoted values cannot contain double-quote characters.");
    end
    quoted = """" + quoted + """";
end

function tf = hasSuppressionPragma(line)
    suppressionPattern = "^%\s*#ok\s*<[^>]+>";
    comment = commentTextOutsideLiterals(line);
    tf = ~isempty(regexp(comment, suppressionPattern, "once", "ignorecase"));
end

function comment = commentTextOutsideLiterals(line)
    text = char(line);
    inCharLiteral = false;
    inStringLiteral = false;
    k = 1;
    while k <= numel(text)
        ch = text(k);
        if inCharLiteral
            if ch == "'"
                if k < numel(text) && text(k+1) == "'"
                    k = k + 2;
                    continue;
                end
                inCharLiteral = false;
            end
        elseif inStringLiteral
            if ch == '"'
                if k < numel(text) && text(k+1) == '"'
                    k = k + 2;
                    continue;
                end
                inStringLiteral = false;
            end
        elseif ch == "%"
            comment = string(text(k:end));
            return;
        elseif ch == "'" && startsCharLiteral(text, k)
            inCharLiteral = true;
        elseif ch == '"'
            inStringLiteral = true;
        end
        k = k + 1;
    end
    comment = "";
end

function tf = startsCharLiteral(text, quoteIndex)
    prev = previousNonspaceChar(text, quoteIndex);
    if prev == ""
        tf = true;
        return;
    end

    tf = isempty(regexp(prev, "[A-Za-z0-9_)\]\}.]", "once"));
end

function ch = previousNonspaceChar(text, index)
    for k = index-1:-1:1
        if ~isspace(text(k))
            ch = text(k);
            return;
        end
    end
    ch = "";
end

function relPath = relativePathFromRoot(root, filepath)
    rootPrefix = string(root) + string(filesep);
    relPath = string(filepath);
    if startsWith(relPath, rootPrefix)
        relPath = extractAfter(relPath, strlength(rootPrefix));
    end
    relPath = strrep(relPath, filesep, "/");
end
