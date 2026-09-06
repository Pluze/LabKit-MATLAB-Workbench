function count = runLabKitDocExamples(model)
%RUNLABKITDOCEXAMPLES Execute trusted, explicitly runnable source examples.
% Caller: checkLabKitDocs, after validated documentation discovery. Each
% example has its own function workspace and temporary working folder. This
% is a repository-code execution boundary, not a sandbox for untrusted docs.

    examples = collectExamples(model);
    count = numel(examples);
    previousPath = path;
    pathCleanup = onCleanup(@() path(previousPath));
    addpath(model.repoRoot);
    for k = 1:numel(model.apps)
        addpath(fullfile(model.repoRoot, "apps", model.apps(k).folder));
    end
    for k = 1:count
        fprintf("DOCS EXAMPLES [%d/%d] %s\n", k - 1, count, examples(k).source);
        heartbeat = timer("ExecutionMode", "fixedSpacing", "StartDelay", 30, "Period", 30, ...
            "TimerFcn", @(~, ~) fprintf("DOCS EXAMPLES [%d/%d] running %s\n", ...
            k - 1, count, examples(k).source));
        heartbeatCleanup = onCleanup(@() stopHeartbeat(heartbeat));
        start(heartbeat);
        try
            executeIsolated(examples(k).code);
        catch exception
            failure = MException("LabKit:Docs:ExampleFailed", ...
                "Runnable example failed in %s: %s", ...
                examples(k).source, exception.message);
            throw(addCause(failure, exception));
        end
        clear heartbeatCleanup
    end
    fprintf("DOCS EXAMPLES [%d/%d] complete\n", count, count);
    clear pathCleanup
end

function examples = collectExamples(model)
    marker = "<!-- labkit-runnable-example -->";
    apiLines = cell(numel(model.api), 1);
    pageLines = cell(numel(model.pages), 1);
    capacity = 0;
    for k = 1:numel(model.api)
        apiLines{k} = splitlines(string(model.api(k).helpText));
        capacity = capacity + nnz(strip(apiLines{k}) == "Example:");
    end
    for k = 1:numel(model.pages)
        pageLines{k} = splitlines(string(fileread(fullfile( ...
            model.sourceRoot, model.pages(k).source))));
        capacity = capacity + nnz(strip(pageLines{k}) == marker);
    end
    examples = repmat(struct("source", "", "code", ""), capacity, 1);
    count = 0;
    for k = 1:numel(model.api)
        item = model.api(k);
        lines = apiLines{k};
        starts = find(strip(lines) == "Example:");
        for index = starts.'
            stop = index + 1;
            while stop <= numel(lines) && ...
                    (strlength(strip(lines(stop))) == 0 || ...
                    startsWith(lines(stop), " "))
                stop = stop + 1;
            end
            code = strjoin(lines(index + 1:stop - 1), newline);
            count = count + 1;
            examples(count) = example(item.source, code);
        end
    end
    for k = 1:numel(model.pages)
        source = model.pages(k).source;
        lines = pageLines{k};
        starts = find(strip(lines) == marker);
        for index = starts.'
            opening = index + 1;
            while opening <= numel(lines) && strlength(strip(lines(opening))) == 0
                opening = opening + 1;
            end
            if opening > numel(lines) || strip(lines(opening)) ~= "```matlab"
                error("LabKit:Docs:InvalidRunnableExample", ...
                    "Runnable marker must precede a MATLAB fence: %s:%d", source, index);
            end
            closing = opening + 1;
            while closing <= numel(lines) && strip(lines(closing)) ~= "```"
                closing = closing + 1;
            end
            if closing > numel(lines)
                error("LabKit:Docs:InvalidRunnableExample", ...
                    "Runnable MATLAB fence must close: %s:%d", source, index);
            end
            code = strjoin(lines(opening + 1:closing - 1), newline);
            count = count + 1;
            examples(count) = example("docs/" + source + ":" + index, code);
        end
    end
end

function value = example(source, code)
    if strlength(strip(code)) == 0
        error("LabKit:Docs:InvalidRunnableExample", ...
            "Runnable example is empty: %s", source);
    end
    value = struct("source", string(source), "code", string(code));
end

function executeIsolated(code)
    folder = string(tempname);
    mkdir(folder);
    previousFolder = pwd;
    previousPath = path;
    previousRng = rng;
    previousVisibility = get(groot, "DefaultFigureVisible");
    previousFigures = findall(groot, "Type", "figure");
    cleanup = onCleanup(@() restoreEnvironment(folder, previousFolder, ...
        previousPath, previousRng, previousVisibility, previousFigures));
    set(groot, "DefaultFigureVisible", "off");
    script = fullfile(folder, "documentedExample.m");
    writeDocText(script, code + newline);
    cd(folder);
    executeScript(script);
    clear cleanup
end

function executeScript(script)
% Fresh function workspace prevents an earlier example supplying missing data.
    run(script);
end

function restoreEnvironment(folder, previousFolder, previousPath, ...
        previousRng, previousVisibility, previousFigures)
    cd(previousFolder);
    path(previousPath);
    rng(previousRng);
    set(groot, "DefaultFigureVisible", previousVisibility);
    figures = findall(groot, "Type", "figure");
    delete(setdiff(figures, previousFigures));
    if isfolder(folder)
        rmdir(folder, "s");
    end
end

function stopHeartbeat(heartbeat)
    stop(heartbeat);
    delete(heartbeat);
end
