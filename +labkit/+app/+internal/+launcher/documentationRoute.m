function route = documentationRoute(family, appId)
%DOCUMENTATIONROUTE Return the canonical generated route for one App guide.
% Expected callers: documentationPage and the documentation renderer.
% Inputs are trusted path-derived family and App identifiers.
family = string(family);
appId = string(appId);
if ~isscalar(family) || ~isscalar(appId) || ...
        isempty(regexp(char(family), '^[a-z0-9]+(?:[-_][a-z0-9]+)*$', 'once')) || ...
        isempty(regexp(char(appId), '^[a-z0-9]+(?:[-_][a-z0-9]+)*$', 'once'))
    error("labkit:app:internal:launcher:InvalidDocumentationRoute", ...
        "Documentation routes require lowercase path-safe family and App identifiers.");
end
route = "use/apps/" + family + "/" + appId + "/index.html";
end
