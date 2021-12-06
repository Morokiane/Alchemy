-- title:  Alchemy Courier
-- author: Blind Seer Studios
-- desc:   Courier dangerous potions
-- script: lua
-- input:  gamepad

--Simplify math operations. Floor will round a decimal down
flr=math.floor
ceil=math.ceil
rnd=math.random
cos=math.cos
rad=math.rad
sin=math.sin
max=math.max
min=math.min
del=table.remove

dc=7 --debug txt color

--Variables for the screen area
w,h=240,136
hw,hh=w/2,h/2

win={}
txt=""

indicatorsOn=false
--Setup camera coordinates
cam={
	x=0,
	y=0
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
	x=170, --was hw
	y=96,	--was hh
	vx=0, --Velocity X
	vy=0, --Velocity Y
	--curv=0, --Current movement velocity
	vmax=1, --Maximum velocity
	grounded=true,
	flp=0,
	type="player",
	curLife=2,
	maxLife=3,
	coins=99,
	stab=51,
	stabPot=0,
	stabPotMax=3,
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
	cpF=0, --which way did the player run through the checkpoint
	cpA=false, --is a checkpoint active
	canMove=true,
	ducking=false,
	damaged=false,
	onQuest=false,
	inTown=true,
	inShop=false
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
	[7]=32,
	[8]=0
	--[240]=432
}

tileAnims={
	[240]={s=.1,f=4}, --coin
	[244]={s=.05,f=5}, --heart
	[194]={s=.1,f=3},
	[210]={s=.1,f=3},
	[197]={s=.1,f=3},
	[213]={s=.1,f=3}
}

t=0
ti=0 --ti is time for the animated tiles

pit=false
meterY=16 --offset for the stab rect. as it decreases

quest={}
qnum=0
timer=0
mapStart=0
mapEnd=472 --Change this to what the end of the map will be (this will depend on level)
mapEndY=136
msgbox=false
pt=0
selX=75
selY=54
desctxt=""
stabplus=false
backpack=false
start=false

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
	TIC=Update --Update is the main game loop that needs to run after the title screen
	--TIC=Title
end

function Start()
	p={
	idx=256,
	x=200, --was hw
	y=96,	--was hh
	vx=0, --Velocity X
	vy=0, --Velocity Y
	--curv=0, --Current movement velocity
	vmax=1, --Maximum velocity
	grounded=true,
	flp=0,
	type="player",
	curLife=2,
	maxLife=3,
	coins=99,
	stab=51,
	stabPot=0,
	stabPotMax=3,
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
	cpF=0, --which way did the player run through the checkpoint
	cpA=false, --is a checkpoint active
	canMove=true,
	ducking=false,
	damaged=false,
	onQuest=false,
	inTown=true,
	inShop=false
}
end

function OVR()
	if TIC==Update then
		HUD()
		Text()
		ShopHUD()
		Debug()
		Mouse()
	end
end
--[[
wavelimit = 136/2
function scanline(row)
	-- skygradient
	--poke(0x3fc0,190-row)
	--poke(0x3fc1,140-row)
	--poke(0x3fc2,0)
	-- screen wave
	if row>wavelimit then
		poke(0x3ff9,math.sin((time()/200+row/5))*2)
	else
		poke(0x3ff9,0)
	end
end]]

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
	line(7,15,8,15,1)
	line(6,16,6,65,1)
	line(9,16,9,65,1)
	line(7,66,8,66,1)
	if p.curLife==0 then
		spr(454,4,68,0)
	elseif p.stab<5 then
		spr(453,4+t%rnd(1,4),68+t%rnd(1,2),0)
	elseif p.stab<15 then
		spr(453,4+t%rnd(1,2),68,0)
	else
		spr(453,4,68,0)
	end
 
 if(time()%500>250) and p.stab<=10 and p.curLife>0 then
 	print('Warning!',18,18,1)
	end
	--Hearts
	for num=1,p.maxLife do
		spr(452,-4+8*num,4,0)
	end
	
	for num=1,p.curLife do
		spr(451,-4+8*num,4,0)
	end
	--Stabilizer
	spr(455,58,4,0)
	print("x"..p.stabPot,66,6,1,true,1,false)
	if stabplus then
		spr(456,58,4,0)
	end
	--Shop

end

function ShopHUD()
	if p.inShop then
		rect(72,51,97,34,4)
		rectb(73,52,95,32,1)
		
		rectb(selX,selY,43,12,1)
		spr(500,120,43,0)
		rect(128,42,40,10,4)
		rectb(118,41,50,12,1)
		print("- Purchase",129,45,1,false,1,true)
		--Stabilizer
		spr(455,77,56,0)
		print("-",86,58,1)
		spr(449,90,56,0)
		print("x20",99,58,1)
		--Heart
		spr(244,125,56,0)
		print("-",134,58,1)
		spr(449,138,56,0)
		print("x20",147,58,1)
		--Stabilizer Plus
		spr(455,77,72,0)
		print("-",86,74,1)
		spr(456,77,72,0)
		spr(449,90,72,0)
		print("x40",99,74,1)
		if stabplus then
			line(76,76,116,76,1)
		end
		--Backpack
		spr(466,125,72,0)
		print("-",134,74,1)
		--spr(456,125,72,0)
		spr(449,138,72,0)
		print("x99",147,74,1)
		if backpack then
			line(124,76,164,76,1)
		end
		--Description
		AddWin(121,94,95,17,4,desctxt)
	end
end

function Debug()	
	if indicatorsOn then
		print("FPS: "..fps:getValue(),w-24,0,dc,false,1,true)
		print("Indicators: " ..tostring(indicatorsOn),1,0,dc,false,1,true)
		print("MaxV: "..flr(p.vy),1,8,dc,false,1,true)
		print("Grounded: "..tostring(p.grounded),48,8,dc,false,1,true)
		print("Life: "..p.curLife,48,16,dc,false,1,true)
		print("Max Life: "..p.maxLife,72,16,dc,false,1,true)
		print("Move: "..tostring(p.canMove),48,24,dc,false,1,true)
		print("Saved: "..tostring(saved),48,32,dc,false,1,true)
		print("Stab: "..tostring(p.stab),48,40,dc,false,1,true)
		print("QNum: "..qnum,48,48,dc,false,1,true)
		print("Town: "..tostring(p.inTown),48,56,dc,false,1,true)		
		print("StabMax: "..p.stabPotMax,48,64,dc,false,1,true)				
		print("Backpak: "..tostring(backpack),48,72,dc,false,1,true)						
		print("X: "..p.x,1,16,dc,false,1,true)
		print("Y: "..p.y,1,24,dc,false,1,true)
		print("Check X: "..p.cpX,1,32,dc,false,1,true)
		print("Check Y: "..p.cpY,1,40,dc,false,1,true)
		print("Pit: "..tostring(pit),1,48,dc,false,1,true)
		print("Fall: "..p.vy,1,56,dc,false,1,true)
		print("Dmgd: "..tostring(p.damaged),1,64,dc,false,1,true)
		print("Timer: "..timer,1,72,dc,false,1,true)
		print("Quest: "..tostring(p.onQuest),1,80,dc,false,1,true)
		print("-Save Data-",1,88,dc,false,1,true)
		print("HP: "..pmem(0),1,96,dc,false,1,true)
		print("Stab: "..pmem(1),1,104,dc,false,1,true)
		print("X: "..pmem(2),1,112,dc,false,1,true)
		print("Y: "..pmem(3),1,120,dc,false,1,true)
		print("Meter: "..pmem(4),1,128,dc,false,1,true)
		print("Quest: "..pmem(5),36,96,dc,false,1,true)
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

function Title()
	local new=false	
	cls()
	sync(0,7,false)

	--spr(256,w/2-64,h/2-64,15,1,0,0,16,16)
	AddWin(w/2,h/2,64,32,7,"Which option?\n\n  New Game\n  Load")
	--tri(x1 y1 x2 y2 x3 y3 color)
	tri(92,66+pt,92,72+pt,95,69+pt,12)
	
	if btnp(c.d) then
		pt=6
		new=true
	elseif btnp(c.u) then
		pt=0
		new=false
	end
	
	if btnp(c.z) and new then
		start=true
		TIC=Update
	elseif btnp(c.z) and not new then
		Load()
		TIC=Update
	end
end

