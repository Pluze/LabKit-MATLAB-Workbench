function file = createSpec(sourceFile, varargin)
%CREATESPEC Create a minimal behavior-specification skeleton in its owner.
%   FILE = labkittest.createSpec(SOURCEFILE, Contract=CONTRACT, Name=NAME)
%   finds SOURCEFILE's author-owned insertion target and writes NAME + "Spec"
%   below its exact tests/specs owner. The generated class declares the target
%   Contract and Env tags and contains one deliberately failing TODO method.
%   Replace only that method body with behavioral evidence; do not invent test
%   folders, stage tags, runner selectors, or wrapper classes.
%
%   Contract must be one of the locations returned by
%   labkittest.locate(SOURCEFILE). Name must be a valid MATLAB class name and
%   need not include the Spec suffix. Existing files are never overwritten.
%
%   FILE = labkittest.createSpec(..., SpecsRoot=FOLDER) writes to a separate
%   specification root for framework development and tests. Ordinary authors
%   use the repository default.

    opts = parseOptions(sourceFile, varargin{:});
    locations = labkittest.locate(opts.SourceFile, "SpecsRoot", opts.SpecsRoot);
    matches = locations([locations.Contract] == opts.Contract);
    if isempty(matches)
        error("LabKit:TestAuthoring:UnknownContract", ...
            "Contract %s is not required for %s.", opts.Contract, opts.SourceFile);
    end
    if numel(matches) ~= 1 || ~matches.AuthorOwned
        error("LabKit:TestAuthoring:FrameworkConformance", ...
            "Contract %s is provided by framework conformance; no App wrapper is created.", ...
            opts.Contract);
    end
    location = matches;
    className = opts.Name;
    if ~endsWith(className, "Spec")
        className = className + "Spec";
    end
    if className ~= string(matlab.lang.makeValidName(char(className)))
        error("LabKit:TestAuthoring:InvalidName", ...
            "Name must form a valid MATLAB class name: %s.", className);
    end
    file = fullfile(location.Folder, className + ".m");
    if exist(file, "file") == 2
        error("LabKit:TestAuthoring:ExistingSpec", ...
            "Refusing to overwrite existing specification: %s.", file);
    end
    if exist(location.Folder, "dir") ~= 7
        mkdir(location.Folder);
    end
    writeTemplate(file, className, location);
    file = string(file);
end

function opts = parseOptions(sourceFile, varargin)
    p = inputParser;
    p.FunctionName = "labkittest.createSpec";
    p.addRequired("SourceFile", @isTextScalar);
    p.addParameter("Contract", "", @isTextScalar);
    p.addParameter("Name", "", @isTextScalar);
    p.addParameter("SpecsRoot", defaultSpecsRoot(), @isFolderPath);
    p.parse(sourceFile, varargin{:});
    opts = p.Results;
    opts.SourceFile = string(opts.SourceFile);
    opts.Contract = lower(strip(string(opts.Contract)));
    opts.Name = string(opts.Name);
    opts.SpecsRoot = string(opts.SpecsRoot);
    if strlength(opts.Contract) == 0 || strlength(opts.Name) == 0
        error("LabKit:TestAuthoring:MissingArgument", ...
            "Contract and Name are required to create a specification.");
    end
end

function writeTemplate(file, className, location)
    methodName = "proves" + erase(className, "Spec");
    source = strjoin([ ...
        "classdef " + className + " < matlab.unittest.TestCase", ...
        "    % " + upper(className) + " Specify " + location.Reason + ".", ...
        "", ...
        "    methods (Test, TestTags = {'Contract:" + location.Contract + ...
            "', 'Env:" + location.Environment + "'})", ...
        "        function " + methodName + "(testCase)", ...
        "            error('LabKit:TestSpec:Unimplemented', ...", ...
        "                'Replace this scaffold with behavioral evidence.');", ...
        "        end", ...
        "    end", ...
        "end"], newline);
    fid = fopen(file, "w", "n", "UTF-8");
    if fid < 0
        error("LabKit:TestAuthoring:Write", ...
            "Could not create specification: %s.", file);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", source);
    clear cleanup
end

function root = defaultSpecsRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fullfile(fileparts(fileparts(packageFolder)), "tests", "specs");
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isFolderPath(value)
    tf = isTextScalar(value) && exist(char(value), "dir") == 7;
end
