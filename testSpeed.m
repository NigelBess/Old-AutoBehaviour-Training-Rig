renderer = Renderer();
lastFrameTime = GetSecs();
vel = 100;
pos = renderer.InitPos(0);
pos = renderer.ToLeft();
while true
     pos = movePos(pos,vel*(GetSecs()-lastFrameTime));
     lastFrameTime = GetSecs();
      renderer.NewFrame(pos);
     
end




function out = movePos(original, offset)
    out = original;
    out = out + [offset, 0, offset, 0];
end