-- title:  Alchemy Courier
-- author: Blind Seer Studios
-- desc:   Courier dangerous potions
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
rand=math.random
del=table.remove

dc=7

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
	x=120, --was hw
	y=112,	--was hh
	vx=0, --Velocity X
	vy=0, --Velocity Y
	--curv=0, --Current movement velocity
	vmax=1, --Maximum velocity
	grounded=true,
	flp=0,
	type="player",
	curLife=2,
	maxLife=3,
	coins=00,
	stab=51,
	stabpot=3,
	s={
		idle=256,
		run=288,
		jump=264,
		fall=320,
		dead=270,
		thru=2,
		duck=322
	},
	cpX=0,
	cpY=0,
	cpF=0,
	canMove=true,
	ducking=false,
	damaged=false
}

e={
	idx=416,
	x=0,
	y=0,
	vx=0,
	vy=0,
	l=true
}

s={
	coin=240,
	check=224,
	checkact=225,
	pit=5,
	heart=244
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

spawns={
	[160]=416,
	--[240]=432
}
--Tile map for ent replace
m={
	x=0,
	y=0
}

tileAnims={
	[240]={s=.1,f=4},
	[432]={s=.1,f=4},
	[244]={s=.05,f=5}
}

t=0
ti=0 --ti is time for the animated tiles

pit=false
meterY=16

quest={}
store={}
sNum=0
timer=0
mapStart=0
mapEnd=472 --Change this to what the end of the map will be (this will depend on level)

screenShake=false

screenShake={
	active=false,
	defaultDuration=15,
	duration=15,
	power=3
}

function Init()
	p.cpX=p.x
	p.cpY=p.y
	ents={}
	EntLocations()
end

function OVR()
	HUD()
	Debug()
	Mouse()
end

function HUD()
	--BG Rectangles
	rect(1,1,15,77,4)
	rect(15,1,65,14,4)
	--HUD border
	line(15,15,15,78,1)
	line(0,78,14,78,1)
	line(16,15,79,15,1)
	line(80,0,80,15,1)
	line(0,0,79,0,1)
	line(0,0,0,77,1)
	--Coin
	spr(449,30,4,0)
	print(string.format("x%02d",p.coins),39,6,1,true,1,false)
	--Potion
	rect(7,meterY,2,p.stab,2)
	spr(453,4,68,0)
	line(7,15,8,15,1)
	line(6,16,6,65,1)
	line(9,16,9,65,1)
	line(7,66,8,66,1)
	--Hearts
	for num=1,p.maxLife do
		spr(452,-4+8*num,4,0)
	end
	
	for num=1,p.curLife do
		spr(451,-4+8*num,4,0)
	end
	--Stabilizer
	spr(454,58,4,0)
	print("x"..p.stabpot,66,6,1,true,1,false)
	
	--[[y needs to be changed to go off of the players location
	based on map grids]]
	--[[if p.y<64 then
		rect(0,128,w,10,7)
	elseif p.y>64 then
		rect(0,0,w,10,7)
	end]]
end

function Debug()
	if indicatorsOn==true then
		print("FPS: "..fps:getValue(),w-24,0,dc,false,1,true)
		print("Indicators: " ..tostring(indicatorsOn),1,0,dc,false,1,true)
		print("MaxV: "..flr(p.vy),1,8,dc,false,1,true)
		print("Grounded: "..tostring(p.grounded),40,8,dc,false,1,true)
		print("Life: "..p.curLife,40,16,dc,false,1,true)
		print("Move: "..tostring(p.canMove),40,24,dc,false,1,true)
		print("X: "..p.x,1,16,dc,false,1,true)
		print("Y: "..p.y,1,24,dc,false,1,true)
		print("Check X: "..p.cpX,1,32,dc,false,1,true)
		print("Check Y: "..p.cpY,1,40,dc,false,1,true)
		print("Pit: "..tostring(pit),1,48,dc,false,1,true)
		print("Fall: "..p.vy,1,56,dc,false,1,true)
		print("Dmgd: "..tostring(p.damaged),1,64,dc,false,1,true)
		print("Timer: "..timer,1,72,dc,false,1,true)
		
		--Collision indicators
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+coll.tly+p.vy,6) --top left
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+coll.tly+p.vy,6) --top right
		pix(p.x+7+p.vx-cam.x,p.y%136+coll.tly+p.vy,15) --top mid
		pix(p.x+8+p.vx-cam.x,p.y%136+coll.tly+p.vy,15) --top mid
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+15+p.vy,6) --bottom left
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+15+p.vy,6) --bottom right
		pix(p.x+7+p.vx-cam.x,p.y%136+16+p.vy,7) --bottom mid
		pix(p.x+8+p.vx-cam.x,p.y%136+16+p.vy,7) --bottom mid
		--On ground indicators
		pix(p.x+coll.tlx-cam.x,p.y%136+16+p.vy,12) --bottom left
		pix(p.x+coll.trx-cam.x,p.y%136+16+p.vy,12) --bottom right
		--Middle left indicators
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+7,8) --left center
		pix(p.x+coll.tlx+p.vx-cam.x,p.y%136+8,8) --left center
		--Middle right indicators
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+7,8) --right center
		pix(p.x+coll.trx+p.vx-cam.x,p.y%136+8,8) --right center
	end
