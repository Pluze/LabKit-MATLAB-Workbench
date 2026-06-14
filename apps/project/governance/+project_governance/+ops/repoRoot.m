% Expected caller: project_governance app, script wrappers, and tests.
% Output is the LabKit repository root inferred from this app package.
function root = repoRoot()
%REPOROOT Return the LabKit repository root.

    opsFolder = fileparts(mfilename('fullpath'));
    packageFolder = fileparts(opsFolder);
    appFolder = fileparts(packageFolder);
    projectFolder = fileparts(appFolder);
    appsFolder = fileparts(projectFolder);
    root = fileparts(appsFolder);
end
