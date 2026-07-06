% Expected caller: Figure Studio export actions and unit tests. Inputs are a
% scalar axes handle and output folder. Output is a manifest struct with paths
% for plot_data.mat, recreate_plot.m, README.txt, optional plot_data.csv, and
% warnings from unsupported graphics objects.
function manifest = exportAxesPackage(ax, folder)
%EXPORTAXESPACKAGE Export visible axes data and reconstruction code.

    manifest = figure_studio.resultFiles.writeAxesDataExport(ax, folder);
end
