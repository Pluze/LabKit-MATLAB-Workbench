function pack = generateSyntheticInputs(definition, rootFolder)
%GENERATESYNTHETICINPUTS Materialize an App's declared synthetic test pack.
%   PACK = labkittest.generateSyntheticInputs(DEFINITION, ROOTFOLDER) is the
%   stable test-only seam for public and accepted private App specifications.
%   Production Apps declare BuildSyntheticSample on their Definition and do
%   not call SDK internal generators directly.
%
%   DEFINITION must be one labkit.app.Definition. ROOTFOLDER is a nonempty
%   caller-owned scratch directory. PACK is a labkit.app.synthetic.Pack.

arguments
    definition (1, 1) labkit.app.Definition
    rootFolder (1, 1) string
end

if strlength(rootFolder) == 0
    error("LabKit:TestSyntheticInputs:InvalidRoot", ...
        "Synthetic input generation requires a nonempty scratch root.");
end

pack = labkit.app.internal.source.SyntheticInputGenerator.generate( ...
    definition, rootFolder);
end
