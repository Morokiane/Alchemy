-- title:  Alchemy Courier
-- author: Blind Seer Studios
-- desc:   Courier dangerous potions
-- script: lua
-- input:  gamepad
-- saveid: beta

ver="v 0.5"
releaseBuild=false
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

dc=13 --debug txt color
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
	x=170,--was hw
	y=96,	--was hh
	vx=0,--Velocity X
	vy=0,--Velocity Y
	--curv=0,--Current movement velocity
	vmax=1.3,--Maximum velocity
	grounded=true,
	flp=0,
	type="player",
	curLife=3,
	maxLife=3,
	coins=0,
	stab=51,
	stabPot=0,
	stabPotMax=3,
	s={
		idle=256,
		run=288,
		jump=264,
		fall=320,
		dead=270,
		thru=2,--for platforms the character can move through
		duck=322
	},
	cpX=0,
	cpY=0,
	cpF=0,--which way did the player run through the checkpoint
	cpA=false,--is a checkpoint active
	canMove=true,
	ducking=false,
	damaged=false,
	onQuest=0,
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
	check=249,
	checkact=250,
	pit=5,
	heart=244,
	startSign=114,
	interact=448
}
--Control variables to make it easier
c={
	u=0,
	d=1,
	l=2,
	r=3,
	--Game controller controls
	a=4,--z
	b=5,--x
	x=6,--a
	y=7,--s
	mxt=0,
	myt=0
}

spawns={
	[7]=32,
	[8]=0
	--[240]=432
}

t=0
ti=0 --ti is time for the animated tiles

pit=false
meterY=16 --offset for the stab rect. as it decreases
meterC=6

quest={}
qnum=0
timer=0
mapStart=0
mapEnd=472 --Change this to what the end of the map will be (this will depend on level)
mapY=0
mapEndY=136
msgbox=false
pt=0
selX=75
selY=54
desctxt=""
stabplus=0
backpack=0
loadGame=false
sky=11

screenShake=false

screenShake={
	active=false,
	defaultDuration=15,
	duration=15,
	power=3
}
--sp=.4
--fr=4

--[[This function allows for changing animation timing on 
tiles. If the animation needs to change run this function
for the level loaders.]]
function InitAnim(lsp,lfr)
	local sp=lsp
	local fr=lfr
	--animation table
	tileAnims={
		[240]={s=.1,f=4},--coin
		[244]={s=.1,f=5},--heart
		[176]={s=sp,f=fr},--column 1
		[180]={s=sp,f=fr},--column 2
		[184]={s=sp,f=fr},--column 3
		[192]={s=sp,f=fr},--column 1
		[196]={s=sp,f=fr},--column 2
		[200]={s=sp,f=fr},--column 3
		[208]={s=sp,f=fr},--column 1
		[212]={s=sp,f=fr},--column 2
		[216]={s=sp,f=fr},--column 3
		[224]={s=sp,f=fr},--column 1
		[228]={s=sp,f=fr},--column 2
		[232]={s=sp,f=fr} --column 3
	}
end

function Init()
	InitAnim(.4,4)
	p.cpX=p.x
	p.cpY=p.y
	ents={}
	EntLocations()
	if releaseBuild then
		TIC=Title
	else
		TIC=Update --Update is the main game loop that needs to run after the title screen
	end
end

function OVR()
	if TIC==Update then
		HUD()
		Text()
		ShopHUD()
		Debug()
	end
end
--[[
wavelimit=136/16
function scanline(row)
	-- skygradient
	--poke(0x3fc0,190-row)
	--poke(0x3fc1,140-row)
	--poke(0x3fc2,0)
	 --screen wave
	if row>wavelimit then
		poke(0x3ff9,math.sin((time()/200+row/5))*2)
	else
		poke(0x3ff9,0)
	end
end
]]
function HUD()
	print(ver,1,130,1,false,1,true)
	--BG Rectangles
	rect(1,1,15,77,12)
	rect(15,1,65,14,12)
	--HUD border
	line(15,15,15,78,0)
	line(0,78,14,78,0)
	line(16,15,79,15,0)
	line(80,0,80,15,0)
	line(0,0,79,0,0)
	line(0,0,0,77,0)
	--Coin
	spr(449,30,4,0)
	--string.format to display 00
	print(string.format("x%02d",p.coins),39,6,0,true,1,false)
	--Potion
	rect(7,meterY,2,p.stab,meterC)
	line(7,15,8,15,0)
	line(6,16,6,65,0)
	line(9,16,9,65,0)
	line(7,66,8,66,0)
	if p.curLife==0 then
		spr(454,4,68,1)
	elseif p.stab<5 then
		spr(453,4+t%rnd(1,4),68+t%rnd(1,2),1)
		meterC=2
	elseif p.stab<15 then
		spr(453,4+t%rnd(1,2),68,1)
		meterC=3
	elseif p.stab<26 then
		spr(453,4,68,1)
		meterC=4
	else
		spr(453,4,68,1)
		meterC=6
	end
 
 if(time()%500>250) and p.stab<=10 and p.curLife>0 then
 	print('Warning!',18,18,2)
	end
	--Hearts
	for num=1,p.maxLife do
		spr(452,-4+8*num,4,6)
	end
	
	for num=1,p.curLife do
		spr(451,-4+8*num,4,6)
	end
	--Stabilizer
	spr(455,58,4,3)
	print("x"..p.stabPot,66,6,0,true,1,false)
	if stabplus==1 then
		spr(456,58,4,3)
	end
end

