-- title:  Platformer Engine
-- author: Morokiane
-- desc:   Platformer Engine to quickly start making a side scrolling platform game
-- script: lua
-- input:  gamepad

--Simplify math operations. Floor will round a decimal.
flr=math.floor
rnd=math.random
cos=math.cos
rad=math.rad
sin=math.sin
max=math.max
min=math.min
del=table.remove

--Variables for the screen area
w,h=240,136
hw,hh=w/2,h/2

indicatorsOn=false
--Setup camera coordinates
cam={
	x=0,
	y=0
}

--[[Sprite table to hold sprite values so they can be called
by an easier name]]
s={
	idle=256,
	run=288,
	jump=264,
	dead=296,
	coin=4,
	thru=2
}
--Collision detectors
--[[These change where the collision detectors are for
the top and sides of a sprite (Bottom can not be changed
from here. The default is every corner and middle of a 
16x16 sprite.]]
coll={
	tlx=3,
	tly=1,
	trx=11,
	try=0
}

--Player variables
p={
	idx=256,
	x=hw,
	y=hh,
	vx=0, --Velocity X
	vy=0, --Velocity Y
	--curv=0, --Current movement velocity
	vmax=1, --Maximum velocity
	grounded=true,
	flp=0
}
--Control variables to make it easier
c={
	u=0,
	d=1,
	l=2,
	r=3,
	z=4,
	x=5,
	a=6,
	s=7,
	mxt=0,
	myt=0
}

t=0
dust={}

function OVR()
	print("FPS: "..fps:getValue(),w-23,0,12,false,1,true)
	print("Indicators: " ..tostring(indicatorsOn),9,0,15,false,1,true)
	print("MaxV: "..flr(p.vy),9,8,15,false,1,true)
	print("Grounded: "..tostring(p.grounded),40,8,15,false,1,true)
	print("x: "..p.x,0,16,15,false,1,true)
	print("y: "..p.y,0,24,15,false,1,true)
	
	if indicatorsOn==true then
		--Collision indicators
		pix(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,6) --top left
		pix(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,6) --top right
		pix(p.x+7+p.vx,p.y+coll.tly+p.vy,15) --top mid
		pix(p.x+8+p.vx,p.y+coll.tly+p.vy,15) --top mid
		pix(p.x+coll.tlx+p.vx,p.y+15+p.vy,6) --bottom left
		pix(p.x+coll.trx+p.vx,p.y+15+p.vy,6) --bottom right
		pix(p.x+7+p.vx,p.y+16+p.vy,7) --bottom mid
		pix(p.x+8+p.vx,p.y+16+p.vy,7) --bottom mid
		--On ground indicators
		pix(p.x+coll.tlx,p.y+16+p.vy,12) --bottom left
		pix(p.x+coll.trx,p.y+16+p.vy,12) --bottom right
		--Middle left indicators
		pix(p.x+coll.tlx+p.vx,p.y+7,8) --left center
		pix(p.x+coll.tlx+p.vx,p.y+8,8) --left center
		--Middle right indicators
		pix(p.x+coll.trx+p.vx,p.y+7,8) --right center
		pix(p.x+coll.trx+p.vx,p.y+8,8) --right center
	end
end

function TIC()
	--[[initial placement of the camera these settings place
	the map tile centered on the screen]]
	cam.x=p.x-120
	--[[Uncomment if needing smooth scrolling on Y along with
	the scrolling in all directions code]]
	--cam.y=p.y-112
	cls(4)
	--
	--map()
	--spr(258,p.x,p.y,0,1,1,0,2,2)
	--Scrolling in all directions
	--map(cam.x//8,cam.y//8,31,18,-(cam.x%8),-(cam.y%8),0)
	--spr(258,p.x-cam.x,p.y-cam.y,0,1,1,0,2,2)
	
	--Scrolling only along X but loading full map grid on Y
	map(cam.x//8,(p.y//136)*17,31,18,-(cam.x%8),-(cam.y%8),0)
	spr(p.idx,p.x-cam.x,p.y%136,5,1,p.flp,0,2,2)
	--[[Collison pix for 8x8 sprite
	pix(p.x,p.y-1,2)
	pix(p.x+15,p.y-1,2)
	
	pix(p.x,p.y+8,2)
	pix(p.x+7,p.y+8,2)
	
	pix(p.x-1,p.y,2)
	pix(p.x-1,p.y+7,2)
	
	pix(p.x+8,p.y,2)
	pix(p.x+8,p.y+7,2)]]
	if btnp(c.a) and indicatorsOn==false then
		indicatorsOn=true
	elseif btnp(c.a) and indicatorsOn==true then
		indicatorsOn=false
	end
	Update()
	--t=time()//20
end

function Update()
	Controller()
	Mouse()
	Collectiables()
end


function Mouse()
	mx,my,ml,mm,mr = mouse()
	c.mxt=mx//8
	c.myt=my//8	
		if ml then 
			n.x=mx
			n.y=my
		end
	spr(16,mx,my,0)
end

function Controller()
	if btn(c.l) then
		p.vx=-p.vmax
		if p.grounded then
			p.idx=s.run+t%80//10*2
			t=time()//5
		end
		p.flp=0
	elseif btn(c.r) then 
		p.vx=p.vmax
		if p.grounded then
			p.idx=s.run+t%80//10*2
			t=time()//5
		end
		p.flp=1
		--t=time()//5
	else
		p.vx=0
		p.idx=s.idle+t%40//10*2
		t=time()//30
		--p.curv=0
	end
	
	if solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy) or 
				solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy) or
				solid(p.x+coll.tlx+p.vx,p.y+15+p.vy) or 
				solid(p.x+coll.trx+p.vx,p.y+15+p.vy) or
				solid(p.x+coll.tlx+p.vx,p.y+7) or
				solid(p.x+coll.tlx+p.vx,p.y+8) or
				solid(p.x+coll.trx+p.vx,p.y+7) or
				solid(p.x+coll.trx+p.vx,p.y+8) then
		p.vx=0
	end
	--checks if you are on the ground
	if solid(p.x+coll.tlx,p.y+16+p.vy) or
				solid(p.x+coll.trx,p.y+16+p.vy) or
				solid(p.x+7+p.vx,p.y+16+p.vy) or
				solid(p.x+8+p.vx,p.y+16+p.vy) or
				hsolid(p.x+coll.tlx,p.y+16+p.vy) or
				hsolid(p.x+coll.trx,p.y+16+p.vy) or
				hsolid(p.x+7+p.vx,p.y+16+p.vy) or
				hsolid(p.x+8+p.vx,p.y+16+p.vy) then
		p.vy=0
		p.grounded=true
	else
		p.vy=p.vy+0.2
	end
	
	if p.vy==0 and btnp(c.z) then 
		p.vy=-3
		p.idx=s.jump
		p.grounded=false
	end
	--check if something is above
	if p.vy<0 and (solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy) or 
																solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy) or
																solid(p.x+7+p.vx,p.y+coll.tly+p.vy) or 
																solid(p.x+8+p.vx,p.y+coll.tly+p.vy)) then
		p.vy=0
	end
	
	--[[if the sprite is tile 2 and has flag 2 either set
	as true or false]]
	if p.grounded==true then
		fset(s.thru,2,true)
	else
		fset(s.thru,2,false)
	end

	--[[if p.curv<p.vmax then
		p.x=p.x+p.curv
	elseif p.curv>1 then
		--p.curv=p.maxv
		p.x=p.x+p.vx
	end]]
	p.x=p.x+p.vx
	p.y=p.y+p.vy
