classdef RepositoryHygieneGuardrailTest < matlab.unittest.TestCase
    %REPOSITORYHYGIENEGUARDRAILTEST Generic repository size and helper hygiene.

    methods (Test, TestTags = {'Integration', 'Style'})
        function trackedFilesStayWithinLineBudget(testCase)
            root = setupLabKitTestPath();
            maxLines = 650;
            actual = collectOversizedTrackedFiles(root, maxLines);
            testCase.verifyEmpty(actual, ...
                ['tracked files except labkit_launcher.m and CHANGELOG.md must remain at or ' ...
                'below ' num2str(maxLines) ' lines. Split large files by ' ...
                'cohesive private helpers or app-owned component packages ' ...
                'before adding more logic. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function scriptsDoNotContainMatlabEntryScripts(testCase)
            root = setupLabKitTestPath();
            actual = collectRelativeFiles(root, fullfile(root, 'scripts', '*.m'));
            testCase.verifyEmpty(actual, ...
                ['launcher-owned MATLAB helpers must remain inside ' ...
                'labkit_launcher.m. Files: ' strjoin(cellstr(actual), ', ')]);
        end

        function trackedTextFilesUseAsciiOnly(testCase)
            root = setupLabKitTestPath();
            tracked = gitTrackedFiles(root);
            textFiles = tracked(arrayfun(@isTextTrackedFile, tracked));
            actual = collectNonAsciiFiles(root, textFiles);
            testCase.verifyEmpty(actual, ...
                ['tracked text files must remain ASCII-only. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function charPathListsDoNotUseBracketConcatenation(testCase)
            root = setupLabKitTestPath();
            tracked = gitTrackedFiles(root);
            matlabFiles = tracked(endsWith(tracked, ".m"));
            actual = collectUnsafeCharPathLists(root, matlabFiles);
            testCase.verifyEmpty(actual, ...
                ['path target lists must use string arrays or cell arrays, ' ...
                'not char bracket concatenation. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function charPathListPatternCatchesUnsafeExamples(testCase)
            pattern = unsafeCharPathListPattern();
            unsafe = ['targets = [fullfile(root, ''artifacts''), ...' newline ...
                '    fullfile(root, ''matlab_test.log'')];'];
            cellList = ['targets = {' newline ...
                '    ''artifacts''' newline ...
                '    ''matlab_test.log''' newline ...
                '};'];
            stringList = ['targets = [fullfile(root, "artifacts"), ...' newline ...
                '    fullfile(root, "matlab_test.log")];'];

            testCase.verifyFalse(isempty(regexp(unsafe, pattern, 'once')), ...
                'Guardrail pattern must catch char fullfile bracket lists.');
            testCase.verifyEmpty(regexp(cellList, pattern, 'once'), ...
                'Guardrail pattern must allow cell path lists.');
            testCase.verifyEmpty(regexp(stringList, pattern, 'once'), ...
                'Guardrail pattern must allow string path lists.');
        end

        function pathScalarsAreNotExpandedAsCharacterColumns(testCase)
            root = setupLabKitTestPath();
            tracked = gitTrackedFiles(root);
            matlabFiles = tracked(endsWith(tracked, ".m"));
            actual = collectUnsafePathScalarColonUses(root, matlabFiles);
            testCase.verifyEmpty(actual, ...
                ['folder-like path scalars must not be expanded with (:), ' ...
                'because char paths then become one path per character. Use ' ...
                'string(folder), cellstr(paths(:)), or reshape only known ' ...
                'string arrays. Files: ' strjoin(cellstr(actual), ', ')]);
        end

        function pathScalarColonPatternCatchesUnsafeExamples(testCase)
            pattern = unsafePathScalarColonPattern();
            colonExpr = "(:)";
            unsafe = [
                "paths = expandFileChoices(string(folder" + colonExpr + "), props);"
                "files = findUnderRoot(rootDir" + colonExpr + ");"
                "out = string(outputFolder" + colonExpr + ");"
            ];
            safe = [
                "paths = string(paths(:));"
                "rows = table(filePath(:), label(:));"
                "folder = string(folder);"
            ];

            testCase.verifyTrue(all(~cellfun(@isempty, regexp(unsafe, pattern, 'once'))), ...
                'Guardrail pattern must catch folder-like scalar path expansion.');
            testCase.verifyTrue(all(cellfun(@isempty, regexp(safe, pattern, 'once'))), ...
                'Guardrail pattern must allow path-list normalization and table column shaping.');
        end

        function appStateNumericAssignmentsSanitizeScalars(testCase)
            root = setupLabKitTestPath();
            actual = collectUnsafeStateNumericAssignments(root);
            testCase.verifyEmpty(actual, ...
                ['app state/model helpers must sanitize UI or option numeric ' ...
                'values to finite scalars before assigning scalar state fields. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function appStateNumericPatternCatchesDirectDoubleAssignments(testCase)
            patterns = unsafeStateNumericAssignmentPatterns();
            unsafe = [
                "step.amount = double(amount);"
                "S.windowStartSec = double(labkit.ui.control.getValue(ui, ""windowStartPanner""));"
                "optsOut.cropWidth = double(optionValue(opts, 'cropWidth', 0));"
            ];
            safe = [
                "step.amount = numericScalar(amount, 0);"
                "step.amount = double(values(:));"
                "value = double(amount);"
                "count = double(event.VerticalScrollCount);"
            ];

            unsafeMatched = false(size(unsafe));
            for k = 1:numel(unsafe)
                unsafeMatched(k) = anyPatternMatches(unsafe(k), patterns);
            end
            safeMatched = false(size(safe));
            for k = 1:numel(safe)
                safeMatched(k) = anyPatternMatches(safe(k), patterns);
            end

            testCase.verifyTrue(all(unsafeMatched), ...
                'Guardrail pattern must catch direct UI/option numeric assignment to state fields.');
            testCase.verifyFalse(any(safeMatched), ...
                'Guardrail pattern must allow scalar helper calls and non-state conversions.');
        end

        function appUiLabelHelpersOwnDeclaredLongLiterals(testCase)
            root = setupLabKitTestPath();
            actual = collectDuplicatedAppUiLabelHelperLiterals(root);
            testCase.verifyEmpty(actual, ...
                ['long user-visible literals declared by app UI label helpers ' ...
                'must not be hard-coded again in the same app source or tests. ' ...
                'Reference the helper instead. Findings: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function appUiLabelHelperPatternCatchesDuplicatedLiteral(testCase)
            helperFile = "apps/family/sample/+sample/+view/sampleLabels.m";
            appFiles = [
                helperFile
                "apps/family/sample/+sample/run.m"
                "tests/cases/gui/apps/family/sample/GuiLayoutSampleTest.m"
            ];
            contents = containers.Map('KeyType', 'char', 'ValueType', 'any');
            contents(char(helperFile)) = [
                "function labels = sampleLabels()"
                "labels = struct('runAction', ""Run current sample"");"
                "end"
            ];
            contents(char(appFiles(2))) = "buttonText = ""Run current sample"";";
            contents(char(appFiles(3))) = "expected = {'Run current sample'};";

            findings = duplicatedLabelLiteralsForFiles(appFiles, contents);
            testCase.verifyEqual(numel(findings), 2, ...
                'Guardrail helper should catch source and test copies of a declared UI label.');
        end

        function matlabFunctionsDoNotUseSingleLineBodies(testCase)
            root = setupLabKitTestPath();
            tracked = gitTrackedFiles(root);
            matlabFiles = tracked(endsWith(tracked, ".m"));
            actual = collectSingleLineFunctionBodies(root, matlabFiles);
            testCase.verifyEmpty(actual, ...
                ['MATLAB functions must not put executable bodies and end on ' ...
                'the declaration line. Split helpers or format bodies on ' ...
                'separate lines. Files: ' strjoin(cellstr(actual), ', ')]);
        end

        function singleLineFunctionPatternCatchesCompressedBodies(testCase)
            lines = [
                "function [a, b] = allowedSignature(x)"
                "function y = bad(x), y = x + 1; end"
                "function z = alsoBad(x); z = x; end"
            ];
            findings = singleLineFunctionBodyLines(lines, "example.m");
            testCase.verifyEqual(findings, ["example.m:2", "example.m:3"], ...
                'Guardrail pattern should catch compressed function bodies without flagging signatures.');
        end

        function appPrivateHelpersAreNotTracked(testCase)
            root = setupLabKitTestPath();
            actualDirs = collectPrivateDirs(fullfile(root, 'apps'), root);
            testCase.verifyTrue(isempty(actualDirs), ...
                ['app private helper directories are not allowed. Files: ' ...
                strjoin(cellstr(actualDirs), ', ')]);

            actualFiles = collectRelativeFiles(root, ...
                fullfile(root, 'apps', '**', 'private', '*.m'));
            testCase.verifyTrue(isempty(actualFiles), ...
                ['app private helper files must live in app-owned packages. Files: ' ...
                strjoin(cellstr(actualFiles), ', ')]);
        end

        function helperQualityAuditReportsShortHelperMetadata(testCase)
            root = setupLabKitTestPath();
            audit = labkitHelperQualityAudit(root, ...
                "MaxLines", 20, "Scope", "all");

            expectedColumns = ["RelativePath", "Lines", "TopLevelScope", ...
                "RolePackage", "FunctionCount", "CallCount", ...
                "PublicStatus", "DirectUnitTestReferences", ...
                "BoundaryClass", "AllowedException", "Recommendation", ...
                "ReviewReason"];
            testCase.verifyEqual(string(audit.Properties.VariableNames), ...
                expectedColumns);
            testCase.verifyTrue(any(audit.RelativePath == ...
                "apps/image_measurement/image_enhance/+image_enhance/+appState/emptyStep.m"), ...
                'Helper audit should include known short app helpers.');
            assertAuditRow(testCase, audit, ...
                "apps/image_measurement/image_enhance/+image_enhance/+appState/emptyStep.m", ...
                "generic-helper", "review-contract");
            assertAuditRow(testCase, audit, ...
                "+labkit/+image/isSupportedPath.m", ...
                "public-framework-api", "keep-boundary");
            testCase.verifyTrue(any(audit.Recommendation == ...
                "inline-or-merge-candidate" | audit.Recommendation == ...
                "review-contract" | audit.Recommendation == ...
                "keep-boundary" | audit.Recommendation == ...
                "review-one-call-contract"), ...
                'Helper audit should produce dry-run classifications.');
        end
    end
end

function assertAuditRow(testCase, audit, path, boundaryClass, recommendation)
    row = audit(audit.RelativePath == path, :);
    testCase.verifyEqual(height(row), 1, ...
        "Helper audit should include " + path + ".");
    if height(row) ~= 1
        return;
    end
    testCase.verifyEqual(row.BoundaryClass, boundaryClass, ...
        "Unexpected boundary class for " + path + ".");
    testCase.verifyEqual(row.Recommendation, recommendation, ...
        "Unexpected recommendation for " + path + ".");
end

function findings = collectSingleLineFunctionBodies(root, files)
    findings = strings(1, 0);
    pattern = singleLineFunctionBodyPattern();
    for k = 1:numel(files)
        filepath = fullfile(root, char(files(k)));
        if exist(filepath, 'file') ~= 2
            continue;
        end
        content = readCachedText(filepath);
        if isempty(regexp(content, pattern, 'once'))
            continue;
        end
        lines = readCachedLines(filepath);
        findings = [findings, singleLineFunctionBodyLines(lines, files(k))];
    end
end

function findings = singleLineFunctionBodyLines(lines, relativeFile)
    findings = strings(1, 0);
    for k = 1:numel(lines)
        text = strtrim(lines(k));
        hasFunction = startsWith(text, "function ");
        hasInlineEnd = ~isempty(regexp(text, '(^|[;,]\s*)end\s*(%.*)?$', 'once'));
        hasBodySeparator = contains(text, ";") || contains(text, ",");
        if hasFunction && hasInlineEnd && hasBodySeparator
            findings(end + 1) = string(relativeFile) + ":" + string(k);
        end
    end
end

function pattern = singleLineFunctionBodyPattern()
    pattern = '(?m)^\s*function\s+[^\r\n]*[;,][^\r\n]*\bend\s*(%.*)?$';
end

function findings = collectUnsafeCharPathLists(root, files)
    findings = strings(1, 0);
    pattern = unsafeCharPathListPattern();
    for k = 1:numel(files)
        filepath = fullfile(root, char(files(k)));
        if exist(filepath, 'file') ~= 2
            continue;
        end
        content = readCachedText(filepath);
        if ~isempty(regexp(content, pattern, 'once'))
            findings(end+1) = files(k);
        end
    end
end

function pattern = unsafeCharPathListPattern()
    pattern = ['(?m)^\s*[A-Za-z]\w*\s*=\s*\[\s*fullfile\([^\]]*''[^\]]*\)' ...
        '\s*,[^\]]*fullfile\([^\]]*''[^\]]*\)\s*\]'];
end

function findings = collectUnsafePathScalarColonUses(root, files)
    findings = strings(1, 0);
    pattern = unsafePathScalarColonPattern();
    for k = 1:numel(files)
        filepath = fullfile(root, char(files(k)));
        if exist(filepath, 'file') ~= 2
            continue;
        end
        content = readCachedText(filepath);
        if ~contains(content, "(:)") || isempty(regexp(content, pattern, 'once'))
            continue;
        end
        lines = readCachedLines(filepath);
        for iLine = 1:numel(lines)
            if ~isempty(regexp(lines(iLine), pattern, 'once'))
                findings(end+1) = files(k) + ":" + string(iLine);
            end
        end
    end
end

function pattern = unsafePathScalarColonPattern()
    pathScalarNames = ['(?:folder|rootDir|startPath|outputFolder|' ...
        'inputFolder|selectedFolder)'];
    pattern = ['(?<![A-Za-z0-9_])' pathScalarNames '\s*\(:\)'];
end

function findings = collectUnsafeStateNumericAssignments(root)
    files = dir(fullfile(root, 'apps', '**', '*.m'));
    findings = strings(1, 0);
    patterns = unsafeStateNumericAssignmentPatterns();
    for k = 1:numel(files)
        filepath = fullfile(files(k).folder, files(k).name);
        if exist(filepath, 'file') ~= 2
            continue;
        end
        content = readCachedText(filepath);
        hasStateTarget = contains(content, "step.") || ...
            contains(content, "S.") || contains(content, "optsOut.");
        if ~contains(content, "double(") || ~hasStateTarget
            continue;
        end
        lines = readCachedLines(filepath);
        for iLine = 1:numel(lines)
            if anyPatternMatches(lines(iLine), patterns)
                findings(end+1) = string(relativePath(root, filepath)) + ":" + string(iLine);
            end
        end
    end
end

function patterns = unsafeStateNumericAssignmentPatterns()
    patterns = [
        "^\s*step\.[A-Za-z]\w*\s*=\s*double\(\s*[A-Za-z]\w*\s*\)\s*;"
        "^\s*S\.[A-Za-z]\w*\s*=\s*double\(\s*labkit\.ui\.control\.getValue\("
        "^\s*optsOut\.[A-Za-z]\w*\s*=\s*double\(\s*optionValue\("
    ];
end

function tf = anyPatternMatches(text, patterns)
    tf = false;
    for k = 1:numel(patterns)
        if ~isempty(regexp(text, patterns(k), 'once'))
            tf = true;
            return;
        end
    end
end

function findings = collectDuplicatedAppUiLabelHelperLiterals(root)
    tracked = gitTrackedFiles(root);
    matlabFiles = tracked(endsWith(tracked, ".m"));
    helperFiles = matlabFiles(arrayfun(@isAppUiLabelHelperFile, matlabFiles));
    if isempty(helperFiles)
        findings = strings(1, 0);
        return;
    end

    scopedFiles = helperFiles;
    for k = 1:numel(helperFiles)
        appName = appNameFromPath(helperFiles(k));
        scopedFiles = [scopedFiles, ...
            matlabFiles(arrayfun(@(f) isSameAppSourceOrTest(f, appName), matlabFiles))];
    end
    scopedFiles = unique(scopedFiles, "stable");

    contents = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for k = 1:numel(scopedFiles)
        filepath = fullfile(root, char(scopedFiles(k)));
        if exist(filepath, 'file') == 2
            contents(char(scopedFiles(k))) = readCachedLines(filepath);
        end
    end
    findings = duplicatedLabelLiteralsForFiles(scopedFiles, contents);
end

function findings = duplicatedLabelLiteralsForFiles(files, contents)
    findings = strings(1, 0);
    helperFiles = files(arrayfun(@isAppUiLabelHelperFile, files));
    for k = 1:numel(helperFiles)
        helperFile = helperFiles(k);
        if ~isKey(contents, char(helperFile))
            continue;
        end
        literals = helperUserVisibleLiterals(contents(char(helperFile)));
        if isempty(literals)
            continue;
        end
        appName = appNameFromPath(helperFile);
        scopedFiles = files(arrayfun(@(f) isSameAppSourceOrTest(f, appName), files));
        scopedFiles = setdiff(scopedFiles, helperFile, "stable");
        for iLiteral = 1:numel(literals)
            literal = literals(iLiteral);
            for iFile = 1:numel(scopedFiles)
                file = scopedFiles(iFile);
                if ~isKey(contents, char(file))
                    continue;
                end
                lines = contents(char(file));
                lineNumbers = linesContainingQuotedLiteral(lines, literal);
                for iLine = 1:numel(lineNumbers)
                    findings(end + 1) = helperFile + " owns " + ...
                        quoteForFinding(literal) + " but " + file + ":" + ...
                        string(lineNumbers(iLine)) + " hard-codes it";
                end
            end
        end
    end
end

function tf = isAppUiLabelHelperFile(file)
    file = string(file);
    tf = startsWith(file, "apps/") && contains(file, "/+view/") && ...
        ~isempty(regexp(file, '(Labels|Choices|Items)\.m$', 'once'));
end

function literals = helperUserVisibleLiterals(lines)
    literals = strings(1, 0);
    pattern = """([^""]{8,})""|'((?:''|[^']){8,})'";
    for k = 1:numel(lines)
        line = string(lines(k));
        if startsWith(strtrim(line), "%")
            continue;
        end
        matches = regexp(line, pattern, 'tokens');
        for iMatch = 1:numel(matches)
            token = string(matches{iMatch});
            token = token(strlength(token) > 0);
            if isempty(token)
                continue;
            end
            literal = replace(token(1), "''", "'");
            if isUserVisibleLabelLiteral(literal)
                literals(end + 1) = literal;
            end
        end
    end
    literals = unique(literals, "stable");
end

function tf = isUserVisibleLabelLiteral(literal)
    tf = strlength(literal) >= 8 && ...
        isempty(regexp(literal, '^[A-Za-z]\w*$', 'once')) && ...
        ~startsWith(literal, "labkit:");
end

function appName = appNameFromPath(file)
    parts = split(string(file), "/");
    packagePart = parts(startsWith(parts, "+"));
    appName = extractAfter(packagePart(1), 1);
end

function tf = isSameAppSourceOrTest(file, appName)
    file = string(file);
    packageToken = "/+" + appName + "/";
    testToken = "/" + appName + "/";
    tf = contains("/" + file, packageToken) || ...
        (startsWith(file, "tests/") && contains("/" + file + "/", testToken));
end

function lineNumbers = linesContainingQuotedLiteral(lines, literal)
    lineNumbers = zeros(1, 0);
    singleQuoted = "'" + replace(literal, "'", "''") + "'";
    doubleQuoted = """" + literal + """";
    for k = 1:numel(lines)
        line = string(lines(k));
        if contains(line, singleQuoted) || contains(line, doubleQuoted)
            lineNumbers(end + 1) = k;
        end
    end
end

function text = quoteForFinding(literal)
    text = """" + literal + """";
end

function files = collectNonAsciiFiles(root, tracked)
    files = strings(1, 0);
    for k = 1:numel(tracked)
        filepath = fullfile(root, char(tracked(k)));
        if exist(filepath, 'file') ~= 2
            continue;
        end
        text = readCachedText(filepath);
        if any(double(text) > 127)
            files(end+1) = tracked(k);
        end
    end
end

function tf = isTextTrackedFile(filepath)
    [~, name, ext] = fileparts(char(filepath));
    ext = lower(string(ext));
    basename = string(name) + ext;
    textExts = [".m", ".md", ".txt", ".json", ".yml", ".yaml", ...
        ".csv", ".tsv", ".xml", ".html", ".css", ".js", ".sh", ...
        ".ps1", ".gitignore", ".gitattributes"];
    textNames = ["LICENSE", "NOTICE", "AGENTS"];
    tf = ismember(ext, textExts) || ismember(basename, textNames) || ...
        startsWith(basename, ".git");
end

function files = collectOversizedTrackedFiles(root, maxLines)
    tracked = gitTrackedFiles(root);
    tracked = setdiff(tracked, ["CHANGELOG.md", "labkit_launcher.m"]);
    files = collectOversizedFiles(root, tracked, maxLines);
end

function files = collectOversizedFiles(root, tracked, maxLines)
    files = strings(1, 0);
    for k = 1:numel(tracked)
        filepath = fullfile(root, char(tracked(k)));
        if exist(filepath, 'file') ~= 2
            continue;
        end
        lineCount = countFileLines(filepath);
        if lineCount > maxLines
            files(end+1) = tracked(k) + " (" + string(lineCount) + " lines)";
        end
    end
end

function dirs = collectPrivateDirs(folder, root)
    if ~isfolder(folder)
        dirs = strings(1, 0);
        return;
    end

    entries = dir(fullfile(folder, '**', 'private'));
    entries = entries([entries.isdir]);
    if isempty(entries)
        dirs = strings(1, 0);
        return;
    end

    paths = fullfile({entries.folder}, {entries.name});
    dirs = unique(string(relativePaths(root, paths)));
end

function files = collectRelativeFiles(root, pattern)
    entries = dir(pattern);
    files = strings(numel(entries), 1);
    fileCount = 0;
    for k = 1:numel(entries)
        if ~entries(k).isdir
            fileCount = fileCount + 1;
            files(fileCount) = string(relativePath(root, ...
                fullfile(entries(k).folder, entries(k).name)));
        end
    end
    files = unique(files(1:fileCount));
end

function n = countFileLines(filepath)
    text = readCachedText(filepath);
    if isempty(text)
        n = 0;
        return;
    end

    lineFeed = char(10);
    n = sum(text == lineFeed);
    if text(end) ~= lineFeed
        n = n + 1;
    end
end

function files = gitTrackedFiles(root)
    persistent cachedRoot cachedFiles
    if isequal(cachedRoot, string(root))
        files = cachedFiles;
        return;
    end
    command = sprintf('git -C "%s" ls-files', root);
    [status, output] = system(command);
    assert(status == 0, 'Could not list tracked files with git.');
    files = string(splitlines(strtrim(output))).';
    files = files(strlength(files) > 0);
    cachedRoot = string(root);
    cachedFiles = files;
end

function lines = readCachedLines(filepath)
    persistent cache
    if isempty(cache)
        cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    key = char(filepath);
    if isKey(cache, key)
        lines = cache(key);
        return;
    end
    lines = readlines(filepath);
    cache(key) = lines;
end

function text = readCachedText(filepath)
    persistent cache
    if isempty(cache)
        cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    key = char(filepath);
    if isKey(cache, key)
        text = cache(key);
        return;
    end
    text = fileread(filepath);
    cache(key) = text;
end

function rel = relativePath(root, filepath)
    rel = filepath;
    prefix = [root filesep];
    if startsWith(filepath, prefix)
        rel = filepath(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end

function paths = relativePaths(root, filepaths)
    paths = cell(size(filepaths));
    for k = 1:numel(filepaths)
        paths{k} = relativePath(root, filepaths{k});
    end
end
