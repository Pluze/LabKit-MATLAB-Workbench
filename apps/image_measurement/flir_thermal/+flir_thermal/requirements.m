% App-local LabKit facade requirement declaration.
% Expected caller: public app entrypoint and contract tests. Side effects: none.

function req = requirements()

    req = labkit.contract.requirements("ui", ">=7 <8", ...
        "image", ">=2.0 <3", ...
        "thermal", ">=1.1 <2");
end
