function v = min_release(s)

h = storageToLevel(s);

if (h > 117.3)
    q = max_release(s) ;
elseif (h >= 117.0)
    q = (max_release(117.3))/(117.3-117.0)*(h-117.0) ;
else
    q = 0.0;
end
v = q;

end