end

function Collectiables()
	--[[Collisions with collectibles can be done either with
	flags set on the sprites, or by looking for the actual
	sprite itself.]] 
	if fget(mget(p.x/8+1,p.y/8+1),1) then
	--if mget(p.x/8+1,p.y/8+1)==s.coin then
		mset(p.x/8+1,p.y/8+1,0)
		--sfx(01,'E-6',5)
	end
end

function solid(x,y)
	return fget(mget(flr(x//8),flr(y//8)),0)
end

function hsolid(x,y)
	return fget(mget(flr(x//8),flr(y//8)),2)
end

FPS={}

function FPS:new(o)
	o=o or {}
	setmetatable(o,self)
	self.__index=self
	self.value=0
	self.frames=0
	self.lastTime=0
	return FPS
end

function FPS:getValue()
	if (time()-self.lastTime<=1000) then
		self.frames=self.frames+1
	else
		self.value=self.frames
		self.frames=0
		self.lastTime=time()
	end
	return self.value
end

fps=FPS:new()
-- <TILES>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333300000000000000000000000000000000000000000001111011111111
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:4433334443222234323333223333333233333332133333314133331444111144
-- 005:00000000000000000aaaaaa0aaaaaa3333333333033333300000000000000000
-- 006:000a3000000a3000000a3000000a3000000a3000000a3000000a3000000a3000
-- 016:f0000000ff000000fff00000ffff0000fffff000ff00000000f0000000000000
-- </TILES>

-- <SPRITES>
-- 000:5555555555512222555513335555144455511444555122225555122255551222
-- 001:5555555522221555324211554222321522212315222123152231311522131115
-- 002:5555555555555555555122225555133355551444555114445551222255551222
-- 003:5555555555555555222215553242115542213215222123152231231522133115
-- 004:5555555555555555555122225555133355551444555114445551222255551222
-- 005:5555555555555555222215553242115542213215222123152231231522133115
-- 006:5555555555555555555122225555133355551444555114445551222255551222
-- 007:5555555555555555222211553242321542212315222123152231311522131115
-- 008:5555555555555555555122225555133355551444555114445551222255551222
-- 009:5555555555555555222215553242115542213215222123152231231522133115
-- 010:5555555555555555555555555551222255551333555514445551144455512222
-- 011:5555555555555555555555552222155532421155422132152221231522312315
-- 012:5555555555555555555555555555555555512223555513335555144455551442
-- 013:5555555555555555555555555555555532421155422132152221231522212315
-- 014:5555555555555555555555555555555555555555555555555511155551222111
-- 015:5555555555555555555555555555555555555555555555551111555533111155
-- 016:5551122355131233551331115551132255551111555512215555113155555111
-- 017:3111211531412215144111553311555511115555122155551131555511115555
-- 018:5551122355131233551331115551132255551111555512215555113155555111
-- 019:3111111531412115144122153311115511115555122155551131555511115555
-- 020:5555122355511233551311115513332255511111555512215555113155555111
-- 021:3111111531112115114122153441115511115555122155551131555511115555
-- 022:5551122355131233551331115551132255551111555512215555113155555111
-- 023:3111211531412215144111553311555511115555122155551131555511115555
-- 024:5555122255551222555141115551422255551111555551235555511155555555
-- 025:2111111521412115114122152211115511115555122155551113155555111555
-- 026:5555122255551222555511225555511155555122555551115555551355555551
-- 027:2213311521111115214121151141221522111155111155551221555511115555
-- 028:5555122255551222555112225551412255511411555511125555555155555555
-- 029:2231311522131115211121152141221511411155222115553113155511111555
-- 030:5222422152222221522234215233344252344442523444225211111251555551
-- 031:2231221512232215412111151412231521121155221213152212211511111555
-- 032:5555555555512222555513335555144451111444513322225133122255111223
-- 033:5555555522221555324211554222121522212315222123152231311533313115
-- 034:5555555555512222555513335555144451111444513322225133122255111223
-- 035:5555555522221555324211554222121522212315222123152231311533313115
-- 036:5555555555512222555513335555144455511444555122225511122255131223
-- 037:5555555522221555324211554222121522212315222123152231311533312115
-- 038:5551222255551333555514445551144455512222555512225555122255551223
-- 039:2222155532421555422215552221115522213215223123152311231533133115
-- 040:5551222255551333555514445551144455512222555512225555122255551223
-- 041:2222155532421555422215552221115522213215223123152311231533133115
-- 042:5551222255551333555514445551144455512222555512225555122255551223
-- 043:2222155532421555422215552221115522213215223123152311231533133115
-- 044:5551222255551333555514445551144455512222555512225555122255551223
-- 045:2222155532421555422215552221115522213215223123152311231533133115
-- 046:5555555555512222555513335555144455511444555122225511122255131223
-- 047:5555555522221555324211554222121522212315222123152231311533312115
-- 048:5555122355551233555511115555132255551111555512315555511155555555
-- 049:3331211532144215112341553311155511115555122155551131555551115555
-- 050:5555122355551233555511115555132255551111555512315555511155555555
-- 051:3331211532144215112341553311155511115555122155551131555551115555
-- 052:5512122355511233555121115555132255551111555511235555511155555555
-- 053:3333111533244215111441553311155511111555112215555113155555111555
-- 054:5511122355131233555121115555132255551111555512215555113155555115
-- 055:3311111534412115144222153311115511111555552315555111155555555555
-- 056:5555122355511233555121115555132255551111555512215555131155551115
-- 057:4411111544212115111222153311115511111555512315555111155555555555
-- 058:5555122355511233555121115555132255551111555512215555131155551115
-- 059:4411111544212115111222153311115511111555512315555111155555555555
-- 060:5511122355131233555121115555132255551111555512215555113155555115
-- 061:3311111534412115144222153311115511111555512315555111155555555555
-- 062:5512122355511233555121115555132255551111555511235555511155555555
-- 063:3333111533244215111441553311155511111555112215555113155555111555
-- 064:5555555555555555555555555555555555555555555555555555555555555555
-- 065:5555555555555555555555555555555555555555555555555555555555555555
-- 066:5555555555555555555555555555555555555555555555555555555555555555
-- 067:5555555555555555555555555555555555555555555555555555555555555555
-- 068:5555555555555555555555555555555555555555555555555555555555555555
-- 069:5555555555555555555555555555555555555555555555555555555555555555
-- 070:5555555555555555555555555555555555555555555555555555555555555555
-- 071:5555555555555555555555555555555555555555555555555555555555555555
-- 072:5555555555555555555555555555555555555555555555555555555555555555
-- 073:5555555555555555555555555555555555555555555555555555555555555555
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:5555555555555555555555555555555555555555555555555555555555555555
-- 077:5555555555555555555555555555555555555555555555555555555555555555
-- 078:5555555555555555555555555555555555555555555555555555555555555555
-- 079:5555555555555555555555555555555555555555555555555555555555555555
-- 080:5555555555555555555555555555555555555555555555555555555555555555
-- 081:5555555555555555555555555555555555555555555555555555555555555555
-- 082:5555555555555555555555555555555555555555555555555555555555555555
-- 083:5555555555555555555555555555555555555555555555555555555555555555
-- 084:5555555555555555555555555555555555555555555555555555555555555555
-- 085:5555555555555555555555555555555555555555555555555555555555555555
-- 086:5555555555555555555555555555555555555555555555555555555555555555
-- 087:5555555555555555555555555555555555555555555555555555555555555555
-- 088:5555555555555555555555555555555555555555555555555555555555555555
-- 089:5555555555555555555555555555555555555555555555555555555555555555
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:5555555555555555555555555555555555555555555555555555555555555555
-- 093:5555555555555555555555555555555555555555555555555555555555555555
-- 094:5555555555555555555555555555555555555555555555555555555555555555
-- 095:5555555555555555555555555555555555555555555555555555555555555555
-- 096:5555555555555555555555555555555555555555555555555555555555555555
-- 097:5555555555555555555555555555555555555555555555555555555555555555
-- 098:5555555555555555555555555555555555555555555555555555555555555555
-- 099:5555555555555555555555555555555555555555555555555555555555555555
-- 100:5555555555555555555555555555555555555555555555555555555555555555
-- 101:5555555555555555555555555555555555555555555555555555555555555555
-- 102:5555555555555555555555555555555555555555555555555555555555555555
-- 103:5555555555555555555555555555555555555555555555555555555555555555
-- 104:5555555555555555555555555555555555555555555555555555555555555555
-- 105:5555555555555555555555555555555555555555555555555555555555555555
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:5555555555555555555555555555555555555555555555555555555555555555
-- 109:5555555555555555555555555555555555555555555555555555555555555555
-- 110:5555555555555555555555555555555555555555555555555555555555555555
-- 111:5555555555555555555555555555555555555555555555555555555555555555
-- 112:5555555555555555555555555555555555555555555555555555555555555555
-- 113:5555555555555555555555555555555555555555555555555555555555555555
-- 114:5555555555555555555555555555555555555555555555555555555555555555
-- 115:5555555555555555555555555555555555555555555555555555555555555555
-- 116:5555555555555555555555555555555555555555555555555555555555555555
-- 117:5555555555555555555555555555555555555555555555555555555555555555
-- 118:5555555555555555555555555555555555555555555555555555555555555555
-- 119:5555555555555555555555555555555555555555555555555555555555555555
-- 120:5555555555555555555555555555555555555555555555555555555555555555
-- 121:5555555555555555555555555555555555555555555555555555555555555555
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:5555555555555555555555555555555555555555555555555555555555555555
-- 125:5555555555555555555555555555555555555555555555555555555555555555
-- 126:5555555555555555555555555555555555555555555555555555555555555555
-- 127:5555555555555555555555555555555555555555555555555555555555555555
-- 128:5555555555555555555555555555555555555555555555555555555555555555
-- 129:5555555555555555555555555555555555555555555555555555555555555555
-- 130:5555555555555555555555555555555555555555555555555555555555555555
-- 131:5555555555555555555555555555555555555555555555555555555555555555
-- 132:5555555555555555555555555555555555555555555555555555555555555555
-- 133:5555555555555555555555555555555555555555555555555555555555555555
-- 134:5555555555555555555555555555555555555555555555555555555555555555
-- 135:5555555555555555555555555555555555555555555555555555555555555555
-- 136:5555555555555555555555555555555555555555555555555555555555555555
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:5555555555555555555555555555555555555555555555555555555555555555
-- 139:5555555555555555555555555555555555555555555555555555555555555555
-- 140:5555555555555555555555555555555555555555555555555555555555555555
-- 141:5555555555555555555555555555555555555555555555555555555555555555
-- 142:5555555555555555555555555555555555555555555555555555555555555555
-- 143:5555555555555555555555555555555555555555555555555555555555555555
-- 144:5555555555555555555555555555555555555555555555555555555555555555
-- 145:5555555555555555555555555555555555555555555555555555555555555555
-- 146:5555555555555555555555555555555555555555555555555555555555555555
-- 147:5555555555555555555555555555555555555555555555555555555555555555
-- 148:5555555555555555555555555555555555555555555555555555555555555555
-- 149:5555555555555555555555555555555555555555555555555555555555555555
-- 150:5555555555555555555555555555555555555555555555555555555555555555
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:5555555555555555555555555555555555555555555555555555555555555555
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:5555555555555555555555555555555555555555555555555555555555555555
-- 155:5555555555555555555555555555555555555555555555555555555555555555
-- 156:5555555555555555555555555555555555555555555555555555555555555555
-- 157:5555555555555555555555555555555555555555555555555555555555555555
-- 158:5555555555555555555555555555555555555555555555555555555555555555
-- 159:5555555555555555555555555555555555555555555555555555555555555555
-- 160:5555555555555555555555555555555555555555555555555555555555555555
-- 161:5555555555555555555555555555555555555555555555555555555555555555
-- 162:5555555555555555555555555555555555555555555555555555555555555555
-- 163:5555555555555555555555555555555555555555555555555555555555555555
-- 164:5555555555555555555555555555555555555555555555555555555555555555
-- 165:5555555555555555555555555555555555555555555555555555555555555555
-- 166:5555555555555555555555555555555555555555555555555555555555555555
-- 167:5555555555555555555555555555555555555555555555555555555555555555
-- 168:5555555555555555555555555555555555555555555555555555555555555555
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:5555555555555555555555555555555555555555555555555555555555555555
-- 171:5555555555555555555555555555555555555555555555555555555555555555
-- 172:5555555555555555555555555555555555555555555555555555555555555555
-- 173:5555555555555555555555555555555555555555555555555555555555555555
-- 174:5555555555555555555555555555555555555555555555555555555555555555
-- 175:5555555555555555555555555555555555555555555555555555555555555555
-- 176:5555555555555555555555555555555555555555555555555555555555555555
-- 177:5555555555555555555555555555555555555555555555555555555555555555
-- 178:5555555555555555555555555555555555555555555555555555555555555555
-- 179:5555555555555555555555555555555555555555555555555555555555555555
-- 180:5555555555555555555555555555555555555555555555555555555555555555
-- 181:5555555555555555555555555555555555555555555555555555555555555555
-- 182:5555555555555555555555555555555555555555555555555555555555555555
-- 183:5555555555555555555555555555555555555555555555555555555555555555
-- 184:5555555555555555555555555555555555555555555555555555555555555555
-- 185:5555555555555555555555555555555555555555555555555555555555555555
-- 186:5555555555555555555555555555555555555555555555555555555555555555
-- 187:5555555555555555555555555555555555555555555555555555555555555555
-- 188:5555555555555555555555555555555555555555555555555555555555555555
-- 189:5555555555555555555555555555555555555555555555555555555555555555
-- 190:5555555555555555555555555555555555555555555555555555555555555555
-- 191:5555555555555555555555555555555555555555555555555555555555555555
-- 192:5555555555555555555555555555555555555555555555555555555555555555
-- 193:5555555555555555555555555555555555555555555555555555555555555555
-- 194:5555555555555555555555555555555555555555555555555555555555555555
-- 195:5555555555555555555555555555555555555555555555555555555555555555
-- 196:5555555555555555555555555555555555555555555555555555555555555555
-- 197:5555555555555555555555555555555555555555555555555555555555555555
-- 198:5555555555555555555555555555555555555555555555555555555555555555
-- 199:5555555555555555555555555555555555555555555555555555555555555555
-- 200:5555555555555555555555555555555555555555555555555555555555555555
-- 201:5555555555555555555555555555555555555555555555555555555555555555
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 206:5555555555555555555555555555555555555555555555555555555555555555
-- 207:5555555555555555555555555555555555555555555555555555555555555555
-- 208:5555555555555555555555555555555555555555555555555555555555555555
-- 209:5555555555555555555555555555555555555555555555555555555555555555
-- 210:5555555555555555555555555555555555555555555555555555555555555555
-- 211:5555555555555555555555555555555555555555555555555555555555555555
-- 212:5555555555555555555555555555555555555555555555555555555555555555
-- 213:5555555555555555555555555555555555555555555555555555555555555555
-- 214:5555555555555555555555555555555555555555555555555555555555555555
-- 215:5555555555555555555555555555555555555555555555555555555555555555
-- 216:5555555555555555555555555555555555555555555555555555555555555555
-- 217:5555555555555555555555555555555555555555555555555555555555555555
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
-- 222:5555555555555555555555555555555555555555555555555555555555555555
-- 223:5555555555555555555555555555555555555555555555555555555555555555
-- 224:5555555555555555555555555555555555555555555555555555555555555555
-- 225:5555555555555555555555555555555555555555555555555555555555555555
-- 226:5555555555555555555555555555555555555555555555555555555555555555
-- 227:5555555555555555555555555555555555555555555555555555555555555555
-- 228:5555555555555555555555555555555555555555555555555555555555555555
-- 229:5555555555555555555555555555555555555555555555555555555555555555
-- 230:5555555555555555555555555555555555555555555555555555555555555555
-- 231:5555555555555555555555555555555555555555555555555555555555555555
-- 232:5555555555555555555555555555555555555555555555555555555555555555
-- 233:5555555555555555555555555555555555555555555555555555555555555555
-- 234:5555555555555555555555555555555555555555555555555555555555555555
-- 235:5555555555555555555555555555555555555555555555555555555555555555
-- 236:5555555555555555555555555555555555555555555555555555555555555555
-- 237:5555555555555555555555555555555555555555555555555555555555555555
-- 238:5555555555555555555555555555555555555555555555555555555555555555
-- 239:5555555555555555555555555555555555555555555555555555555555555555
-- 240:5555555555555555555555555555555555555555555555555555555555555555
-- 241:5555555555555555555555555555555555555555555555555555555555555555
-- 242:5555555555555555555555555555555555555555555555555555555555555555
-- 243:5555555555555555555555555555555555555555555555555555555555555555
-- 244:5555555555555555555555555555555555555555555555555555555555555555
-- 245:5555555555555555555555555555555555555555555555555555555555555555
-- 246:5555555555555555555555555555555555555555555555555555555555555555
-- 247:5555555555555555555555555555555555555555555555555555555555555555
-- 248:5555555555555555555555555555555555555555555555555555555555555555
-- 249:5555555555555555555555555555555555555555555555555555555555555555
-- 250:5555555555555555555555555555555555555555555555555555555555555555
-- 251:5555555555555555555555555555555555555555555555555555555555555555
-- 252:5555555555555555555555555555555555555555555555555555555555555555
-- 253:5555555555555555555555555555555555555555555555555555555555555555
-- 254:5555555555555555555555555555555555555555555555555555555555555555
-- 255:5555555555555555555555555555555555555555555555555555555555555555
-- </SPRITES>

-- <MAP>
-- 000:300000000000000000000000000000000000000000000000000000000030300000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:101010100000000010000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000100000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000010000000000000000000000000001010100000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000001000000000000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000100000000000000000000000000000001000000000000000000000000000101010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000010101010100000000000000000000010101000000000000000000000101010000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000000000000101010100000000000101010100000000000000000000000000000000000000000000000000000000000001010100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:001010101010000000000000000010000000000000000000101010101000000000000000000000000000000000000000001000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:000000000000000000000000000010000000000040000000000000000000000000000000000000000000000000001010001000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:301010101010101010101010101010101010101010101010101010101030301010101010101010101010101010101010101000000000001010000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000001000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:000000000000000000000000000000000000000000000000000000000000300000000000001010101010101010101010101010000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000000000000000000000000000000000000000000300000001010101010101010101010101010101010100000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <FLAGS>
-- 000:00104000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f04002038b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE>

