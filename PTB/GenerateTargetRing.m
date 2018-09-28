function ring = GenerateTargetRing(outer, inner)

side = floor(outer)*2;

[x,y]=meshgrid(1:side, 1:side);
circleMask = (((x - side/2).^2 + (y - side/2).^2)<=outer^2) & (((x - side/2).^2 + (y - side/2).^2)>inner^2);
ring = ones(side,side,4);
ring(:,:,1) = 0;
ring(:,:,2) = 1;
ring(:,:,3) = 0;
ring(:,:,4) = circleMask;
end
