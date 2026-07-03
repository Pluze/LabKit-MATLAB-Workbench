% App-local LabKit facade requirement declaration.
% Expected caller: public app entrypoint and contract tests. Side effects: none.

function req = requirements()

    req = labkit.contract.requirements( ...
        "ui", ">=4.1 <5", ...
        "dta", ">=2.0 <3");
end