end

function TIC()
	cls(4)
	--[[initial placement of the camera these settings place
	the map tile centered on the screen]]
	cam.x=p.x-120
	--[[Uncomment if needing smooth scrolling on Y along with
	the scrolling in all directions code]]
	--cam.y=p.y-112

	if cam.x<mapStart then
		cam.x=mapStart
	end
	if cam.x>mapEnd-232 then
		cam.x=mapEnd-232
	end
	--Scrolling only along X but loading full map grid on Y
	map(cam.x//8,(p.y//136)*17,31,18,-(cam.x%8),-(cam.y%8),0,1,remap)
	if p.damaged then
		if (time()%300>200) then 
 		spr(p.idx,p.x-cam.x,p.y%136,0,1,p.flp,0,2,2)
  end
 else
 	spr(p.idx,p.x-cam.x,p.y%136,0,1,p.flp,0,2,2)
 end
 
	if keyp(9) and indicatorsOn==false then
		indicatorsOn=true
	elseif keyp(9) and indicatorsOn==true then
		indicatorsOn=false
	end
	
	if btnp(0) then
		table.insert(quest,sNum)
		sNum=sNum+1
		flag=1
	end
	if btnp(1) then
		table.remove(quest,1)
		sNum=sNum-1
	end
	
	Update()
	
	ti=ti+1
--[[	
	if(time()%500>250) then
  print('Warning!',h/2,w/2)
 end
	
	if(time()>2000)then
  print('Fugit inreparabile tempus',32,60)
 end]] 
	--t=time()//20
end

function Update()
	DrawEnt()
	Player()
	Collectiables()
	Pit()
	Quest()
	CheckPoint()
	Stabilizer()
	ShakeScreen()
	Blinky()
end

function Mouse()
	mx,my,ml,mm,mr = mouse()
	c.mxt=mx//8
	c.myt=my//8	
		if ml then 
			p.x=mx
			p.y=my
		end
	spr(16,mx,my,0)
end

function psfx(o,i)
	if o.type=="player" then
		sfx(i) 
	end 
end

function Player()
	--this enables a running
	if p.canMove then
		if btn(c.r) and btn(c.a) then
			p.vx=p.vmax+1
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
				p.stab=p.stab-.1
				meterY=meterY+.1
			end
			p.flp=1
		elseif btn(c.l) and btn(c.a) then
			p.vx=-p.vmax-1
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
				p.stab=p.stab-.1
				meterY=meterY+.1
			end
			p.flp=0
		elseif btn(c.l) then
			p.vx=-p.vmax
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
			end
			p.flp=0
		elseif btn(c.r) then 
			p.vx=p.vmax
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
			end
			p.flp=1
		else
			p.vx=0
			p.idx=p.s.idle+t%40//10*2
			t=time()//30
		end
	end
	--jump
	if p.vy==0 and btnp(c.z) and p.canMove and not p.ducking then
		p.vy=-3.6
		p.grounded=false
		p.stab=p.stab-1
		meterY=meterY+1
		--psfx(o,1)
	end
	--duck
	if btn(c.d) and p.vx==0 then
		p.idx=p.s.duck
		p.ducking=true
		p.canMove=false
	else
		p.canMove=true
		p.ducking=false
	end

	--check if there is something beside the player
	if solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,0) or 
				solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,0) or
				solid(p.x+coll.tlx+p.vx,p.y+15+p.vy,0) or 
				solid(p.x+coll.trx+p.vx,p.y+15+p.vy,0) or
				solid(p.x+coll.tlx+p.vx,p.y+7,0) or
				solid(p.x+coll.tlx+p.vx,p.y+8,0) or
				solid(p.x+coll.trx+p.vx,p.y+7,0) or
				solid(p.x+coll.trx+p.vx,p.y+8,0) then
		p.vx=0
	end
	--checks if you are on the ground
	if solid(p.x+coll.tlx,p.y+16+p.vy,0) or
				solid(p.x+coll.trx,p.y+16+p.vy,0) or
				solid(p.x+7+p.vx,p.y+16+p.vy,0) or
				solid(p.x+8+p.vx,p.y+16+p.vy,0) or
				--some how this triggers when you run and jump onto it
				solid(p.x+coll.tlx,p.y+16+p.vy,1) or
				solid(p.x+coll.trx,p.y+16+p.vy,1) or
				solid(p.x+7+p.vx,p.y+16+p.vy,1) or
				solid(p.x+8+p.vx,p.y+16+p.vy,1) then
		p.vy=0
		p.grounded=true
	else
		p.vy=p.vy+0.2
		p.idx=p.s.fall
		p.grounded=false
	end
	--check if something is above
	if p.vy<0 and (solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,0) or 
																solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,0) or
																solid(p.x+7+p.vx,p.y+coll.tly+p.vy,0) or 
																solid(p.x+8+p.vx,p.y+coll.tly+p.vy,0)) then
		p.vy=0
	elseif p.vy<0 and (solid(p.x+coll.tlx+p.vx,p.y+coll.tly+p.vy,1) or 
																solid(p.x+coll.trx+p.vx,p.y+coll.tly+p.vy,1) or
																solid(p.x+7+p.vx,p.y+coll.tly+p.vy,1) or 
																solid(p.x+8+p.vx,p.y+coll.tly+p.vy,1)) then
		fset(p.s.thru,1,false)
	end
	--[[if the sprite is tile 2 and has flag 1 either set
	as true or false]]
	if p.grounded and not btnp(c.d) and p.canMove then
		fset(p.s.thru,1,true)
	elseif p.grounded then
		fset(p.s.thru,1,false)
	end
	--[[so close! at 0 won't work. 1.5 kinda works]]
	if p.vy>=1.5 then
		fset(p.s.thru,1,true)
	end
	
	if p.x<mapStart then
		p.x=mapStart
	end
	if p.x>mapEnd-8 then
		p.x=mapEnd-8
	end

	p.x=p.x+p.vx
	p.y=p.y+p.vy
	
	Damage()
	--Dead()
end

function Dead()
	if p.curLife==0 then
		p.canMove=false
		p.stab=0
		print("Dead!",p.x,p.y-5,7)
		p.idx=p.s.dead
	end 
end
--[[should probably move the p.stab/meterY to its own
function then return it back]]
function Damage()	
	if p.vy>2 then
		p.stab=p.stab-.1
		meterY=meterY+.1
	end
	if p.vy>4 then
		p.stab=p.stab-.5
		meterY=meterY+.5
	end
	if fget(mget(p.x//8,p.y//8+1),7) and not p.damaged then
		p.stab=p.stab-5
		meterY=meterY+5
		screenShake.active=true
		p.damaged=true
	end
	if p.stab<=0 and p.curLife>0 then
		p.curLife=p.curLife-1
		p.x=p.cpX
		p.y=p.cpY
		p.flp=p.cpF
		p.stab=51
		meterY=16
	elseif p.curLife<=0 then
		Dead()
	end
end

function Blinky()
	if p.damaged and timer<=100 then
		timer=timer+1
	elseif timer>=100 then
		p.damaged=false
		timer=0
	end
end

function Stabilizer()
	if btnp(c.x) and p.stabpot>0 and p.stab>=31 and p.stab<51 then
		p.stab=51
		meterY=16
		p.stabpot=p.stabpot-1
	elseif btnp(c.x) and p.stab<31 and p.stabpot>0 then
		p.stab=p.stab+15
		meterY=meterY-15
		p.stabpot=p.stabpot-1
	end
end

function Enemy()
	--Set initial velocity
	e.vx=0
	--[[if on solid ground move left, if velocity becomes 0
	set moving left to false and move in the other direction]]
	if solid(e.x+1,e.y+16+e.vy) and e.l then
		e.vx=e.vx-0.2
	elseif e.vx==0 then
		e.l=false
	end
	
	if solid(e.x+14,e.y+16+e.vy) and not e.l then
		e.vx=e.vx+0.2
	elseif e.vx==0 then
		e.l=true
	end
	--apply movement to the enemy
	e.x=e.x+e.vx
end

function Pit()
	if mget(p.x//8+1,p.y//8)==s.pit then
		p.x=p.cpX
		p.y=p.cpY
		p.flp=p.cpF
		p.curLife=p.curLife-1
	end
end

function CheckPoint()
	if mget(p.x//8+1,p.y//8+1)==s.check then
		mset(p.x/8+1,p.y/8+1,s.checkact)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
	end
end

function Collectiables()
	--[[Collisions with collectibles can be done either with
	flags set on the sprites, or by looking for the actual
	sprite itself.]]
	--rectb(p.x-1,p.y+1,8,8,7)
	if mget(p.x//8+1,p.y//8+1)==s.coin then
		mset(p.x/8+1,p.y/8+1,0)
		p.coins=p.coins+1
		--table.remove(ents,i)
		--sfx(01,'E-6',5)
	end
	if mget(p.x//8+1,p.y//8+1)==s.heart and p.curLife<3 then
		mset(p.x/8+1,p.y/8+1,0)
		p.curLife=p.curLife+1
		--table.remove(ents,i)
		--sfx(01,'E-6',5)
	end
end

function Quest()
	for counter=1,#quest do
		print(quest[counter],0,24,12)
	end
	switch(action,
		case(quest[1],function() NoQuest() end),
		case(quest[2],function() QuestOne() end),
		case(quest[3],function() QuestTwo() end),
		default(function() print("No Quest",72,0,7) end)
	)
	--fset(481,0,true)
	if mget(p.x//8,p.y//8)==17 then
		--mset(24,104,352)
		print("trigger",p.x-cam.x-8,p.y-cam.y-8,7)
		--spr(352,24,104)
	end
	--spr(p.idx,p.x-cam.x,p.y%136,5,1,p.flp,0,2,2)
end

function NoQuest()
	print("No quest",w/2,0,7)
	spr(464,8-cam.x,104-cam.y,0,1,0,0,2,3)
end

function QuestOne()
	print("Quest One",w/2,0,7)
	spr(464,8-cam.x,104-cam.y,0,1,0,0,2,3)
end

function QuestTwo()
	print("Quest Two",w/2,0,7)
	spr(464,8-cam.x,104-cam.y,0,1,0,0,2,3)
end

function AddEnt(t)
	table.insert(ents,{
		t=t.t or 0,
		x=t.x,
		y=t.y,
		vx=t.vx or 0,
		vy=t.vy or 0,
		l=t.l,
		flp=t.flp,
		spr=t.spr,
		type=t.type or "normal",
	})
end

function EntLocations()
	for x=0,240 do
		for y=0,136 do
			if spawns[mget(x,y)] then
				AddEnt({spr=(mget(x,y)+256),x=x*8,y=y*8})
			end
		end
	end
end

function DrawEnt()
	for i,v in pairs(ents) do
		v.vx=0
		--[[if on solid ground move left, if velocity becomes 0
		set moving left to false and move in the other direction]]
		if not solid(v.x-1,v.y+15+v.vy,0) and solid(v.x+1,v.y+24+v.vy) and v.l then
			v.vx=v.vx-0.3
		elseif v.vx==0 then
			v.l=false
			v.flp=1
		end
		
		if not solid(v.x+14,v.y+15+v.vy,0) and solid(v.x+14,v.y+24+v.vy) and not v.l then
			v.vx=v.vx+0.3
		elseif v.vx==0 then
			v.l=true
			v.flp=0
		end
		--apply movement to the enemy
		v.x=v.x+v.vx
		--Draw the sprite and replace the map tile
		spr(v.spr+ti%40//10*2,v.x+m.x-cam.x,v.y-m.y,0,1,v.flp,0,2,2)
		mset(v.x/8,v.y/8,0)
		
		if v.x//8==p.x//8 and v.y//8+1==p.y//8 and not p.damaged and not p.ducking then
			print("hit",p.x-8-cam.x,p.y-cam.y,7)
			p.stab=p.stab-10
			meterY=meterY+10
			screenShake.active=true
			p.damaged=true
		end
	end
end

Init()

--Tools
function remap(animTile)
	local outTile,flip,rotate=animTile,0,0
	local at=tileAnims[animTile]
	if at then
		outTile=outTile+flr(ti*at.s)%at.f
	end
	return outTile,flip,rotate
end

function switch(n,...)
	for _,v in ipairs{...} do
		if v[1]==n or v[1]==nil then
			return v[2]()
		end
	end
end

function case(n,f)
	return {n,f}
end

function default(f)
	return{nil,f}
end
--this returns the x,y and flag for tile collisions
function solid(x,y,f)
	return fget(mget(flr(x//8),flr(y//8)),f)
end

function ShakeScreen()
 if screenShake.active==true then
		poke(0x3FF9,math.random(-screenShake.power,screenShake.power))
		poke(0x3FF9+1,math.random(-screenShake.power,screenShake.power))
		screenShake.duration=screenShake.duration-1
		
		if screenShake.duration<=0 then
			screenShake.active=false
		end
 else
  memset(0x3FF9,0,2)
  screenShake.active=false
  screenShake.duration=screenShake.defaultDuration
	end
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
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 017:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 192:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 224:0230000002300000023000000230000002300000023000000110000011110000
-- 225:0211000002131100021333110213311002111000021000000110000011110000
-- 240:0033330003322330332442233444443334444443124444230124423000111100
-- 241:0003300000343300002423000024220000242200002422000011110000011000
-- 242:0003300000033000000320000002200000022000000220000002100000011000
-- 243:0003300000334300003242000022420000224200002242000011110000011000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222312222233102223310002331000003100000000000
-- 246:0000000002200310222233212223322102332210003221000002100000000000
-- 247:0000000002200210223322212332222103222210002221000002100000000000
-- 248:0000000003300210332222213222222102222210002221000002100000000000
-- </TILES>

-- <SPRITES>
-- 000:0000000000012222000013330000144400011444000122220000122200001222
-- 001:0000000022221000324211004222321022212310222123102231311022131110
-- 002:0000000000000000000122220000133300001444000114440001222200001222
-- 003:0000000000000000222210003242110042213210222123102231231022133110
-- 004:0000000000000000000122220000133300001444000114440001222200001222
-- 005:0000000000000000222210003242110042213210222123102231231022133110
-- 006:0000000000000000000122220000133300001444000114440001222200001222
-- 007:0000000000000000222211003242321042212310222123102231311022131110
-- 008:0000000000000000000122220000133300001444000114440001222200001222
-- 009:0000000000000000222210003242110042213210222123102231231022133110
-- 010:0000000000000000000000000001222200001333000014440001144400012222
-- 011:0000000000000000000000002222100032421100422132102221231022312310
-- 012:0000000000000000000000000000000000012223000013330000144400001442
-- 013:0000000000000000000000000000000032421100422132102221231022212310
-- 014:0000000000000000000000000000000000000000000000000001111101122122
-- 015:0000000000000000000000000000000000000000000000001000001021111120
-- 016:0001122300131233001331110001132200001111000012210000113100000111
-- 017:3111211031412210144111003311000011110000122100001131000011110000
-- 018:0001122300131233001331110001132200001111000012210000113100000111
-- 019:3111111031412110144122103311110011110000122100001131000011110000
-- 020:0000122300011233001311110013332200011111000012210000113100000111
-- 021:3111111031112110114122103441110011110000122100001131000011110000
-- 022:0001122300131233001331110001132200001111000012210000113100000111
-- 023:3111211031412210144111003311000011110000122100001131000011110000
-- 024:0000122200001222000141110001422200001111000001230000011100000000
-- 025:2111111021412110114122102211110011110000122100001113100000111000
-- 026:0000122200001222000011220000011100000122000001110000001300000001
-- 027:2213311021111110214121101141221022111100111100001221000011110000
-- 028:0000122200001222000112220001412200011411000011120000000100000000
-- 029:2231311022131110211121102141221011411100222110003113100011111000
-- 030:0131212200112112013221410111121401223221012213220011113300001111
-- 031:2244432024444320244333201243222012222220122422201112221000011100
-- 032:0000000000012222000013330000144401111444013322220133122200111223
-- 033:0000000022221000324211004222121022212310222123102231311033313110
-- 034:0000000000012222000013330000144401111444013322220133122200111223
-- 035:0000000022221000324211004222121022212310222123102231311033313110
-- 036:0000000000012222000013330000144400011444000122220011122200131223
-- 037:0000000022221000324211004222121022212310222123102231311033312110
-- 038:0001222200001333000014440001144400012222000012220000122200001223
-- 039:2222100032421000422210002221110022213210223123102311231033133110
-- 040:0001222200001333000014440001144400012222000012220000122200001223
-- 041:2222100032421000422210002221110022213210223123102311231033133110
-- 042:0001222200001333000014440001144400012222000012220000122200001223
-- 043:2222100032421000422210002221110022213210223123102311231033133110
-- 044:0001222200001333000014440001144400012222000012220000122200001223
-- 045:2222100032421000422210002221110022213210223123102311231033133110
-- 046:0000000000012222000013330000144400011444000122220011122200131223
-- 047:0000000022221000324211004222121022212310222123102231311033312110
-- 048:0000122300001233000011110000132200001111000012310000011100000000
-- 049:3331211032144210112341003311100011110000122100001131000001110000
-- 050:0000122300001233000011110000132200001111000012310000011100000000
-- 051:3331211032144210112341003311100011110000122100001131000001110000
-- 052:0012122300011233000121110000132200001111000011230000011100000000
-- 053:3333111033244210111441003311100011111000112210000113100000111000
-- 054:0011122300131233000121110000132200001111000012210000113100000110
-- 055:3311111034412110144222103311110011111000002310000111100000000000
-- 056:0000122300011233000121110000132200001111000012210000131100001110
-- 057:4411111044212110111222103311110011111000012310000111100000000000
-- 058:0000122300011233000121110000132200001111000012210000131100001110
-- 059:4411111044212110111222103311110011111000012310000111100000000000
-- 060:0011122300131233000121110000132200001111000012210000113100000110
-- 061:3311111034412110144222103311110011111000012310000111100000000000
-- 062:0012122300011233000121110000132200001111000011230000011100000000
-- 063:3333111033244210111441003311100011111000112210000113100000111000
-- 064:0000000000012222000013330000144401111444013322220133122200111223
-- 065:0000000022221000324211004222121022211310222441102213411033111310
-- 066:0000000000000000000000000000000000000000000000000012222200013333
-- 067:0000000000000000000000000000000000000000000000002221000024211000
-- 080:0000122300001233000011110000132200001111000012310000011100000000
-- 081:3331231032112210112121003311100011110000122100001131000001110000
-- 082:0001444400114442001222220001222200011133000111130001311100013311
-- 083:2212110022112110231122212111111111441111314411101111311011111100
-- 160:3330000023330000022300000002330200002222000022210002111200211311
-- 161:0000033300003332000332202332200011200000111000001110000021000000
-- 162:0000000003333300233223320220022200002221000211120021131100021112
-- 163:0000000000333300233223301120022011100000111000002100000012000000
-- 164:0000000000003332003332220022222100021112002113110002111200002220
-- 165:0000000023333000112233301110223011100020210000001200000022000000
-- 166:0000000000000000033333002332233202200222000022210002111200211311
-- 167:0000000000000000003333002332233011200220111000001110000021000000
-- 176:0002111200002220000000000000000200000002000000020000000000000000
-- 177:1200000022000000220000004220000022200000222000002200000000000000
-- 178:0000222000000000000000020000002200000022000000020000000000000000
-- 179:2200000022000000220000004200000022000000200000000000000000000000
-- 180:0000000000000002000000020000000200000000000000000000000000000000
-- 181:2200000024200000222000002220000022000000000000000000000000000000
-- 182:0002111200002220000000000000000000000000000000000000000000000000
-- 183:1200000022000000022000002242000022220000222200000220000000000000
-- 192:0000000001111110133333311322223113233310013311000011000000100000
-- 193:0033330003322330332442233444443334444443124444230124423000111100
-- 194:0211000002131100021333110213311002111000021000000110000011110000
-- 195:0000000001101100122122101232321012333210012321000012100000010000
-- 196:0000000002202200244244202444442024444420024442000024200000020000
-- 197:0000000001111110001441000012210001244210124444211222222101111110
-- 198:0000000001100110001331000013210000122100001211000011110000011000
-- 208:0000000000000000000000000000001100000133000013320011332101213313
-- 209:0000000000000000000000001010000031310000123310001113310033323100
-- 224:0121233401211233012112220121123314432233144332320123322301222233
-- 225:4442310044423100222210002223210032222100232221003332310033332410
-- 240:0121223301212131012111110121011101210113012101320121001200100001
-- 241:1113241011112100111110003331100011231000112100001121000011110000
-- </SPRITES>

-- <MAP>
-- 000:300000000000000000000000000000000000000000000000000000000030300000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:0000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000001010100000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000001000000000000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000000000000000000f00000000000000001000000000000000000000000000101010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:0000000000000000000000000000000000000000101010000a0000000000000000101010000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000000000020000000000020202020101010100000004f00000000000000000000004f00000000000000000000000000001010100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:000000110000000000000000000000000000000000000000101010101000000000000000000000000000000000000000001000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:00000000000000000000000000000e000000000000000000101010101000000000006060606000000000000000001010001000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:301010101010101050501010101010101010101010101010101010101050501010101010101010101010101010101010101000000000001010000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000001000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:000000000000000010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:20003000400040005000500060006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000302000000000
-- 019:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX>

-- <FLAGS>
-- 000:00102000200008000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080808080808080800000000000000000808080808080808000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f04002038b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE>

