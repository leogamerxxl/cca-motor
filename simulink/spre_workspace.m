function spre_workspace(mdl, nume, variabila, poz, decimare)
%SPRE_WORKSPACE Adaugă un bloc To Workspace (format Timeseries) care salvează semnalul în VARIABILA.
L = biblioteci();
bloc(mdl, nume, L.workspace, poz, 'VariableName', variabila, 'SaveFormat', 'Timeseries', ...
     'Decimation', nr(decimare));
end
