-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

inv={}
store={}
sNum=0
blah=false

function OVR()
	for counter=1,#inv do
		print(inv[counter],0,(counter*8),12)
	end
	switch(action,
  case(inv[1], function() spr(0,0,0)  end),
  case(inv[2], function() spr(1,8,0)  end),
  case(inv[3], function() spr(2,16,0) end),
		case(inv[4], function() spr(3,24,0) end),
		case(inv[5], function() spr(4,32,0) end),
		case(inv[6], function() spr(5,40,0) end),
  default( function() print("end") 			end)
 )
end

function TIC()
	cls()
	if btnp(0) then
		table.insert(inv,sNum)
		sNum=sNum+1
	end
	if btnp(1) then
		table.remove(inv,1)
		sNum=sNum-1
	end
end

function switch(n,...)
	for _,v in ipairs{...} do
		if v[1]==n or v[1]==nil then
			return v[2]()
		end
	end
end

function case(n,f)
	return{n,f}
end

function default(f)
	return{nil,f}
end
-- <TILES>
-- 000:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 001:2222222222222222222222222222222222222222222222222222222222222222
-- 002:3333333333333333333333333333333333333333333333333333333333333333
-- 003:4444444444444444444444444444444444444444444444444444444444444444
-- 004:5555555555555555555555555555555555555555555555555555555555555555
-- 005:6666666666666666666666666666666666666666666666666666666666666666
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

