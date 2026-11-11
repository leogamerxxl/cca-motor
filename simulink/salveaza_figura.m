function salveaza_figura(fig, fisier)
%SALVEAZA_FIGURA Salvează figura ca PNG (exportgraphics din R2020a, altfel saveas) și o închide.
try
    exportgraphics(fig, fisier, 'Resolution', 150);
catch
    saveas(fig, fisier);
end
close(fig);
end
