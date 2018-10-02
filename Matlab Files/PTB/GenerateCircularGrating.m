function final = GenerateCircularGrating(radius, contrast)
gb = imadjust(GenerateGabor(100, pi/4, 64*pi, 0, 1), [0 1], [.5-contrast/2 .5 + contrast/2], .2);
res = size(gb);
side = floor(radius)*2;
gb = imresize(gb, side/res(1));

[x,y]=meshgrid(1:side, 1:side);
circleMask = (((x - side/2).^2 + (y - side/2).^2)>=radius^2);
gb(circleMask) = .5;
final = gb;
end