--[[function TIC()
	
--[[	
	if btnp(0) then
		table.insert(quest,1)
	end
	if btnp(1) then
		table.remove(quest,1)
	end
	Update()
	

	
	if keyp(28) then
		Save()
	elseif keyp(29) then
		Load()
	end

--[[
	if(time()%500>250) then
  print('Warning!',h/2,w/2)
 end
	
	if(time()>2000)then
  print('Fugit inreparabile tempus',32,60)
 end 
	--t=time()//20
end]]

function Main()
	--[[initial placement of the camera these settings 
	place	the map tile centered on the screen]]
	cam.x=p.x-120
	cam.y=p.y-113

	if cam.x<mapStart then
		cam.x=mapStart
	elseif cam.x>mapEnd-232 then
		cam.x=mapEnd-232
	end
	--this will only work for two vertical map screens
	if cam.y<mapStart then
		cam.y=mapStart
	elseif cam.y>mapEndY-113 then
		cam.y=mapEndY
	end
	map(cam.x//8,cam.y//8,31,18,-(cam.x%8),-(cam.y%8),0,1,remap)
	
	if p.damaged then
		if (time()%300>200) then
			spr(p.idx,p.x-cam.x,p.y-cam.y,0,1,p.flp,0,2,2)
	 end
 else
 	spr(p.idx,p.x-cam.x,p.y-cam.y,0,1,p.flp,0,2,2)
 end
	--Scrolling only along X but loading full map grid on Y
	--map(cam.x//8,(p.y//136)*17,31,18,-(cam.x%8),-(cam.y%8),0,1,remap)
	--[[if p.damaged then
		if (time()%300>200) then 
 		spr(p.idx,p.x-cam.x,p.y%136,0,1,p.flp,0,2,2)
  end
 else
 	spr(p.idx,p.x-cam.x,p.y%136,0,1,p.flp,0,2,2)
 end]]
end

function Update()
	sync(0,0,false)
	cls(4)
	if keyp(9) and indicatorsOn==false then
		indicatorsOn=true
	elseif keyp(9) and indicatorsOn==true then
		indicatorsOn=false
	end
	
	Enemy()
	Main()
	Town()
	Player()
	Collectiables()
	CheckPoint()
	Stabilizer()
	ShakeScreen()
	Blinky()
	
	ti=ti+1
end

function Mouse()
	mx,my,ml,mm,mr = mouse()
	c.mxt=mx//8
	c.myt=my//8	
		if ml then 
			p.x=mx
			p.y=my
		end
	spr(3,mx,my,0)
end

function psfx(o,i)
	if o.type=="player" then
		sfx(i) 
	end 
end

function Player()
	--this enables a running
	if p.canMove and not msgbox and not p.inShop then
		if btn(c.r) and btn(c.a) then
			p.vx=p.vmax+1
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
				if not p.inTown then
					p.stab=p.stab-.1
					meterY=meterY+.1
				end
			end
			p.flp=1
		elseif btn(c.l) and btn(c.a) then
			p.vx=-p.vmax-1
			if p.grounded then
				p.idx=p.s.run+t%80//10*2
				t=time()//5
				if not p.inTown then
					p.stab=p.stab-.1
					meterY=meterY+.1
				end
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
	if p.vy==0 and btnp(c.z) and p.canMove and not msgbox and not p.ducking and not p.inShop then
		p.vy=-3.6
		p.grounded=false
		if not p.inTown then
			p.stab=p.stab-1
			meterY=meterY+1
		end
		--psfx(o,1)
	end
	--duck
	if btn(c.d) and p.vx==0 and not msgbox and not p.inShop then
		p.idx=p.s.duck
		p.ducking=true
		p.canMove=false
		coll.tly=6
	else
		p.canMove=true
		p.ducking=false
		coll.tly=1
	end
	--[[crawl
	if btn(c.l) and p.ducking then
		p.idx=p.s.duck
		p.vx=p.vx+p.vmax+1
	end]]

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
	
	Pit()
	if not p.inTown then
		Damage()
	end
end

function Dead()
	--[[not sure how to handle this once the player dies?
	do they just start the level over or is it game over
	and they go back to the last save?]]
	if p.curLife==0 then
		p.canMove=false
		p.stab=0
		print("Dead!",p.x,p.y-5,7)
		p.idx=p.s.dead
		table.remove(quest,1)
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
	--Spikes are flag 7
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
	if btnp(c.x) and p.stabPot>0 and p.stab>=31 and p.stab<51 then
		p.stab=51
		meterY=16
		p.stabPot=p.stabPot-1
	elseif btnp(c.x) and p.stab<31 and p.stabPot>0 then
		if stabplus then
			p.stab=p.stab+20
			meterY=meterY-20
			p.stabPot=p.stabPot-1
		else
			p.stab=p.stab+15
			meterY=meterY-15
			p.stabPot=p.stabPot-1
		end
	end
end

function SingleEnemy()
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
		if p.cpA then
			p.x=p.cpX
			p.y=p.cpY
			p.flp=p.cpF
		else
			p.x=54
			p.y=112 --These should be beginning of level
		end
		p.curLife=p.curLife-1
	end
end

function CheckPoint()
	if mget(p.x//8+1,p.y//8+1)==s.check then
		mset(p.x/8+1,p.y/8+1,s.checkact)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
	end
end

function Collectiables()
	--[[Collisions with collectibles can be done either with
	flags set on the sprites, or by looking for the actual
	sprite itself.]]
	--rectb(p.x-1,p.y+1,8,8,7)
	if (mget(p.x//8+1,p.y//8+1)==s.coin or mget(p.x//8,p.y//8)==s.coin) and p.coins<99 then
		mset(p.x//8+1,p.y//8+1,0)
		mset(p.x//8,p.y//8,0)
		p.coins=p.coins+1
		--table.remove(ents,i)
		--sfx(01,'E-6',5)
	end
	if (mget(p.x//8+1,p.y//8+1)==s.heart or mget(p.x//8,p.y//8)==s.heart) and p.curLife<3 then
		mset(p.x//8+1,p.y//8+1,0)
		mset(p.x//8,p.y//8,0)
		p.curLife=p.curLife+1
		--table.remove(ents,i)
		--sfx(01,'E-6',5)
	end
end

function Text()
	if msgbox==true then
		AddWin(hw,hh,128,65,3,txt)
		--rect(179,95,7,7,4)
		spr(482,178,95+math.sin(time()//90),0)
		--print("A",180,97+math.sin(time()//90),1)
	end
end

function Town()
	switch(action,
		case(quest[1],function() NoQuest() end),
		case(quest[2],function() QuestOne() end),
		case(quest[3],function() QuestTwo() end),
		default(function() print("End of table",w/2,0,7) end)
	)
	for counter=1,#quest do
		print(quest[counter],w/2,(counter*8),7)
	end
	
	while qnum>0 do
		table.insert(quest,1)
		qnum=qnum-1
	end
	--quest giver sprite
	spr(464,24-cam.x,88-cam.y,0,1,0,0,2,3)
	--shop keeper sprite
	spr(459,440-cam.x,80-cam.y,0,1,0,0,3,4)
	--display interact bubble
	if mget(p.x//8,p.y//8)==7 or mget(p.x//8,p.y//8)==8 or mget(p.x//8,p.y//8)==192 or mget(p.x//8+2,p.y//8)==192 or mget(p.x//8+1,p.y//8)==192
	 or mget(p.x//8,p.y//8)==9 then
		spr(448,p.x-cam.x+4,p.y-cam.y-8+math.sin(time()//90),0)
	end
	
	if (fget(mget(p.x//8,p.y//8),2) or fget(mget(p.x//8-1,p.y//8+1),2)) and btnp(c.a) and not p.onQuest and not msgbox then
		p.canMove=false
		msgbox=true
		p.onQuest=true
		p.inTown=false
		table.insert(quest,"On quest")
	elseif fget(mget(p.x//8,p.y//8),2) and btnp(c.a) then
		p.canMove=true
		msgbox=false
	end
	
	if fget(mget(p.x//8,p.y//8),3) then
		p.onQuest=false
	end
	--Sign
	--spr(192,78-cam.x,112-cam.y,0,1,0,0,1,2)
	if (mget(p.x//8,p.y//8)==192 or mget(p.x//8+2,p.y//8)==192 or mget(p.x//8+1,p.y//8)==192) and btnp(c.a) then
		print("got it",64,64,7)
	end
	--Shop
	if (fget(mget(p.x//8,p.y//8),4) or fget(mget(p.x//8-1,p.y//8+1),4)) and btnp(c.a) and not p.inShop then
		p.canMove=false
		p.inShop=true
	elseif fget(mget(p.x//8,p.y//8),4) and btnp(c.a) and p.inShop then
		p.canMove=true
		p.inShop=false
	end
	if p.inShop then
		Shop()
	end
	--[[if keyp(13) and not p.inShop then
 	p.inShop=true
  p.canMove=false
 elseif keyp(13) and p.inShop then
 	p.inShop=false
  p.canMove=true
 end]]
 --Shop()
end

function Shop()	
	if p.inShop then
		if btnp(c.r) then
			selX=75+48
		elseif btnp(c.d) then
			selY=54+16
		elseif btnp(c.l) then
			selX=123-48
		elseif btnp(c.u) then
			selY=70-16
		end
		
		if selX==75 and selY==54 then
			desctxt="Adds Stabilizer"
			if btnp(c.s) and p.coins>=20 and p.stabPot<p.stabPotMax then
				p.stabPot=p.stabPot+1
				p.coins=p.coins-20
			end
		elseif selX==123 and selY==54 then
			desctxt="Fills one heart"
			if btnp(c.s) and p.coins>=50 and p.curLife<3 then
				p.curLife=p.curLife+1
				p.coins=p.coins-20
			end 
		elseif selX==75 and selY==70 then
			if not stabplus then
				desctxt="Stabilizers are\nmore effective"
			else
				desctxt="Out of stock"
			end
			if btnp(c.s) and p.coins>=40 and not stabplus then
				stabplus=true
				p.coins=p.coins-40
			end
		elseif selX==123 and selY==70 then
			if not backpack then
				desctxt="Bigger backpack. Holds\nmore stabilizers"
			else
				desctxt="Out of stock"
			end
			if btnp(c.s) and p.coins>=99 and not backpack then
				p.stabPotMax=6
				backpack=true
				p.coins=p.coins-1
			end
		end
	end
end

function NoQuest()
	print("No quest",w/2,0,7)
end

function QuestOne()
	print("Quest One",w/2,0,7)
	spr(478,(57*8)-cam.x,(30*8)-cam.y,0,1,0,0,2,3)
	if p.onQuest then
		txt="Courier,\nPlease take this potion to\nJanna at the edge of the forest.\nPlease be careful and not\nbreak it. We don't want to\nlose you like the last one."
	end
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Thank you!\nThis will work nicely."
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.a) then
		msgbox=false
		NextLvl()
	end
end

function QuestTwo()
	print("Quest Two",w/2,0,7)
	txt="blah"
end

function NextLvl()
	--This will need a sync that take me back to starting map
	p.x=80
	p.y=80
	p.stab=51
	meterY=16
	p.inTown=true
	Save()
end

function Save()
	--[[pmem
	pmem index -> val Retrieve data from persistent memory
	pmem index val -> val Save data to persistent memory
	]]
	local savStab=ceil(p.stab)
	local savMeter=ceil(meterY)-1
	local savY=flr(p.y)
	--pmem(saveScoreIdx,bestScore)
 --bestScore = pmem(saveScoreIdx)
	pmem(0,p.curLife)
	pmem(1,savStab)
	pmem(2,p.x)
	pmem(3,savY)	
	pmem(4,savMeter)
	pmem(5,#quest)
	pmem(6,p.coins)
end

function Load()
	p.curLife=pmem(0)
	p.stab=pmem(1)
	p.x=pmem(2)
	p.y=pmem(3)
	meterY=pmem(4)
	qnum=pmem(5)
	p.coins=pmem(6)
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
			--if spawns[mget(x,y)] then
			--	mset(x,y,32)
			if mget(x,y)==160 then
			--if spawns[mget(x,y)] then
				AddEnt({spr=(mget(x,y)+256),x=x*8,y=y*8,type="flier"})
			elseif mget(x,y)==128 then
				AddEnt({spr=(mget(x,y)+256),x=x*8,y=y*8,type="blob"})
			end
		end
	end
end

function Enemy()
	for i,e in pairs(ents) do
		e.vx=0
		
		if e.type=="flier" then
			--[[if on solid ground move left, if velocity becomes 0
			set moving left to false and move in the other direction]]
			if not solid(e.x-1,e.y+15+e.vy,0) and solid(e.x+1,e.y+24+e.vy) and e.l then
				e.vx=e.vx-0.3
			elseif e.vx==0 then
				e.l=false
				e.flp=1
			end
			
			if not solid(e.x+14,e.y+15+e.vy,0) and solid(e.x+14,e.y+24+e.vy) and not e.l then
				e.vx=e.vx+0.3
			elseif e.vx==0 then
				e.l=true
				e.flp=0
			end
			--apply movement to the enemy
			e.x=e.x+e.vx
			--Draw the sprite and replace the map tile
			spr(e.spr+ti%40//10*2,e.x-cam.x,e.y-cam.y,0,1,e.flp,0,2,2)
			if mget(e.x//8,e.y//8)==160 then
				mset(e.x/8,e.y/8,0)
			end
			if indicatorsOn then
				print("x"..e.x//8,e.x-cam.x,e.y-13-cam.y,0,false,1,true)
				print("y"..e.y//8,e.x-cam.x,e.y-7-cam.y,0,false,1,true)
				
				print("x"..p.x//8,p.x-cam.x,p.y-13-cam.y,0,false,1,true)
				print("y"..p.y//8,p.x-cam.x,p.y-7-cam.y,0,false,1,true)
			end
			
			--should eventually update this to use the actual player collider
			if e.x//8==p.x//8 and (e.y//8==p.y//8 or e.y//8+1==p.y//8+1 or e.y//8+1==p.y//8) and not p.damaged and not p.ducking then
				print("hit",p.x-8-cam.x,p.y-cam.y,7)
				p.stab=p.stab-10
				meterY=meterY+10
				screenShake.active=true
				p.damaged=true
			end
		end
		
		if e.type=="blob" then
		
			if not solid(e.x-1,e.y+15+e.vy,0) and solid(e.x+1,e.y+16+e.vy) and e.l then
				e.vx=e.vx-0.3
			elseif e.vx==0 then
				e.l=false
				e.flp=0
			end
			
			if not solid(e.x+14,e.y+15+e.vy,0) and solid(e.x+14,e.y+16+e.vy) and not e.l then
				e.vx=e.vx+0.3
			elseif e.vx==0 then
				e.l=true
				e.flp=1
			end
			e.x=e.x+e.vx
			
			if indicatorsOn then
				print("x"..e.x//8,e.x-cam.x,e.y-13-cam.y,0,false,1,true)
				print("y"..e.y//8,e.x-cam.x,e.y-7-cam.y,0,false,1,true)
			end
			
			spr(e.spr+ti%40//10*2,e.x-cam.x,e.y-cam.y,0,1,e.flp,0,2,2)
			if mget(e.x//8,e.y//8)==128 then
				mset(e.x/8,e.y/8,0)
			end
			if (e.x//8==p.x//8 or e.x//8+1==p.x//8+1 or e.x//8==p.y//8+1 or e.x//8+1==p.y//8+1) and (e.y//8==p.y//8 or e.y//8==p.y//8+1 or e.y//8+1==p.y//8) and not p.damaged and not p.ducking then
				print("hit",p.x-8-cam.x,p.y-cam.y,7)
				p.stab=p.stab-10
				meterY=meterY+10
				screenShake.active=true
				p.damaged=true
			end
		end
	end --for
end

Init()
--Start()

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
		poke(0x3FF9,rnd(-screenShake.power,screenShake.power))
		poke(0x3FF9+1,rnd(-screenShake.power,screenShake.power))
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

function AddWin(x,y,w,h,col,txt)
	for i=1,#win do
		table.insert(win,i,#win)
	end
	rect(x-w/2,y-h/2,w,h,col)
	rectb(x-w/2+1,y-h/2+1,w-2,h-2,1) --no idea but it works
 print(txt,x-w/2+3,y-h/2+3,1,0,1,true)
end

function DrawWin()
	for w in pairs(win) do
		rect(w.x,w.y,w.w,w.h,2)
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
-- 003:0100000013100000133100001333100013333100133110000113100000000000
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:aaaaaaaaa088880aa080000aa088800aa000080aa080080aa008800aaaaaaaaa
-- 011:aaaaaaaaa008800aa080000aa088800aa080080aa080080aa008800aaaaaaaaa
-- 012:4444444233333332333333323333333203333332003333320003333200003332
-- 013:4444444433333333333333333333332222221123333312333333123333331233
-- 014:4444444433333333333333332233332232111123332112333322223333222233
-- 015:4444444433333333333333332233333332112222332133333321333333213333
-- 016:4443444444244444422244443332244433233244323333341333333311333333
-- 017:4443444444442444444222444422333442333333323333333313333331113331
-- 018:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 023:0000000000000000000000000000000000000000111111111333333312222222
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:3322223323222232112222122112211232111122332112223322222333222223
-- 027:3322223323222232212222112112211222111123222112333222223332222233
-- 028:2444444423333333233333332333333323333330233333002333300023330000
-- 029:3333123333331232333312113333111233331123333312333333123333331233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3321333323213333112133332111333332113333332133333321333333213333
-- 032:2113333322213331222123222212222221112222111112221111112211111112
-- 033:1122232222122222222122222222122222211122221111122111111111111111
-- 034:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 039:0111121100001200000012000000120000001200000012000000120000001200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3322223323222233112223322112233232223322332233223223322232233222
-- 043:3322223333222232233222112332211222332223223322332223322322233223
-- 044:0000000011000000111200001221200022221200222212002222312022223120
-- 045:3322223323222232333333333333333333333333444444442222222222222222
-- 046:3322223323222232333333333333333333333333444444442222222222222222
-- 047:3322223323222232333333333333333333333333444444442222222222222222
-- 048:3333122233321222333122223331222233312222333122223332122233331222
-- 049:2222333322233333222333332223333322233333222333332223333322223333
-- 050:0003300033233004331120440211333403323334433010300434010000433100
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222221102222221
-- 057:3330000033200000222000002110000033333330222222201111222044122110
-- 058:2233222222332222233222232332222333222233332222333222233332222344
-- 059:2222332222223322322223323222233233222233332222333332222344322223
-- 060:2222322222223242111111112121224211111242111111112222224222223222
-- 061:1221222212221222122212221222122212221222122112221111222211111122
-- 062:2222222222222222222222222222222222222222222222222222222222222222
-- 063:2222122122212221222122212221222122212221222112212222111122111111
-- 064:3333222233333222333332223333322233333222333332223333322233332222
-- 065:2221333322212333222213332222133322221333222213332221233322213333
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222222233222222332333223333332233333222333333323333333233333322
-- 069:0000000022000000220222002222220022222000222222202222222022222200
-- 070:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 071:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 072:0112222100222212002221240022212200022211000112220002222200011111
-- 073:2212222044212220444212202222122211112222222222222211111111100000
-- 074:2222333322223333222333332223444422333333223333332333333323444444
-- 075:3333222233332222333332224444322233333322333333223333333244444432
-- 076:1422312212223122212231222422312212223122122231222122312222223122
-- 077:1444442314444442144444421444444214444442144444121111112312222244
-- 078:3333343333333433333334334444444433433333334333333343333344444444
-- 079:3244444124444441244444412444444124444441214444413211111144222221
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333233333332333332223333332233333322333233222332222222222222
-- 085:2222220022222220222222202222200022222222222222222222222022222000
-- 086:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 087:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:3333311133311111331111223111222211122112312211143321111433211114
-- 091:1113333311111333221111332222111321122111411122134111123341111233
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:1442333314442333144423331444244414442333144123331112333312222244
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3333244133324441333244414442444133324441333214413333211144222221
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:ffffffffffffffff000dd0ff00ddddff00ddddff000dd0ff000000ff000000ff
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:3341111433411114334111143344444433444444334111143341111433411114
-- 107:4111143341111433411114334444443344444433411114334111143341111433
-- 108:3221223323212233222223322222233222223322333333223333322233333222
-- 109:2233222222332222233222232332222333222233332222333222233332222344
-- 110:2222332222223322322223323222233233222233332222333332222344322223
-- 111:3322122333221232233222222332222222332222223333332223333322233333
-- 113:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 114:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:000000ff000000ff000000ff000000ff000000ff000000ff000000ff000000ff
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:3341111433411114334111143341111433411114334444443222222222222222
-- 123:4111143341111433411114334111143341111433444444332222222322222222
-- 124:2222222222222222222222232222222322222233222222332222233322222344
-- 125:2222333322223333222333332223444422333333223333332333333323444444
-- 126:3333222233332222333332224444322233333322333333223333333244444432
-- 127:2222222222222222322222223222222233222222332222223332222244322222
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 129:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 130:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:000000ff000000ff000dd0ff00ddddff00ddddff000dd0ff000000ff000000ff
-- 137:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 151:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 152:000000ff000000ff000000ff000000ff000000ff000000ff000000ff000000ff
-- 153:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:000000ff000000ff000dd0ff00ddddff00ddddff000dd0ff000000ff000000ff
-- 169:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:222221103322110031211fff2111222021122200112221112111111011111100
-- 183:0000000000000000ffffffff0000000000000000000000000000000000000000
-- 184:000000ff000000ffffffffff0000000000000000000000000000000000000000
-- 185:ffffffffffffffffffffffff0000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 194:1121122111211321113113211131132111311321113143241131211214444444
-- 195:1121122111211321113113211131132111311321113123221131311312222222
-- 196:1121122111211321113113211131132111311321113133231131411413333333
-- 197:1221121113211211132113111321131113211311432413112112131144444441
-- 198:1221121113211211132113111321131113211311232213113113131122222221
-- 199:1221121113211211132113111321131113211311332313114114131133333331
-- 200:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 201:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 202:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 203:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 204:3333343333333411333321224442122233212233332123333212333342123333
-- 205:1111111122212222222122223331333333313333333133333331333333313333
-- 206:1111111122221222222212223333133333331333333313333333133333331333
-- 207:3333343311333433221234332221244433221233333212333333212333332124
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 210:1334244412344434122333341223322312222222122222221222222214422242
-- 211:1442322213422242133444421334433413333333133333331333333312233323
-- 212:1223433314233323144222231442244214444444144444441444444413344434
-- 213:4424444143444331333433212233322122232221222222212222242142222421
-- 214:2232222124222441444244313344433133343331333333313333323123333231
-- 215:3343333132333221222322414422244144424441444444414444434134444341
-- 216:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 217:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 218:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 219:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 220:2223333334333333121223333432343334323133121223333432222222233333
-- 221:3331333333313333333333333433343331333133333333332221222233313333
-- 222:3333133333331333333333333343334333133313333333332222122233331333
-- 223:3333312233333122333231223343212233132122333221222222312233333122
-- 224:0230000002300000023000000230000002300000023000000110000011110000
-- 225:0211000002131100021333110213311002111000021000000110000011110000
-- 226:1344224413444444133344331333343212233322122222221222222214422242
-- 227:1422332214222222144422441444424313344433133333331333333312233323
-- 228:1233443312333333122233221222232414422244144444441444444413344434
-- 229:4222444144243341444333313443223133322221222222212222422122224221
-- 230:2333222122324421222444414224334144433331333333313333233133332331
-- 231:3444333133432231333222212332442122244441444444414444344144443441
-- 232:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 233:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 236:2213333322133333221333332213333322133333221333332213333322133333
-- 237:3331333333313333333133333331333333313333333133333331333333313333
-- 238:3333133333331333333313333333133333331333333313333333133333331333
-- 239:3333312233433122223221223222312233333122322231222344212232223122
-- 240:0033330003322330332442233444443334444443124444230124423000111100
-- 241:0003300000343300002423000024220000242200002422000011110000011000
-- 242:0003300000033000000320000002200000022000000220000002100000011000
-- 243:0003300000334300003242000022420000224200002242000011110000011000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222312222233102223310002331000003100000000000
-- 246:0000000002200310222233212223322102332210003221000002100000000000
-- 247:0000000002200210223322212332222103222210002221000002100000000000
-- 248:0000000003300210332222213222222102222210002221000002100000000000
-- 252:2223333334333333121223333432343334323133121223333432222222233333
-- 253:3331333333313333333333333433343331333133333333332221222233313333
-- 254:3333133333331333333333333343334333133313333333332222122233331333
-- 255:3333312233333122333231223343212233132122333221222222312233333122
-- </TILES>

-- <TILES1>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
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
-- </TILES1>

-- <TILES2>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
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
-- </TILES2>

-- <TILES3>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
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
-- </TILES3>

-- <TILES4>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
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
-- </TILES4>

-- <TILES5>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
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
-- </TILES5>

-- <TILES6>
-- 001:1111111111111111111111111111111111111111111111111111111111111111
-- 002:3333333303000000003000000003000000003000000003000000003000000003
-- 003:6000000600000000006006000006600000066000006006000000000060000006
-- 004:fffffffffffffffffff77fffff7777ffff7777fffff77fffffffffffffffffff
-- 005:7777777770000007700000077000000770000007700000077000000777777777
-- 006:0000000000000000000000000000000000077000007007000700007070000007
-- 007:aaaaaaaaa008800aa080080aa000800aa008000aa080000aa088880aaaaaaaaa
-- 008:aaaaaaaaa008800aa000080aa000800aa000080aa080080aa008800aaaaaaaaa
-- 009:aaaaaaaaa008800aa008800aa080800aa088880aa000800aa000800aaaaaaaaa
-- 010:4443444444244444422244443332244433233244323333341333333311333333
-- 011:4443444444442444444222444422333442333333323333333313333331113331
-- 012:3333333333333333333333333333332222221123333312333333123333331233
-- 013:3333333333333333333333332233332232111123332112333322223333222233
-- 014:3333333333333333333333332233332232111123332112333322223333222233
-- 015:3333333333333333333333332233332232111123332112333322223333222233
-- 016:0100000013100000133100001333100013333100133110000113100000000000
-- 024:0000000000000000000000000000000000000000111111113333333322222222
-- 025:0000000000000000000000000000000000000000111111113333333122222221
-- 026:2113333322213331222123222212222221112222111112221111112211111112
-- 027:1122232222122222222122222222122222211122221111122111111111111111
-- 028:3333123333331232333312113333111233331123333312333333123333331233
-- 029:3322223323222232112222112112211232111123332112333322223333222233
-- 030:3322223323222232112222112112211232111123332112333322223333222233
-- 031:3322223323222232112222112112211232111123332112333322223333222233
-- 035:0000000000000033003330330033333300033333033333330333333300333333
-- 036:0000330003303330333033303333333333333333333333333333333333333333
-- 037:0000220033202220332333203333332233333222333333323333333233333322
-- 038:0000000022000000220222002222220022222000222222202222222022222200
-- 040:0211111102100000021000000210000002100000021000000210000002100000
-- 041:1121111000210000002100000021000000210000002100000021000000210000
-- 042:3333122233321222333122223331222233312222333122223332122233331222
-- 043:2222333322233333222333332223333322233333222333332223333322223333
-- 044:3333123333331232333312113333111233331123333312333333123333331233
-- 045:3322223323222232112222112112211232111123332112333322223333222233
-- 046:3322223323222232112222112112211232111123332112333322223333222233
-- 047:3322223323222232112222112112211232111123332112333322223333222233
-- 051:0333333303333333022333330033333322333333223323330222233200022222
-- 052:3333333333333333333333333333333333333333233323332333233222332222
-- 053:3333333233333332333332223333332233333322333233222332222222222222
-- 054:2222220022222220222222202222200022222222222222222222222022222000
-- 056:0000000000000000000000000000000000000033033333220222222202222222
-- 057:3330000033200000222000002110000033333330222222202222222011222110
-- 058:3333222233333222333332223333322233333222333332223333322233332222
-- 059:2221333322212333222213332222133322221333222213332221233322213333
-- 060:3322223323222232333333333333333333333333333333332222222222222222
-- 061:3322223323222232333333333333333333333333333333332222222222222222
-- 062:3322223323222232333333333333333333333333333333332222222222222222
-- 063:3322223323222232333333333333333333333333333333332222222222222222
-- 066:0000000000000033003330330033333300033333033333330333333300333333
-- 067:2222332223323332333233323333333333333333333333333333333333333333
-- 068:2222332223323332333233323333333333333333333333333333333333333333
-- 069:2222332223323332333233323333333333333333333333333333333333333333
-- 070:2222222233222222332333223333332233333222333333323333333233333322
-- 071:0000000022000000220222002222220022222000222222202222222022222200
-- 072:0112222200221122002211110022211100022122000112220002222200011111
-- 073:1111222021111220111122202112222221222222222222222211111111100000
-- 074:5555555555555555555555555555555555555555555555555555555555555555
-- 075:5555555555555555555555555555555555555555555555555555555555555555
-- 076:0000000011000000111200001221200022221200222212002222312022223120
-- 077:2332333323332333233323332333233323332333233223332222333322222233
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3333233233323332333233323332333233323332333223323333222233222222
-- 082:0333333303333333022333330033333322333333223323330222233200022222
-- 083:3333333333333333333333333333333333333333233323332333233222332222
-- 084:3333333333333333333333333333333333333333233323332333233222332222
-- 085:3333333333333333333333333333333333333333233323332333233222332222
-- 086:3333333233333332333332223333332233333322333233222332222222222222
-- 087:2222220022222220222222202222200022222222222222222222222022222000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:5555555555555555555555555555555555555555555555555555555555555555
-- 091:5555555555555555555555555555555555555555555555555555555555555555
-- 092:2222322222223242111111112121224211111242111111112222224222223222
-- 093:2444443324444443244444432444444324444443244444232222223323333344
-- 094:3333343333333433333334334444444433433333334333333343333344444444
-- 095:3344444234444442344444423444444234444442324444423322222244333332
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 098:0111122201111221000111110011111100111111001101110000011000000000
-- 099:1122221111222111111111111111111111111111111111111111111100111111
-- 100:1222122212221122122111111111111111111111222111111232211111232212
-- 101:2111222121111221111111111111111111121111122211112231112223211221
-- 102:1222211111222111111111111111111111111111111111111111111111111100
-- 103:2221111012211110111110001111110011111100111011000110000000000000
-- 104:5555555555555555000dd05500dddd5500dddd55000dd0550000005500000055
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:5555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555
-- 108:1422312212223122212231222422312212223122122231222122312222223122
-- 109:2443333324443333244433332444344424443333244233332223333323333344
-- 110:3333343333333433333334334444444433433333334333333343333344444444
-- 111:3333344233334442333344424443444233334442333324423333322244333332
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 120:0000005500000055000000550000005500000055000000550000005500000055
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:5555555555555555555555555555555555555555555555555555555555555555
-- 123:5555555555555555555555555555555555555555555555555555555555555555
-- 124:2222322222223242111111112121224211111242111111112222224222223222
-- 125:2444443324444443244444432444444324444443244444232222223323333344
-- 126:3333343333333433333334334444444433433333334333333343333344444444
-- 127:3344444234444442344444423444444234444442324444423322222244333332
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 136:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 137:5555555555555555555555555555555555555555555555555555555555555555
-- 138:4444444444444444443333334433333344333333443333334322222232222222
-- 139:4444444344444432333333223333332233333322333333222222222222222222
-- 140:3332333333323333444244442221222222212222222122221111111111111111
-- 141:3332333333323333444244442221222222212222222122221111111111111111
-- 142:3333333333333333333333333333333333333333333333333322222232222222
-- 143:3333333333333332333333223333332233333322333333222222222222222222
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:0003300033233004331120440211333403323334433010300434010000433100
-- 151:5555555555555555555555555555555555555555555555555555555555555555
-- 152:0000005500000055000000550000005500000055000000550000005500000055
-- 153:5555555555555555555555555555555555555555555555555555555555555555
-- 154:4444444344444432333333223333332233333322333333222222222222222222
-- 155:4444444344444432443333224433332244333322443333224322222232222222
-- 156:4444444344444432333333223333332233333322333333222222222222222222
-- 157:4444444444444444443333334433333344333333443333334322222232222222
-- 158:1111111111111111222222222222222222222222222222222222222222222222
-- 159:3333333333333333333333333333333333333333333333333322222232222222
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0000000000000001000000010000100100001100000011130000121300001223
-- 162:0002000000022000100222001102222021112322221133223223332333233222
-- 163:0200000003200002033200232333223322332333222323323322232233322223
-- 164:2002000020022000101222001112222021112322221133222223332333233222
-- 165:0200000003200000033200002333200222332023222322333322233333322332
-- 166:0000000000000000200000002001000020110000211100002111200022122000
-- 168:0000005500000055000dd05500dddd5500dddd55000dd0550000005500000055
-- 169:5555555555555555555555555555555555555555555555555555555555555555
-- 170:4444444444444444443333334432222244323333443233334432333344323333
-- 171:4444444344444432333333222222332233334322333343223333432233334322
-- 172:4444444444444444443333334433333344333333443333334322222232222222
-- 173:4444444344444432333333223333332233333322333333222222222222222222
-- 174:1111111111111111222222222222222222222222222222222222222222222222
-- 175:1111111111111111222222222222222222222222222222222222222222222222
-- 177:0111122200111122000113330002223311112223011112220011111100000011
-- 178:3323222223222333222233323223331133122221112222221222112211111111
-- 179:2333223322222333223332222333223333322223111122222112222211222111
-- 180:3223222222222333222233323223332233222222333222221222112211111111
-- 181:2333232222222223212222332122133311212112111122222112222211222111
-- 182:2222211033221100312115552111222021122200112221112111111011111100
-- 183:0000000000000000555555550000000000000000000000000000000000000000
-- 184:0000005500000055555555550000000000000000000000000000000000000000
-- 185:5555555555555555555555550000000000000000000000000000000000000000
-- 186:4432333344323333443233334432333344334444443333334322222232222222
-- 187:3333432233334322333343223333432244444322333333222222222222222222
-- 188:4444444344444432443333224433332244333322443333224322222232222222
-- 189:1111111111111111222222222222222222222222222222222222222222222222
-- 190:4444444344444432333333223333332233333322333333222222222222222222
-- 191:4444444444444444443333334433333344333333443333334322222232222222
-- 192:0011110001122110012334100112211000122100111111111233232113223231
-- 202:5555555555555555555555555555555555555555555555555555555555555555
-- 203:5555555555555555555555555555555555555555555555555555555555555555
-- 204:5555555555555555555555555555555555555555555555555555555555555555
-- 205:5555555555555555555555555555555555555555555555555555555555555555
-- 208:1323332111111111001121000012110001111110012344101111221112233441
-- 218:5555555555555555555555555555555555555555555555555555555555555555
-- 219:5555555555555555555555555555555555555555555555555555555555555555
-- 220:5555555555555555555555555555555555555555555555555555555555555555
-- 221:5555555555555555555555555555555555555555555555555555555555555555
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
-- </TILES6>

-- <TILES7>
-- 000:3333333331111111311111113111111131111111311111113111111131111111
-- 001:3333333333331111333311113333111133331111333311133333333333333333
-- 002:3333333333331111333331113333311133331111333111113311111133331111
-- 003:3333333333331133333311133333111133331111333311133333113333331113
-- 004:3333333333111111311111111111111111111111331113333311333333111333
-- 005:3333333311111111111111111111111111111111133333313333333131113333
-- 006:3333333311111111111111111111111111111111111133331113333111333311
-- 007:3333333311333311113333111133331111333311333333111333331111333311
-- 008:3333333311111111111111111111111111111111111111111111111111111111
-- 009:3333333311333311113331111333311113333331133333331133333311133333
-- 010:3333333311133111111331111111311111111111331111113333111133333311
-- 011:3333333311111111111111111111111111111111111333331133311313331113
-- 012:3333333311111111111111111111111111111111311111133311113333311333
-- 013:3333333311111111111111111111111111111111333331113113331111133331
-- 014:3333333311111111111111111111111111111111133331333333333313333333
-- 015:3333333311111113111111131111111311111113311111133311111331111113
-- 016:3111111131111111311111113111111131111111311111133111133331111333
-- 017:3333111133331111333311113333111133331111333333333333333333333333
-- 018:3333311113333111133333111333331113333311333333333333333333333333
-- 019:3333111333331113333311133333111333331113333333333333333333333333
-- 020:3311133333111333331113333311133333111333333333333333333333333333
-- 021:3111333331113333311133333111333331113333333333333333333333111111
-- 022:1133331111333311113333111133331111333311333333333333333311111333
-- 023:1133331111333311113333111133331111333311333333333333333131111111
-- 024:1111111111111111111111111111111111111111311111111111111111111111
-- 025:1111133311111111111111111331111113331111133331331113333311111333
-- 026:3333331133333311113333111113331111333311333333333333333333333333
-- 027:3333111333331133333333333333311133331111333333333333333333333333
-- 028:3331333333113333311133331111333311313333333333333333333333333333
-- 029:1113333111333311333331113311111111111131333333333333333333333333
-- 030:1133331111333311113331111133311111333111333333333333333333333333
-- 031:1111111311111113111111131111111311111113333111133331111333311113
-- 032:3111133331111333311113333111133331111333311113333111133331111333
-- 033:3333333333333333333333333333333333333333333333333333333333333333
-- 034:3333333333333333333333333333333333333333333333333333333333333333
-- 035:3333333333333333333333333333333333333333333333333333333333333333
-- 036:3333333333333331333333313333331133333111333331113333311133331111
-- 037:1111111111111111111111111111111111111111111111111111111111111111
-- 038:1111111111111111111111111111111111111111111111111111111111111111
-- 039:1111111111111111111111111111111111111111111111111111111111111111
-- 040:1111111111111111111111111111111111111111111111111111111111111111
-- 041:1111111111111111111111111111111111111111111111111111111111111111
-- 042:1111333311111333111111331111111311111111111111111111111111111111
-- 043:3333333333333333333333333333333333333333333333333333333313333333
-- 044:3333333333333333333333333333333333333333333333333333333333333333
-- 045:3333333333333333333333333333333333333333333333333333333333333333
-- 046:3333333333333333333333333333333333333333333333333333333333333333
-- 047:3331111333311113333111133331111333311113333111133331111333311113
-- 048:3111133331111333311113333111133331111333311113333111133331111333
-- 049:3333333333333333333333333333333333333333333333333333333333333333
-- 050:3333333333333333333333333333333333333333331111133313333131133331
-- 051:3333333333333333333333333333333333333333333333333333333333333333
-- 052:3333111133311111333111113331111133111111331111113111111131111111
-- 053:1111111111111111111111111111111111111111111111111111111111111111
-- 054:1111111111111113111133331133333313333333133333331333333333333333
-- 055:1133333133333333333333333333333333333333333333333333333333333333
-- 056:1111111133111111331111113331111133311111333111113333111133331111
-- 057:1111111111111111111111111111111111111111111111111111111111111111
-- 058:1111111111111111111111111111111111111111111111111111111111111111
-- 059:1333333313333333113333331133333311333333111333331113333311113333
-- 060:3333333333333333333333333333333333333333333333333333333333333333
-- 061:3333333333333333333333333333333333333333333333333333333333333333
-- 062:3333333333333333333333333333333333333333333333333333333333333333
-- 063:3331111333311113333111133331111333311113333111133331111333311113
-- 064:3111133331111333311113333111133331111333311113333111133331111333
-- 065:3333333333333333333333333333333333333333333333333333333333333333
-- 066:3113313131133313311133333311133333311111333311113333333333333333
-- 067:3333333333333331333333113333111111111111111111133333333333333333
-- 068:1111111111111111111111111111111113311111333111113331111133311111
-- 069:1111111111111111111111131111111311111113111111331111113311111133
-- 070:3333333333333333333333333333333333333333333333313333331233331112
-- 071:3333333333333333333333333333333331111113122222212222222222222222
-- 072:3333311133333111333333113333333133333333111333332221113322222211
-- 073:1111111111111111111111111111111131111111331111113333111113333111
-- 074:1111111111111111111111111111111111111111111111111111111111111111
-- 075:1111113311111113111111111111111111111111111111111111111111111111
-- 076:3333333333333333333333331133333311113333111111131111111111111111
-- 077:3333333333333333333333333333333333333333333333331113333311113333
-- 078:3333333333333333333333333333333333333333333333333333333333333333
-- 079:3331111333311113333111133331111333311113333111133331111333311113
-- 080:3111133331111333311113333111133331111333311113333111133331111333
-- 081:3333333333333333333333333333333333333333333333333333333333333333
-- 082:3333333333333333333333333333333333333333333333333333333333333333
-- 083:3333333333333333333333333333333333333333333333333333333133333311
-- 084:3331111133111111331111113111111131111111111111111111111111111111
-- 085:1111133311111333111113311111131211111122111112221111222211122222
-- 086:3331111131111222112222222222222222222222222222222222222222222222
-- 087:1122222222222222222222222222222222222222222222222222222222222222
-- 088:2222222222222222222222222222222222222222222222222222222222222212
-- 089:2113333122211133222221112222221122222222222222222222222222221111
-- 090:1111111131111111331111111333111111333311221133112222111111222211
-- 091:1111111111111111111111111111111111111111111111111111111111111111
-- 092:1111111111111111111111111111111111111133111113331111133311111333
-- 093:1111133311111133111111131331111333333111333331113333331133333311
-- 094:3333333333333333333333333333333333333333333333333333333313333333
-- 095:3331111333311113333111133331111333311113333111133331111333311113
-- 096:3111133331111333311113333111133331111333311113333111133331111333
-- 097:3333333333333333333333333333331133333111333311113331111133111111
-- 098:3333333333333333111111111111111111111111111111111111111133333333
-- 099:3333111133311111111111111111111111111111111111111111111111111111
-- 100:1111111111111111111111111111111111111111111111111111111111111111
-- 101:1112222211122222111222221112222211122222111222221112222111122211
-- 102:2222222222222222222222222222221222211222211122221122222222222222
-- 103:2222222222222222222222222222222222222222221111112113333121333333
-- 104:2222222222222222222222222222222222222222122222221111111233333311
-- 105:2222222222222222222222112221111112222222222222222222222212222222
-- 106:2222111122221122111111221122211222222111222211122221331221133312
-- 107:1111111111111111111111111111111111111111111111111111111111111111
-- 108:1111133311111133111111331111111111111111111111131111111311111113
-- 109:3333333133333331313333311133333113333331333333313333333133333331
-- 110:1333333313333333133333331333333313333333133333331333333313333333
-- 111:3331111333311113333111133331111333311113333111133331111333311113
-- 112:3111133331111333311113333111133331111333311113333111133331111333
-- 113:3311133331113111311311331113133311131333311331133111333331111133
-- 114:3333333311113333311113333311133333311333333113333311133331111333
-- 115:3111111133111111331111113311111133111111331111113311111133111111
-- 116:1111111111111111111111111111111111111111111111111111111111111111
-- 117:1112111211111222111112221111122211111222111112221111112111111113
-- 118:2222222222222221222221132222133322113333213333333333333333333333
-- 119:1333333333333333333333333333333333333333333333333333333333333333
-- 120:3333333333333333333333333333333333333333333333333311333313313333
-- 121:1111111133333333333333333333333333333333333333333333333333333333
-- 122:1133331233333312333332113333311133333121333331213333112133331222
-- 123:1111111121111111211111112111111121111111111111111111111111111111
-- 124:1111111111111111111111111111111111111111111111111111111111111111
-- 125:3333333133333331133333111333331111333311113331131133311311331133
-- 126:1333333333333333333333333333333333333333333333333333333333333333
-- 127:3331111333311113333111133331111333311113333111133331111333311113
-- 128:3111133331111333311113333111133331111333311113333111133331111333
-- 129:3111113333111111333311113333333333333333333333333333333333333333
-- 130:3111133311113333113333333333333333333333333333333333333133333311
-- 131:3311111133111111311111113111111131111111111111111111111111111111
-- 132:1111111111111111111111111111111111111111111111111111111111111111
-- 133:1111111311111113111111131111111111111111111111111111111111111111
-- 134:3333333333333333333333333333333333333333333333333333333313333333
-- 135:3331333133311333333311333333333333333333333333333333333133311113
-- 136:1133333331133333333333333333333333333333333333331113333333311333
-- 137:3333333333333333333333333333333333333333333333333333333333333333
-- 138:3333122233311212333112123311221133112111331221213112212131121111
-- 139:1111111111111111111111111111111111111111111111111111111111111111
-- 140:1111111111111111111111111111111111111111111111111111111111111111
-- 141:1133113311331133113313331131133313311333133133331331333333313333
-- 142:3333333333333333333333333333333333333333333333333333333333333333
-- 143:3331111333311113333111133331111333311113333111133331111333311113
-- 144:3111133331111333311113333111133331111333311113333111133331111333
-- 145:3333333333333333333333333333333333333331333333113333111133311113
-- 146:3333311133331111331111113111111311111133111133333333331133331111
-- 147:1111111111111111111111113311111131111111111111111111111111111111
-- 148:1111111111111111111111111111111111111111111111111111111111111111
-- 149:1111111111111111111111111111111111111111111111111111111111111111
-- 150:1333333313333333113333331133333311133333111333331111333311113333
-- 151:3311333333133311333333333333333333313333333113333333111133333333
-- 152:3333113311113113333333133333313333331133311113331111333333333333
-- 153:3333333333333333333333313333333133333311333331113333211133331112
-- 154:1122121111221211122121111221211122112111221211112212111121221111
-- 155:1111111111111111111111111111111111111111111111111111111111111111
-- 156:1111111111111113111111131111113311111133111113331111133311113333
-- 157:3331333333313313333133313331131133331113333333333333333333333333
-- 158:3333333333333333333333333333333333333333333333333333333333333333
-- 159:3331111333311113333111133331111333311113333111133331111333311113
-- 160:3111133331111333311113313111133131111311311111113111111131111113
-- 161:3111133311113331111311111333111313311133333111333331133333111333
-- 162:3111111111113311333331113333111133311111331111113111111111111111
-- 163:1111111111111111111111111111111111111111111111111111111111111111
-- 164:1111111111111111111111111111111111111111111111111111111111111111
-- 165:1111111111111111111111111111111111111111111111111111111111111111
-- 166:1111133311111133111111131111111111111111111111111111111111111111
-- 167:3333333333333333333333333333333313333333111333331111333311111133
-- 168:3333333333333333333333333333333333333331333333113333311133331111
-- 169:3331111233111122311112221111222111112221111222111122221111222212
-- 170:2121111111211111121111111211111122111111211111112111111111111113
-- 171:1111111111111111111111111111111111111111111111113111111131111113
-- 172:1113333311133333113333331333333313333333333333333333333333333333
-- 173:3333333333333333333333333333333333333333333333333333333333333333
-- 174:3333333333333333333333333333333333333333333333333333333333333333
-- 175:3331111333311113333111133331111333311113333111133331111333311113
-- 176:3111111331111113311111133111111331111111311111113111111131111131
-- 177:3311133133111311331111113331111133311111131111111111111111111111
-- 178:1111111111111111111111111111111111111111111111111111111131111111
-- 179:1111111111111111111111111111111111111111111111111111111111111111
-- 180:1111111111111111111111111111111111111111111111111111111111111111
-- 181:1111111111111111111111111111111111111111111111111111111111111111
-- 182:1111111111111111111111111111111111111111111111111111111111111111
-- 183:1111111111111111111111111111111111111111111111111111111111111111
-- 184:1111111111111111111111121111112211111222111122221112222211222222
-- 185:1222211222222122222211212222122122212211221122112212211121122111
-- 186:1111111311111113111111331111113311111333111113331111133311111333
-- 187:3111111331111113331111133311111333111113331111133311111333311111
-- 188:3333333333333333333333333333333333333333333113333311311333133313
-- 189:3333333333333333333333333333333333333333333333333333333333333333
-- 190:3333333333333333333333333333333333333333333333333333333333333333
-- 191:3331111333311113333111133331111333311113333111133331111333311113
-- 192:3111133331111333311113333111133331111333311113333111133331111331
-- 193:3111113333111331331133113113333131333333133333331333333333333333
-- 194:1111111111111111111111111111111131111111311111113311111133111111
-- 195:1111111111111113111111131111111311111133111111331111113311113333
-- 196:1111111131111111333111113333111133333311333333313333333333333333
-- 197:1111111111111111111111111111111111111111111111111111111131111111
-- 198:1111111111111111111111111111111111111111111111111111111111111122
-- 199:1111111211111122111112221111222211122222122222222222222222222222
-- 200:2222222222222222222222212222221122222211222221122222112222211222
-- 201:1122111112221111122111112221111122211111221111112211111121111111
-- 202:1111133311111333111113331111133311111333111113331111133311111333
-- 203:3331111133331111333331113333311133333311333333313333333333333333
-- 204:3313331113333313133311131111113311111333111111111111111131111111
-- 205:3333333333333333333333333333133333311333111133331113333333333333
-- 206:3333333333333333333333333333333333333333333333333333333333333333
-- 207:3331111333311113333111133331111333311113333111133331111333311113
-- 208:3111133131111313311113133111131331111333311111333111113331111133
-- 209:3333333333333333333333333333333333333333333333333333333333333333
-- 210:3311111133111111331111113311111133111113311113333111333311133333
-- 211:1113333313333333333333333333333333333333333333333333333333333333
-- 212:3333333333333333333333333333333333333333333333333133333313333333
-- 213:3311111133333333333333333333333333333311333311223311222211222222
-- 214:1111122211122222122222221222222222222222222222222222222222222222
-- 215:2222222222222222222222212222222122222111222211112221111222111122
-- 216:2211222221122222111222221112222211222221122222212222221122222211
-- 217:2111111111111111111111111111111111111111111111111111111111111111
-- 218:1111133311111333111113331111133311111333111113331111111111111111
-- 219:3333333333333333333333333333333333333331333331111111111111111112
-- 220:3331111133111212311122113111221111122121112211211221112122111221
-- 221:1133113311111111121111111211111112111113121111131211113322211133
-- 222:1113333311111111333331113333311133333333333333333333333333333333
-- 223:3331111311111113111111131111111333111113333111133331111333311113
-- 224:3111113331111113311111113111111131111111311111113111111131111111
-- 225:3333333133333111111111111111111111111111111111111111111111111111
-- 226:1133333313333333111111111111111111111111111111111111111111111111
-- 227:3333333333333333133311113333111133331111333311113333333133333333
-- 228:1333311133311122333311111333111111331111111111111111113333111333
-- 229:2222222222222222131111111331111133311111333111113333311333333113
-- 230:2222222222222111111111111111111111111111111111113331111333311333
-- 231:1122122222222222111111111111111111111111111111113311111333111133
-- 232:2222211322223333111113331111133311111333111113333333333333333333
-- 233:3111111131113331311333333113333331113331311111113111133331133333
-- 234:1111111111111111111111111111111111111111111111111111133311113333
-- 235:1111222222222222111111111111111111111111111111113311111133331111
-- 236:2111121111122211111111111111111111111111111111111133333133333333
-- 237:2211133322113333111111111111111111111111111111111111111131111111
-- 238:3333333333333333111111111111111111111111111111111111111111111111
-- 239:3331111333311113111111131111111311111113111111131111111311111113
-- 240:3111111131111111311111113111111131111111311111113111111133333333
-- 241:1111111111111111111111111111111111111111111111111111111133333333
-- 242:1111111111111111111111111111111111111113111111131111111333333333
-- 243:1333333311333333111113331111111131111111331111113331111133333333
-- 244:3333111333331113333331133333311313333113133311133333111333333333
-- 245:3331111333311113333111133331111333311113333111133331111333333333
-- 246:3331113333311133333111333331113333311133333111333331113333333333
-- 247:3311133333111333331133333311333333113333331133333311133333333333
-- 248:3311133331111333311113333111133331111333311113333111133333333333
-- 249:3111333331113333311133333111333331113333311133333111333333333333
-- 250:1113331111333311113331111133311111333111113333111113331133333333
-- 251:1133311111333311111333111113331111133311113333111133311333333333
-- 252:3331111333331111333333113333333313333333111113333111133333333333
-- 253:3111111111111111111111111111111131111111311111113111111133333333
-- 254:1111111111111111111111111111111111111111111111111111111133333333
-- 255:1111111311111113111111131111111311111113111111131111111333333333
-- </TILES7>

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
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
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
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
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
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:01342222133322223133222211333222f1333333f1133333ff111333fff11111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
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
-- 198:0000000000000000000000000010010001214110124414211224412101111110
-- 199:0000000001100110001331000013210000122100001211000011110000011000
-- 200:0200000022200000020000000000000000000000000000200000022200000020
-- 203:0000000000000000000000000000000000000000000000000000000000000011
-- 204:0111111101212212001222220122222212333332124444430144444211344432
-- 205:0000000010000000110000001210000021000000210000002210000011110000
-- 208:0000000000000000000000000000001100000133000013320011332101213313
-- 209:0000000000000000000000001010000031310000123310001113310033323100
-- 210:0022220002311320021331200213312002133120021331202213312202122120
-- 219:0001112200112222011212221212212212211222122222221444422214444311
-- 220:2222223213332332111332232221333322221222222221332222221311222222
-- 221:3222100031121100212222102122211032222221111222212113222111143331
-- 222:0000000000000000000000000000000100000014000001120000134400013333
-- 223:0000000000000000000000001100000044100000244100003244100043244100
-- 224:012123340121123301211222012112331443223314433232f1233223f1222233
-- 225:4442310044423100222210002223210032222100232221003332310033332410
-- 226:0222222022244222224224222242242222444422224224221222222101111110
-- 227:02222220224442222242242222444222224224222244422212222221f1111110
-- 235:0144443101444431001443410001444300001444000001440000001400000001
-- 236:1111222212211111122222231333123333331123344431124443431144343333
-- 237:1114444111144441311144413144443134443110344410002331000033310000
-- 238:0001343300133433000123220001444400001444000001220001123300012323
-- 239:3324410023244100421441004314100011114100100010002110000023100000
-- 240:f1212233f1212131f1211111f121f111f121f113f121f132f121ff12ff1ffff1
-- 241:1113241011112100111110003331100011231000112100001121000011110000
-- 242:0222222f22422422224224222224422222422422224224221222222101111110
-- 243:f222222022422422224224222224442222222422222442221222222101111110
-- 244:0222222022244222224222222224222222224222224422221222222101111110
-- 251:0000000000000000000000010000000100000001000000130000001300000011
-- 252:1342222211111111333101332221012223210123322101323221013311110111
-- 253:2210000011000000310000002100000021000000221000002210000011100000
-- 254:0001222200014122000143220001132200001111000012110001321100011111
-- 255:2311000011310000313100003111000011100000121000003210000011100000
-- </SPRITES>

-- <SPRITES1>
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
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
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
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
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
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
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
-- 198:0000000000000000000000000010010001214110124414211224412101111110
-- 199:0000000001100110001331000013210000122100001211000011110000011000
-- 200:0200000022200000020000000000000000000000000000200000022200000020
-- 203:0000000000000000000000000000000000000000000000000000000000000011
-- 204:0111111101212212001222220122222212333332124444430144444211344432
-- 205:0000000010000000110000001210000021000000210000002210000011110000
-- 208:0000000000000000000000000000001100000133000013320011332101213313
-- 209:0000000000000000000000001010000031310000123310001113310033323100
-- 219:0001112200112222011212221212212212211222122222221444422214444311
-- 220:2222223213332332111332232221333322221222222221332222221311222222
-- 221:3222100031121100212222102122211032222221111222212113222111143331
-- 222:0000000000000000000000000000000100000014000001120000134400013333
-- 223:0000000000000000000000001100000044100000244100003244100043244100
-- 224:0121233401211233012112220121123314432233144332320123322301222233
-- 225:4442310044423100222210002223210032222100232221003332310033332410
-- 235:0144443101444431001443410001444300001444000001440000001400000001
-- 236:1111222212211111122222231333123333331123344431124443431144343333
-- 237:1114444111144441311144413144443134443110344410002331000033310000
-- 238:0001343300133433000123220001444400001444000001220001123300012323
-- 239:3324410023244100421441004314100011114100100010002110000023100000
-- 240:0121223301212131012111110121011101210113012101320121001200100001
-- 241:1113241011112100111110003331100011231000112100001121000011110000
-- 251:0000000000000000000000010000000100000001000000130000001300000011
-- 252:1342222211111111333101332221012223210123322101323221013311110111
-- 253:2210000011000000310000002100000021000000221000002210000011100000
-- 254:0001222200014122000143220001132200001111000012110001321100011111
-- 255:2311000011310000313100003111000011100000121000003210000011100000
-- </SPRITES1>

-- <SPRITES2>
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
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
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
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
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
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
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
-- 198:0000000000000000000000000010010001214110124414211224412101111110
-- 199:0000000001100110001331000013210000122100001211000011110000011000
-- 200:0200000022200000020000000000000000000000000000200000022200000020
-- 203:0000000000000000000000000000000000000000000000000000000000000011
-- 204:0111111101212212001222220122222212333332124444430144444211344432
-- 205:0000000010000000110000001210000021000000210000002210000011110000
-- 208:0000000000000000000000000000001100000133000013320011332101213313
-- 209:0000000000000000000000001010000031310000123310001113310033323100
-- 219:0001112200112222011212221212212212211222122222221444422214444311
-- 220:2222223213332332111332232221333322221222222221332222221311222222
-- 221:3222100031121100212222102122211032222221111222212113222111143331
-- 222:0000000000000000000000000000000100000014000001120000134400013333
-- 223:0000000000000000000000001100000044100000244100003244100043244100
-- 224:0121233401211233012112220121123314432233144332320123322301222233
-- 225:4442310044423100222210002223210032222100232221003332310033332410
-- 235:0144443101444431001443410001444300001444000001440000001400000001
-- 236:1111222212211111122222231333123333331123344431124443431144343333
-- 237:1114444111144441311144413144443134443110344410002331000033310000
-- 238:0001343300133433000123220001444400001444000001220001123300012323
-- 239:3324410023244100421441004314100011114100100010002110000023100000
-- 240:0121223301212131012111110121011101210113012101320121001200100001
-- 241:1113241011112100111110003331100011231000112100001121000011110000
-- 251:0000000000000000000000010000000100000001000000130000001300000011
-- 252:1342222211111111333101332221012223210123322101323221013311110111
-- 253:2210000011000000310000002100000021000000221000002210000011100000
-- 254:0001222200014122000143220001132200001111000012110001321100011111
-- 255:2311000011310000313100003111000011100000121000003210000011100000
-- </SPRITES2>

-- <SPRITES3>
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
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
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
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
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
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
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
-- 198:0000000000000000000000000010010001214110124414211224412101111110
-- 199:0000000001100110001331000013210000122100001211000011110000011000
-- 200:0200000022200000020000000000000000000000000000200000022200000020
-- 203:0000000000000000000000000000000000000000000000000000000000000011
-- 204:0111111101212212001222220122222212333332124444430144444211344432
-- 205:0000000010000000110000001210000021000000210000002210000011110000
-- 208:0000000000000000000000000000001100000133000013320011332101213313
-- 209:0000000000000000000000001010000031310000123310001113310033323100
-- 219:0001112200112222011212221212212212211222122222221444422214444311
-- 220:2222223213332332111332232221333322221222222221332222221311222222
-- 221:3222100031121100212222102122211032222221111222212113222111143331
-- 222:0000000000000000000000000000000100000014000001120000134400013333
-- 223:0000000000000000000000001100000044100000244100003244100043244100
-- 224:0121233401211233012112220121123314432233144332320123322301222233
-- 225:4442310044423100222210002223210032222100232221003332310033332410
-- 235:0144443101444431001443410001444300001444000001440000001400000001
-- 236:1111222212211111122222231333123333331123344431124443431144343333
-- 237:1114444111144441311144413144443134443110344410002331000033310000
-- 238:0001343300133433000123220001444400001444000001220001123300012323
-- 239:3324410023244100421441004314100011114100100010002110000023100000
-- 240:0121223301212131012111110121011101210113012101320121001200100001
-- 241:1113241011112100111110003331100011231000112100001121000011110000
-- 251:0000000000000000000000010000000100000001000000130000001300000011
-- 252:1342222211111111333101332221012223210123322101323221013311110111
-- 253:2210000011000000310000002100000021000000221000002210000011100000
-- 254:0001222200014122000143220001132200001111000012110001321100011111
-- 255:2311000011310000313100003111000011100000121000003210000011100000
-- </SPRITES3>

-- <SPRITES4>
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
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
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
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
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
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
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
-- 198:0000000000000000000000000010010001214110124414211224412101111110
-- 199:0000000001100110001331000013210000122100001211000011110000011000
-- 200:0200000022200000020000000000000000000000000000200000022200000020
-- 203:0000000000000000000000000000000000000000000000000000000000000011
-- 204:0111111101212212001222220122222212333332124444430144444211344432
-- 205:0000000010000000110000001210000021000000210000002210000011110000
-- 208:0000000000000000000000000000001100000133000013320011332101213313
-- 209:0000000000000000000000001010000031310000123310001113310033323100
-- 219:0001112200112222011212221212212212211222122222221444422214444311
-- 220:2222223213332332111332232221333322221222222221332222221311222222
-- 221:3222100031121100212222102122211032222221111222212113222111143331
-- 222:0000000000000000000000000000000100000014000001120000134400013333
-- 223:0000000000000000000000001100000044100000244100003244100043244100
-- 224:0121233401211233012112220121123314432233144332320123322301222233
-- 225:4442310044423100222210002223210032222100232221003332310033332410
-- 235:0144443101444431001443410001444300001444000001440000001400000001
-- 236:1111222212211111122222231333123333331123344431124443431144343333
-- 237:1114444111144441311144413144443134443110344410002331000033310000
-- 238:0001343300133433000123220001444400001444000001220001123300012323
-- 239:3324410023244100421441004314100011114100100010002110000023100000
-- 240:0121223301212131012111110121011101210113012101320121001200100001
-- 241:1113241011112100111110003331100011231000112100001121000011110000
-- 251:0000000000000000000000010000000100000001000000130000001300000011
-- 252:1342222211111111333101332221012223210123322101323221013311110111
-- 253:2210000011000000310000002100000021000000221000002210000011100000
-- 254:0001222200014122000143220001132200001111000012110001321100011111
-- 255:2311000011310000313100003111000011100000121000003210000011100000
-- </SPRITES4>

-- <SPRITES5>
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
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
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
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
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
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
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
-- 198:0000000000000000000000000010010001214110124414211224412101111110
-- 199:0000000001100110001331000013210000122100001211000011110000011000
-- 200:0200000022200000020000000000000000000000000000200000022200000020
-- 203:0000000000000000000000000000000000000000000000000000000000000011
-- 204:0111111101212212001222220122222212333332124444430144444211344432
-- 205:0000000010000000110000001210000021000000210000002210000011110000
-- 208:0000000000000000000000000000001100000133000013320011332101213313
-- 209:0000000000000000000000001010000031310000123310001113310033323100
-- 219:0001112200112222011212221212212212211222122222221444422214444311
-- 220:2222223213332332111332232221333322221222222221332222221311222222
-- 221:3222100031121100212222102122211032222221111222212113222111143331
-- 222:0000000000000000000000000000000100000014000001120000134400013333
-- 223:0000000000000000000000001100000044100000244100003244100043244100
-- 224:0121233401211233012112220121123314432233144332320123322301222233
-- 225:4442310044423100222210002223210032222100232221003332310033332410
-- 235:0144443101444431001443410001444300001444000001440000001400000001
-- 236:1111222212211111122222231333123333331123344431124443431144343333
-- 237:1114444111144441311144413144443134443110344410002331000033310000
-- 238:0001343300133433000123220001444400001444000001220001123300012323
-- 239:3324410023244100421441004314100011114100100010002110000023100000
-- 240:0121223301212131012111110121011101210113012101320121001200100001
-- 241:1113241011112100111110003331100011231000112100001121000011110000
-- 251:0000000000000000000000010000000100000001000000130000001300000011
-- 252:1342222211111111333101332221012223210123322101323221013311110111
-- 253:2210000011000000310000002100000021000000221000002210000011100000
-- 254:0001222200014122000143220001132200001111000012110001321100011111
-- 255:2311000011310000313100003111000011100000121000003210000011100000
-- </SPRITES5>

-- <SPRITES6>
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
-- 014:0000000000000000000000000000000000000000000000000000000000011111
-- 015:0000000000000000000000000000000000000000000000000000000010000010
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
-- 030:0112212201312122001121120132214101111214012232210122132200111133
-- 031:2111112022444320244443202443332012432220122222201224222011122200
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
-- 128:0000000000000000001101110133133300113422001342220013222201342222
-- 129:0000000000000000110011003311331022331100222231002222231022222331
-- 130:0000000000000000001000000131011100131333000134220013422200132222
-- 131:0000000000000000000001001100131033113100223310002222310022222310
-- 132:0000000000000000000000000010001101310133001314220001422200132222
-- 133:0000000000000000000000001100001033110131223313102222310022222310
-- 134:0000000000000000001000000131011100131333000134220013422200132222
-- 135:0000000000000000000001001100131033113100223310002222100022222100
-- 144:0134222213332222313322221133322201333333011333330011133300011111
-- 145:2222231322222311222223102222331022233310333331103333110011111000
-- 146:0134222201342222133322223133222211333222011333330011133300111111
-- 147:2222233122222313222223112222231022223310222331103333110011111100
-- 148:0134222211342222333322221333222213333222113333330111133301111111
-- 149:2222233122222313222223112222233122223331222333113333111011111110
-- 150:0134222201342222133322223133322211333333011333330011133300011111
-- 151:2222231022222130222221102222310022233100333311003333100011111000
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
-- 198:0000000000000000000000000010010001214110124414211224412101111110
-- 199:0000000001100110001331000013210000122100001211000011110000011000
-- 200:0200000022200000020000000000000000000000000000200000022200000020
-- 203:0000000000000000000000000000000000000000000000000000000000000011
-- 204:0111111101212212001222220122222212333332124444430144444211344432
-- 205:0000000010000000110000001210000021000000210000002210000011110000
-- 208:0000000000000000000000000000001100000133000013320011332101213313
-- 209:0000000000000000000000001010000031310000123310001113310033323100
-- 219:0001112200112222011212221212212212211222122222221444422214444311
-- 220:2222223213332332111332232221333322221222222221332222221311222222
-- 221:3222100031121100212222102122211032222221111222212113222111143331
-- 222:0000000000000000000000000000000100000014000001120000134400013333
-- 223:0000000000000000000000001100000044100000244100003244100043244100
-- 224:0121233401211233012112220121123314432233144332320123322301222233
-- 225:4442310044423100222210002223210032222100232221003332310033332410
-- 235:0144443101444431001443410001444300001444000001440000001400000001
-- 236:1111222212211111122222231333123333331123344431124443431144343333
-- 237:1114444111144441311144413144443134443110344410002331000033310000
-- 238:0001343300133433000123220001444400001444000001220001123300012323
-- 239:3324410023244100421441004314100011114100100010002110000023100000
-- 240:0121223301212131012111110121011101210113012101320121001200100001
-- 241:1113241011112100111110003331100011231000112100001121000011110000
-- 251:0000000000000000000000010000000100000001000000130000001300000011
-- 252:1342222211111111333101332221012223210123322101323221013311110111
-- 253:2210000011000000310000002100000021000000221000002210000011100000
-- 254:0001222200014122000143220001132200001111000012110001321100011111
-- 255:2311000011310000313100003111000011100000121000003210000011100000
-- </SPRITES6>

-- <SPRITES7>
-- 000:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 001:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 002:fffffffffffffffffffffffffffffffffffffffffffffffffffffff1ffffff11
-- 003:fffffffffffffffffffffffffffffffffffffffff11111111111111111111111
-- 004:ffffffffffffffffffffffffffffffffffffffffffffffff11ffffff111fffff
-- 005:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 006:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 007:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 008:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 009:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 010:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 011:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 012:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 013:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 014:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 015:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 016:ffffffffff11111ff11111111114241111424241112422211142222111122211
-- 017:ffffffffffffffffffffffff1fffffff1fffffff1fffff111fff11111ff11111
-- 018:fffff111fffff111ffff1111ffff1114f1111114111111241111114424442424
-- 019:1144444144242424444442442424242444444442242424244244424224242424
-- 020:111fffff11111111411111112411111142424242242424224242424222242222
-- 021:ffffffff111111ff111111111111111142424111242222214242424222222222
-- 022:ffffffffffffffffffffffff1fffffff11ffffff111fffff111fffff2111ffff
-- 023:fffffffffffffffffffffffffffffffffffffffffffffffff1111fff1111111f
-- 024:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 025:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 026:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 027:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 028:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 029:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 030:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 031:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 032:f1111111ff111111ffffffffffffffffffffffffffffffffffffffffffffffff
-- 033:1f111144ff111444f1111444f1114444f11144441114444411144444f1112444
-- 034:4444444444244424444444442444242444444444442424244444424424242424
-- 035:4444444224242424424442422424242444424442242424244242424124111111
-- 036:4242424224242422424242422224222242424242112224221112424211122222
-- 037:4242422222222222424222422222222242424222222222222242222222222222
-- 038:4111fff12111ff112111ff1121111f1122111f1122211ff122211ff1222111ff
-- 039:1144111f142421114442421124222211124221111122111f1111111ff1111fff
-- 040:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 041:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 042:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 043:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 044:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 045:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 046:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 047:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 048:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 049:f1114444f1114424f1111444ff111124fff11111ffff1111fffff111fffffff1
-- 050:44444442442424244444424224242421444244111111111111111111111111ff
-- 051:411111112111111f1111ffff111fffff11ffffff1fffffffffffffffffffffff
-- 052:11114242f1112222f1111142ff111111fff11111fffff111ffffffffffffffff
-- 053:422242222222222221112222111112221111112211111111fff11111fffff111
-- 054:222211ff222111ff222111ff222111ff21111f11111111111111111111111113
-- 055:fffffffffffffffffffffffff111111f11111111111111111131111133111111
-- 056:ffffffffffffffffffffffffffffffff1fffffff11ffffff11ffffff11ffffff
-- 057:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 058:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 059:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 060:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 061:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 062:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 063:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 064:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 065:fffffffffffff111ffff1111fff11144fff11444fff11424fff11242fff11122
-- 066:ffffffff11ffffff111fffff2111ffff4211ffff2211ffff2211ffff2111ffff
-- 067:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 068:fffffffffffffffffffffffffffffff1ffffff11fffff111ffff1111fff11111
-- 069:fffff111fff11111f11111131111113311113333113331113311111111111111
-- 070:1111333313333311333311113311111111111113111113231113333313232323
-- 071:1111113311111323111333331333232333333333332333233333333323232323
-- 072:111fffff111fffff111fffff111fffff111fffff111fffff111fffff2111ffff
-- 073:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 074:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 075:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 077:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 078:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 079:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 080:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 081:ffff1111fffff111ffffffffffffffffffffffffffffffffffffffffffffffff
-- 082:111fffff11ffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 083:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 084:fff11111fff11111fff11133fff11113ffff1111ffff1111fffff111ffffff11
-- 085:1111113311132323333333332323232333333333132323231133333311232323
-- 086:3333333333232323333333332323232333333333232323233233323323232323
-- 087:3333333333232323333333332323232333333333232323233233323323232323
-- 088:3111ffff31111fff331111ff2321111f33331111232321113233321123232323
-- 089:ffffffffffffffffffffffffffffffff1fffffff11ffffff1111ffff111111ff
-- 090:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 091:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 092:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 093:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 094:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 095:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 096:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 097:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 098:ffffffffffffffffffffff11fff11111ff111111f1111133f111333311113333
-- 099:ffffffffffffffff11ffffff1111ffff11111fff311111ff3331111f3333111f
-- 100:fffffff1ffffffffffffffffffff1111fff11111ff111111ff111333f1113333
-- 101:1113333311112323f1113233ff11132111111311111111111111111111111113
-- 102:3333333323232323323332331111112311111111111111113333311133333331
-- 103:3333333323232323323332332323232133323111132311111132111311211133
-- 104:3333333323232323323332331323231111113111111111113111111333111113
-- 105:3111111123211111323331111113232111113311111111113311111133111133
-- 106:ffffffff1fffffff111111ff1111111f11111111111331111333111133311111
-- 107:fffffffffffffffffffffffffffffffffffff1111fff11111111111111111133
-- 108:fffffffffffffffffffffffffffffff1111fff111111ff113111111133111111
-- 109:ffffffffffffffffffffffff11111fff111111f1111111111333111133331111
-- 110:fffffffffffffffff11111ff1111111f1111111f113331111133311111333111
-- 111:ffffffffffffffffffffffffffffffffff111ffff111111f1111111111131111
-- 112:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 113:fffffffffffffffffffffffffffffff1fffffff1fffffff1fffffff1fffffff1
-- 114:1113331111133311113333111123231111333311112323111132321111232311
-- 115:1333111f13333111133331111123211111333311112323111132323111132321
-- 116:f1113333f1113333f11133331111233311113333111323211113323111132321
-- 117:1111113311111133111111331111113311111133111111231111113311111123
-- 118:3333333131113331311111112111111133111111231113233211123123111311
-- 119:1131113311211133113111331121113312311133112111231111113311111123
-- 120:3311111333111113331111132311111333111133232113233233323323232323
-- 121:3311113333111133331111332311113333111113231111133211111323111113
-- 122:3311111233111111331111112311111133311133232323213233321123231111
-- 123:3111113313111333111113331111133311111333111113231111133311111323
-- 124:3331111333311113333111133333111333333333232323233233323321132323
-- 125:3333311133333111333331112333211133333111232321113232311111232111
-- 126:1133311111333111113331111133211111333333112323231132323211232323
-- 127:113331111333311133333111233311113331111f232111ff321111ff11111fff
-- 128:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 129:fffffff1fffffff1fffffff1ffffffffffffffffffffffffffffffffffffffff
-- 130:1132321111222321113232321122222211123222111222211112222111112221
-- 131:1112323113222321323232312222222111113222111112221111111111111111
-- 132:1112323111122321111232311112222111123222111222221111222211111122
-- 133:1111111211111113111111121111111132111111222111112211111111111221
-- 134:3211111123211111323111122222111232323222122222221122222211112221
-- 135:1211113223111123321111322211112232111132221111222111111211111112
-- 136:3232323223232323321111322211111231111112211111122111111222111112
-- 137:3211111223111111321111112211111132111111221113112111321121112221
-- 138:3332111123231111323231112222221112223222122222221122222211222211
-- 139:1111123211111322111112321111122231111222111112221111112211111112
-- 140:3111323121112321311132112111121131111111211111112111111111131121
-- 141:1132311111222111113221111122211111222111112221111122211111121111
-- 142:113232311122232111323211122222111222311112222111122211111121111f
-- 143:1111ffff111fffff11ffffff1fffffffffffffffffffffffffffffffffffffff
-- 144:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 145:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 146:f1111221f1111111ff111111ffff1111fffff111ffff1111fff11113ff111133
-- 147:11f1111111ffffff1111ffff111111ff11111111333111113333311133333311
-- 148:11111111fff11111ffffff11fff11111f1111111111111111111333311333333
-- 149:1111123211112322123232321223222311323232111123221111123131111211
-- 150:1111111121111111323211122223222331113231111111211111111111311111
-- 151:1112111113222111311232311111112311111112113111111133111111332111
-- 152:1111111111112111111211112211111131111111111133331113333311133333
-- 153:1111323111122322113232321111222211111132311111123333111123332111
-- 154:1111111111111111311111122223111132111111211111111111333111133331
-- 155:1132111113221111323232112223211112321111132211131131111311211123
-- 156:1112323211222322123232321111111211111111311111113333311123211111
-- 157:1111111111111111321111312111111111111111111113311333333313333333
-- 158:111111ff11111fff111fffff11ffffff1111ffff1111ffff31111fff23111fff
-- 159:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 160:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 161:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 162:ff111333ff111323f1113333f1112323f1113333111323211112323111132321
-- 163:33333311111133111111311111111111111111111111111111ff111111ff1111
-- 164:1133333311333323113331131123111113321111232311113232111122211111
-- 165:3311111133211111333111112323111133321111132311111232111112231111
-- 166:1333111113231111133311111323111113321111132311111232111112231111
-- 167:1133311111232311113332111123231111323311112323111132321111222211
-- 168:1133331111233111113331111123211113333111132311111232111113232323
-- 169:3333311113232111113331111123211111323111132321111232111122211111
-- 170:1113333111133321111333311123232111323331112323211132323111232221
-- 171:1131113311111323111112331111132311111332111123231111323211112223
-- 172:3311111123111111311111112111111132111111232321113232311121111111
-- 173:1333333333211113333111112321111133311111232111113231111222211123
-- 174:333111ff332111ff333111ff232111ff333111ff232111ff321111ff21111fff
-- 175:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 176:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 177:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 178:11123231111223211112323111122221f1113222f1112222f1111222ff111112
-- 179:1111111111111111111111111122211132223111222221112222111122111111
-- 180:3231111123221111323211112222111112223222122222221122222211112222
-- 181:1232111113221111123211112222111132221111222111122221113221111122
-- 182:1232311113222111113221111122222211223222111222221111222221111222
-- 183:1132321111222111113221112222211122222111222221112222111122211111
-- 184:1232323213222322123232322222111232321112222211111221111111111111
-- 185:3211113123111221321111322221112232221112222211122222111212211112
-- 186:1132323111222221113222111112221111123211111222111112221111111111
-- 187:1111323211122222111222321112222211123222111122221111222211111111
-- 188:1111111111111111111111111111111122111111222111112211111111111f11
-- 189:3232323223222222323222322222211212223111122221111222211112222111
-- 190:31111fff221111ff2231111f2222111f2222211112222111112211111111111f
-- 191:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 192:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 193:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 194:fff11111ffff1111ffffffffffffffffffffffffffffffffffffffffffffffff
-- 195:111111ff11111fffffffffffffffffffffffffffffffffffffffffffffffffff
-- 196:11111111ff111111ff111222ff111222fff11122fff11122fff11122fff11122
-- 197:1111122211112222223222222222222232223222222222222222424222222422
-- 198:3111111122111111223211112222224232223224222222222222222222222224
-- 199:1111111111111122111122222422222242223222222222222222222222222222
-- 200:1111111111112211223222222222222222223222222222222222222222222222
-- 201:1111113211111232111233224242222224223222222222222222222222222222
-- 202:3111111121111112222222222222222222223221222221112221111121111111
-- 203:3211111122221111221111112111111f11111fff111fffff11ffffffffffffff
-- 204:1111fff111fffff1ffffffffffffffffffffffffffffffffffffffffffffffff
-- 205:111111111111111f11111fffffffffffffffffffffffffffffffffffffffffff
-- 206:111111fff1111fffffffffffffffffffffffffffffffffffffffffffffffffff
-- 207:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 208:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 209:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 210:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 211:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 212:fff11122fff11122ffff1112ffff1111ffff1111fffff111ffffff11fffffff1
-- 213:3222424222222222222222222222222222222222112222221111122211111111
-- 214:3222224222222224222222222222222222222222222222222222222211111111
-- 215:4222224422222422222224222222224422222222222222212221111111111111
-- 216:2222222242222222422222222222221122211111111111111111111f1111ffff
-- 217:2222221122221111221111111111111f11111fff11ffffffffffffffffffffff
-- 218:111111ff1111ffff1fffffffffffffffffffffffffffffffffffffffffffffff
-- 219:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 220:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 221:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 222:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 223:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 224:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 225:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 226:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 227:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 228:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 229:f1111111fffff111ffffffffffffffffffffffffffffffffffffffffffffffff
-- 230:1111111111111111ffffffffffffffffffffffffffffffffffffffffffffffff
-- 231:1111111f11ffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 232:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 233:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 234:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 235:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 236:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 237:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 238:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 239:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 240:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 241:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 242:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 243:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 244:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 245:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 246:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 247:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 248:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 249:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 250:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 251:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 252:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 253:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 254:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 255:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- </SPRITES7>

-- <MAP>
-- 004:a8aaba000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:a9abbbe0e0e0e0e0e0e0e0f0c10000000000000000000000000000000000000000000000000000000000000000000000c0d0e0e0e0e0e0e0e0e0e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:a8aabae1e1e1e1e1e1e1e1f100000000000000c0d0e0e0e0e0e0e0e0e0f0c1000000000000003242526200000000000000d1e1e1e1e1e1e1e1e1e1e1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:a9abbbe2e2e2e2e2e2e2e2f20000000000000000d1e1e1e1e1e1e1e1e1f100000000000000003343536300000000000000d2e2e2e2e2e2e2e2e2e2e2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:a8aabae4e4e4e4e4e4e4e4f40000000000000000d2e2e2e2e2e2e2e2e2f200000000000000243434344454000000000000d4e4e4e4e4e4e4e4e4aaba000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:a9abbbe4e4e4e4e4e4e4e4f50000000000000000d3e3e3e3e3e3e3e3e3f300000000000000253535354555000000000000d5e5e5e5e5e5e5e5e5abbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:a8aabae4e4e40000000000c20000000000000000d4e4e4e4ccdcecfce4f400000000000000263646566676000000000000c20000000000e4e4e4aaba000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:a9abbbe5e5000070000000c30000000000000000d5e4e4e4cdddedfde4f500000000000000383747576777000083930000c3000090000000e5e5abbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:b8aabae4e4819170000000c4001a2a3a4a5a6a00d4e4e4e4cedeeefee4f4009696000c0000969648589696969684940000c4000090007191e4e4aaba000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:b9abbbe5e5829270000000c5001b2b3b4b5b6b00d5e4e4e4cfdfefffe4f5009797000d0000979749599797979785950000c5000090007292e5e5abbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c80111011101110111011101110111d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:c9d9c9d9c9d9c9d9c9d9c9d92c5cc9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c90212021202120212021202120212d9c92c5cd9c9d9c9d9c9d9c9d9c9d9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:e8f8e8f8e8f8e8f8e8f8e8f82d5de8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8a80313031303130313031303130313b8a82d5db8a8b8a8b8a8b8a8b8a8b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:0000000000000000000000002e3e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <MAP1>
-- 004:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:a8b8cadaeafaeafae8f8e8f8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:a9b9cbdbebfbebfbe9f9e9f9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP1>

-- <MAP2>
-- 004:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:a8b8cadaeafaeafae8f8e8f8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:a9b9cbdbebfbebfbe9f9e9f9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP2>

-- <MAP3>
-- 004:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:a8b8cadaeafaeafae8f8e8f8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:a9b9cbdbebfbebfbe9f9e9f9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP3>

-- <MAP4>
-- 004:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:a8b8cadaeafaeafae8f8e8f8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:a9b9cbdbebfbebfbe9f9e9f9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP4>

-- <MAP5>
-- 004:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:a8b8cadaeafaeafae8f8e8f8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:a9b9cbdbebfbebfbe9f9e9f9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP5>

-- <MAP6>
-- 004:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:a8b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:a9b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8d8c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9d9c9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:a8b8cadaeafaeafae8f8e8f8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8a8b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:a9b9cbdbebfbebfbe9f9e9f9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9a9b9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8e8f8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP6>

-- <MAP7>
-- 000:4949494949494900102030405060708090a0b0c0d0e0f049494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:4949494949494901112131415161718191a1b1c1d1e1f149494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:4949494949494902122232425262728292a2b2c2d2e2f249494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:4949494949494903132333435363738393a3b3c3d3e3f349494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:49b8494949494904142434445464748494a4b4c4d4e4f449494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:49b9494949494905152535455565758595a5b5c5d5e5f549494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:49b8494949494906162636465666768696a6b6c6d6e6f649494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:4949494949494907172737475767778797a7b7c7d7e7f749494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:4949494949494908182838485868788898a8b8c8d8e8f849494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:4949494949494909192939495969798999a9b9c9d9e9f949494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:494949494949490a1a2a3a4a5a6a7a8a9aaabacadaeafa49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:494949494949490b1b2b3b4b5b6b7b8b9babbbcbdbebfb49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:494949494949490c1c2c3c4c5c6c7c8c9cacbcccdcecfc49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:494949494949490d1d2d3d4d5d6d7d8d9dadbdcdddedfd49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:494949494949490e1e2e3e4e5e6e7e8e9eaebecedeeefe49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:49b949494949490f1f2f3f4f5f6f7f8f9fafbfcfdfefff49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:494949494949494949494949494949494949494949494949494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:000000000000000000000000000000000000000000000000000049000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP7>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <WAVES1>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES1>

-- <WAVES2>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES2>

-- <WAVES3>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES3>

-- <WAVES4>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES4>

-- <WAVES5>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES5>

-- <WAVES6>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES6>

-- <WAVES7>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES7>

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

-- <SFX1>
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
-- </SFX1>

-- <SFX2>
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
-- </SFX2>

-- <SFX3>
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
-- </SFX3>

-- <SFX4>
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
-- </SFX4>

-- <SFX5>
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
-- </SFX5>

-- <SFX6>
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
-- </SFX6>

-- <SFX7>
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
-- </SFX7>

-- <FLAGS>
-- 000:00102000000040408001020400000000101800000000001010500000000000001010000000000010101000000000000010100000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS>

-- <FLAGS1>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS1>

-- <FLAGS2>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS2>

-- <FLAGS3>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS3>

-- <FLAGS4>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS4>

-- <FLAGS5>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS5>

-- <FLAGS6>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS6>

-- <FLAGS7>
-- 000:00102000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS7>

-- <SCREEN1>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN1>

-- <SCREEN2>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN2>

-- <SCREEN3>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN3>

-- <SCREEN4>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN4>

-- <SCREEN5>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN5>

-- <SCREEN6>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN6>

-- <SCREEN7>
-- 000:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 001:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 002:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 003:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 004:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 005:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 006:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 007:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 008:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 009:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 010:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 011:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 012:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 013:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 014:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 015:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 016:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 017:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 018:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 019:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 020:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 021:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 022:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 023:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 024:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 025:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 026:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 027:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 028:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 029:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 030:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 031:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 032:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 033:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 034:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 035:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 036:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 037:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 038:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 039:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 040:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 041:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 042:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 043:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 044:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 045:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 046:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 047:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 048:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 049:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 050:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 051:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 052:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 053:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 054:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 055:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 056:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 057:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 058:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 059:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 060:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 061:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 062:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 063:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 064:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 065:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 066:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 067:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 068:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 069:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 070:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 071:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 072:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 073:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 074:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 075:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 076:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 077:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 078:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 079:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 080:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 081:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 082:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 083:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 084:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 085:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 086:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 087:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 088:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 089:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 090:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 091:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 092:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 093:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 094:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 095:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 096:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 097:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 098:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 099:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 100:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 101:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 102:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 103:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 104:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 105:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 106:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 107:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 108:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 109:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 110:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 111:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 112:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 113:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 114:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 115:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 116:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 117:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 118:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 119:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 120:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 121:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 122:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 123:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 124:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 125:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 126:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 127:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 128:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 129:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 130:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 131:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 132:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 133:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 134:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- 135:444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
-- </SCREEN7>

-- <PALETTE>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE>

-- <PALETTE1>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE1>

-- <PALETTE2>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE2>

-- <PALETTE3>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE3>

-- <PALETTE4>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE4>

-- <PALETTE5>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE5>

-- <PALETTE6>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE6>

-- <PALETTE7>
-- 000:1a1c2c0f380f3062308bac0f9bbc0f1a1c2c38b764ff000029366f3b5dc941a6f673eff7f4f4f494b0c2566c86101c2c
-- </PALETTE7>

