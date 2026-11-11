%% Rulează P5-P6 și salvează rezultatele numerice în ../rezultate/rezultate_matlab.json
% (comparate cu implementarea Python: python/calcule_p5p6.py)

grafice_implicit = ~exist('GRAFICE', 'var');
if grafice_implicit, GRAFICE = false; end
main_p5p6;
if grafice_implicit, clear GRAFICE; end

iesire = struct();
iesire.dcdc = D;
iesire.chopper = H;
iesire.incarcator = Ci;
iesire.incarcare_medie = rmfield(Im, {'t', 'I', 'U', 'SOC', 'P_bat', 'P_AC'});
iesire.incarcare_comutatie = rmfield(Ic, {'t', 'I', 'U', 'Iref', 's'});
iesire.dcdc_comutatie = rmfield(Dc, {'t', 'IL', 'UDC', 'IB', 'UB', 'D', 'P'});
aici = fileparts(mfilename('fullpath'));
f = fopen(fullfile(aici, '..', 'rezultate', 'rezultate_matlab.json'), 'w');
fprintf(f, '%s', jsonencode(iesire));
fclose(f);
fprintf('\nRezultate salvate în rezultate/rezultate_matlab.json\n');
