function page = documentationPage(root, command, source)
%DOCUMENTATIONPAGE Resolve one public App's online or generated local page.
apps = labkit.app.internal.launcher.discoverApps(root);
match = find(string({apps.command}) == string(command), 1);
if isempty(match) || apps(match).visibility ~= "public"
    error("labkit:app:internal:launcher:DocumentationUnavailable", ...
        "No public documentation page is available for %s.", command);
end
[~, appId] = fileparts(apps(match).folder);
appId = replace(string(appId), "_", "-");
manuals = dir(fullfile(root, "docs", "apps", "*", appId, "README.md"));
if numel(manuals) ~= 1
    error("labkit:app:internal:launcher:DocumentationUnavailable", ...
        "No documentation source is available for %s.", command);
end
[~, family] = fileparts(fileparts(manuals(1).folder));
if source == "online"
    page = "https://pluze.github.io/LabKit-MATLAB-Workbench/apps/" + ...
        family + "/" + appId + ".html";
    return;
end
page = string(fullfile(root, "site", "apps", family, appId + ".html"));
if exist(page, "file") ~= 2
    error("labkit:app:internal:launcher:LocalDocumentationMissing", ...
        "Local documentation has not been generated for %s.", command);
end
end
