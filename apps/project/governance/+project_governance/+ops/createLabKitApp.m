% Expected caller: project_governance app and tests. Inputs are name-value
% options. Output is a struct describing created files. Side effects: copies
% scaffold source files and writes a unit-test scaffold.
function created = createLabKitApp(varargin)
%CREATELABKITAPP Generate a new LabKit app scaffold.

    p = inputParser;
    p.FunctionName = "project_governance.ops.createLabKitApp";
    p.addParameter("Family", "", @isTextScalar);
    p.addParameter("Slug", "", @isTextScalar);
    p.addParameter("EntryPoint", "", @isTextScalar);
    p.addParameter("Label", "", @isTextScalar);
    p.addParameter("Root", project_governance.ops.repoRoot(), @isTextScalar);
    p.addParameter("Force", false, @isLogicalScalar);
    p.parse(varargin{:});

    root = char(string(p.Results.Root));
    family = validateIdentifierSlug(p.Results.Family, "Family");
    slug = validateIdentifierSlug(p.Results.Slug, "Slug");
    entryPoint = string(p.Results.EntryPoint);
    if strlength(entryPoint) == 0
        entryPoint = "labkit_" + camelName(slug) + "_app";
    else
        entryPoint = matlab.lang.makeValidName(char(entryPoint));
    end
    label = string(p.Results.Label);
    if strlength(label) == 0
        label = titleFromSlug(slug);
    end

    scaffoldRoot = scaffoldSourceRoot();
    appFolder = fullfile(root, "apps", family, slug);
    testFolder = fullfile(root, "tests", "cases", "unit", "apps", family);
    testFile = fullfile(testFolder, char(camelName(slug) + "ScaffoldTest.m"));
    if exist(appFolder, "dir") == 7 && ~logical(p.Results.Force)
        error("LabKit:CreateApp:DestinationExists", ...
            "App folder already exists: %s", appFolder);
    end

    if exist(appFolder, "dir") == 7
        rmdir(appFolder, "s");
    end
    ensureFolder(fileparts(appFolder));
    copyfile(scaffoldRoot, appFolder);

    oldEntry = fullfile(appFolder, "scaffold_App_app.m");
    newEntry = fullfile(appFolder, char(entryPoint + ".m"));
    movefile(oldEntry, newEntry);

    oldPackage = fullfile(appFolder, "+scaffold_app");
    newPackage = fullfile(appFolder, char("+" + slug));
    movefile(oldPackage, newPackage);

    replaceGeneratedText(appFolder, slug, entryPoint, label);
    writeGeneratedUnitTest(testFile, slug);

    created = struct( ...
        "AppFolder", string(appFolder), ...
        "EntryPoint", entryPoint, ...
        "EntryFile", string(newEntry), ...
        "PackageName", string(slug), ...
        "TestFile", string(testFile));

    fprintf("Created LabKit app:\n");
    fprintf("  App:  %s\n", created.AppFolder);
    fprintf("  Test: %s\n", created.TestFile);
end

function root = scaffoldSourceRoot()
    opsFolder = fileparts(mfilename("fullpath"));
    packageFolder = fileparts(opsFolder);
    governanceFolder = fileparts(packageFolder);
    root = fullfile(governanceFolder, "scaffold", "generated_app");
    if exist(root, "dir") ~= 7
        error("LabKit:CreateApp:MissingScaffold", ...
            "Scaffold source folder does not exist: %s", root);
    end
end

function replaceGeneratedText(appFolder, slug, entryPoint, label)
    files = collectMFiles(appFolder);
    appId = matlab.lang.makeValidName(char(slug));
    labelLower = lower(label);
    for k = 1:numel(files)
        file = files(k);
        text = string(fileread(file));
        text = replace(text, "scaffold_App_app", entryPoint);
        text = replace(text, "LabKit Scaffold App", label);
        text = replace(text, "Scaffold Summary", label + " Summary");
        text = replace(text, "Scaffold Preview", label + " Preview");
        text = replace(text, "scaffoldApp", appId);
        text = replace(text, "Scaffold app", label);
        text = replace(text, "Scaffold App", label);
        text = replace(text, "Scaffold ", label + " ");
        text = replace(text, "Run scaffold step", "Run " + labelLower + " step");
        text = replace(text, "scaffold placeholder workflow", labelLower + " placeholder workflow");
        text = replace(text, "scaffold inputs", labelLower + " inputs");
        text = replace(text, "scaffold state", labelLower + " state");
        text = replace(text, "Reset scaffold", "Reset " + labelLower);
        text = replace(text, "scaffold_app", slug);
        writeTextFile(file, text);
    end
end

function writeGeneratedUnitTest(testFile, slug)
    ensureFolder(fileparts(testFile));
    className = string(getFileBaseName(testFile));
    packageName = string(slug);
    lines = [
        "classdef " + className + " < matlab.unittest.TestCase"
        "    %" + upper(className) + " Verify generated app scaffold helpers."
        ""
        "    methods (Test, TestTags = {'Unit'})"
        "        function detailLinesRenderDefaultState(testCase)"
        "            lines = " + packageName + ".view.detailLines(struct());"
        ""
        "            testCase.verifyTrue(iscell(lines));"
        "            testCase.verifyFalse(isempty(lines));"
        "        end"
        "    end"
        "end"
        ];
    writeTextFile(testFile, strjoin(lines, newline) + newline);
end

function slug = validateIdentifierSlug(value, label)
    slug = string(value);
    if strlength(slug) == 0
        error("LabKit:CreateApp:MissingOption", "%s is required.", label);
    end
    slug = lower(regexprep(slug, "[^A-Za-z0-9_]", "_"));
    slug = regexprep(slug, "_+", "_");
    slug = regexprep(slug, "^_|_$", "");
    if strlength(slug) == 0 || ~strcmp(char(slug), matlab.lang.makeValidName(char(slug)))
        error("LabKit:CreateApp:InvalidSlug", ...
            "%s must become a valid MATLAB package name.", label);
    end
end

function name = camelName(slug)
    parts = split(string(slug), "_");
    for k = 1:numel(parts)
        parts(k) = upper(extractBefore(parts(k), 2)) + extractAfter(parts(k), 1);
    end
    name = strjoin(parts, "");
end

function label = titleFromSlug(slug)
    parts = split(string(slug), "_");
    for k = 1:numel(parts)
        parts(k) = upper(extractBefore(parts(k), 2)) + extractAfter(parts(k), 1);
    end
    label = strjoin(parts, " ");
end

function files = collectMFiles(folder)
    entries = dir(fullfile(folder, "**", "*.m"));
    files = strings(numel(entries), 1);
    for k = 1:numel(entries)
        files(k) = string(fullfile(entries(k).folder, entries(k).name));
    end
end

function base = getFileBaseName(file)
    [~, base] = fileparts(file);
end

function ensureFolder(folder)
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function writeTextFile(file, text)
    fid = fopen(file, "w");
    if fid < 0
        error("LabKit:CreateApp:WriteFailed", "Could not write file: %s", file);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
    clear cleaner
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end
