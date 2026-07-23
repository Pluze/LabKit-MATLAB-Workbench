function values = publicApps()
%PUBLICAPPS Return path-derived parameter values for every public LabKit App.
%   VALUES = labkittest.publicApps returns a scalar structure whose fields are
%   stable MATLAB parameter labels and whose values describe one public App.
%   Each value has Package, Folder, and RelativeFolder fields. Discovery uses
%   the same public launcher catalog as users and derives the package from the
%   App's single +package/definition.m contract; no App manifest is kept.
%
%   The result is intended for matlab.unittest TestParameter providers. It
%   fails when a public App does not expose exactly one definition package.

    root = labkittest.setup();
    listing = labkit_launcher("list");
    listing = listing(listing.Visibility == "public", :);
    values = struct();
    for k = 1:height(listing)
        relativeEntry = string(listing.RelativePath(k));
        appFolder = fileparts(fullfile(root, char(relativeEntry)));
        definitions = dir(fullfile(appFolder, "+*", "definition.m"));
        if numel(definitions) ~= 1
            error("LabKit:TestCatalog:InvalidAppDefinition", ...
                "Public App %s must expose exactly one +package/definition.m.", ...
                listing.Command(k));
        end
        [packageFolder, packageName] = fileparts(definitions(1).folder);
        packageName = erase(string(packageName), "+");
        relativeFolder = extractAfter(string(appFolder), string(root) + filesep);
        relativeFolder = replace(relativeFolder, filesep, "/");
        label = matlab.lang.makeValidName(char(packageName));
        if isfield(values, label)
            error("LabKit:TestCatalog:DuplicateAppParameter", ...
                "Public App package names must be unique: %s.", packageName);
        end
        values.(label) = struct( ...
            "Package", packageName, ...
            "Folder", string(appFolder), ...
            "RelativeFolder", relativeFolder, ...
            "Entrypoint", string(listing.Command(k)));
        clear packageFolder
    end
    if isempty(fieldnames(values))
        error("LabKit:TestCatalog:NoPublicApps", ...
            "The public launcher catalog contains no Apps.");
    end
end
