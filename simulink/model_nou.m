function mdl = model_nou(mdl)
%MODEL_NOU Creează un model Simulink gol cu numele MDL (închide fără salvare o versiune deja încărcată).
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);
if usejava('desktop'), open_system(mdl); end
end
