function findings = findRepositoryHygiene(root, files)
%FINDREPOSITORYHYGIENE Scan text and source boundaries without executing code.
findings = strings(0, 1);
for file = files(:).'
    relative = replace(extractAfter(file, strlength(string(root)) + 1), "\", "/");
    source = fileread(file);
    lines = splitlines(string(source));
    for index = 1:numel(lines)
        characters = char(lines(index));
        codes = double(characters);
        % English uses ASCII letters; Greek letters are scientific notation.
        greek = (codes >= 913 & codes <= 937) | ...
            (codes >= 945 & codes <= 969) | ismember(codes, ...
            [181 976 977 981 982 1008 1009 1013]);
        scientific = greek | ismember(codes, [197 229]) | ...
            (codes >= 8304 & codes <= 8351) | ...
            (codes >= 8448 & codes <= 8527);
        if any(codes > 127 & isstrprop(characters, "alpha") & ~scientific)
            record("non-english-text", index);
        end
    end
    checkPattern("drive-path", "(?<![A-Za-z])[A-Za-z]:[\\/]");
    checkPattern("user-path", "/(?:Users|home)/[^/\s]+/");
    checkPattern("timestamp", "\d{8}_\d{6}");
    if ~endsWith(lower(relative), ".m")
        continue;
    end
    names = regexp(source, "(?m)^\s*function\s+" + ...
        "(?:\[[^\]\r\n]*\]\s*=\s*|[A-Za-z]\w*\s*=\s*)?" + ...
        "([A-Za-z]\w*)\s*(?:\(|$)", "tokens");
    for name = string([names{:}])
        if strlength(name) > 63
            record("identifier-length", 1);
        end
    end
    if startsWith(relative, "+labkit/+app/+internal/") && ...
            count(relative, "/") == 3
        record("sdk-owner", 1);
    end
    if relative == "labkit_launcher.m" || ...
            startsWith(relative, ["+labkit/" "apps/" "tools/"])
        checkDynamicCalls();
        checkPattern("toolbox-pool", ...
            "(?<![\w.])(?:parpool\s*\(|parfor\s+|spmd\s*\(|" + ...
            "parallel\.Pool|parallel\.Cluster)");
    end
    if startsWith(relative, "apps/")
        checkPattern("native-dialog", ...
            "(?<![\w.])(?:uigetfile|uiputfile|uigetdir)\s*\(");
    end
    if startsWith(relative, "tests/specs/apps/")
        checkPattern("test-sdk-internal", "labkit\.app\.internal");
    end
    if startsWith(relative, "tests/specs/")
        checkPattern("test-runtime-seam", ...
            "labkit\.app\.internal\.runtime\.RuntimeFactory");
    end
end
listing = dir(fullfile(root, "apps", "**", "+*"));
for folder = reshape(listing([listing.isdir]), 1, [])
    if ismember(string(folder.name), ["+actions" "+ops" "+io" "+ui" ...
            "+userInterface" "+view" "+export" "+helpers" "+utils" ...
            "+manager" "+processor"])
        relative = replace(extractAfter(string(fullfile(folder.folder, ...
            folder.name)), strlength(string(root)) + 1), "\", "/");
        record("package-name", 1);
    end
end

    function record(category, line)
        findings(end + 1, 1) = relative + ":" + line + " [" + category + "]";
    end

    function checkPattern(category, expression)
        positions = regexp(source, expression, "start");
        for position = positions
            record(category, 1 + count(string(source(1:position - 1)), newline));
        end
    end

    function checkDynamicCalls()
        [positions, calls] = regexp(source, ...
            '(?<![\w.])(eval|evalin|assignin|str2func|feval)\s*\(', ...
            'start', 'match');
        assignments = regexp(source, ...
            ['(?<![\w.])assignin\s*\(\s*' ...
            '(?:"base"|''base'')\s*,\s*' ...
            '(?:"[A-Za-z]\w*"|''[A-Za-z]\w*'')\s*,'], 'start');
        validAssignments = ismember(positions, assignments);
        positions(validAssignments) = [];
        calls(validAssignments) = [];
        allowedFiles = [ ...
            "+labkit/+app/+internal/+discovery/invokeDiscoveredApp.m"
            "tools/profiling/profileLabKitTarget.m"];
        allowedCounts = [2 1];
        markers = ["Dynamic extension boundary" "Dynamic maintainer-tool boundary"];
        allowance = find(allowedFiles == relative, 1);
        if ~isempty(allowance) && numel(calls) == allowedCounts(allowance) && ...
                all(string(calls) == "fe" + "val(") && contains(source, markers(allowance))
            return;
        end
        if ~isempty(allowance) && isempty(positions)
            record("dynamic-allowance", 1);
        end
        for position = positions
            record("dynamic-call", 1 + count(string(source(1:position - 1)), newline));
        end
    end
end
