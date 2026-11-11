function s = nr(x)
%NR Valoare numerică -> șir pentru parametrii blocurilor (16 cifre semnificative; vectori ca [a b]).
if isscalar(x)
    s = num2str(x, 16);
else
    s = mat2str(x, 16);
end
end
