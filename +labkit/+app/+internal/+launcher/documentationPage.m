function page = documentationPage(root, command, source)
%DOCUMENTATIONPAGE Resolve one public App's online or generated local page.
apps = labkit.app.internal.discovery.discoverApps(root);
match = find(string({apps.command}) == string(command), 1);
if isempty(match) || apps(match).visibility ~= "public"
    error("labkit:app:internal:launcher:DocumentationUnavailable", ...
        "No public documentation page is available for %s.", command);
end
[~, appId] = fileparts(apps(match).folder);
appId = replace(string(appId), "_", "-");
manuals = dir(fullfile(root, "docs", "use", "apps", "*", appId, "README.md"));
if numel(manuals) ~= 1
    error("labkit:app:internal:launcher:DocumentationUnavailable", ...
        "No documentation source is available for %s.", command);
end
[~, family] = fileparts(fileparts(manuals(1).folder));
route = labkit.app.internal.launcher.documentationRoute(family, appId);
if source == "online"
    page = "https://pluze.github.io/LabKit-MATLAB-Workbench/" + ...
        erase(route, "index.html");
    return;
end
page = string(fullfile(root, "site", ...
    replace(route, "/", string(filesep))));
if exist(page, "file") ~= 2
    error("labkit:app:internal:launcher:LocalDocumentationMissing", ...
        "Local documentation has not been generated for %s.", command);
end
end