function ShopHUD()
	if p.inShop then
		rect(72,51,97,34,12)
		rectb(73,52,95,32,0)
		
		rectb(selX,selY,43,12,0)
		rect(117,40,52,12,12)
		rectb(118,41,50,12,0)
		spr(498,120,43,0)
		print("- Purchase",129,45,0,false,1,true)
		--Stabilizer
		spr(455,77,56,3)
		print("-",86,58,0)
		spr(449,90,56,0)
		print("x10",99,58,0)
		--Heart
		spr(244,125,56,0)
		print("-",134,58,0)
		spr(449,138,56,0)
		print("x20",147,58,0)
		--Stabilizer Plus
		spr(455,77,72,3)
		print("-",86,74,0)
		spr(456,77,72,3)
		spr(449,90,72,0)
		print("x40",99,74,0)
		if stabplus==1 then
			line(76,76,116,76,0)
		end
		--Backpack
		spr(466,125,72,3)
		print("-",134,74,0)
		--spr(456,125,72,0)
		spr(449,138,72,0)
		print("x99",147,74,0)
		if backpack==1 then
			line(124,76,164,76,0)
		end
		--Description
		AddWin(121,94,95,17,12,desctxt)
		spr(483,162,97+math.sin(time()//90),0)
	end
end

function Debug()	
	if indicatorsOn then
		print("FPS: "..fps:getValue(),w-24,0,dc,false,1,true)
		print(ver,w-24,8,dc,false,1,true)
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
		print("X: "..p.x//8,1,16,dc,false,1,true)
		print("Y: "..p.y//8,1,24,dc,false,1,true)
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
		print("Coins: "..pmem(6),36,104,dc,false,1,true)
		print("Stab+: "..pmem(7),36,112,dc,false,1,true)
		print("Pack: "..pmem(8),36,120,dc,false,1,true)
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

menu=false

function Title()
	sync(0,7,false)
	cls(12)
	if timer<=100 then
		map()
		timer=timer+1
	elseif timer>=100 then
		spr(256,w/2-64,h/2-64,11,1,0,0,16,16)
		if not menu then
			print("Press B to Start",75,h/2+52,0,true)
		end
	end
	--tri(x1 y1 x2 y2 x3 y3 color)
	if btnp(c.b) and not menu then
		menu=true
	end
	
	if menu then
		if pmem(0)~=0 then
			print("Save data found",1,1,2)
		end
		AddWin(w/2,h/2,64,24,12,"  New Game\n  Load Game\n  Exit")
		tri(92,58+pt,92,64+pt,95,61+pt,2)
	
		if btnp(c.d) and pt~=12 then
			pt=pt+6
		elseif pt==12 then
			pt=12
		end
		
		if btnp(c.u) and pt~=0 then
			pt=pt-6
		elseif pt==0 then
			pt=0
		end
		
		if btnp(c.a) and pt==0 then
			loadGame=true
			TIC=Update
		elseif btnp(c.a) and pt==6 then
			if pmem(0)==0 then
				return
			else
				loadGame=true
				Load()
				TIC=Update
			end
		elseif btnp(c.a) and pt==12 then
			TIC=Options
		end
	end
	if keyp(52) then
		pmem(0,0)
	end
end

function Options()
	--AddWin(w/2,h/2,64,24,7,"Nothing here.\nCheck back\nlater.")
	if btnp(c.a) then
		exit()
	end
end

--function TIC()
	
--[[	
	if btnp(0) then
		table.insert(quest,1)
	end
	if btnp(1) then
		table.remove(quest,1)
	end]]
	--Update()

--[[
	if(time()%500>250) then
  print('Warning!',h/2,w/2)
 end
	
	if(time()>2000)then
  print('Fugit inreparabile tempus',32,60)
 end]]
	--t=time()//20
--end

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
	if cam.y<mapY then
		cam.y=mapY
	--[[113 may have to change to a variable if the map
	does not process correcly when starting on a lower screen]]
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
	if loadGame then
		sync(0,0,false)
		loadGame=false
	end
	update_psystems()
	cls(sky)
	if keyp(9) and indicatorsOn==false then
		indicatorsOn=true
	elseif keyp(9) and indicatorsOn==true then
		indicatorsOn=false
	end
	if keyp(28) then
		Save()
	elseif keyp(29) then
		Load()
	end
	
	Main()
	Town()
	Player()
	Collectiables()
	CheckPoint()
	Stabilizer()
	ShakeScreen()
	Blinky()
	Enemy()
	draw_psystems()
	
	ti=ti+1
	
	if keyp(46) then
		table.insert(quest,1)
		p.onQuest=1
	end

	--[[if btnp(c.u) then
		make_smoke_ps(15*8,13*8)
	end]]
end

function Player(o)
	--this enables a running
	if p.canMove and not msgbox and not p.inShop then
		if btn(c.r) and btn(c.x) then
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
		elseif btn(c.l) and btn(c.x) then
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
	if p.vy==0 and btnp(c.a) and p.canMove and not msgbox and not p.ducking and not p.inShop then
		p.vy=-3.6
		p.grounded=false
		if not p.inTown then
			p.stab=p.stab-1
			meterY=meterY+1
		end
		if fget(mget(p.x//8,p.y//8),5) then
			p.vy=-4.3
		end
		--psfx(o,1)
		sfx(1)
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
		fset(1,1,false)
		fset(2,1,false)
		fset(3,1,false)
	end
	--[[if the sprite is tile 2 and has flag 1 either set
	as true or false]]
	if p.grounded and not btnp(c.d) and p.canMove then
		fset(1,1,true)
		fset(2,1,true)
		fset(3,1,true)
	elseif p.grounded then
		fset(1,1,false)
		fset(2,1,false)
		fset(3,1,false)
	end
	--[[so close! at 0 won't work. 1.5 kinda works]]
	if p.vy>=1.5 then
		fset(1,1,true)
		fset(2,1,true)
		fset(3,1,true)
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
	timer=0
	if p.curLife==0 then
		Explode()
		p.canMove=false
		p.stab=0
		p.coins=0
		AddWin(w/2,h/2-30,64,24,12,"You Died!\nPress A to\nreturn to town.")
		print("Dead!",p.x-cam.x,p.y-5-cam.y,7)
		p.idx=p.s.dead
		if btnp(c.a) then
			deleteallps()
			p.curLife=1
			BackToTown()
		end
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
	if fget(mget(p.x//8+1,p.y//8+1),7) --[[and fget(mget(p.x//8,p.y//8),7)]] and not p.damaged and p.curLife>0 then
		p.stab=p.stab-5
		meterY=meterY+5
		screenShake.active=true
		p.damaged=true
		psfx(o,4)
	end
	
	if p.curLife<=0 then
		Dead()
	elseif p.stab<=0 then
		p.curLife=p.curLife-1
		if p.stab<=0 and p.curLife>0 then
			p.x=p.cpX
			p.y=p.cpY
			p.flp=p.cpF
			p.stab=51
			meterY=16
		end
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
	if btnp(c.y) and p.stabPot>0 and p.stab>=31 and p.stab<51 then
		p.stab=51
		meterY=16
		p.stabPot=p.stabPot-1
	elseif btnp(c.y) and p.stab<31 and p.stabPot>0 then
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
	--[[if on solid ground move left,if velocity becomes 0
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
	if fget(mget(p.x//8+1,p.y//8),6) then
	--if mget(p.x//8+1,p.y//8)==s.pit then
		if p.cpA then
			p.x=p.cpX
			p.y=p.cpY
			p.flp=p.cpF
			sfx(5)
		else
			p.x=54
			p.y=112 --These should be beginning of level
		end
		p.curLife=p.curLife-1
	end
end

function CheckPoint()
	if mget(p.x//8+1,p.y//8+1)==s.check then
		mset(p.x//8+1,p.y//8+1,s.checkact)
		p.cpX=flr(p.x)
		p.cpY=flr(p.y)
		p.cpF=p.flp
		p.cpA=true
		psfx(o,19)
	end
end

function Collectiables()
	--[[Collisions with collectibles can be done either with
	flags set on the sprites,or by looking for the actual
	sprite itself.]]
	--rectb(p.x-1,p.y+1,8,8,7)
	if (mget(p.x//8+1,p.y//8+1)==s.coin or mget(p.x//8,p.y//8)==s.coin) and p.coins<99 then
		mset(p.x//8+1,p.y//8+1,0)
		mset(p.x//8,p.y//8,0)
		p.coins=p.coins+1
		--psfx(o,18)
		--table.remove(ents,i)
		sfx(18)
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
		AddWin(hw,hh,128,65,12,txt)
		spr(483,178,95+math.sin(time()//90),0)
	end
end

function Town()
	switch(action,
		case(quest[1],function() NoQuest() end),
		case(quest[2],function() TownOne() end),
		case(quest[3],function() TownTwo() end),
		case(quest[4],function() TownThree() end),
		case(quest[5],function() ForestOne() end),
		default(function() print("End of table",w/2,0,7) end)
	)
	--Print out all the values in the quest table.
	--[[for counter=1,#quest do
		print(quest[counter],w/2,(counter*8),7)
	end]]
	
	while qnum>0 do
		table.insert(quest,1)
		qnum=qnum-1
	end
	--quest giver sprite
	if p.inTown then
		spr(464,24-cam.x,88-cam.y,0,1,0,0,2,3)
		--shop keeper sprite
		spr(459,440-cam.x,80-cam.y,0,1,0,0,3,4)
	end
	--display interact bubble
	if mget(p.x//8,p.y//8)==7 or mget(p.x//8,p.y//8)==8 or mget(p.x//8,p.y//8)==9 then
		spr(448,p.x-cam.x+4,p.y-cam.y-8+math.sin(time()//90),0)
	end
	
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and p.onQuest==1 then
		spr(498,p.x-cam.x+4,p.y-cam.y-8+math.sin(time()//90),0)		
	end
	--
	if (fget(mget(p.x//8,p.y//8),2) or fget(mget(p.x//8-1,p.y//8+1),2)) and btnp(c.a) and p.onQuest==0 and not msgbox then
		p.canMove=false
		msgbox=true
		p.onQuest=1
		table.insert(quest,"On quest")
	elseif fget(mget(p.x//8,p.y//8),2) and btnp(c.b) then
		p.canMove=true
		msgbox=false
	end
	
	if fget(mget(p.x//8,p.y//8),3) then
		p.onQuest=0
	end
	--Shop
	if (fget(mget(p.x//8,p.y//8),4) or fget(mget(p.x//8-1,p.y//8+1),4)) and btnp(c.a) and not p.inShop then
		p.canMove=false
		p.inShop=true
	elseif fget(mget(p.x//8,p.y//8),4) and btnp(c.b) and p.inShop then
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
			if btnp(c.x) and p.coins>=10 and p.stabPot<p.stabPotMax then
				p.stabPot=p.stabPot+1
				p.coins=p.coins-10
			end
		elseif selX==123 and selY==54 then
			desctxt="Fills one heart"
			if btnp(c.x) and p.coins>=50 and p.curLife<3 then
				p.curLife=p.curLife+1
				p.coins=p.coins-20
			end 
		elseif selX==75 and selY==70 then
			if stabplus==0 then
				desctxt="Stabilizers are\nmore effective"
			else
				desctxt="Out of stock"
			end
			if btnp(c.x) and p.coins>=40 and stabplus==0 then
				stabplus=1
				p.coins=p.coins-40
			end
		elseif selX==123 and selY==70 then
			if backpack==0 then
				desctxt="Bigger backpack. Holds\nmore stabilizers"
			else
				desctxt="Out of stock"
			end
			if btnp(c.x) and p.coins>=99 and backpack==0 then
				p.stabPotMax=6
				backpack=1
				p.coins=p.coins-1
			end
		end
	end
end

function NoQuest()
	print("No quest",w/2,0,7)
end

function TownOne()
	print("Town 1",w/2,0,7)
	spr(478,(176*8)-cam.x,(11*8)-cam.y,0,1,0,0,2,3)
	if p.onQuest==1 then
		txt="Courier,\nPlease take this potion to\nJanna at the edge of the\nforest. Please be careful\nand not break it. We don't\nwant to have what\nhappened last time."
	end
	
	--Sign
	--spr(192,78-cam.x,112-cam.y,0,1,0,0,1,2)
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and btnp(c.x) then
		MapCoord(60,179,0,136,64,12)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
		p.inTown=false
	end
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Thank you!\nThis will work nicely."
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.b) then
		msgbox=false
		BackToTown()
	end
end

function TownTwo()
	print("Town 2",w/2,0,7)
	if p.onQuest==1 then
		txt="Quest text goes here"
	end
	spr(473,(124*8)-cam.x,(28*8)-cam.y,0,1,0,0,2,3)
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and btnp(c.x) then
		MapCoord(180,239,0,17,183,7)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
		p.inTown=false
	end
	
	if p.y>136 then
		mapStart=120*8
	end
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Some platitude goes here"
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.b) then
		msgbox=false
		BackToTown()
	end
end

function TownThree()
	print("Town 3",w/2,0,7)
	if p.onQuest==1 then
		txt="Quest text goes here"
	end
	spr(473,(124*8)-cam.x,(28*8)-cam.y,0,1,0,0,2,3)
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and btnp(c.x) then
		MapCoord(0,239,17,34,6,26)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
		p.inTown=false
	end
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Some platitude goes here"
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.b) then
		msgbox=false
		BackToTown()
	end
end

function ForestOne()
	print("Forest 1",w/2,0,7)
	if p.onQuest==1 then
		txt="Quest text goes here"
	end
	spr(473,(124*8)-cam.x,(28*8)-cam.y,0,1,0,0,2,3)
	if (mget(p.x//8,p.y//8)==s.startSign or mget(p.x//8+2,p.y//8)==s.startSign or mget(p.x//8+1,p.y//8)==s.startSign) and btnp(c.x) then
		InitAnim(.2,4)
		make_smoke_ps(14*8,15*8)	
		make_smoke_ps(17*8,15*8)	
		sync(0,1,false)
		sky=9
		MapCoord(0,29,0,17,8,10)
		p.cpX=p.x
		p.cpY=p.y
		p.cpF=p.flp
		p.cpA=true
		p.inTown=false
	end
	
	if fget(mget(p.x//8,p.y//8),3) and btnp(c.a) and not msgbox then
		txt="Some platitude goes here"
		msgbox=true
	elseif fget(mget(p.x//8,p.y//8),3) and btnp(c.b) then
		msgbox=false
		BackToTown()
	end
end

function BackToTown()
	sync(0,0,false)
	MapCoord(0,59,0,0,21,12)
	p.flp=0
	p.stab=51
	meterY=16
	p.inTown=true
	sky=11
	Save()
end

function Save()
	--[[pmem
	pmem index -> val Retrieve data from persistent memory
	pmem index val -> val Save data to persistent memory
	]]
	--[[pmem can only store ints so floats have to be floored
	or ceiling]]
	local savStab=ceil(p.stab)
	local savMeter=ceil(meterY)-1
	local savX=flr(p.x)
	local savY=flr(p.y)
	--pmem(saveScoreIdx,bestScore)
 --bestScore=pmem(saveScoreIdx)
	pmem(0,p.curLife)
	pmem(1,savStab)
	pmem(2,savX)
	pmem(3,savY)	
	pmem(4,savMeter)
	pmem(5,#quest)
	pmem(6,p.coins)
	pmem(7,stabplus)
	pmem(8,backpack)
	pmem(9,p.onQuest)
end

function Load()
	p.curLife=pmem(0)
	p.stab=pmem(1)
	p.x=pmem(2)
	p.y=pmem(3)
	meterY=pmem(4)
	qnum=pmem(5)
	p.coins=pmem(6)
	stabplus=pmem(7)
	backpack=pmem(8)
	p.onQuest=pmem(9)
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
			--[[if on solid ground move left,if velocity becomes 0
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
			if mget(e.x/8,e.y/8)==128 then
				mset(e.x/8,e.y/8,0)
			end
			--if (e.x//8==p.x//8 or e.x//8+1==p.x//8+1 or e.x//8==p.y//8+1 or e.x//8+1==p.y//8+1) and (e.y//8==p.y//8 or e.y//8==p.y//8+1 or e.y//8+1==p.y//8) and not p.damaged then
			if (e.x//8==p.x//8 and e.y//8==p.y//8) or (e.x//8+1==p.x//8 and e.y//8+1==p.y//8) and not p.damaged and p.curLife>0 then
				print("hit",p.x-8-cam.x,p.y-cam.y,7)
				p.stab=p.stab-1
				meterY=meterY+1
				screenShake.active=true
				p.damaged=true
			end
		end
	end --for
end

Init()

--Tools

--Particle system
particle_systems={}

-- Call this,to create an empty particle system,and then fill the emittimers,emitters,
-- drawfuncs,and affectors tables with your parameters.
function make_psystem(minlife,maxlife,minstartsize,maxstartsize,minendsize,maxendsize)
	local ps={
	-- global particle system params

	-- if true,automatically deletes the particle system if all of it's particles died
	autoremove=true,

	minlife=minlife,
	maxlife=maxlife,

	minstartsize=minstartsize,
	maxstartsize=maxstartsize,
	minendsize=minendsize,
	maxendsize=maxendsize,

	-- container for the particles
	particles={},

	-- emittimers dictate when a particle should start
	-- they called every frame,and call emit_particle when they see fit
	-- they should return false if no longer need to be updated
	emittimers={},

	-- emitters must initialize p.x,p.y,p.vx,p.vy
	emitters={},

	-- every ps needs a drawfunc
	drawfuncs={},

	-- affectors affect the movement of the particles
	affectors={},
	}

	table.insert(particle_systems,ps)

	return ps
end

-- Call this to update all particle systems
function update_psystems()
	local timenow=time()
	for key,ps in pairs(particle_systems) do
		update_ps(ps,timenow)
	end
end

-- updates individual particle systems
-- most of the time,you don't have to deal with this,the above function is sufficient
-- but you can call this if you want (for example fast forwarding a particle system before first draw)
function update_ps(ps,timenow)
	for key,et in pairs(ps.emittimers) do
		local keep=et.timerfunc(ps,et.params)
		if not keep then
			table.remove(ps.emittimers,key)
		end
	end

	for key,p in pairs(ps.particles) do
		p.phase=(timenow-p.starttime)/(p.deathtime-p.starttime)

		for key,a in pairs(ps.affectors) do
			a.affectfunc(p,a.params)
		end

		p.x=p.x+p.vx
		p.y=p.y+p.vy

		local dead=false
		if (p.x<0 or p.x>240 or p.y<0 or p.y>136) then
			dead=true
		end

		if timenow>=p.deathtime then
			dead=true
		end

		if dead then
			table.remove(ps.particles,key)
		end
	end

	if (ps.autoremove and #ps.particles<=0) then
		local psidx=-1
		for pskey,pps in pairs(particle_systems) do
			if pps==ps then
				table.remove(particle_systems,pskey)
				return
			end
		end
	end
end
-- draw a single particle system
function draw_ps(ps,params)
	for key,df in pairs(ps.drawfuncs) do
		df.drawfunc(ps,df.params)
	end
end

function draw_ps_pixel(ps,params)
	for key,p in pairs(ps.particles) do
		cs=math.floor(p.phase*#params.colors)+1
		pix(p.x,p.y,params.colors[cs])
	end
end
-- draws all particle system
-- This is just a convinience function,you probably want to draw the individual particles,
-- if you want to control the draw order in relation to the other game objects for example
function draw_psystems()
	for key,ps in pairs(particle_systems) do
		draw_ps(ps)
	end
end
-- This need to be called from emitttimers,when they decide it is time to emit a particle
function emit_particle(psystem)
	local p={}

	local ecount=nil
	local e=psystem.emitters[math.random(#psystem.emitters)]
	e.emitfunc(p,e.params)

	p.phase=0
	p.starttime=time()
	p.deathtime=time()+frnd(psystem.maxlife-psystem.minlife)+psystem.minlife

	p.startsize=frnd(psystem.maxstartsize-psystem.minstartsize)+psystem.minstartsize
	p.endsize=frnd(psystem.maxendsize-psystem.minendsize)+psystem.minendsize

	table.insert(psystem.particles,p)
end

function frnd(max)
	return math.random()*max
end

function make_smoke_ps(ex,ey)
	local ps=make_psystem(200,2000,1,3,6,9)
	
	ps.autoremove=false

	table.insert(ps.emittimers,
		{
			timerfunc=emittimer_constant,
			params={nextemittime=time(),speed=100}
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc=emitter_box,
			params={minx=ex-4,maxx=ex+14,miny=ey,maxy=ey+2,minstartvx=0,maxstartvx=0,minstartvy=0,maxstartvy=0}
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc=draw_ps_fillcirc,
			params={colors={12,11,10}}
		}
	)
	table.insert(ps.affectors,
		{ 
			--affectfunc=affect_force,
			--params={fx=0.003,fy=-0.009 }
			affectfunc=affect_forcezone,
			params={fx=0.003,fy=-0.009,zoneminx=0--[[64]],zonemaxx=127,zoneminy=64,zonemaxy=100}
		}
	)
end

function make_explosion_ps(ex,ey)
	local ps=make_psystem(100,500,9,14,1,3)
	
	table.insert(ps.emittimers,
		{
			timerfunc=emittimer_burst,
			params={ num=3 }
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc=emitter_box,
			params={ minx=ex-4,maxx=ex+4,miny=ey-4,maxy= ey+4,minstartvx=0,maxstartvx=0,minstartvy=0,maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc=draw_ps_fillcirc,
			params={ colors={2,3,4} }
		}
	)
end

function make_explosmoke_ps(ex,ey)
	local ps=make_psystem(1500,2000,5,8,17,18)

	table.insert(ps.emittimers,
		{
			timerfunc=emittimer_burst,
			params={ num=1 }
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc=emitter_point,
			params={ x=ex,y=ey,minstartvx=0,maxstartvx=0,minstartvy=0,maxstartvy=0 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc=draw_ps_fillcirc,
			params={ colors={3} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc=affect_force,
			params={ fx=0.003,fy=-0.01 }
		}
	)
end

function make_explosparks_ps(ex,ey)
	local ps=make_psystem(300,700,1,2,0.5,0.5)
	
	table.insert(ps.emittimers,
		{
			timerfunc=emittimer_burst,
			params={ num=10}
		}
	)
	table.insert(ps.emitters,
		{
			emitfunc=emitter_point,
			params={ x=ex,y=ey,minstartvx=-1.5,maxstartvx=1.5,minstartvy=-1.5,maxstartvy=1.5 }
		}
	)
	table.insert(ps.drawfuncs,
		{
			drawfunc=draw_ps_pixel,
			params={ colors={1,2,3} }
		}
	)
	table.insert(ps.affectors,
		{ 
			affectfunc=affect_force,
			params={ fx=0,fy=0.1 }
		}
	)
end

-- EMIT TIMERS ==================================================--
function emittimer_burst(ps,params)
	for i=1,params.num do
		emit_particle(ps)
	end
	return false
end
-- Emits a particle every "speed" time
-- params:
-- speed - time between particle emits
function emittimer_constant(ps,params)
	if (params.nextemittime<=time()) then
		emit_particle(ps)
		params.nextemittime=params.nextemittime+params.speed
	end
	return true
end

-- EMITTERS =====================================================--

function emitter_point(p,params)
	p.x=params.x
	p.y=params.y

	p.vx=frnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy=frnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end
-- Emits particles from the surface of a rectangle
-- params:
-- minx,miny and maxx,maxy - the corners of the rectangle
-- minstartvx,minstartvy and maxstartvx,maxstartvy - the start velocity is randomly chosen between these values
function emitter_box(p,params)
	p.x=frnd(params.maxx-params.minx)+params.minx
	p.y=frnd(params.maxy-params.miny)+params.miny

	p.vx=frnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy=frnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

-- AFFECTORS ====================================================--

-- Constant force applied to the particle troughout it's life
-- Think gravity,or wind
-- params: 
-- fx and fy - the force vector
function affect_force(p,params)
	p.vx=p.vx+params.fx
	p.vy=p.vy+params.fy
end

-- A rectangular region,if a particle happens to be in it,apply a constant force to it
-- params: 
-- zoneminx,zoneminy and zonemaxx,zonemaxy - the corners of the rectangular area
-- fx and fy - the force vector
function affect_forcezone(p,params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx=p.vx+params.fx
		p.vy=p.vy+params.fy
	end
end

-- DRAW FUNCS ===================================================--

-- Filled circle particle drawer,the particle animates it's size and color trough it's life
-- params:
-- colors array - indexes to the palette,the particle goes trough these in order trough it's lifetime
-- startsize and endsize is coming from the particle system parameters,not the draw func params!
function draw_ps_fillcirc(ps,params)
	for key,p in pairs(ps.particles) do
		cs=math.floor(p.phase*#params.colors)+1
		r=(1-p.phase)*p.startsize+p.phase*p.endsize
		circ(p.x-cam.x,p.y-cam.y,r,params.colors[cs])
	end
end

function Explode()
	local rx=p.x+8
	local ry=p.y+8
	make_explosmoke_ps(rx,ry)
	make_explosparks_ps(rx,ry)
	make_explosion_ps(rx,ry)
end

function deleteallps()
	for key,ps in pairs(particle_systems) do
		particle_systems[key] = nil
	end
end

function MapCoord(ms,me,myt,myb,px,py)
	mapStart=ms*8
	mapEnd=me*8
	mapY=myt*8
	mapEndY=myb*8 --this is the top of the map screen of the bottom y map screen
	p.x=px*8
	p.y=py*8
end

function psfx(o,i)
	if p.type=="player" then
		sfx(i)
	end 
end

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
	rectb(x-w/2+1,y-h/2+1,w-2,h-2,0) --no idea but it works
 print(txt,x-w/2+3,y-h/2+3,0,1,1,true)
end

function DrawWin()
	for w in pairs(win) do
		rect(w.x,w.y,w.w,w.h,2)
	end
end

function Timer(c)
	if(time()>c)then
  return c
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
-- 001:4444444233333332333333322222222200222222022222202111120011112000
-- 002:4444444433333333333333332222222200000000000000000000000000000000
-- 003:2444444423333333233333332222222222222200022222200021111200021111
-- 004:0000000000000000000220000022220000222200000220000000000000000000
-- 005:2222222220000002200000022000000220000002200000022000000222222222
-- 006:0000000000000000000000000000000000022000002002000200002020000002
-- 007:44444c4444444c4444444c44cccccccc44c4444444c4444444c44444cccccccc
-- 008:44444c4444444c4444444c44cccccccc44c4444444c4444444c44444cccccccc
-- 009:44444c4444444c4444444c44cccccccc44c4444444c4444444c44444cccccccc
-- 010:aaaaaaaaa088880aa080000aa088800aa000080aa080080aa008800aaaaaaaaa
-- 011:aaaaaaaaa008800aa080000aa088800aa080080aa080080aa008800aaaaaaaaa
-- 012:4444444233333332333333323333333203333332003333320003333200003332
-- 013:444444443333333333333333333333992222119a333319aa333319aa333319aa
-- 014:44444444333333333333333399333399a911119aaa9119aaaa9999aaaa9999aa
-- 015:44444444333333333333333399333333a9112222aa913333aa913333aa913333
-- 016:6667666666866666688866667778866677877866787777768777777788777777
-- 017:6667666666668666666888666688777668777777787777777787777778887778
-- 018:00ccccc00cccccccccc0c0ccc0cc0c0c0cc0c0cc0c0c0c0000c00000000c00cc
-- 019:c0cccc00ccccccc0c0c0cccc0c0c0ccc0000c0cc00000c0cc000c000000c0000
-- 020:000000000000000000000000ccc00000c0cc00000c0c000000c000000c000000
-- 021:0007775500007785000007780000007700000007000000880000088800008888
-- 022:5577700058770000877000007700000070000000880000008880000088880000
-- 023:44444c4444444c4444444c44cccccccc44c44444111111111333333312222222
-- 024:44444c4444444c4444444c44cccccccc44c44444111111113333333322222222
-- 025:44444c4444444c4444444c44cccccccc44c44444111111113333333122222221
-- 026:dd7777dd7d7777d7ff7777f77ff77ff7d7ffff77dd7ff777dd77777ddd77777d
-- 027:dd7777dd7d7777d77f7777ff7ff77ff777ffff7d777ff7ddd77777ddd77777dd
-- 028:2444444423333333233333332333333323333330233333002333300023330000
-- 029:333319aa333319a833331988333318893333189a333319aa333319aa333319aa
-- 030:aa9999aa8a9999a88899998898899889a988889aaa9889aaaa9999aaaa9999aa
-- 031:aa9133338a9133338891333398813333a9813333aa913333aa913333aa913333
-- 032:8887777788887778888887888888888888888888111888881111188811111118
-- 033:8888878888888888888888888888888888888888888811188811111111111111
-- 034:0003300040033233440244334733442047332330070803340080474000877400
-- 035:0000000000000077007770770077777700077777077777770777777700777777
-- 036:0000770007707770777077707777777777777777777777777777777777777777
-- 037:0000880077808880778777807777778877777888777777787777777877777788
-- 038:0000000088000000880888008888880088888000888888808888888088888800
-- 039:411112114444124444441244cccc12cc44c4124444c4124444c41244cccc12cc
-- 040:4211111142144c4442144c44c21ccccc421444444214444442144444c21ccccc
-- 041:1121111444214c4444214c44cc21cccc442144444421444444214444cc21cccc
-- 042:dd7777dd7d7777ddff777dd77ff77dd7d777dd77dd77dd77d77dd777d77dd777
-- 043:dd7777dddd7777d77dd777ff7dd77ff777dd777d77dd77dd777dd77d777dd77d
-- 044:4444444488444444888144448118144411118144111181441111281411112814
-- 045:333319aa222219a8333333333333333333333333444444442222222222222222
-- 046:aa9999aa8a9999a8333333333333333333333333444444442222222222222222
-- 047:aa9133338a912222333333333333333333333333444444442222222222222222
-- 048:3333122233321222333122223331222233312222333122223332122233331222
-- 049:2222333322233333222333332223333322233333222333332223333322223333
-- 050:0004400044344004442230440322447404434474444080700474080000477800
-- 051:0777777707777777088777770077777788777777887787770888877800088888
-- 052:7777777777777777777777777777777777777777877787778777877888778888
-- 053:7777777877777778777778887777778877777788777877888778888888888888
-- 054:8888880088888880888888808888800088888888888888888888888088888000
-- 056:0000000000000000000000000000000000000033033333220222222202222288
-- 057:3330000033200000222000002110000033333330222222202222222088882110
-- 058:77dd777777dd77777dd7777d7dd7777ddd7777dddd7777ddd7777dddd7777ddd
-- 059:7777dd777777dd77d7777dd7d7777dd7dd7777dddd7777ddddd7777dddd7777d
-- 060:1111211111112dcdeeeee8e8dededdcd8e8e8dcdeeeee8e811111dcd11112111
-- 061:e33e3333e333e333e333e333e333e333e333e333e33ee333eeee3333eeeeee33
-- 062:3333333333333333333333333333333333333333333333333333333333333333
-- 063:3333e33e333e333e333e333e333e333e333e333e333ee33e3333eeee33eeeeee
-- 064:3333222233333222333332223333322233333222333332223333322233332222
-- 065:2221333322212333222213332222133322221333222213332221233322213333
-- 066:0000000000000077007770770077777700077777077777770777777700777777
-- 067:8888778887787778777877787777777777777777777777777777777777777777
-- 068:8888888877888888778777887777778877777888777777787777777877777788
-- 069:0000000088000000880888008888880088888000888888808888888088888800
-- 070:0000000000ccc0000c0c0c00c0c0c00c0c0000ccc0c000c00c00000c00c00000
-- 071:0000000000ccc0c0cc0c0c0cc0c000c00c00000cc000000000000000c0000000
-- 072:01122228002222280022228d002228dc000228dd000112880002222200011111
-- 073:cc822220dd822220ccd82220cccd8222dddd8222888822222211111111100000
-- 074:7777dddd7777dddd777ddddd777ddddd77dddddd77dddddd7ddddddd7ddddddd
-- 075:dddd7777dddd7777ddddd777ddddd777dddddd77dddddd77ddddddd7ddddddd7
-- 076:ec112811ed112811de1128111c112811ed112811ed112811de11281111112811
-- 077:eccccc34ecccccc3ecccccc3ecccccc3ecccccc3eccccce3eeeeee34e33333cc
-- 078:44444c4444444c4444444c44cccccccc44c4444444c4444444c44444cccccccc
-- 079:43ccccce3cccccce3cccccce3cccccce3cccccce3eccccce43eeeeeecc33333e
-- 081:000000000000000000088000008ee80008888e80888eeee888888eee88888888
-- 082:0777777707777777088777770077777788777777887787770888877800088888
-- 083:7777777777777777777777777777777777777777877787778777877888778888
-- 084:7777777877777778777778887777778877777788777877888778888888888888
-- 085:8888880088888880888888808888800088888888888888888888888088888000
-- 086:00000000c00000000c0c0000c0c0c0000c0c00c000c00c0c000000c000000000
-- 089:1110000011100000221023002212210022221000231100002310000023200000
-- 090:4444411144411111441111dd4111dddd111dd88d21dd888c22d8888c22d8888c
-- 091:1114444411111444dd111144dddd1114d88dd111c888dd12c8888d22c8888d22
-- 092:1111211111112dcdeeeee8e8dededdcd8e8e8dcdeeeee8e811111dcd11112111
-- 093:ecc34444eccc3444eccc3444eccc3ccceccc3444ecce3444eee34444e33333cc
-- 094:44444c4444444c4444444c44cccccccc44c4444444c4444444c44444cccccccc
-- 095:44443cce4443ccce4443ccceccc3ccce4443ccce4443ecce44443eeecc33333e
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 097:8838838808344380008448000088880000888800008888000088880000888800
-- 098:0888888808888888000888880088888800888888008808880000088000000000
-- 099:8888888888888888888888888888811188888811888888818888888800888888
-- 100:8888888888888888888888888888888811888888222118881232211181232212
-- 101:8888888888888888888888888881118881121888122288812231812223211221
-- 102:8888888888888888888888888888888888888888111888881888888888888800
-- 103:8888888088888880888880008888880088888800888088000880000000000000
-- 104:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 105:0003000000322000032222000222220002222200022222000222220002222200
-- 106:22c8888c22c8888c22c8888c22cccccc22cccccc22c8888c22c8888c22c8888c
-- 107:c8888c22c8888c22c8888c22cccccc22cccccc22c8888c22c8888c22c8888c22
-- 108:4444444444444444443333334433333344333333443333334322222232222222
-- 109:4444444344444432333333223333332233333322333333222222222222222222
-- 110:3332333333323333444244442221222222212222222122221111111111111111
-- 111:3332333333323333444244442221222222212222222122221111111111111111
-- 113:00888800008888000088880008888880088eee80088888800088880008888880
-- 114:008888000888888008edde800888888000888800888888888eccece88ceecec8
-- 115:0000111000000111000000120000000100000000000000000000000000000000
-- 116:0122332301223323202223232222232312222323023223230223232300232323
-- 117:2321221033222101332221123222212132321111332211103322111033221100
-- 118:0111000011100000110000001000000000000000000000000000000000000000
-- 121:3222222322212212222222120222220002222200022222000222220002222200
-- 122:22c8888c22c8888c22c8888c22c8888c22c8888c22cccccc2333333333333333
-- 123:c8888c22c8888c22c8888c22c8888c22c8888c22cccccc223333333233333333
-- 124:4444444344444432333333223333332233333322333333222222222222222222
-- 125:4444444344444432443333224433332244333322443333224322222232222222
-- 126:4444444344444432333333223333332233333322333333222222222222222222
-- 127:1111111111111111222222222222222222222222222222222222222222222222
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 129:088eee800888888000888800008ee80000888800008ee8000088880000888800
-- 130:8ceccce8888888880088e800008e88000888888008edee808888ee888eeddee8
-- 132:0022332300223323002233230022332300223323002233230022332300223323
-- 133:3232110032321100323211003232110032321100323211003232110032321100
-- 134:1122111211211122122111221221112212211122122111221121112211221112
-- 135:2111221122111211221112212211122122111221221112212211121121112211
-- 136:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 137:2444444423333333233333331111111112211221233223322332233212211221
-- 138:0000000000000008000000080000800800008800000088860000878600008776
-- 139:0007000000077000800777008807777078887677778866776776667666766777
-- 140:0700000076700007766700767666776677667666777676676677767766677776
-- 141:7007000070877000808777008887777078887677778866777776667666766777
-- 142:0700000076700000766700007666700777667076777677666677766666677667
-- 143:0000000000000000700000007008000070880000788800007888700077877000
-- 145:008888000088880008888880088eee8088888888888eeee88888888888888888
-- 146:0000000000000000000000000000000000667000066667006007767000007777
-- 147:0000000000000000000000000000000000066600006666660677700077770000
-- 148:0022322300223223002232330023323300233233023322330232133223211332
-- 149:3232110032321100323211002232110022322100122321101123221011133221
-- 150:1122111211122111111221111112211111122111111221111112211111221112
-- 151:2111221111122111111221111112211111122111111221111112211121112211
-- 152:1111110001111110001222210001222200001222000001220000001200000001
-- 153:0011111101111110122221002222100022210000221000002100000010000000
-- 154:0888877700888877000886660007776688887776088887770088888800000088
-- 155:6676777776777666777766676776668866877778887777778777887788888888
-- 156:7666776677777666776667777666776666677776888877777887777788777888
-- 157:6776777777777666777766676776667766777777666777778777887788888888
-- 158:7666767777777776787777667877866688787887888877777887777788777888
-- 159:7777788066778800687880007888777078877700887778887888888088888800
-- 160:0000000000000000000990000099990000999900000990000000000000000000
-- 161:0067666606866666688866667778866677877866787777768777777788777777
-- 162:6667660066668660666888666688777668777777787777777787777778887778
-- 168:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 170:dddddddd7777777777777d77777777777777777777d777777777777777777777
-- 171:dddddddd77777d77777777777777777777d77777777777777777777777777777
-- 172:7777777777f777f777777777f7f7f7f777777777f7f7f7f77f7f7f7ff7f7f7f7
-- 173:dddddddd77ddd777ddd777ddf77ff777fffddfff77ffff77fffffffffff77fff
-- 174:4444444444444444443333334432222244323333443233334432333344323333
-- 175:4444444344444432333333222222332233334322333343223333432233334322
-- 176:8888888888ee8ee888ce8ce888ce8ce888ce8ce888ceacea88ceacea8a8ac88c
-- 177:8888888888ee8ee888ce8ce888ce8ce888ce8ce888ce8ce888ce8ce88888a88a
-- 178:8888888888ee8ee888ce8ce888ce8ce888ce8ce888ce8ce888ce8ce88888a88a
-- 179:8888888888ee8ee888ce8ce888ce8ce888ce8ce888ceccec88ceccec8c8c8888
-- 180:caaaaaaaaeccceeeaaaeeeaa0ee00eee000aa000ee0000ee00000000000ee000
-- 181:aacaaaaaeeacceeeaaaeeeaa0ee00cee000aa000ee0000ee00000000000ee000
-- 182:aaaacaaaeeccaeeeaaaeeeaa0ee00eee000aa000ee0000ee00000000000ee000
-- 183:aaaaaacaeeccceaeaaaeeeaa0ec00eee000aa000ee0000ee00000000000ee000
-- 188:7f7f7f7ff7fff7ff7f7f7f7fffffffff7f7f7f7fffffffffffffffffffffffff
-- 190:4432333344323333443233334432333344334444443333334322222232222222
-- 191:3333432233334322333343223333432244444322333333222222222222222222
-- 192:8ccaaaca888ccccc8a8cc88c8aa888888aa88aa88aaaaaaa8aaaaaaa8acaaaaa
-- 193:8aa888a88ccaaaaa88caacca888ccccc888cc88c888888888888888888a88888
-- 194:8aa888a88ccaaaaa89caacca899ccccc899ccccc889998cc8889888c88a88888
-- 195:888ccc8c8aa888888ca88aa88ccaaaaa8ccaacca8ccccccc8ccccccc8c8ccccc
-- 204:3333333333333388333318113331811133181122331812223181222231812222
-- 205:8888888811181111111811112228222222282222222822222228222222282222
-- 206:8888888811118111111181112222822222228222222282222222822222228222
-- 207:3333333388333333118133331118133322118133222181332222181322221813
-- 208:888888888ee88ee88ce88ce88ce88ce88ce88ce8acea8ce8acea8ce8c88ca8a8
-- 209:888888888ee88ee88ce88ce88ce88ce88ce88ce88ce88ce88ce88ce8a88a8888
-- 210:888888888ee88ee88ce88ce88ce88ce88ce88ce88ce88ce88ce88ce8a88a8888
-- 211:888888888ee88ee88ce88ce88ce88ce88ce88ce8ccec8ce8ccec8ce88888c8c8
-- 220:11122222dcd222228e8eeddddcdedcdddcded8dd8e8eeddddcd1111111122222
-- 221:2228222222282222dddddddddcdddcddd8ddd8dddddddddd1118111122282222
-- 222:2222822222228222ddddddddddcdddcddd8ddd8ddddddddd1111811122228222
-- 223:2222281122222811ddde2811ddcde811dd8de811ddde18111111281122222811
-- 224:caacccc8ccccc888c88cc8888a888aa8aa88aaa8aaa8aaa8aaaaaaa8aaaaaca8
-- 225:a88aaaa8aaaaacc8accaacc8c8ccc88888cc8888888c88888888888888888a88
-- 226:a88aaaa8aaaaacc8accaacc8c9ccc99899cc9998989c98888899988888898a88
-- 227:8cc8888888888aa88aa88aa8acaaacc8ccaaccc8cccaccc8ccccccc8ccccc8c8
-- 236:1182222211822222118222221182222211822222118222221182222211822222
-- 237:2228222222282222222822222228222222282222222822222228222222282222
-- 238:2222822222228222222282222222822222228222222282222222822222228222
-- 239:2ddd28112dcd2811eedee811d111d811d222d811deeed8111dcc181121112811
-- 240:00333300034444303444444334444443244444432c44444302cccc2000222200
-- 241:000cc00000c4cc0000434c000043440000434400004344000022220000022000
-- 242:00033000000330000003c000000cc000000cc000000cc000000c200000022000
-- 243:000cc00000cc4c0000c434000044340000443400004434000022220000022000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222c122222cc10222cc10002cc100000c100000000000
-- 246:0000000002200c102222cc21222cc22102cc221000c221000002100000000000
-- 247:000000000220021022cc22212cc222210c222210002221000002100000000000
-- 248:000000000cc00210cc222221c222222102222210002221000002100000000000
-- 249:0ed000000ed000000ed000000ed000000ed000000ed000000880000088880000
-- 250:0e8800000e8c88000e8ccc880e8cc8800e8880000e8000000880000088880000
-- 252:11122222dcd222228e8eeddddcdedcdddcded8dd8e8eeddddcd1111111122222
-- 253:2228222222282222dddddddddcdddcddd8ddd8dddddddddd1118111122282222
-- 254:2222822222228222ddddddddddcdddcddd8ddd8ddddddddd1111811122228222
-- 255:2222281122222811ddde2811ddcde811dd8de811ddde18111111281122222811
-- </TILES>

-- <TILES1>
-- 001:0330000034430000444400003222440031132240311300243113000233330333
-- 002:0000000000000000000000000000000000000000000000004444444403300330
-- 003:0000033000003443000044440044222304223113420031132000311333303333
-- 004:2222222220000002200000022000000220000002200000022000000222222222
-- 007:aaaaaaaaa000000aa000000aa000000aa000000aa000000aa000000aaaaaaaaa
-- 008:aaaaaaaaa000000aa000000aa000000aa000000aa000000aa000000aaaaaaaaa
-- 009:aaaaaaaaa000000aa000000aa000000aa000000aa000000aa000000aaaaaaaaa
-- 010:aaaaaaaaa000000aa000000aa000000aa000000aa000000aa000000aaaaaaaaa
-- 011:aaaaaaaaa000000aa000000aa000000aa000000aa000000aa000000aaaaaaaaa
-- 012:00000000000022100002c2110022211c001c2110001113300000034400000033
-- 013:0000000001220000112c2000c11222000112c100033111004430000033000000
-- 016:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 017:ffffffffffffffffffffffffffffffffffffffffff7ffff7f7f6fff77767fff7
-- 018:fffffffffffff7fffff7ff77ff7fff77f77fff77777ffff7f7fff67767fff667
-- 019:ffffffffffffffffffffff7f7fff7fff7fff77fff7f777fff76777767f667766
-- 020:ffffffffffffffffffffffffffffffffffffffff7ffff7ff7fff6f7f7fff7677
-- 022:0007777700ffff7c0fffff757ff7ff7577557f777c5556777556666775766776
-- 023:777ff8585577857755578777556678757666788576678f867768558777655667
-- 024:858ff7777758775577787555578766555887666768f876677855867776655677
-- 025:77777000c7ffff0057fffff057ff7ff777f75577776555c77666655767766757
-- 026:00006606066f66660666f5560f66655566f66666666655566665556506555655
-- 027:6005506666655566666655666556666665556556555555565555556655555556
-- 028:006600006f666f0066f66ff066666ff06666fff066666fff555566ff555566f0
-- 029:0022330000222200002222000022220000222200002322000023220000232200
-- 032:fffffffffffffffffffff7fffffff7fffffff77fffffff77ffffff77fffffff7
-- 033:77667ffff6676777f6757665f6755765ff655566ff775c677776777c76655f76
-- 034:667f7667566766555566f6555c66755c6666776676557775f7555775ff75c666
-- 035:7f66766667f6f665667ff655666ff755655ff75c55c757ff5c7f557767ff55c6
-- 036:fff766777776766f5667576f5675576f665556ff76c577ffc777677767f55667
-- 037:ffffffffffffffffff7fffffff7ffffff77fffff77ffffff77ffffff7fffffff
-- 038:77777777ff7787777555677555556676c556666775577767f7777776ff766667
-- 039:877566675677666766676677666776776667777f7667777f7767f7ff7767f788
-- 040:76665778766677657766766677677666f7777666f7777667ff7f7677887f7677
-- 041:77777777777877ff57765557676655557666655c767775576777777f766667ff
-- 042:066665556666555666f555660f655666666666656666f666666f66660ff66666
-- 043:5555555555555566655655656665556555655666556566556566665566666665
-- 044:65556f006655fff056f6fff055600ff05566ff0066666ff05f6666ff56000fff
-- 045:0023220000332200003322000033320000233200002322000023220000232200
-- 046:f0f0000ff0e0000fffe0000ff0f0e00ff0f0e00fe0ff700ef0000000f0e0000f
-- 047:000f00f0000f0f00000f0e0f000f0f0e000f0070000070000000f0000000f000
-- 048:ffffff66ff7fff76ffff7777fff77777fffff776ffffff66fffff77ffff77ff7
-- 049:6555cf7666555f7c666777557ffff55566fff7ff6f765c7ff76655c776666556
-- 050:fffffffffffffffffffffffffffffffffffffffffffffffcffffffccfffffcc5
-- 051:ffffffffffffffffffffffffffffffffffffffffffffffff6fffffff66ffffff
-- 052:ff765556f766c566755666675556667fc5777f6767775666677655566556c557
-- 053:6f7fffff7777ffffff777ffffffff7ffffffffff66ffff7f67f777ff777777ff
-- 054:ff766667f777777675577767c55666675555667675556775ff77877777777777
-- 055:7767f7887767f7ff7667777f6667777f66677677666766775677666787756667
-- 056:887f7677ff7f7677f7777667f777766677677666776676667666776576665778
-- 057:766667ff6777777f767775577666655c6766555557765557777877ff77777777
-- 058:0ff66066ffffff06fffff66fff0ff66600ffff660fff0fff0ff0000f00000000
-- 059:fff66606f66f66f0f666ffffff66ff66f00ff266000f22f600f2220f00022200
-- 060:660f6600666f6660066ff660000fff00600ff0006fff0000fff0000000000000
-- 061:00232200003322000033320000333200003322000333f330333ff33333ffff33
-- 062:700e000f07e0000f00000e0f0000700e000007f0000000000000000000000000
-- 063:0000f00000000f0000000e0000fe0e0000700e000077e0000000000000000000
-- 064:ff777777ff777f76f7ffff66ffffffffff7ffffffff777ffffff7777fffff7f6
-- 065:755c6556655567766665777676f7775cf766655576666557665c667f655567ff
-- 066:ffffff5fffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 067:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 068:655666677c55667ff7c567f6ff7fff66555ffff755777666c7f5556667fc5556
-- 069:7ff77ffff77fffff66ffffff677fffff77777fff7777ffff67fff7ff66ffffff
-- 070:75766776755666677c55567777557f777ff7ff750fffff7500ffff7c00077777
-- 071:776556677768558776678f8676667885556678755557877755778577777ff858
-- 072:766556777855867768f8766758876667578766557778755577587755858ff777
-- 073:6776675776666557776555c777f7557757ff7ff757fffff0c7ffff0077777000
-- 074:000000000000000000000000000000000000042100002c220002422c00241111
-- 075:0000000000000000000000000000000010000000110000002210000011c10000
-- 076:0000000000000000000022100002c11200021101002133400002103200000fff
-- 077:000000000220000022c2000011112000143100000320000002ff0000ffffff00
-- 078:000000000000000f00f0000000f00000000f0000f000f0000ffff0000000f000
-- 079:f0000000f000f0000f00f00000ff0000000ff0000000f00f000fffff000fff00
-- 080:fffffff7ffffff77ffffff77fffff77ffffff7fffffff7ffffffffffffffffff
-- 081:76655f767776777cff775c67ff655566f6755765f6757665f667677777667fff
-- 082:6c55ff767755f7c5ff757c55c57ff556557ff666556ff766566f6f76666766f7
-- 083:666c57ff5775557f5777556766776666c55766c5556f6655556676657667f766
-- 084:67f55667c777677776c577ff665556ff5675576f5667576f7776766ffff76677
-- 085:7fffffff77ffffff77fffffff77fffffff7fffffff7fffffffffffffffffffff
-- 086:000fff0000111ff000111ff000f1fff0000ff00000f1110000ff1f0000000000
-- 087:000f1f00000f1f00000ff00000000000000ff000000ff0000000f0000000f000
-- 090:00211111000114330000034400000044000000330000002200000fff000fffff
-- 091:111200004110000030000000000000000000000000000000f0000000ff000000
-- 094:0f000f0000f00f0000f00f00000ffff0000000ff0000000f0000000f00000000
-- 095:00fff00000fff0000ffff000ffff0000fff00000fff00000fff00000fff00000
-- 096:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 097:7767fff7f7f6fff7ff7ffff7ffffffffffffffffffffffffffffffffffffffff
-- 098:667766f76777767fff777f7fff77fff7fff7fff7f7ffffffffffffffffffffff
-- 099:766fff76776fff7f7ffff77777fff77f77fff7ff77ff7fffff7fffffffffffff
-- 100:7fff76777fff6f7f7ffff7ffffffffffffffffffffffffffffffffffffffffff
-- 102:00f1f00000f1f000000ff00000000000000ff000000ff000000f0000000f0000
-- 103:0000f0000000f000000ff000000ff00000000000000ff000000f1f00000f1f00
-- 104:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 110:000000000000000000000000000000000000000000000000000000000000000f
-- 111:0fff00000fff00000fff0000ffff0000fffff000fffff000fffff000fffff000
-- 118:000f0000000f0000000ff000000ff00000000000000ff00000f1f00000f1f000
-- 119:0000000000f1ff0000111f00000ff0000fff1f000ff111000ff1110000fff000
-- 124:0000000000000000000000000000000000667000066667006007767000007777
-- 125:0000000000000000000000000000000000066600006666660677700077770000
-- 126:0000000f0000000f000000ff00000fff0000ffff0fffffffffffeffffffffefe
-- 127:fffff000ffffff00ffffff00fffffff0fffffff0ffffffffeffeffff0eefffef
-- 128:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 136:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 138:0000000000000008000000080000800800008800000088860000878600008776
-- 139:0007000000077000800777008807777078887677778866776776667666766777
-- 140:0700000076700007766700767666776677667666777676676677767766677776
-- 141:7007000070877000808777008887777078887677778866777776667666766777
-- 142:0700000076700000766700007666700777667076777677666677766666677667
-- 143:0000000000000000700000007008000070880000788800007888700077877000
-- 154:0888877700888877000886660007776688887776088887770088888800000088
-- 155:6676777776777666777766676776668866877778887777778777887788888888
-- 156:7666776677777666776667777666776666677776888877777887777788777888
-- 157:6776777777777666777766676776667766777777666777778777887788888888
-- 158:7666767777777776787777667877866688787887888877777887777788777888
-- 159:7777788066778800687880007888777078877700887778887888888088888800
-- 160:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 168:0000000000000000000dd00000dddd0000dddd00000dd0000000000000000000
-- 176:8abab98a8abaab989aa8ab989aa88ab9b8898ab9b88998aba89b98aba89bb98a
-- 177:ab9b98abab9bb98a8bbab98a8bbaab989aa8ab989aa88ab9ba898ab9ba8998ab
-- 178:b9898ab9b98998aba99b98aba99bb98a8bbab98a8bbaab989ba8ab989ba88ab9
-- 179:98a8ab9898a88ab9b8898ab9b88998aba99b98aba99bb98a89bab98a89baab98
-- 180:aa88a889a898a88ba899898b89b9898a89bb9b9a8bab9b988baaba989a8aba99
-- 181:bbaabaa8ba8abaa9ba88a8a9a898a8aba899898ba9b9898aa9bb9b8a8bab9b88
-- 182:99bb9bba9bab9bb89baabab8ba8abab9ba88a8a9b898a8abb89989aba9b989aa
-- 183:8899899b89b9899a89bb9b9a9bab9b989baabab89a8abab99a88a8b9b898a8bb
-- 184:99888999898988899b888888888888888a8ab8a8888889888898888888888888
-- 185:99888999898988899b888888888888888b8b88b888888a8888a8888889888888
-- 186:bb888bbb8b8b888bba888888888888888888988888888b8888b888888a888888
-- 187:888888888888888889888888888888888888988888888b8888b888888a888888
-- 192:89bab98a89baab9899a8ab9899a88ab9bb898ab9bb8998abab9b98abab9bb98a
-- 193:a89b98aba89bb98a88bab98a88baab9899a8ab9899a88ab9b9898ab9b98998ab
-- 194:ba898ab9ba8998abaa9b98abaa9bb98a88bab98a88baab9898a8ab9898a88ab9
-- 195:9ba8ab989ba88ab9bb898ab9bb8998abaa9b98abaa9bb98a8abab98a8abaab98
-- 196:9a88a8b99898a8bbb89989bbb9b989aab9bb9baabbab9ba8bbaabaa8aa8aba89
-- 197:8baaba988a8aba999a88a8999898a8bb989989bb99b989ba99bb9bbabbab9ba8
-- 198:a9bb9b8aabab9b888baaba888a8aba998a88a8998898a89b8899899b99b989ba
-- 199:b89989abb9b989aaa9bb9baaabab9b88abaaba88aa8aba89aa88a8898898a89b
-- 200:88888888898888a8888888888a888988888888888888888888888888888888a8
-- 201:888888988a8888b8888888888b888a88888888888888888888888898888888b8
-- 202:888888a88b8888888888888888888b888888888888888888888888a888888888
-- 203:888888a88b8888888888888888888b888888888888888888888888a888888888
-- 208:ba8ab8baa88ab8baa898a9a88998a9a889b989899bb989899bab9b9bbaab9b9b
-- 209:9bab9a9bbaab9a9bba8ab8baa88ab8baa898a8a88998a8a889b989899bb98989
-- 210:89b98b899bb98b899bab9a9bbaab9a9bba8ababaa88ababaa898a8a88998a8a8
-- 211:a898a9a88998a9a889b98b899bb98b899bab9b9bbaab9b9bba8ababaa88ababa
-- 212:898a89b9898a89b99b989bab9b989babbb989b8abb989b8a9ab9ba989ab9ba98
-- 213:a8aba898a8aba898898a89b9898a89b9998a89ab998a89ab8b989b8a8b989b8a
-- 214:bab9ba8abab9ba8aa8aba898a8aba89888aba8b988aba8b9a98a89aba98a89ab
-- 215:9b989bab9b989babbab9ba8abab9ba8aaab9ba98aab9ba98b8aba8b9b8aba8b9
-- 216:9999999899989988988889888b88888b98a8888a888889889898888888888888
-- 217:9999999899989988988889888b88888ba8b8888b88888a88a8a8888889888889
-- 218:bbbbbbb8bbb8bb88b8888b888a88888ab888888888888b88b8b888888a88888a
-- 219:88888888888888888888888889888889b888888888888b88b8b888888a88888a
-- 224:ba8abbbaa88abbbaa898aaa88998aaa889b98a899bb98a899bab989bbaab989b
-- 225:9bab999bbaab999bba8abbbaa88abbbaa898aba88998aba889b98a899bb98a89
-- 226:89b988899bb988899bab999bbaab999bba8ab9baa88ab9baa898aba88998aba8
-- 227:a898aaa88998aaa889b988899bb988899bab989bbaab989bba8ab9baa88ab9ba
-- 228:8ab9bab98ab9bab998aba8ab98aba8abb8aba88ab8aba88aa98a8998a98a8998
-- 229:ab989b98ab989b988ab9bab98ab9bab99ab9baab9ab9baabb8aba88ab8aba88a
-- 230:b98a898ab98a898aab989b98ab989b988b989bb98b989bb99ab9baab9ab9baab
-- 231:98aba8ab98aba8abb98a898ab98a898aa98a8998a98a89988b989bb98b989bb9
-- 232:8b88888888888889888888888888888898988888888888888b88889888888898
-- 233:888888888888888a8888888888888888a8a88888888888888888889888888898
-- 234:898888888888888b8888888888888888b8b88888888888888988889888888898
-- 235:898888888888888b8888888888888888b8b88888888888888988889888888898
-- 240:00333300034444303444444334444443244444432c44444302cccc2000222200
-- 241:000cc00000c4cc0000444c000044440000444400004444000022220000022000
-- 242:00033000000330000003c000000cc000000cc000000cc000000c200000022000
-- 243:000cc00000cc4c0000c444000044440000444400004444000022220000022000
-- 244:0000000002200210222222212222222102222210002221000002100000000000
-- 245:0000000002200210222222c122222cc10222cc10002cc100000c100000000000
-- 246:0000000002200c102222cc21222cc22102cc221000c221000002100000000000
-- 247:000000000220021022cc22212cc222210c222210002221000002100000000000
-- 248:000000000cc00210cc222221c222222102222210002221000002100000000000
-- 249:0ed000000ed000000ed000000ed000000ed000000ed000000880000088880000
-- 250:0e8800000e8c88000e8ccc880e8cc8800e8880000e8000000880000088880000
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
-- 000:cccccccccccccccccf00000ccf00000ccf00000ccf00000ccf00000ccf00000c
-- 001:cccccccccccccccccc000ecccc000fcccc000dcccc00dcccccfdccceccde0dcc
-- 002:ccccccccccccccccc000dcc0c000dcc0c000dcc04000dcc00000dcc0c000dcc0
-- 003:cccccccccccccccc0ecce00000ee0000000000000fece00d0cccd0ec00ccd00c
-- 004:cccccccccccccccc000000000000000000000000ce0dc4e0cccccccdcce0eccc
-- 005:cccccccccccccccc0000000000000000000000000000ed4d000dccdcffccce00
-- 006:ccccccccccccccccdcc00000dcc00000dcc00000dcc00000ccc00000dcc00000
-- 007:cccccccccccccccc0000dccc0000cccc0000cccc0000cccc0000dccc000000ed
-- 008:cccccccccccccccc0000fc0000000e00d0000000cde00000ccccde00ccccccd0
-- 009:cccccccccccccccc000000000000000000000000000edccd00eccdccfcce00fc
-- 010:cccccccccccccccc00000000000000000000000000000edcd0004ccdcf04cc00
-- 011:cccccccccccccccc000000000000000000000000ce0000dcdccf0dcc0ccd00cc
-- 012:cccccccccccccccc000000000000000000000000f0dd0000ddcc8000c4000000
-- 013:cc000000cc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 016:cf00000ccf00000ccf00000ccf00000ccf0004cccf00dccccf00dccccf00dccc
-- 017:cc00004ccc0000eccc0000fccc0000dccccccccccccccccccccccccccccccccc
-- 018:cd00dcc0cc00dcc0cc00dcc0cc00dcc0cccccccccccccccccccccccccccccccc
-- 019:00ccd00c00ccd00c00ccd00c00ccd00ccccccccccccccccccccccccccccccccc
-- 020:cc80fccccc008ccccc008ccccc008cccccccdccccccdd444ccf00000cf000000
-- 021:eecccf00edccc000edcccf00eeccce00ccccccccd0edcccc000000f000000000
-- 022:dcc00000dcc00000dcc00000dcc00000ccc4f000d44d00000000000000000000
-- 023:00000000000000000000d0000000c4000000eccc000000ed0000000000000000
-- 024:0dccccc0000eccc00000cc400000ccd0cccccccccccccccc0000eccc000000cc
-- 025:dccf084cdccdccccdccc4de8eccd0000cccccccccccccccccccccccccccccccc
-- 026:408ccd0000ecc4dc00fccccdf80ccc00cccccccccccccccccccccccccccccccc
-- 027:eccf00ccc4f000ccd00000cc000e00cccccccccccccccccccccccccccccccccc
-- 028:ce000000cf000000c8000000c8000000cccccf00cccccf00cccccf00cccccf00
-- 029:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 032:cf004ccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccc
-- 033:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 034:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 035:ccccccccccccccc0ccccccc0ccccccc0cccccce0cccccc00cccccf00ccccd000
-- 036:f000000000000000000000000000000000000000000000000000000000000000
-- 037:0000000000000000000000000000000000000000000000440e44444404444444
-- 038:000000000000000000000000000000000edef00044444d004444444044444440
-- 040:000000dc00000000000000000000000000000000000000000000000000000000
-- 041:ccccccccccccccccdccccccc8ccccccc0dcccccc0fcccccc00eccccc000ccccc
-- 042:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 043:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 044:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00
-- 045:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 048:cf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccc
-- 049:cccccccccccccccfccccccd0ccccccd0ccccccc0ccccccc0cccccccdcccccccc
-- 050:e0fdcccc0cd0ccccdccddcccdcf84ccc8ccccccc0ccccccd00feef00cef0008f
-- 051:cccce000cccc0000ccc00000cc400000ce0000008000000000008000dcccce00
-- 052:00000000000000000000000000000000000000000000000f00000003000000f4
-- 053:0444444404444444e4444444d444444444444444444444444444444444444d89
-- 054:4444444044444440444444444444444444444444444444444444444499999880
-- 055:000000000000000000000000d00000004e00000044e00000444d0000ed444e00
-- 057:000ccccc000ccccc0000eccc0000004c0000000e000000000000000000000000
-- 058:ccccccccccccccccccccccccccccccccccccccccdccccccc0ecccccc000000e4
-- 059:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 060:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00
-- 061:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 064:cf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccc
-- 065:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 067:cccccf00ccccc000ccccd000cccce000ccce0000ccc00000ccd00000cd000000
-- 068:000000340000004400000f4400000e4d00000009000008990000099900009999
-- 069:4444e0994430008948000089f088999999999999999999999999999999999999
-- 070:9999999999999999999999999999999999999999999999999999999999999999
-- 071:980e444f99990e449999900e9999998099999999999999999999999999999988
-- 072:00000000d00000004e000000044f0000900f440099900e309999908089999900
-- 074:000000000000000000000000000000000000dccc0000cccc0000cccc0000cccc
-- 075:8ccccccc0dcccccc00dccccc000cccccc000cccccd00dccccc00fccccce004cc
-- 076:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00
-- 077:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 080:cf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccd
-- 081:cccccccccccccccdcccce000ccce0000cce00000ce000000f000dccc00ee008f
-- 082:ccccccccdddddd0000000000000000000000000000000000cccccf00eccccc00
-- 083:e000000000000000000000000000000000000000000000000000000000000000
-- 084:0000999900009999000099990000999900009999000099990000980000000089
-- 085:999999999999999999999999999808999800999980999999999999989999990d
-- 086:999999999999999999999999999999999980899900e3f0004444444444444444
-- 087:90099999999999999999999899999998999999990899999944e008804444eeee
-- 088:8800000099880009000000089999990099999900999990f0000034e03dd444e8
-- 089:0000000080000000900000009000000090000000900000008800000008000000
-- 090:0000cccc0000cccc00000ded0000008c0000fdcc0000eccc00000dcc000000cc
-- 091:ccc00eccccce00cccccd00cccccd00cccccc00cccccc00ccccce0eccccce0dcc
-- 092:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00
-- 093:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 096:cf00cccfcf00ccc0cf00ccc0cf00ccc0cf00ccc8cf00ccc4cf00cccccf00cccc
-- 097:0ed0ef000c80ccc80cfecccd0ecccccc008dccd80000ff004f000000cccccccc
-- 098:0ccccc000ccccc000dcccc000dcccc000dcccc000ccccc00eccccd00ccccc800
-- 100:0000099900000999000009990000009900000000000000000000000000000000
-- 101:999998e499990e44998e444484444444d44444444444444444444444d4444444
-- 102:44444444444444444444444444444d4e444d0033ef44d80d30e44de444444444
-- 103:4444444444444444444444444444444444444444444444444444444444444444
-- 104:44444408444444094444440944444d8844444e90444440904444d080444d0809
-- 105:0800000000000000800000008000000080000000800000008000000000000000
-- 106:000000dc000000ec0000000c0000000e0000000e0000000e0000000e0000000d
-- 107:ccc00cccccd0fccccce0dccccd0eccccce0cccccc0fcccccc0dccccccecccccc
-- 108:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00
-- 109:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 112:cf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccc
-- 113:cccccccccccccccccccccccccccccccccccccccccccccc40ccccce00ccccf000
-- 114:ccccd000cccd0000ccc00000cc800000e00000000000dd0000fccc000eccd000
-- 117:e4444444f444444404444444044444440d4444440f44444400d4444400e44444
-- 118:4444444444444434442220024202222f24222223444444444244444242f22220
-- 119:444444444444444444444444f44444442f2444444f444444ff4444440244444d
-- 120:444f090844d0098044f089904d00999040099000408980003099080000990900
-- 122:0000000c000000ec000000cc00000ecc0000eccc0000cccc0000cccc0000cccc
-- 123:4cccccccdcccccccecccccccecccccccdccfcccccd48dcccc80ecccccccccccc
-- 124:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00
-- 125:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 128:cf00cccccf00cccccf00cccfcf00ccc0cf00cce0cf00cd0ecf00f00ccf00000c
-- 129:ccce00fdd000cccd008cde000fcd000eece0fdcccd00ccccc00ecccfd00dccf0
-- 130:4cd00000f000000000000000dd000000c8000000c00000000000000000000000
-- 133:000444440000344400000d4400000044000000440000000d0000000000000000
-- 134:44f2000044444444444444444444444444444444444444440f44444400044444
-- 135:2444444044444e004444d0004444000044440008444800894f00099900008999
-- 136:0890890009809000090880009809000090890000909800009980000009000000
-- 137:0000000000000000000000000000000000000000000000008000000f3f000004
-- 138:000dcccc004ccccc0ecccccc0ccccccceccccccccccccccccccccccccccccccc
-- 139:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 140:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00
-- 141:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 144:cf0000eccf0000dccf0000dccf0000fccf00000ccf00e00fcf000000cf00ccce
-- 145:d00ccf00d00c0000d00d0000d0000000d000000000000000000000e000004f00
-- 147:0000000000000000000000000000000000000000000000000000000000f00000
-- 150:0000e44000000000000000000000000000000000000000090000000900008999
-- 151:0000999900009990000999900899990989999089999980999999089899988990
-- 152:090000000800000e90000004900000d480000044000000440000004400000044
-- 153:4e0000ec4d0000dc440000dc44e0004c4430004c444000dc4440000c444f0000
-- 154:ccccccccccccccccccccccccccccccccccccccccce00cccccfccfccccccc0dcc
-- 155:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 156:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00
-- 157:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 160:cf00cccccf00cccdcf00cccecf00ccc0cf00cc44cf00cce4cf00ccf4cf00cd34
-- 161:f0f400000e440000f444df0044444400444444484444444f4444444f4444444f
-- 162:00000000000000000000000000000000000000000000000d0000004400008d44
-- 163:00de000000444e00004444400f444443e4444444444444444444444444444444
-- 164:000000000000000000000000000000004d000000444000004444deef44444444
-- 165:00000000000000000000000000000000000000990000099900089999d8999999
-- 166:0008999900099999009999998999999999999990999999909999990899999009
-- 167:9990990099009900980890009009900009990000899900009999000099980000
-- 168:0000004400000044000000440000004400000044000000440000004400000044
-- 169:444d00004444e00044444f004444440044444444444444444444444444444444
-- 170:cccd0ccceee0dccc0000cccc000ecccc0000000e30000ecc4e000000f0080000
-- 171:cecccccccecccccccdccccccdccccccccccccccccccccccc0000000f00000f00
-- 172:cccccf00cccccf00cccccf00cccccf00cccccf00cccccf00eeddcf0000000000
-- 173:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 176:cf00cf44cf00d344cf00e444cf000444cf000d44cf0000fecf000000cf000000
-- 177:444444404444448044444e004444d0004444000eeee000f30000000000000000
-- 178:000f44440e44444404444444e4444444444444cc33333dcc0000dcc00000cccf
-- 179:44444444444444444440e4444440444dcccde3e0c4cccd080000cc000000fd00
-- 180:4444444e4444089944e09999f0899999899999998888888800cc00000ecc0000
-- 181:0999999999999999999999999999999899999908888800080000000000000000
-- 182:9998000999000999900099990009999999099999888888890000000000000000
-- 183:99900000990000009800000090000000adcc0000cccc00fdfccc00dc8ccc000e
-- 184:00000044000000d3000000000000000000000000c0000000c0000000e0000000
-- 185:4444444e333e0000000000080000089900099999088888800000000000000000
-- 186:0009800899908089980080998008009900090099008800880000000000000000
-- 187:0000d4440004444400e444440044444403444444033333330000000000000000
-- 188:dee0000044444f0044444f0044444f0044444f00333338000000000000000000
-- 189:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 192:cf000000cf000000cf000000cf000000cf000000cf000000cf000000cf000000
-- 194:0000ccc400004ccc0000eccc000000e40000000000000000000ece00000ecc00
-- 195:e0000000ccd00004ccccd00dccccccc08edcccc0000cccc0000dccc00004ccd0
-- 196:fccc0000cccccd0e4cccde0ceccc000feccc000feccc000feccc000feccc0008
-- 197:00000000dc000ecccce00dcccce000cccce000cccce000cccce000cccce00ecc
-- 198:00000000e000edc4e00dcccde00cc400e00ccd00e0ecce00e0fccd00e00cc400
-- 199:8ccc0000dccc00edcccc0eccfccc00ec8ccc00ec8ccc00ec8ccc00ececcc00ec
-- 200:00000000c00000cccf0004c4cf0eccf0cf0dcc00cf0dcc00cf0dccf0cf0ecce0
-- 201:00000000ccc00000edcc000000ecce0d008ccd0e000ccd0000fcce0000ecc00e
-- 202:00080000dcccce00ccdecc00ccdf0000cccce000ccccccf0fdccccd0000eccd0
-- 205:fc000000fc000000fc000000fc000000fc000000fc000000fc000000fc000000
-- 208:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 209:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 210:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 211:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 212:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 213:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 214:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 215:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 216:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 217:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 218:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 219:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 220:cccccccccccccccc000000000000000000000000000000000000000000000000
-- 221:cc000000cc000000000000000000000000000000000000000000000000000000
-- </TILES7>

-- <SPRITES>
-- 000:0000000000082222000083330000844400088444000822220000822200008222
-- 001:0000000022228000323288004222ce102228dc102228dc1022e8c110228e1110
-- 002:0000000000000000000822220000833300008444000884440008222200008222
-- 003:000000000000000022228000323288004228ce102228dc1022e8dc10228ec110
-- 004:0000000000000000000822220000833300008444000884440008222200008222
-- 005:000000000000000022228000323288004228ce102228dc1022e8dc10228ec110
-- 006:0000000000000000000822220000833300008444000884440008222200008222
-- 007:0000000000000000222288003232ce104228dc102228dc1022e8c110228e1110
-- 008:0000000000000000000822220000833300008444000884440008222200008222
-- 009:000000000000000022228000323288004228ce102228dc1022e8dc10228ec110
-- 010:000000000000000000000000000f22220000f3330000f444000ff444000f2222
-- 011:0000000000000000000000002222f0003232ff004228ce102228dc1022d8dc10
-- 012:00000000000000000000000000000000000f2223000083330000844400008442
-- 013:0000000000000000000000000000000032d7ff00d22fc7f0222fdcf0222fdcf0
-- 014:0000000000000000000000000000000000000000000000000000000000088888
-- 015:0000000000000000000000000000000000000000000000000000000080000080
-- 016:0008822a008482aa0084488800088edd0000888800008ee80000882800000888
-- 017:a888e110a848ee1084488800ee880000888800008ee800008828000088880000
-- 018:0008822a008482aa0084488800088edd0000888800008ee80000882800000888
-- 019:a8881110a848e1108448ee10ee888800888800008ee800008828000088880000
-- 020:0000822a000882aa0084888800844edd0008888800008ee80000882800000888
-- 021:a8881110a8a8e1108848ee10e4488800888800008ee800008828000088880000
-- 022:0008822a008482aa0084488800088edd0000888800008ee80000882800000888
-- 023:a888e110a848ee1084488800ee880000888800008ee800008828000088880000
-- 024:00008222000082220008488800084eee00008888000008e20000088800000000
-- 025:288811102848e1108848ee10ee888800888800008ee800008882800000888000
-- 026:0000f2220000f2220000ff2200000fff00000f7700000fff000000f20000000f
-- 027:22fdc1102fff11102f4f7110ff4f771077ffff00ffff0000f77f0000ffff0000
-- 028:0000822200008222000882220008df2200088d88000088870000000f00000000
-- 029:22dfcff0228dfff028887ff028d877f088d8880077788000d88d800088888000
-- 030:088ee8220828e8220088e882082ee8af08888efa0844dee808448dee001111cc
-- 031:2888882022444320244443202443332082432220822222208223222011122200
-- 032:000000000008222200008333000084440888844408442222084482220088822a
-- 033:00000000222280003232880042228e102228dc102228dc1022a8c110aaa81110
-- 034:000000000008222200008333000084440888844408442222084482220088822a
-- 035:00000000222280003232880042228e102228dc102228dc1022a8c110aaa81110
-- 036:000000000008222200008333000084440008844400082222008882220084822a
-- 037:00000000222280003232880042228e102228dc102228dc1022a8c110aaa81110
-- 038:000822220000833300008444000884440008222200008222000082220000822a
-- 039:222280003232800042228000222888002228ce102288dc102a88dc10aa8ec110
-- 040:000822220000833300008444000884440008222200008222000082220000822a
-- 041:222280003232800042228000222888002228ce102288dc102a88dc10aa8ec110
-- 042:000822220000833300008444000884440008222200008222000082220000822a
-- 043:222280003232800042228000222888002228ce102288dc102a88dc10aa8ec110
-- 044:000822220000833300008444000884440008222200008222000082220000822a
-- 045:222280003232800042228000222888002228ce102288dc102a88dc10aa8ec110
-- 046:000000000008222200008333000084440008844400082222008882220084822a
-- 047:00000000222280003232880042228e102228dc102228dc1022a8c110aaa8e110
-- 048:0000822a000082aa0000888800008edd0000888800008e280000088800000000
-- 049:aaa8e110aa844e1088834800ee888000888800008ee800008828000008880000
-- 050:0000822a000082aa0000888800008edd0000888800008e280000088800000000
-- 051:aaa8e110aa844e1088834800ee888000888800008ee800008828000008880000
-- 052:0083822a000882aa0008888800008edd00008888000088e20000088800000000
-- 053:aaa8e110aa844e1088844800ee8880008888800088ee80000882800000888000
-- 054:0088822a008482aa0008888800008edd0000888800008ee80000882800000880
-- 055:aa881110a448e110844eee10ee8888008888800008e280000888800000000000
-- 056:0000822a000882aa0008488800008edd0000888800008ee80000828800008880
-- 057:448811104488e110888eee10ee8888008888800008e280000888800000000000
-- 058:0000822a000882aa0008488800008edd0000888800008ee80000828800008880
-- 059:448811104488e110888eee10ee8888008888800008e280000888800000000000
-- 060:0088822a008482aa0008888800008edd0000888800008ee80000882800000880
-- 061:aa881110a448e110844eee10ee8888008888800008e280000888800000000000
-- 062:0083822a000882aa0008888800008edd00008888000088e20000088800000000
-- 063:aaa81110aa844e1088844800ee8880008888800088ee80000882800000888000
-- 064:000000000008222200008333000084440888844408442222084482220088822a
-- 065:00000000222280003232880042228e1022288c102224411022834110aa888e10
-- 066:00000000000000000000000000000000000000000000000000f2222200083333
-- 067:0000000000000000000000000000000000000000000000002228000023288000
-- 080:0000822a000082aa0000888800008edd0000888800008e280000088800000000
-- 081:aaa8ec10aa88ee108888ef00ee888000888800008ee800008828000008880000
-- 082:00084444008844420082222200082222000888aa0008888a0008488800084488
-- 083:228c88002288c8802a8811182888888888448888a84488808888e88088888800
-- 128:0000000000000000008808880833833300883c440083c44400834444083c4444
-- 129:0000000000000000880088003388338044338800444438004444438044444338
-- 130:000000000000000000800000083808880083833300083c440083c44400834444
-- 131:0000000000000000000008008800838033883800443380004444380044444380
-- 132:000000000000000000000000008000880838083300838c440008c44400834444
-- 133:0000000000000000000000008800008033880838443383804444380044444380
-- 134:000000000000000000800000083808880083833300083c440083c44400834444
-- 135:0000000000000000000008008800838033883800443380004444800044444800
-- 144:083c444483334444383344448833344408333333088333330088833300088888
-- 145:4444438344444388444443804444338044433380333338803333880088888000
-- 146:083c4444083c4444833344443833444488333444088333330088833300088888
-- 147:4444433844444383444443884444438044443380444338803333880088888000
-- 148:083c4444883c4444333344448333444483333444883333330888833300888888
-- 149:4444433844444383444443884444433844443338444333883333888088888800
-- 150:083c4444083c4444833344443833344488333333088333330088833300088888
-- 151:4444438044444830444448804444380044433800333388003333800088888000
-- 160:ddd00000eddd00000eed0000000edd07000077770000777f0007fff7007ff2ff
-- 161:00000ddd0000ddde000ddee07ddee000ffe00000fff00000fff000007f000000
-- 162:000000000ddddd007dd77dd7077007770000777f0007fff7007ff2ff0007fff7
-- 163:0000000000dddd007dd77dd0ff700770fff00000fff000007f000000f7000000
-- 164:000000000000ddd700ddd7770077777f0007fff7007ff2ff0007fff700007770
-- 165:000000007dddd000ff77ddd0fff077d0fff000707f000000f700000077000000
-- 166:00000000000000000ddddd007dd77dd7077007770000777f0007fff7007ff2ff
-- 167:000000000000000000dddd007dd77dd0ff700770fff00000fff000007f000000
-- 176:0007fff700007770000000000000000700000007000000070000000000000000
-- 177:f70000007700000077000000d770000077700000777000007700000000000000
-- 178:0000777000000000000000070000007700000077000000070000000000000000
-- 179:770000007700000077000000d700000077000000700000000000000000000000
-- 180:0000000000000007000000070000000700000000000000000000000000000000
-- 181:770000007d700000777000007770000077000000000000000000000000000000
-- 182:0007fff700007770000000000000000000000000000000000000000000000000
-- 183:f7000000770000000770000077d7000077770000777700000770000000000000
-- 192:00000000088888808cccccc88ceeeec88ceccc8008cc88000088000000800000
-- 193:00333300034444303444444334444443244444432c44444302cccc2000222200
-- 194:07ff000007fdff0007fdddff07fddff007fff00007f000000ff00000ffff0000
-- 195:6666666660060066022022060232320602333206602320666602066666606666
-- 196:66666666600600660ee0ee060eeeee060eeeee0660eee066660e066666606666
-- 197:1111111110000001110110111106601110655601065555600666666010000001
-- 198:3333333333333333333333333303303330706003076606700776607030000003
-- 199:3333333330033003330770333307503333055033330580333300003333300333
-- 200:3233333322233333323333333333333333333333333333233333322233333323
-- 203:0000000000000000000000000000000000000000000000000000000000000088
-- 204:0888888808181181008111110811111181333331814444420844444188244421
-- 205:0000000080000000880000008180000018000000180000001180000088880000
-- 208:00000000000000000000000000000088000008ee00008eee0088eee20888ee22
-- 209:00000000000000000000000080800000e8e800008eee8000222ee800222ee800
-- 210:3322223332d00d23320ed023320de023320ed023320de023220ed02232022023
-- 217:000000000000000000000000000000000000080000008788008888a808788aaa
-- 218:00000000000000000000000000000000000080008008e800888e8e808788e800
-- 219:000888ee008eeeee08eeeeee8eeeeeee8eeeee118eeee1118444411183344288
-- 220:e88888e88eee8ee8888ee88e1118eeee11118888111118ee1111118e88111111
-- 221:eeee8000e88ee800881eee808811ee80e111eee888811ee81882111888832228
-- 222:00000000000000000000000000000008000000830000088e0000833300083333
-- 223:0000000000000000000000008800000033800000e33800003233800033233800
-- 224:0888eee308888eee088881ee088881ee833e11ee833ee1ee088ee1ee088111ee
-- 225:333ee800333ee80011118000111e1800eeee1800eeee1800eeeee800eeee1380
-- 226:06666660666cc66666c66c6666c66c6666cccc6666c66c668666666808888880
-- 227:0222222022ccc22222c22c2222ccc22222c22c2222ccc2228222222808888880
-- 233:00877aaa000877aa00888777000811880082217a008727770088877700878877
-- 234:a808e800a88888008808e8001288880012288800a278e8007887878088888800
-- 235:0833442808334428008342480008334200008334000008340000008400000008
-- 236:88881111888888888888e88e8e88eeee2ee8eeee24448eee444848ee4484ee88
-- 237:8883444888833442e8884442e8344428e3342880e4448000ee280000ee280000
-- 238:0008333380833333800824220008444400008444000008ee00088eaa0008eaea
-- 239:332338002323380042833800448380008888380080008000e8800000ea800000
-- 240:088811ee088818e8088888880888088808880881088808180888008800800008
-- 241:888e138088881800888880001118800088818000888800008888000088880000
-- 242:0aaaaaa0aacaacaaaacaacaaaaaccaaaaacaacaaaacaacaa8aaaaaa808888880
-- 243:0333333033c33c3333c33c33333ccc3333333c33333cc3338333333808888880
-- 249:0008822200008121000818280000878800008788000087880000878800008888
-- 250:180888002808e8001808e8008808e80078088800780888007808880088088800
-- 251:0000000000000000000000080000000800000008000000880000008800000088
-- 252:8848888888888888888808888888088888880888888808888888088888880888
-- 253:8880000088000000880000008800000088000000888000008880000088800000
-- 254:00088eee000838ee000838ee000888ee00008888000081880008e18800088888
-- 255:ea8800008848000088480000888800008880000081800000e180000088800000
-- </SPRITES>

-- <SPRITES1>
-- 000:0000000000082222000083330000844400088444000822220000822200008222
-- 001:0000000022228000323288004222ce102228dc102228dc1022e8c110228e1110
-- 002:0000000000000000000822220000833300008444000884440008222200008222
-- 003:000000000000000022228000323288004228ce102228dc1022e8dc10228ec110
-- 004:0000000000000000000822220000833300008444000884440008222200008222
-- 005:000000000000000022228000323288004228ce102228dc1022e8dc10228ec110
-- 006:0000000000000000000822220000833300008444000884440008222200008222
-- 007:0000000000000000222288003232ce104228dc102228dc1022e8c110228e1110
-- 008:0000000000000000000822220000833300008444000884440008222200008222
-- 009:000000000000000022228000323288004228ce102228dc1022e8dc10228ec110
-- 010:000000000000000000000000000f22220000f3330000f444000ff444000f2222
-- 011:0000000000000000000000002222f0003232ff004228ce102228dc1022d8dc10
-- 012:00000000000000000000000000000000000f2223000083330000844400008442
-- 013:0000000000000000000000000000000032d7ff00d22fc7f0222fdcf0222fdcf0
-- 014:0000000000000000000000000000000000000000000000000000000000088888
-- 015:0000000000000000000000000000000000000000000000000000000080000080
-- 016:0008822a008482aa0084488800088edd0000888800008ee80000882800000888
-- 017:a888e110a848ee1084488800ee880000888800008ee800008828000088880000
-- 018:0008822a008482aa0084488800088edd0000888800008ee80000882800000888
-- 019:a8881110a848e1108448ee10ee888800888800008ee800008828000088880000
-- 020:0000822a000882aa0084888800844edd0008888800008ee80000882800000888
-- 021:a8881110a8a8e1108848ee10e4488800888800008ee800008828000088880000
-- 022:0008822a008482aa0084488800088edd0000888800008ee80000882800000888
-- 023:a888e110a848ee1084488800ee880000888800008ee800008828000088880000
-- 024:00008222000082220008488800084eee00008888000008e20000088800000000
-- 025:288811102848e1108848ee10ee888800888800008ee800008882800000888000
-- 026:0000f2220000f2220000ff2200000fff00000f7700000fff000000f20000000f
-- 027:22fdc1102fff11102f4f7110ff4f771077ffff00ffff0000f77f0000ffff0000
-- 028:0000822200008222000882220008df2200088d88000088870000000f00000000
-- 029:22dfcff0228dfff028887ff028d877f088d8880077788000d88d800088888000
-- 030:088ee8220828e8220088e882082ee8af08888efa0844dee808448dee001111cc
-- 031:2888882022444320244443202443332082432220822222208223222011122200
-- 032:000000000008222200008333000084440888844408442222084482220088822a
-- 033:00000000222280003232880042228e102228dc102228dc1022a8c110aaa81110
-- 034:000000000008222200008333000084440888844408442222084482220088822a
-- 035:00000000222280003232880042228e102228dc102228dc1022a8c110aaa81110
-- 036:000000000008222200008333000084440008844400082222008882220084822a
-- 037:00000000222280003232880042228e102228dc102228dc1022a8c110aaa81110
-- 038:000822220000833300008444000884440008222200008222000082220000822a
-- 039:222280003232800042228000222888002228ce102288dc102a88dc10aa8ec110
-- 040:000822220000833300008444000884440008222200008222000082220000822a
-- 041:222280003232800042228000222888002228ce102288dc102a88dc10aa8ec110
-- 042:000822220000833300008444000884440008222200008222000082220000822a
-- 043:222280003232800042228000222888002228ce102288dc102a88dc10aa8ec110
-- 044:000822220000833300008444000884440008222200008222000082220000822a
-- 045:222280003232800042228000222888002228ce102288dc102a88dc10aa8ec110
-- 046:000000000008222200008333000084440008844400082222008882220084822a
-- 047:00000000222280003232880042228e102228dc102228dc1022a8c110aaa8e110
-- 048:0000822a000082aa0000888800008edd0000888800008e280000088800000000
-- 049:aaa8e110aa844e1088834800ee888000888800008ee800008828000008880000
-- 050:0000822a000082aa0000888800008edd0000888800008e280000088800000000
-- 051:aaa8e110aa844e1088834800ee888000888800008ee800008828000008880000
-- 052:0083822a000882aa0008888800008edd00008888000088e20000088800000000
-- 053:aaa8e110aa844e1088844800ee8880008888800088ee80000882800000888000
-- 054:0088822a008482aa0008888800008edd0000888800008ee80000882800000880
-- 055:aa881110a448e110844eee10ee8888008888800008e280000888800000000000
-- 056:0000822a000882aa0008488800008edd0000888800008ee80000828800008880
-- 057:448811104488e110888eee10ee8888008888800008e280000888800000000000
-- 058:0000822a000882aa0008488800008edd0000888800008ee80000828800008880
-- 059:448811104488e110888eee10ee8888008888800008e280000888800000000000
-- 060:0088822a008482aa0008888800008edd0000888800008ee80000882800000880
-- 061:aa881110a448e110844eee10ee8888008888800008e280000888800000000000
-- 062:0083822a000882aa0008888800008edd00008888000088e20000088800000000
-- 063:aaa81110aa844e1088844800ee8880008888800088ee80000882800000888000
-- 064:000000000008222200008333000084440888844408442222084482220088822a
-- 065:00000000222280003232880042228e1022288c102224411022834110aa888e10
-- 066:00000000000000000000000000000000000000000000000000f2222200083333
-- 067:0000000000000000000000000000000000000000000000002228000023288000
-- 080:0000822a000082aa0000888800008edd0000888800008e280000088800000000
-- 081:aaa8ec10aa88ee108888ef00ee888000888800008ee800008828000008880000
-- 082:00084444008844420082222200082222000888aa0008888a0008488800084488
-- 083:228c88002288c8802a8811182888888888448888a84488808888e88088888800
-- 128:0000000000000000008808880833833300883c440083c44400834444083c4444
-- 129:0000000000000000880088003388338044338800444438004444438044444338
-- 130:000000000000000000800000083808880083833300083c440083c44400834444
-- 131:0000000000000000000008008800838033883800443380004444380044444380
-- 132:000000000000000000000000008000880838083300838c440008c44400834444
-- 133:0000000000000000000000008800008033880838443383804444380044444380
-- 134:000000000000000000800000083808880083833300083c440083c44400834444
-- 135:0000000000000000000008008800838033883800443380004444800044444800
-- 144:083c444483334444383344448833344408333333088333330088833300088888
-- 145:4444438344444388444443804444338044433380333338803333880088888000
-- 146:083c4444083c4444833344443833444488333444088333330088833300088888
-- 147:4444433844444383444443884444438044443380444338803333880088888000
-- 148:083c4444883c4444333344448333444483333444883333330888833300888888
-- 149:4444433844444383444443884444433844443338444333883333888088888800
-- 150:083c4444083c4444833344443833344488333333088333330088833300088888
-- 151:4444438044444830444448804444380044433800333388003333800088888000
-- 160:ddd00000eddd00000eed0000000edd07000077770000777f0007fff7007ff2ff
-- 161:00000ddd0000ddde000ddee07ddee000ffe00000fff00000fff000007f000000
-- 162:000000000ddddd007dd77dd7077007770000777f0007fff7007ff2ff0007fff7
-- 163:0000000000dddd007dd77dd0ff700770fff00000fff000007f000000f7000000
-- 164:000000000000ddd700ddd7770077777f0007fff7007ff2ff0007fff700007770
-- 165:000000007dddd000ff77ddd0fff077d0fff000707f000000f700000077000000
-- 166:00000000000000000ddddd007dd77dd7077007770000777f0007fff7007ff2ff
-- 167:000000000000000000dddd007dd77dd0ff700770fff00000fff000007f000000
-- 176:0007fff700007770000000000000000700000007000000070000000000000000
-- 177:f70000007700000077000000d770000077700000777000007700000000000000
-- 178:0000777000000000000000070000007700000077000000070000000000000000
-- 179:770000007700000077000000d700000077000000700000000000000000000000
-- 180:0000000000000007000000070000000700000000000000000000000000000000
-- 181:770000007d700000777000007770000077000000000000000000000000000000
-- 182:0007fff700007770000000000000000000000000000000000000000000000000
-- 183:f7000000770000000770000077d7000077770000777700000770000000000000
-- 192:00000000088888808cccccc88ceeeec88ceccc8008cc88000088000000800000
-- 193:00333300034444303444444334444443244444432c44444302cccc2000222200
-- 194:07ff000007fdff0007fdddff07fddff007fff00007f000000ff00000ffff0000
-- 195:6666666660060066022022060232320602333206602320666602066666606666
-- 196:66666666600600660ee0ee060eeeee060eeeee0660eee066660e066666606666
-- 197:1111111110000001110110111106601110655601065555600666666010000001
-- 198:3333333333333333333333333303303330706003076606700776607030000003
-- 199:3333333330033003330770333307503333055033330580333300003333300333
-- 200:3233333322233333323333333333333333333333333333233333322233333323
-- 203:0000000000000000000000000000000000000000000000000000000000000088
-- 204:0888888808181181008111110811111181333331814444420844444188244421
-- 205:0000000080000000880000008180000018000000180000001180000088880000
-- 208:00000000000000000000000000000088000008ee00008eee0088eee20888ee22
-- 209:00000000000000000000000080800000e8e800008eee8000222ee800222ee800
-- 210:3322223332d00d23320ed023320de023320ed023320de023220ed02232022023
-- 217:000000000000000000000000000000000000080000008788008888a808788aaa
-- 218:00000000000000000000000000000000000080008008e800888e8e808788e800
-- 219:000888ee008eeeee08eeeeee8eeeeeee8eeeee118eeee1118444411183344288
-- 220:e88888e88eee8ee8888ee88e1118eeee11118888111118ee1111118e88111111
-- 221:eeee8000e88ee800881eee808811ee80e111eee888811ee81882111888832228
-- 222:00000000000000000000000000000008000000830000088e0000833300083333
-- 223:0000000000000000000000008800000033800000e33800003233800033233800
-- 224:0888eee308888eee088881ee088881ee833e11ee833ee1ee088ee1ee088111ee
-- 225:333ee800333ee80011118000111e1800eeee1800eeee1800eeeee800eeee1380
-- 226:06666660666cc66666c66c6666c66c6666cccc6666c66c668666666808888880
-- 227:0222222022ccc22222c22c2222ccc22222c22c2222ccc2228222222808888880
-- 233:00877aaa000877aa00888777000811880082217a008727770088877700878877
-- 234:a808e800a88888008808e8001288880012288800a278e8007887878088888800
-- 235:0833442808334428008342480008334200008334000008340000008400000008
-- 236:88881111888888888888e88e8e88eeee2ee8eeee24448eee444848ee4484ee88
-- 237:8883444888833442e8884442e8344428e3342880e4448000ee280000ee280000
-- 238:0008333380833333800824220008444400008444000008ee00088eaa0008eaea
-- 239:332338002323380042833800448380008888380080008000e8800000ea800000
-- 240:088811ee088818e8088888880888088808880881088808180888008800800008
-- 241:888e138088881800888880001118800088818000888800008888000088880000
-- 242:0aaaaaa0aacaacaaaacaacaaaaaccaaaaacaacaaaacaacaa8aaaaaa808888880
-- 243:0333333033c33c3333c33c33333ccc3333333c33333cc3338333333808888880
-- 249:0008822200008121000818280000878800008788000087880000878800008888
-- 250:180888002808e8001808e8008808e80078088800780888007808880088088800
-- 251:0000000000000000000000080000000800000008000000880000008800000088
-- 252:8848888888888888888808888888088888880888888808888888088888880888
-- 253:8880000088000000880000008800000088000000888000008880000088800000
-- 254:00088eee000838ee000838ee000888ee00008888000081880008e18800088888
-- 255:ea8800008848000088480000888800008880000081800000e180000088800000
-- </SPRITES1>

-- <SPRITES2>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
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
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
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
-- </SPRITES2>

-- <SPRITES3>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
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
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
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
-- </SPRITES3>

-- <SPRITES4>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
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
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
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
-- </SPRITES4>

-- <SPRITES5>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
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
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
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
-- </SPRITES5>

-- <SPRITES6>
-- 000:0000190000000000011111100014410000122100012442101244442112222221
-- 001:0000200001111111012122120012222201222222123333321244444301444442
-- 002:0000200000000000000000000000000000000000000000000000000000000000
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
-- 100:0000200002000000222000000200000000000000000000000000002000000222
-- 110:0000190002110000021311000213331102133110021110000210000001100000
-- 111:0000190000000000011001100013310000132100001221000012110000111100
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
-- </SPRITES6>

-- <SPRITES7>
-- 000:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 001:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 002:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb00
-- 003:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000
-- 004:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00bbbbbb000bbbbb
-- 005:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 006:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 007:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 008:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 009:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 010:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 011:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 012:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 013:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 014:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 015:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 016:bbbbbbbbbbb0000bb00000000005650000565650006666660056666000066600
-- 017:bbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb0bbbbbbb0bbbbb000bbb00000bb00000
-- 018:bbbbb000bbbbb000bbbb0000bbbb0005b0000006000000650000005665656565
-- 019:0056555065656565565656566565656556565656656565655656565665656665
-- 020:000bbbbb00000000500000006600000056565656656665665656565666666666
-- 021:bbbbbbbb000000bb000000000000000056565000666666605656565666666666
-- 022:bbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb00bbbbbb000bbbbb000bbbbb6000bbbb
-- 023:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000bb0000000b
-- 024:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 025:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 026:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 027:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 028:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 029:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 030:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 031:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 032:b0000000bb00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 033:bb000056bb000565b0000655b0006565b00055560005656500065656b0006565
-- 034:5556555665656565565656566565656556565656656565655656565665656665
-- 035:5656565665656566565656566665666656565656656665665656565066000000
-- 036:5656565665666666565656566666666656565656000666660006565600066666
-- 037:5656566666666666565666566666666656665666666666666656666666666666
-- 038:5000bbb06000bb006000bb0060000b0056000000666000b0666000b0666000bb
-- 039:0000000000555000055555000565650000666000000000000000000bb00000bb
-- 040:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 041:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 042:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 043:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 044:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 045:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 046:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 047:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 048:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 049:b0005556b0006565b0000656bb000065bbb00000bbbb0000bbbbb000bbbbbbb0
-- 050:56565656656565665656565666656660565650000000000000000000000000bb
-- 051:500000006000000b0000bbbb000bbbbb00bbbbbb0bbbbbbbbbbbbbbbbbbbbbbb
-- 052:00005666b0006666b0000056bb000000bbb00000bbbbb000bbbbbbbbbbbbbbbb
-- 053:566656666666666660006666000006660000006600000000bbb00000bbbbb000
-- 054:666600bb666000bb666000bb666000bb60000b00000000000000000000000006
-- 055:bbbbbbbbbbbbbbbbbbbbbbbbb000000b00000000000000000060000066000000
-- 056:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb00bbbbbb00bbbbbb00bbbbbb
-- 057:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 058:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 059:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 060:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 061:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 062:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 063:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 064:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 065:bbbbbbbbbbbbb000bbbb0000bbb00065bbb00556bbb00565bbb00656bbb00066
-- 066:bbbbbbbb00bbbbbb000bbbbb6000bbbb5500bbbb6500bbbb6600bbbb6000bbbb
-- 067:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 068:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbb00bbbbb000bbbb0000bbb00000
-- 069:bbbbb000bbb00000b00000060000006600006666006660006600000000000000
-- 070:0000666606666600666600006600000000000005000005650005555505656565
-- 071:0000005500000565000555550555656555555555556555655555555565656565
-- 072:000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb6000bbbb
-- 073:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 074:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 075:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 076:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 077:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 078:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 079:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 080:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 081:bbbb0000bbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 082:000bbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 083:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 084:bbb00000bbb00000bbb00055bbb00005bbbb0000bbbb0000bbbbb000bbbbbb00
-- 085:0000005500055565555555556565656555555555056565650055555500656565
-- 086:5555555555656565555555556565656555555555656565655655555565656565
-- 087:5555555555656565555555556565656555555555656565655655565565656565
-- 088:5000bbbb60000bbb550000bb6560000b55550000656560005655560065656565
-- 089:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb00bbbbbb0000bbbb000000bb
-- 090:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 091:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 092:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 093:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 094:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 095:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 096:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 097:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 098:bbbbbbbbbbbbbbbbbbbbbb00bbb00000bb000000b0000044b000444400004444
-- 099:bbbbbbbbbbbbbbbb00bbbbbb0000bbbb00000bbb400000bb4440000b4444000b
-- 100:bbbbbbb0bbbbbbbbbbbbbbbbbbbb0000bbb00000bb000000bb000444b0003444
-- 101:0005555500006565b0005655bb00056000000500000000000000000000000004
-- 102:5555555565656565565556550000006500000000000000004444400034443440
-- 103:5555555565656565565556556565650055565000056500000056000400600044
-- 104:5555555665656565565556550065650000005000000000004000000434000004
-- 105:5000000065600000565550000005656000005500000000004400000034000044
-- 106:bbbbbbbb0bbbbbbb000000bb0000000b00000000000440000444000034400000
-- 107:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbb00000000000000000044
-- 108:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbb000000bb004000000044000000
-- 109:bbbbbbbbbbbbbbbbbbbbbbbb00000bbb000000b0000000000444000044440000
-- 110:bbbbbbbbbbbbbbbbb00000bb0000000b0000000b004440000044400000443000
-- 111:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000bbbb000000b0000000000040000
-- 112:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 113:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0
-- 114:0004440000044400004444000034340000444400003434000043430000343400
-- 115:0444000b04344000044440000034300000444400003434000043434000043430
-- 116:b0004444b0004434b00044440000343400004443000434300003434000043330
-- 117:0000004400000034000000440000003400000044000000340000004300000034
-- 118:4444444040004430400000003000000044000000340005654300065033000500
-- 119:0050004400600034005000440060003406500044006000340000004300000034
-- 120:4400000444000004440000043400000444000044343004344343434334343434
-- 121:4400004444000034440000443400003444000003340000044340000333000004
-- 122:4400000644000000440000003400000044400043343434304343430033340000
-- 123:5000004405000434000004440000043400000444000004340000034300000434
-- 124:4440000444300004444000043434000444434444343434344343434330043434
-- 125:4444400044344000444440003434300044434000343430004343400000343000
-- 126:0044400000343000004440000034300000434443003434340043434300343334
-- 127:004440000434400044444000343400004440000b343000bb430000bb00000bbb
-- 128:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 129:bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 130:0043430000343430004343430033333300034343000333300003334000003330
-- 131:0003434004343430434343403333333000004343000003330000000000000000
-- 132:0003434000033430000343400003333000034333000333330000333300000033
-- 133:0000000300000003000000030000000043000000333000003300000000000660
-- 134:4300000034300000434000033333000343334333033333330033333300003330
-- 135:0300004333000033430000433300003343000043330000333000000300000003
-- 136:4343434334333433430000433300000340000003300000033000000333000003
-- 137:4300000334000000430000003300000043000000330005003000560030006660
-- 138:4343000034330000434340003333330003334343033333330033333300333300
-- 139:0000034300000433000003430000033340000333000003330000003300000003
-- 140:4000434030003430400043003000030040000000300000003000000000060060
-- 141:0043400000333000004340000033300000334000003330000033300000030000
-- 142:004343400033343000434300033333000333400003333000033300000030000b
-- 143:0000bbbb000bbbbb00bbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 144:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 145:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 146:b0000330b0000000bb000000bbbb0000bbbbb000bbbb0000bbb00004bb000044
-- 147:00b0000000bbbbbb0000bbbb000000bb00000000444000004444400034444400
-- 148:00000000bbb00000bbbbbb00bbb00000b0000000000000000000444400443444
-- 149:0000065600006566065656560665666500565656000065660000065030000600
-- 150:0000000060000000565600066665666650005650000000600000000000440000
-- 151:0006000005666000500056500000006600000006004000000044000000443000
-- 152:0000000000006000000600006600000050000000000044440004444400043444
-- 153:0000565000066566005656560000666600000056400000064444000034443000
-- 154:0000000000000000500000066666000056000000600000000000444000043440
-- 155:0056000005660000565656006666600006560000066600040050000400600034
-- 156:0006565600666666065666560000000600000000400000004444400034300000
-- 157:0000000000000000560000506000000000000000000004400444444404443444
-- 158:000000bb00000bbb000bbbbb00bbbbbb0000bbbb0000bbbb40000bbb34000bbb
-- 159:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 160:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 161:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 162:bb000444bb000434b0004444b0003434b0004443000434300003434000043330
-- 163:44444400000044000000400000000000000000000000000000bb000000bb0000
-- 164:0044444400344434004440040034000004430000343400004343000033300000
-- 165:4400000044300000444000003434000044430000043400000343000003340000
-- 166:0444000004340000044400000434000004430000043400000343000003340000
-- 167:0044400000343400004443000034340000434400003434000043430000343300
-- 168:0044440000343000004440000034300004434000043400000343000003343334
-- 169:4444400004343000004440000034300000434000043430000343000033300000
-- 170:0004444000044430000444400034343000434440003434300043434000343330
-- 171:0050004400000434000003430000043400000343000034340000434300003333
-- 172:4400000034000000400000003000000043000000343430004343400030000000
-- 173:0444444444300004444000003430000044400000343000004340000333300034
-- 174:444000bb443000bb444000bb343000bb444000bb343000bb430000bb30000bbb
-- 175:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 176:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 177:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 178:00034340000334300003334000033330b0004333b0003333b0000333bb000003
-- 179:0000000000000000000000000033300043334000333330003333000033000000
-- 180:4340000034330000434300003333000003334333033333330033333300003333
-- 181:0343000004330000034300003333000043330000333000063330005630000066
-- 182:0343400004333000004340000033333300334343000333330000333360000333
-- 183:0043430000333000004340003333300043334000333330003333000033300000
-- 184:0343434304333433034343433333000343330003333300000330000000000000
-- 185:4300006034000660430000663330006643330006333300063333000603300006
-- 186:0043434000333330004333000003330000034300000333000003330000000000
-- 187:0000434300033333000333430003333300034333000033330000333300000000
-- 188:0000000000000000000000000000000033000000333000003300000000000b00
-- 189:4343434334333433434343433333300303334000033330000333300003333000
-- 190:40000bbb340000bb4340000b3333000b4333400003333000003300000000000b
-- 191:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 192:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 193:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 194:bbb00000bbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 195:000000bb00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 196:00000000b0000000bb000000bb000666bbb00066bbb00066bbb00066bbb00066
-- 197:0000066600006666005666666666666656665666666666666666666666666666
-- 198:5000000066000000665600006666666656665666666666666666666666666666
-- 199:0000000000000066000066666666666666666666666666666666666666666666
-- 200:0000000000006600666666666666666666666666666666666666666666666666
-- 201:0000006600000666000666666666666666666666666666666666666666666666
-- 202:5000000060000006666666666666666666666660666660006660000060000000
-- 203:6600000066660000660000006000000b00000bbb000bbbbb00bbbbbbbbbbbbbb
-- 204:0000bbb000bbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 205:000000000000000b00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 206:000000bbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 207:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 208:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 209:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 210:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 211:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 212:bbb00066bbb00066bbbb0006bbbb0000bbbb0000bbbbb000bbbbbb00bbbbbbb0
-- 213:5666666666666666666666666666666666666666006666660000066600000000
-- 214:5666666666666666666666666666666666666666666666666666666600000000
-- 215:6666666666666666666666666666666666666666666666606660000000000000
-- 216:6666666666666666666666666666660066600000000000000000000b0000bbbb
-- 217:6666660066660000660000000000000b00000bbb00bbbbbbbbbbbbbbbbbbbbbb
-- 218:000000bb0000bbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 219:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 220:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 221:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 222:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 223:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 224:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 225:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 226:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 227:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 228:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 229:b0000000bbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 230:0000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 231:0000000b00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 232:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 233:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 234:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 235:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 236:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 237:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 238:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 239:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 240:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 241:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 242:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 243:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 244:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 245:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 246:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 247:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 248:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 249:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 250:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 251:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 252:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 253:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 254:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 255:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- </SPRITES7>

-- <MAP>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000069140414047800000000000000000000000000000000000000
-- 001:000000000000000000000000000000000000000000006474650000000000000000000000000000000000000000000000000000002131412141000000000000000000000000000000002131410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006500000000000000000000000000000000000000000021412141000000000000000000216500000000000000000000000068130313037900000000000000000000005101110101110111
-- 002:000000000000000000000000000000000021314100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021314100000000000000213141000000000000000000000000000000006474650000000000000000000000000000000000000000000000212131410000000000647400000000000000000000000000000000002121000000000000410000000000000000000000000000000000000000000000000000213141000000000000000000006500000000000000000000000069140414047800000000000000000000000002120202120212
-- 003:000000000000000000000000000000006474652131410000000000000000000000000021314100000000000000000000000000000000410000000000000000000000000000000000213141000000000000000000000000000000000000000000314100000065650000000000000000000000000000000000000000000000002131410000000000656474647400000000000000000000000000000021314100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051011161000068130313037800000000000000000000000068130313031303
-- 004:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000213141000000000000000031410000000000000000000000000000000000000000000000000000002131410000000000000065756575000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000212000f0069140414047900000000000000000000000069140414041404
-- 005:e0e0e0e0e0e0e0e0e0e0e0f0c10000000000000000000000000000000000000000000000000000000000000000000000c0d0e0e0e0e0e0e0e0e0e0e000000000000000000000000000000000000000000000000000213141000000003242424252620000000000000000000032425262000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0d0e0e0e0e0e0e0e0e0e0000000000000000000000000000000000f0000000f000000000000000000687800000000000000000000000000000000000000000068130313031304
-- 006:e1e1e1e1e1e1e1e1e1e1e1f100000000000000c0d0e0e0e0e0e0e0e0e0f0c1000000000000003242526200000000000000d1e1e1e1e1e1e1e1e1e1e1000000000000324252620000000000000000000000000000000000000000000033434343536300000000000000000000334353630000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000003242526200000000000000d1e1e1e1e1e1e1e1e1e10000000000000000000000000000000000000000000000000000000000306979002900293900009f000000000000000f000000000069140414041403
-- 007:e2e2e2e2e2e2e2e2e2e2e2f20000000000000000d1e1e1e1e1e1e1e1e1f100000000000000003343536300000000000000d2e2e2e2e2e2e2e2e2e2e20000000000003343536300000000000000000000000000000000000000000000263646566676000000000000000000323434344462000000000000000000000000000000000000000000000000000000000000000000a8b8f8000000000000000000003343536300000000000000d2e2e2e2e2e2e2e2e2e20000003242526200000000000000000000000000000000000000000000006813011101110111012a2939000000000000000000000068130313031304
-- 008:eafae4e4e4e4e4e4e4e4e4f40000000000000000d2e2e2e2e2e2e2e2e2f200000000000000243434344454000000000000d4e4e4e4e4e4e4e4e4eafa0000000000243434344454000000000000000000000000000f0000000000000000374757670000000000000000000033353535456300000000000000000000000000000000000000000f00000f00000f000000000000a9b9f9000000000000000000243434344454000000000000d3e5e5e5e5e5e5e5eafa00000033435363000000230022000000000000000000000000000000000069140212021202120212012a293900000000000000000069140414041403
-- 009:ebfbe5e4e4a5b5e4e4e4e4f50000000000000015d3e3e3e3e3e3e3e3e3f315000000000000253535354555000000001500d5e5e5e5e5a5b5e5e5ebfb001500000025353535455500000000000000000000000000000000000000000000004858000000000000000000000026364656667600000000000000000000000000000000000f00000000000000000000000000001a110111011161000000000000253535354555000000150000d4e5e5e5e5e5e5e5ebfb011101110111011101110111011161000000000000005101110111011101130313031303130313030212011161000000000000000068130313031304
-- 010:eafae4e4e4a6b6e4e4e4e4c20000000000000016d4e4e4e4ccdcecfce4f416000000000000263646566676000000001600c2e4e4e4e4a6b6e4e4eafa00160000002636465666760000000000000000000000000000003a4a6a000000000048580000000f000000000f000000374757670000a8b8c8d8e8f8000000001a116100000000000000325262000000000051011102120212021200000000000f00263646566676000000160000c20000000000e4e4eafa021202120212021202120212021200000000000000000002120212021202140414041404140414031313021210202000000000005e69140414041404
-- 011:ebfbe5e5e5a7b77070e4e4c30000000000000017d5e4e4e4cdddedfde4f517000000000000383747576700000083931700c3e4e49090a7b7e5e5ebfb001700000000374757670000000000000000000000000000002939230060602923294959390000000000000000000000294959390023a9b9c9d9e9f9009f0000021200000023000000003353630000495900000212031303130313012a0000000000003747576700000000170000c3000000808000e4ebfb03130313031303130313031303780000000000000000006813031303130313031303130313031304141403680000000000005d005d68130313031303
-- 012:eafae4e4e481917070e4e4c400a8b8c8d8e8f818d4e4e4e4cedeeefee4f418969600270000969648589696969684941800c4e4e490907191e4e4eafa0018a8c8f800384858000000000000000000000f006a00510111011101110111011101110111989898989898989801110111011101110111011101110111011103780000001a2a00001a11012a00001a2a000068130414041404140212012a000000003848580000000000180000c400000080800000eafa04140414041404140414041404790000000000000000006914041404140414041404140414041404141304690f000000000000005e69140414041404
-- 013:ebfbe5e5e582927070e4e4c500a9b9c9d9e9f919d5e4e4e4cfdfefffe4f519979729280000979749599797979785951900c5e4e490907292e5e5ebfb0019a9c9f9293949590029390029390000000000233900000212021202120212021202120212990000000000008902120212021202120212021202120212021204790000000212000002120212000002120000691403130313031303130212012a00293949590023000000190000c500000080800000ebfb031303130313031303130313037800000000000000000068130313031303130313031303130313031314036800000000000000005d68130313031303
-- 014:e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6d70111011101110111011101110111d7e6f6e6f6e6f6e6f6e6f6e6f6e6f60111011101110111011101110111012a00001a110111011103130313031303130313031303784b4b4b4b4b4b4b4b68130313031303130313031303130313031303784b4b4b68784b4b681303784b4b68784b4b68130414041404140414031302120111011101110111d7e6f6e6f6e6f6e6f6e6f6e6f6e6f604140414041404140414041404798c8c8c8c8c8c8c8c8c69140414041404140414041404140414041413046910202000000000005e69140414041404
-- 015:c6d6c6d6c6d6c6d6c6d6c6d60b0dc6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d6d70212021202120212021202120212d70b0dc6d6c6d6c6d6c6d6c6d6c6d60212021202120212021202120212021200000212021202120414041404140414041404140479cacacacacacacaca6914041404140414041404140414041404140479cacaca6979caca69140479caca6979caca69140313031303130313031303130212021202120212d7c6d6c6d6c6d6c6d6c6d6c6d6c6d603130313031303130313031303784b4b4b4b4b4b4b4b4b681303130313031303130313031303130313130368000000005d0000005d68130313031303
-- 016:d7c6d6c6d6c6d6c6d6c6d6c60c0ed6c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d60313031303130313031303130313c60c0ed6c6d6c6d6c6d6c6d6c6d6d70313031303130313031303130313036850507813031303130313031303130313031303130378cbcbcbcbcbcbcbcb6813031303130313031303130313031303130378cbcbcb6878cbcb68130378cbcb6878cbcb68130414041404140414041404140313031303130313c6d6c6d6c6d6c6d6c6d6c6d6c6d6d70414041404140414041404140479cbcbcbcbcbcbcbcbcb691404140414041404140414041404140414140469000000005e0000005e69140414041404
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000681303130313031303130313037800000f005d0000005d0000005d681313
-- 018:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000213141213141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000213141000000000000000000000000000000000000000000000000006914041404140414041404140479000000005e005e00000000005e691414
-- 019:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002131213141000000000000007431410000000000000000000000000000000021213141000000000000000074410000000000000000000000000000000000000000000000000000000000000021314100006813031303130313031303130378000000005d000000000000005d681313
-- 020:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000740000000000000000000000000000000000000000004100000000000000000000000000000032425262000000000021314100000000002131410000000000000000000000006914041404140414041404140479102020005e005e00000000005e691414
-- 021:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000216441000000000000000000000000000000000000410000000000000000000074410000000033435363000000000000002131410000000000000000000000000000000000000000000000006813031303130378000000005d005d00000000005d681313
-- 022:00000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000f0000000f000000000000000000000000000000000000000000000000009f0000000000000000000000000000000000000000000000000000000000000000000000000000000000e0e0e0e0e0e0e0e0e0e0f0c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002434344454000000000000000000000000000000000000000000213141000000000000000000006914041403130479000000005e005e00000000005e691414
-- 023:000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a11012a00000000000000000000000000005101110111011101110111011101110000000000000000000000e1e1e1e1e1e1e1e1e1e1f1000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000002535354555000000000000000000000000000000000000000000000000000000000000000000000000681304140378000000005d000000000000005d681313
-- 024:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a2a00001a2a000000000000000000000000000000000000000000000212021261000000000f00000000000000000002120212021202120212021202120000000000000000000000e2e2e2e2e2e2e2e2e2e2f20000000000000000000000000000000000000000000000000000080000000000000000000f0000000000000000002636465676000000000000000000000000000000000f00000000000000000000000000000000000000691403130378000000005e000000000000005e691414
-- 025:0000000000000000000000000000000000000000000000001a1101110111012a00000000000000000000000000001a11021201110212000000000f00000000000f0000000f00000000001a110313037800000000000000000000000000000068130313031303130313031303130000000000000000000000eafae4e4e4e4e4e4e4e4f4000000000000000000000000000000000000000000000000000000293900000000000000000000000000000000000037475767000000000000000000000000000000000000000000000000000000000000000000000000000068140479000000005d005d000000000000681313
-- 026:000000000000000000000000000000000000000000001a110212021202120212012a000000000000000f000000000212031302120313012a000000000008000000000000000000001a1102120414047900000000000000000000000000000069140414041404140414041404140000000000000000000000ebfbe4a5b5e4e4e4e4e4f5000000000015000000000000000000000000000000000f000051011101116100000008a8b8e8f80000000000000000384858000000a8b8c8f86a0048580000000000000000a8b8c8d8e8f86a000000000000000000000000000f000000000000005e005e00000000005e691414
-- 027:00000000000000000000000000000000000000001a11021203130313031303130212012a00000008000000001a110313041403130414021200000000000000000000000000001a11021203130313037810200000000000000000000000000068130313031303130313031303130000000000000000000000eafae4a6b6e400000000c200000000001600000000000f000000a8f8000000000000000000021202120000000029a9b9e9f93900000000000029394959000023a9b9c9f9002249590000000000002939a9b9c9d9e9f900002300000000000000000000000f000000000000005d005d00000000005d681313
-- 028:011101110111011101111020202020300111011102120313041404140414041403130212012a00000000000002120414031304140313031301110111011101110111011101110212031304140414047900000000000000000000000000000069140414041404140414041404140000000000000000000000ebfbe5a7b7e480800000c300000000001700000000000f000000a9f9000000002300000000681303780000005101110111011161005101110111011101110111011101110111011101989898981101110110203001110111011101110111011101110111011101011101110000005e00000000005e691414
-- 029:02120212021202120212000000000000021202120313041403130313031303130414031302120111011101110313031304140313041404140212021202120212021202120212031304140313031303780f000000000000000000000000000068130313031303130313031303130000000000000000000000eafae4e4e5e580800000c400969696961800000000000000001a1101110111011101116100691404790000000002120212021200000002120212021202120212021202120212021202990000891202120200000002120212021202120212021202120212021202021202120000005d00000000005d681313
-- 030:03130313031303130378000000000000681303130414031304140414041404140313041403130212021202120414041403130414031303130313031303130313031303130313041403130414041404784b4b6811011101110111610000000069140414041404140414041404140000000000000000000000ebfbe5e5e5e580800000c5009797979719002939001a1101110212021202120212021200006813037800000000681303130378000000681303130313031303130313031303130313680000000078031303290f3903130313031303130313031303130313031303130303780000005e00000000005e691414
-- 031:0414041404140414047900000000000069140414031304140313031303130313041403130414031303130313031303130414031304140414041404140414041404140414041403130414031303130379caca6912021202120212000000000068130313031303130313031303130000000000000000000000f6e6f6e6f6e6f6e6f6e6f6c6d6c6d6c6d60111011102120212031303130313031303787a7a691404797a7a7a7a6914041404797a7a7a691404140414041404140414041404140414698c9c8c9c7904140313031304140414041404140414041404140414041404140404794b4b4b4b4b4b4b4b4b4b681313
-- 032:031303130313031303780000000000006813031304140313041404140414041403130414031304140414041404140414031304140313031303130313031303130313031303130414031304140414041403130313031303130378000000000069140414041404140414041404140000000000000000000000c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d6d70212021203130313041404140414041404797b7b681303787b7b7b7b6813031303787b7b7b681303130313031303130313031303130313687a7a7a7a780313041404140313031303130313031303130313031303130313030378cacacacacacacacacaca691414
-- 033:041404140414041404790000000000006914041403130414031303130313031304140313041403130313031303130313041403130414041404140414041404140414041404140313041403130313031304140414041404140479000000000068130313031303130313031303130000000000000000000000d7c6d6c6d6c6d6c6d6c6d6c6d6c6d6c6d60313031304140414031303130313031303788b8b691404798b8b8b8b6914041404798b8b8b691404140414041404140414041404140414694b4b4b4b790414041404140414041404140414041404140414041404140414040479cbcbcbcbcbcbcbcbcbcb681313
-- 034:780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000069140414041404140414041404140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005050505000005050505050500000000050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:79000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006813031303130313031303130313000000000000000000000000000000c0d0e0e0e0e0e0e0e0e0e0e0f0c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:7900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000691404140414041404140414041400000000000000000000000000000000d1e1e1e1e1e1e1e1e1e1e1f100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:7800000000000000000000000000000000000000000000000000000000000000000000510111610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000681303130313031303130313031300000000000000000000000000000000d2e2e2e2e2e2e2e2e2e2e2f200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:790000000000000000000000000000000000000000000000000000000000000008000000021200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1101110111012a003069140414041404140414041404140000000000000000000000000000000000d3e5e5e5e5e5e5e5eafa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:78000000000000000000000000000000000000000000000000000000000000000000000068780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a110212021202120212000068130313031303130313031303130000000000000000000000000000150000d4e5e5e5e5e5e5e5ebfb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:7900000f000f00000000000000000000000000000000000000000000000000001a110111047900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002120313031303780000003069140414041404140414041404140000000000000000000000000000160000c20000000000e4e4eafa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:7800000f000f0000000000000000000000000f000f004f000f000f0000001a11021202120378000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1103130414041404790000000000000000000000000000000000000000000000000000000000000000170000c3000000808000e4ebfb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:7900000f000f000000000000000000000000000000000000000000001a1102120313031304790000000000000000000008000000000000001a110111011101114b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b781304140313031303780000000000000000000000000000000000000000000000000000000000000000180000c400000080800000eafa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:011101110111012a000000000000000000001a110111011101110111021203130414041403130111012a00000000000000000000000000000212021202120212bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb791403130414041404140111011100000000000000000000000000000000000000000000000000000000190000c500000080800000ebfb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:0212021202120212100000000000000000300212021202120212021203130414031303130414021202120111012a00001a110111011101110313031303130378bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb78130414031303130313021202120111011101110111011101110111011101110111011101110111d7e6f6e6f6e6f6e6f6e6f6e6f6e6f60111011101110111011101110111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:03130313031303784b5b6b7b4b5b6b7b4b5b68130313031303130313041403130414041403130313031302120212011102120212021202120414041404140479bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb79140313041404140414031303130212021202120212021202120212021202120212021202120212d7c6d6c6d6c6d6c6d6c6d6c6d6c6d60212021202120212021202120212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:0414041404140479cacacacacacacacacaca6914041404140414041403130414031303130414041404140313031302120313031303130313031303130313031303130313031303130378bbbbbbbbbb781303130414031303130313041404140313031303130313031303130313031303130313031303130313c6d6c6d6c6d6c6d6c6d6c6d6c6d6d71403130313031303130313031303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:0313031303130378dbdbdbdbdbdbdbdbdbdb6813031303130313031304140313041404140313031303130414041403130414041404140414041404140414041404140414041404140479bbbbbbbbbb7914041403130414041404140313031304140414041404140414041404140414041404140414041404140313031303130313031303130313031304140414041404140414041404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:0414041404140479dadadadadadadadadada6914041404140414041403130414031303130414041404140313031304140313031303130313031303130313031303130313031303130378bbbbbbbbbb7813031304140313031303130414041403130313031303130313031303130313031303130313031303130414041404140414041404140414041403130313031303130313031303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:0313031303130313031303130313031303130313031303130313031304140313041404140313031303130414041403130414041404140414041404140414041404140414041404140479cacacacaca7914041403130414041404140313031304140414041404140414041404140414041404140414041404140313031303130313031303130313031304140414041404140414041404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:0414041404140414041404140414041404140414041404140414041403130414031303130414041404140313031304140313031303130313031303130313031303130313031303130378cbcbcbcbcb7813031304140313031303130414041403130313031303130313031303130313031303130313031303130414041404140414041404140414041403130313031303130313031303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 134:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000078000000000000000000000000000000000000000000000000
-- 135:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000079000000000000000000000000000000000000000000000000
-- </MAP>

-- <MAP1>
-- 000:00000000000000000000000000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:00000000000000000000000000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:00000000000000000000000000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:00000000000000000000000000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:00000000000000000000000000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:00000000000000000000000000000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:25352535910000000000a1b1c1000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:26362636130000000000a2b2c2000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:01010104140000000000a3b3c3000b4b0d4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:0101010313000000000000d200000b4b0d4d000000a4b400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:010101041400000000c4d4d300000b4b0d4d000000a5b500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:01010105152535253525358191000b4b0d4dc06135253500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:01010101162636263626368292d00b4b0d4d004353263600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:01010101010101010101010313000b4b0d4d004454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:010101010101010101010103138b8b8d8b8d8d4353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:010101010101010101010104148c8e8c8e8c8e4454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP1>

-- <MAP7>
-- 000:f04949494949f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0e0f049494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:f049494949f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f149494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:f049f04949f0f0f000102030405060708090a0b0c0d0f249494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:f0f0f0494949f0f001112131415161718191a1b1c1d1f349494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:f0f0f0494949f0f002122232425262728292a2b2c2d2f449494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:f0f0f0494949f0f003132333435363738393a3b3c3d3f549494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:49f0f04949f0f0f004142434445464748494a4b4c4d4f649494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:49494949494949f005152535455565758595a5b5c5d5f749494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:4949494949f0f0f006162636465666768696a6b6c6d6f849494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:494949494949f0f007172737475767778797a7b7c7d7f949494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:494949494949f0f008182838485868788898a8b8c8d8fa49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:49494949494949f009192939495969798999a9b9c9d9fb49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:494949494949f0f00a1a2a3a4a5a6a7a8a9aaabacadafc49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:4949494949f0f0f00b1b2b3b4b5b6b7b8b9babbbcbdbfd49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:49f049494949490e0c1c2c3c4c5c6c7c8c9cacbcccdcfe49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:49f049494949490f0d1d2d3d4d5d6d7d8d9dadbdcdddff49494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:494949494949494949494949494949494949494949494949494949494949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:000000000000000000000000000000000000000000000000000049000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP7>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 004:eeddcbba9877654210012345689abcde
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
-- 001:322052507280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:02001210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:739073e083b093e0a34093a0a3809300a300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 005:24f534e744e044d054d054c064b0d4a7c4a0c480b480a470945084507440e4305420441024100400f400f400f400f400f400f400f400f400f400f40041b000000000
-- 016:3130513071009100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100503000000400
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000
-- 018:e100c130a15081606160417031a021d021f011f001c02180a170d160f150f120f110f100f100f100f100f100f100f100f100f100f100f100f100f100502000000000
-- 019:60008020b060c090c0a0b0c090e080e070e060e050c050a060809070a050a030902090109000d000d000e000f000f000f000f000f000f000f000f000305000000000
-- 032:210041006100710081009100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100305000000000
-- 033:010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100300000000000
-- </SFX>

-- <SFX1>
-- 000:b210c200e200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200300000000000
-- 001:b220c250d280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 002:d200e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 003:c220a250a260b280c280f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200307000000000
-- 004:b390b3e0c3b0d3e0e340d3a0e380d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300407000000000
-- 005:24f534e744e044d054d054c064b0d4a7c4a0c480b480a470945084507440e4305420441024100400f400f400f400f400f400f400f400f400f400f40041b000000000
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
-- 000:00202020000408408001020400000000101000000000001010500000000000001010000000000010101000000000000010100000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000000002020000000101010100000000000001010001000000000000000000000000010100000000000000000001010000000000000001010020210100000000002020202000010020402101000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <FLAGS1>
-- 000:00102000040040800102000000000000000810100000101010100000000000000000101010001010101000000000000010100000101010101010000000000000101000001010101010100000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000404040400000000000000000000000000000000000000000000000000000000040404040000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS1>

-- <FLAGS2>
-- 000:00002000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000
-- </FLAGS2>

-- <FLAGS3>
-- 000:00002000000040800102000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

-- <SCREEN>
-- 000:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 001:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 002:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 003:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 004:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 005:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 006:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 007:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 008:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 009:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 010:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 011:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 012:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000565550000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 013:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000cccccccccccccc0006565656500000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 014:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cccccccccccc0000565656565000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 015:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc000565000ccccccccccc00056565656566000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 016:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc005656500cccccccc000000656565656565656565656500000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 017:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc006666660ccccc0000000065656565656566656666666660000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 018:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc005666600ccc000000000056565656565656565656565656000cccccc00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 019:cccccccccccccccccccccccccccccccccccccccccccccccccccccccc000666000cc00000656565656565666566666666666666666000cccc0000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 020:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cc000056555655565656565656565656565656665000ccc000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 021:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccc000565656565656565656665666666666666666000cc0000555000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 022:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000655565656565656565656565656565666566000cc0005555500cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 023:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00065656565656566656666666666666666666660000c0005656500cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 024:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0005556565656565656565656565656566656665600000000666000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 025:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0005656565656565656665660006666666666666666000c000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 026:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006565656565656565656500006565666566666666000c00000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 027:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000656565656665660000000006666666666666666000ccc00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 028:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000555656565656500000000000566656665666666600cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 029:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006565656565666000000cc000666666666666666000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 030:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000656565656560000ccccc000005660006666666000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 031:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00006566656660000ccccccc00000000000666666000ccc000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 032:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000005656500000ccccccccc000000000006660000c00000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 033:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000cccccccccccc00000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 034:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000ccccccccccccccccccc00000000000000060000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 035:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000ccccccccccccccccccccccc000000000066600000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 036:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000666600000055000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 037:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccccccc000000666660000000565000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 038:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cccccccccccccccccccccc00000066666000000055555000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 039:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000656000ccccccccccccccccccc0000000666600000005556565000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 040:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc005565500cccccccccccccccccc00000066660000000555555555000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 041:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc005656500ccccccccccccccccc000006660000000056555655565000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 042:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc006566600cccccccccccccccc0000660000000005555555555555000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 043:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000666000ccccccccccccccc000000000000005656565656565656000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 044:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000cccccccccccccccc000000000005555555555555555555000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 045:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccc0000000055565556565655565656560000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 046:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00055555555555555555555555555550000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 047:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000056565656565656565656565656560000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 048:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000555555555555555555555555555500000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 049:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000565656565656565656565656565600000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 050:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000005555555655555556555655565556000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 051:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000656565656565656565656565656565000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 052:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00005555555555555555555555555555650000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 053:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00006565656565656565656565656565656000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 054:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000ccccccccccccccc000565556555655565556555655565556555000000000ccccccccccccccccccccccccccc00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 055:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000cccccccc0000cc000560000000656565650000656500000565600000000cccccccccccccccc000000ccc0000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 056:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000cccccc00000000005000000000055565000000050000000550000000000ccccc000000ccc00000000c00000000ccc000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 057:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000044400000cccc0000000000000000000000056500000000000000000000000440000ccc00000000cc000000000000444000c000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 058:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00044444440000ccc0004440000000044444000005600044000000444000000044400000000000040000000044400000044400000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 059:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000044444444000cc00034440000000434443440006000443400000434000044344000000000004444000000444400000044300000040000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 060:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000444000444000cc00044440000004444444440005000444400000444000044440000065000004444400004444440000044400000444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 061:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004440004344000c00044340000003440004430006000344400000444000034440000000500043444300004443440000034300004344000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 062:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0044440004444000c00044440000004440000000005000444400000444000044440000000000044444400004444440000044400044444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 063:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034340000343000000034340000003430000000006000343400000434000034340000000000043434340004343430000034300034340000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 064:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004444000044440000004443000000444400000006500044440000444400000344400043000004444443444444434000004344434440000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 065:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000343400003434000004343000000034340005650060003434300434340000043434343000000434343434343434300000343434343000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 066:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000434300004343400003434000000043430006500000004343434343434000034343430000000343434343434343400000434343430000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 067:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034340000043430000433300000003433000500000000343434343433000004333400000000043430043434003430000034333400000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 068:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004343000003434000034340000000034300000003000043434343434300000343430000000003434000434000434000004343400000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 069:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000343430043434300003343000000003343000003300003334333433340000003433000000000433300034300033300000333430000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 070:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00043434343434340000343400000000343400003430000434300004343000000434340000000034340004300004340000043430000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 071:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc003333333333333000033330000000003333000333000033330000033300000033333300000003333000030000333000033333000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 072:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034343000043430003433343000000433343334300004340000003430000000333434340000333400000000033400003334000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 073:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00033330000003330003333333300000033333333300003330000003330005000333333300000333300000000033300003333000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 074:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00033340000000000000333333000000003333333000000330000003300056000033333300000033300000000033300003330000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 075:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000333000000000000000330000066000003330000000033300000330006660003333000000000300060060000300000030000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 076:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000033000c0000000000000000006560000000000060000000000000000565000000000005600000006565600000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 077:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000ccccccccc0000000006566600000000566600000006000000665660000000005660000006666660000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 078:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000cccccccccc00065656565656000650005650000600000056565650000006565656000656665656000050000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 079:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000ccccc0000006656665666566660000006666000000000066666666000066666000000000066000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 080:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000c00000000056565650005650000000065000000000000056560000000656000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 081:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000044400000000000000000656600000060004000000000444440000006600000000666000440000000000004400000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 082:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00004444440000000444400000650000000000044000000044444444400000000444000500004444440000444444440000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 083:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000044344444000044344430000600004400000044300000043444344430000004344000600034343000000444344434000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 084:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004444444440000444444440000000444000000444000004444004444400000044440005000444400000004444444444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 085:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004340000440000344434443000000434000000343400003430000434300000044430000004343400000044300004443000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 086:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00044440000400000444004444000000444000000444300004440000044400000044440000003434000000044400000444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 087:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034340000000000340000343400000434000000343400003430000034300000343430000004343000000034300000343000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 088:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00044430000000004430000444300000443000000434400044340000043400000434440000003434300000044400000444000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 089:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000434300000000034340000043400000434000000343400043400000434300000343430000034343434300034300000343000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 090:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0003434000cc000043430000034300000343000000434300034300000343000000434340000043434343400043400003430000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 091:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004333000cc00003330000003340000033400000034330003343334333000000034333000003333300000003330003430000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 092:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00034340000000004340000003430000034340000043430003434343430000600043434000004343000000004343434340000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 093:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000334300000000034330000043300000433300000333000043334333400066000333330000333330000000034333433340000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 094:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0003334000000000434300000343000000434000004340000343434343000066004333000003334300000000434343434340000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 095:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0003333000333000333300003333000000333333333330003333000333300066000333000003333300000000333330033333000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 096:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0004333433340000333433343330000003343434333400043330003433300060003430000034333330000000333400043334000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 097:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0003333333330000333333333300006000333333333300033330000333300060003330000003333333000000333300003333000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 098:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000333333300000033333333300056000033333333000003300000333300060003330000003333330000000333300000330000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 099:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000333000000000033333000006660000333333000000000000003300006000000000000000000000c00033330000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 100:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000cc00000000000006665000000000000000000000000000006650000000660000000000ccc000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 101:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000cccc00000000000666666000000000000660000660000000666600000066666000000ccccc00000000cc0000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 102:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000566666665600000000666666666666000666666666666666000000cccccccc00000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 103:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006666666666666666666666666666666666666666666666666666000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 104:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006656665666566656666666666666666666666666666666666000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 105:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00066666666666666666666666666666666666666666666666000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 106:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006666666666666666666666666666666666666666666660000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 107:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00066666666666666666666666666666666666666666660000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 108:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000665666666656666666666666666666666666666600000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 109:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0006666666666666666666666666666666666666600000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 110:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000666666666666666666666666666666666660000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 111:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000666666666666666666666666666666000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 112:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00006666666666666666666666666660000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 113:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000066666666666666666666600000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 114:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000066666666666666000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 115:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 116:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 117:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 118:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 119:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 120:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 121:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 122:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 123:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 124:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 125:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 126:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 127:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 128:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 129:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 130:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 131:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 132:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 133:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 134:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 135:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- </SCREEN>

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
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

-- <PALETTE1>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
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
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE7>

