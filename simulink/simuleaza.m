function out = simuleaza(mdl)
%SIMULEAZA Rulează modelul; dacă apare o eroare, afișează informații utile pentru diagnostic
%   (de exemplu semnalele disponibile pe magistrala de măsură a unei mașini) și o retransmite.
try
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
catch e
    fprintf(2, '\nEroare la simularea modelului %s:\n%s\n', mdl, e.message);
    sel = find_system(mdl, 'BlockType', 'BusSelector');
    for q = 1:numel(sel)
        try
            set_param(mdl, 'SimulationCommand', 'update');
        catch
        end
        try
            fprintf(2, 'Semnale disponibile la %s: %s\n', sel{q}, strjoin(get_param(sel{q}, 'InputSignals'), ', '));
        catch
        end
    end
    rethrow(e);
end
end
