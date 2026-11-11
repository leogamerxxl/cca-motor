function cale = bloc(mdl, nume, surse, poz, varargin)
%BLOC Adaugă în modelul MDL blocul NUME, încercând pe rând căile din bibliotecă SURSE (șir sau cell),
%   la poziția POZ = [x1 y1 x2 y2], apoi setează parametrii (perechi 'Nume', 'valoare', în ordinea dată –
%   ordinea contează, de ex. la DC Machine: întâi PresetModel, apoi FieldType, apoi valorile).
%   Toate valorile se dau ca șiruri de caractere (num2str(x, 16) – vezi funcția NR).
if ischar(surse), surse = {surse}; end
cale = [mdl '/' nume];
erori = '';
gasit = false;
for q = 1:numel(surse)
    try
        add_block(surse{q}, cale, 'Position', poz);
        gasit = true;
        break;
    catch e
        erori = sprintf('%s\n   %s -> %s', erori, strrep(surse{q}, newline, ' '), e.message);
        try
            delete_block(cale);              % un bloc creat pe jumătate nu trebuie să blocheze varianta următoare
        catch
        end
    end
end
if ~gasit
    error('cca:bloc', 'Blocul "%s" nu a putut fi adăugat. Încercări:%s', nume, erori);
end
for q = 1:2:numel(varargin)
    try
        set_param(cale, varargin{q}, varargin{q + 1});
    catch e
        error('cca:parametru', 'Blocul "%s": %s = "%s" nu a putut fi setat: %s', nume, varargin{q}, ...
              varargin{q + 1}, e.message);
    end
end
end
