function cel = celula_aleasa()
%CELULA_ALEASA Parametrii celulei Li-ion alese (citiți din ../date/celula_aleasa.json).
%   Celula: Molicel INR-21700-P50B – fișa tehnică oficială v1.1 (sursa în JSON).
aici = fileparts(mfilename('fullpath'));
txt = fileread(fullfile(aici, '..', 'date', 'celula_aleasa.json'));
cel = jsondecode(txt);
end
