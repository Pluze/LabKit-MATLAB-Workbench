function catalog = appCatalog(root)
%APPCATALOG Return the GUI-free catalog shared by launcher consumers.
% ROOT is a checkout or installed LabKit root. Discovery reads App entry and
% definition metadata without opening the Launcher or invoking an App.

apps = labkit.app.internal.discovery.discoverApps(root);
catalog = labkit.app.internal.launcher.appCatalogTable(apps);
end
