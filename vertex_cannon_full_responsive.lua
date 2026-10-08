local P=game:GetService("Players")local lp=P.LocalPlayer
local RS=game:GetService("ReplicatedStorage")local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")local Stats=game:GetService("Stats")
local VU=game:GetService("VirtualUser")local SS=game:GetService("SoundService")
local TS=game:GetService("TweenService")

local S={running=false,rate=1500,eff=1500,pattern="AUTO",onlyDmg=true,
conc=true,weight=true,throt=true,net=true,rescan=true,afk=true,sfx=true,
keybd=true,health=true,failTrk=true,adaptive=false,ramp=true,killSw=true,
turbo=false,turboMult=25,turboMultIdx=4,turboMultOpts={10,15,20,25,35,50,75,100},
burstWin=false,burstOn=3,burstOff=1.5,burstPhase="on",burstNext=tick(),
cursor=1,ultraCur=1,ultraRotTick=tick(),carry=0,fired=0,total=0,actual=0,lastTick=tick(),
ping=0,reason="ok",fps=60,fpsFrames=0,fpsTick=tick(),
startTime=tick(),remotes={},dmgR={},dmgW={},cnt=0,dmgCnt=0,premCnt=0,totW=0,
lastFire={},health={},failCount={},pri={},prem={},premToggles={},log={},ui={},
packets={},lastBytes=0,lastBytesTick=tick(),packetKB=0,frozen=false,
maxFires=500,frzThr=1200,overload=0,lastWarn=0,rMult=1,rampStart=0,
lastUpdateTick=0,acc=0,cap=0,lowStreak=0,autoPattern="AUTO",actualPattern="ULTRA",
noLag=false,
antiDelay=false,instantFire=false,pingComp=false,spikeGuard=false,moveSync=false,anchorMode=false,
anchorPos=nil,
pingBase=0,pingSamples={},lastPingSpike=0,spikeUntil=0,
fireCount={},hotRemote=nil,
premiumOnly=false,autoRescanOnEquip=true,
sessionBest=0,
categoryEnabled={},
lastReport="",
accentHue=0,pulsePhase=0,lastFiredTotal=0,rateGlow=0,
rateHistory={},lastRateSample=0,statPulse={},
scanDots=0,scanAnimUntil=0,
opMode={warmUntil=0,batchAccum=0,lastBurstTick=0,boostUntil=0,burstSize=0,
    maxObserved=0,avgInterval=0,intervalSamples={}},
moveState={lastPos=nil,lastPosTick=0,velocity=Vector3.new(0,0,0),
    moving=false,walkFrames=0,stillFrames=0,wasMoving=false},
findStats={total=0,premium=0,damage=0,byParent={},lastScan=0,lastDuration=0},
profiles={},profileActive=nil,
hitbox={en=false,invis=true,all=false,size=15,step=5,stepIdx=2,steps={1,5,10,25},
target=nil,saved={},acc=0,lastCount=0,hp=0,maxHp=0,dist=0}}

local function save()
    if not getgenv then return end
    getgenv().CP=getgenv().CP or {}
    local p=getgenv().CP
    for k,v in pairs(S)do if type(v)=="boolean"or type(v)=="number"or type(v)=="string"then p[k]=v end end
    p.profiles=S.profiles
    p.categoryEnabled=S.categoryEnabled
end
local function load()
    if not getgenv or not getgenv().CP then return end
    for k,v in pairs(getgenv().CP)do
        if k~="profiles"and k~="categoryEnabled"and S[k]~=nil and type(S[k])==type(v)then S[k]=v end
    end
    if getgenv().CP.profiles then S.profiles=getgenv().CP.profiles end
    if getgenv().CP.categoryEnabled then S.categoryEnabled=getgenv().CP.categoryEnabled end
end
load()

local function applyNoLag()
    if S.noLag then
        S.antiDelay=true S.instantFire=true S.pingComp=true
        S.spikeGuard=true S.moveSync=true S.anchorMode=true
    else
        S.antiDelay=false S.instantFire=false S.pingComp=false
        S.spikeGuard=false S.moveSync=false S.anchorMode=false S.anchorPos=nil
    end
end
applyNoLag()

local cs
pcall(function()
    cs=Instance.new("Sound")cs.SoundId="rbxassetid://6895079853"
    cs.Volume=0.3 cs.Parent=SS
end)
local function click(p)
    if not S.sfx or not cs then return end
    pcall(function()local s=cs:Clone()s.PlaybackSpeed=p or 1 s.Parent=SS s:Play()
    task.delay(0.3,function()s:Destroy()end)end)
end

-- ═══ RIPPLE helper ═══
local function attachRipple(btn)
    if not btn then return end
    btn.ClipsDescendants=true
    btn.Activated:Connect(function()
        local rp=Instance.new("Frame")
        rp.AnchorPoint=Vector2.new(0.5,0.5)
        rp.Size=UDim2.new(0,4,0,4)
        rp.Position=UDim2.new(0.5,0,0.5,0)
        rp.BackgroundColor3=Color3.fromRGB(255,255,255)
        rp.BackgroundTransparency=0.7
        rp.BorderSizePixel=0
        rp.ZIndex=btn.ZIndex+5
        rp.Parent=btn
        Instance.new("UICorner",rp).CornerRadius=UDim.new(1,0)
        local target=math.max(btn.AbsoluteSize.X,btn.AbsoluteSize.Y)*1.5
        TS:Create(rp,TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
            Size=UDim2.new(0,target,0,target),
            BackgroundTransparency=1,
        }):Play()
        task.delay(0.5,function()if rp and rp.Parent then rp:Destroy()end end)
    end)
end

local tGui,tQ,tActive=nil,{},false
local function tFlush()
    if tActive or #tQ==0 then return end
    tActive=true
    local pg=lp:WaitForChild("PlayerGui",5)
    if not pg then tActive=false return end
    if not tGui or not tGui.Parent then
        if pg:FindFirstChild("CT")then pg.CT:Destroy()end
        tGui=Instance.new("ScreenGui")tGui.Name="CT"
        tGui.ResetOnSpawn=false tGui.IgnoreGuiInset=true tGui.Parent=pg
    end
    local it=table.remove(tQ,1)
    local t=Instance.new("Frame")
    t.Size=UDim2.new(0,260,0,36)t.Position=UDim2.new(1,40,0,20)
    t.BackgroundColor3=Color3.fromRGB(20,11,11)t.BorderSizePixel=0 t.Parent=tGui
    t.BackgroundTransparency=0.05
    Instance.new("UICorner",t).CornerRadius=UDim.new(0,8)
    local st=Instance.new("UIStroke")st.Color=it.c or Color3.fromRGB(255,40,40)
    st.Thickness=1.5 st.Parent=t
    local accent=Instance.new("Frame")
    accent.Size=UDim2.new(0,4,1,-8)accent.Position=UDim2.new(0,4,0,4)
    accent.BackgroundColor3=it.c or Color3.fromRGB(255,40,40)
    accent.BorderSizePixel=0 accent.Parent=t
    Instance.new("UICorner",accent).CornerRadius=UDim.new(0,2)
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-24,1,0)lbl.Position=UDim2.new(0,16,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=(it.i or"")..(it.t or"")
    lbl.TextColor3=it.c or Color3.fromRGB(255,80,80)
    lbl.TextSize=11 lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextTruncate=Enum.TextTruncate.AtEnd lbl.Parent=t
    TS:Create(t,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(1,-280,0,20)}):Play()
    task.delay(2.2,function()
        if t and t.Parent then
            local a=TS:Create(t,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(1,40,0,20)})
            a:Play()a.Completed:Connect(function()
                t:Destroy()task.wait(0.05)tActive=false tFlush()
            end)
        else tActive=false tFlush()end
    end)
end
local function toast(txt,col,icon)
    table.insert(tQ,{t=txt,c=col,i=icon})tFlush()
end

local cFS=setmetatable({},{__mode="k"})
local function prime(r)
    if not r then return nil end
    local f=cFS[r]if f then return f end
    local ok,v=pcall(function()return r.FireServer end)
    if ok and v then cFS[r]=v return v end
    return nil
end

task.spawn(function()while true do task.wait(1)
    pcall(function()
        local st=Stats.Network.ServerStatsItem["Data Ping"]
        if st then local v=st:GetValue()
            if v and v>0 then
                local np=math.floor(v)
                local old=S.ping
                S.ping=np
                table.insert(S.pingSamples,np)
                if #S.pingSamples>20 then table.remove(S.pingSamples,1)end
                if S.pingComp then
                    local sum=0
                    for _,x in ipairs(S.pingSamples)do sum=sum+x end
                    S.pingBase=math.floor(sum/#S.pingSamples)
                end
                if S.spikeGuard and old>0 and np-old>=80 then
                    S.lastPingSpike=tick()S.spikeUntil=tick()+0.3
                end
            end
        end
    end)
end end)
task.spawn(function()while true do task.wait(0.5)
    pcall(function()
        local st=Stats.Network.ServerStatsItem["Data Sent"]
        if st then local b=st:GetValue()or 0
            local n=tick()local dt=n-S.lastBytesTick
            if dt>0 then S.packetKB=(b-S.lastBytes)/dt/1024
                table.insert(S.packets,S.packetKB)
                if #S.packets>10 then table.remove(S.packets,1)end
            end
            S.lastBytes=b S.lastBytesTick=n
        end
    end)
end end)

-- ═══ POLISH animation loop ═══
task.spawn(function()
    while true do
        task.wait(0.05)
        S.accentHue=(S.accentHue+0.005)%1
        S.pulsePhase=(S.pulsePhase+0.15)%(math.pi*2)
        S.scanDots=(S.scanDots+0.1)%4
        if S.ui.accentBar and S.running then
            S.ui.accentBar.BackgroundColor3=Color3.fromHSV(S.accentHue,0.85,0.95)
        elseif S.ui.accentBar then
            S.ui.accentBar.BackgroundColor3=Color3.fromRGB(255,40,40)
        end
        if S.ui.toggle and S.running then
            local p=(math.sin(S.pulsePhase)+1)/2
            local c=0.5+p*0.5
            S.ui.toggle.BackgroundColor3=Color3.fromRGB(
                math.floor(20*c+40*(1-c)),math.floor(11*c),math.floor(11*c))
        end
        -- tab glow
        if S.ui.tabGlow then
            local p=(math.sin(S.pulsePhase*1.5)+1)/2
            S.ui.tabGlow.BackgroundTransparency=0.35+p*0.35
        end
        -- scan dots
        if S.ui.findBtn and tick()<S.scanAnimUntil then
            local d=math.floor(S.scanDots)+1
            S.ui.findBtn.Text="⚡"..string.rep(".",d)
        end
    end
end)

local function hbSave(h)if S.hitbox.saved[h]then return end
    S.hitbox.saved[h]={size=h.Size,trans=h.Transparency,col=h.CanCollide,ml=h.Massless}end
local function hbRestore(h)
    local v=S.hitbox.saved[h]if not v then return end
    pcall(function()if h and h.Parent then h.Size=v.size h.Transparency=v.trans
        h.CanCollide=v.col h.Massless=v.ml end end)
    S.hitbox.saved[h]=nil end
local function hbApply(p)
    if not p or not p.Character then return end
    local h=p.Character:FindFirstChild("Head")if not h then return end
    local hm=p.Character:FindFirstChildOfClass("Humanoid")
    if not hm or hm.Health<=0 then return end
    hbSave(h)local sz=S.hitbox.size
    pcall(function()h.Massless=true h.CanCollide=false
        h.Size=Vector3.new(sz,sz,sz)
        if S.hitbox.invis then h.Transparency=1
        else local v=S.hitbox.saved[h]if v then h.Transparency=v.trans end end end)
    if p==S.hitbox.target then
        S.hitbox.hp=math.floor(hm.Health)S.hitbox.maxHp=math.floor(hm.MaxHealth)
        local hr=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hr then S.hitbox.dist=math.floor((h.Position-hr.Position).Magnitude)end
    end
end
local function hbClear()for h in pairs(S.hitbox.saved)do hbRestore(h)end S.hitbox.saved={}end
local function hbTarget()
    if not lp.Character then return nil end
    local hr=lp.Character:FindFirstChild("HumanoidRootPart")if not hr then return nil end
    local b,bd=nil,math.huge
    for _,p in ipairs(P:GetPlayers())do if p~=lp and p.Character then
        local hm=p.Character:FindFirstChildOfClass("Humanoid")
        local h=p.Character:FindFirstChild("Head")
        if hm and hm.Health>0 and h then
            local d=(h.Position-hr.Position).Magnitude
            if d<bd then bd=d b=p end
        end
    end end
    return b
end
local function hbRefresh()
    if not S.hitbox.en then return end
    if S.hitbox.all then
        local c=0
        for _,p in ipairs(P:GetPlayers())do if p~=lp then
            local hm=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hm and hm.Health>0 then hbApply(p)c=c+1 end
        end end
        S.hitbox.lastCount=c S.hitbox.target=nil
    else
        local t=hbTarget()
        if t then hbApply(t)S.hitbox.target=t S.hitbox.lastCount=1
        else S.hitbox.target=nil S.hitbox.lastCount=0 end
    end
end

local function scanAll()
    local found,seen={},{}
    local svcs={"ReplicatedStorage","ReplicatedFirst","ServerStorage",
        "ServerScriptService","StarterGui","StarterPack","StarterPlayer",
        "Workspace","Players","Lighting","Chat","Teams","SoundService",
        "TextChatService","JointsService","CoreGui","VoiceChatService",
        "TestService","VirtualInputManager","VRService"}
    for _,n in ipairs(svcs)do
        local ok,svc=pcall(function()return game:GetService(n)end)
        if ok and svc then
            pcall(function()
                for _,o in ipairs(svc:GetDescendants())do
                    if not seen[o] and (o:IsA("RemoteEvent") or o:IsA("UnreliableRemoteEvent") or o:IsA("RemoteFunction"))then
                        seen[o]=true found[#found+1]=o
                    end
                end
            end)
        end
    end
    for _,c in ipairs({lp:FindFirstChild("Backpack"),lp:FindFirstChild("PlayerGui"),
        lp:FindFirstChild("PlayerScripts"),lp.Character})do
        if c then pcall(function()
            for _,o in ipairs(c:GetDescendants())do
                if not seen[o] and (o:IsA("RemoteEvent") or o:IsA("UnreliableRemoteEvent") or o:IsA("RemoteFunction"))then
                    seen[o]=true found[#found+1]=o
                end
            end
        end)end
    end
    pcall(function()
        for _,p in ipairs(P:GetPlayers())do
            if p~=lp and p.Character then
                for _,o in ipairs(p.Character:GetDescendants())do
                    if not seen[o] and (o:IsA("RemoteEvent") or o:IsA("UnreliableRemoteEvent"))then
                        seen[o]=true found[#found+1]=o
                    end
                end
            end
        end
    end)
    return found
end

local DAMAGE_NAMES={yereayak=true,yereyumruk=true,yumruk=true,basicdumbell=true,
kick=true,smash=true,punch=true,dumbell=true,dumbbell=true,hit=true,swing=true,
attack=true,strike=true,slash=true,shoot=true,fire=true,cast=true,ability=true,
skill=true,sword=true,melee=true,weapon=true,swinghit=true,click=true}

local PREM_CATS={
    {key="fast_punch",label="FAST PUNCH",pats={"fast","punch"},must="punch",tint=Color3.fromRGB(255,80,120)},
    {key="5x_dumbell",label="5X DUMBBELL",pats={"5x","dumbell"},must="dumbell",tint=Color3.fromRGB(255,140,60)},
    {key="fast_hit",label="FAST HIT",pats={"fast","hit"},must="hit",tint=Color3.fromRGB(255,200,60)},
    {key="speed_punch",label="SPEED PUNCH",pats={"speed","punch"},must="punch",tint=Color3.fromRGB(80,220,120)},
    {key="10x_dumbell",label="10X DUMBBELL",pats={"10x","dumbell"},must="dumbell",tint=Color3.fromRGB(60,200,255)},
    {key="5x_punch",label="5X PUNCH",pats={"5x","punch"},must="punch",tint=Color3.fromRGB(120,180,255)},
    {key="10x_punch",label="10X PUNCH",pats={"10x","punch"},must="punch",tint=Color3.fromRGB(160,120,255)},
    {key="20x_punch",label="20X PUNCH",pats={"20x","punch"},must="punch",tint=Color3.fromRGB(200,100,255)},
    {key="50x_punch",label="50X PUNCH",pats={"50x","punch"},must="punch",tint=Color3.fromRGB(255,100,200)},
    {key="100x_punch",label="100X PUNCH",pats={"100x","punch"},must="punch",tint=Color3.fromRGB(255,60,160)},
    {key="fast_kick",label="FAST KICK",pats={"fast","kick"},must="kick",tint=Color3.fromRGB(255,120,80)},
    {key="speed_hit",label="SPEED HIT",pats={"speed","hit"},must="hit",tint=Color3.fromRGB(120,255,180)},
    {key="strong",label="STRONG",pats={"strong"},must="strong",tint=Color3.fromRGB(255,140,140)},
    {key="strongest",label="STRONGEST",pats={"strongest"},must="strongest",tint=Color3.fromRGB(255,80,80)},
    {key="super",label="SUPER",pats={"super"},must="super",tint=Color3.fromRGB(180,180,255)},
    {key="ultra",label="ULTRA",pats={"ultra"},must="ultra",tint=Color3.fromRGB(200,120,255)},
    {key="god",label="GOD",pats={"god"},must="god",tint=Color3.fromRGB(255,215,60)},
    {key="godly",label="GODLY",pats={"godly"},must="godly",tint=Color3.fromRGB(255,240,120)},
    {key="legendary",label="LEGENDARY",pats={"legendary"},must="legendary",tint=Color3.fromRGB(255,180,60)},
    {key="mythic",label="MYTHIC",pats={"mythic"},must="mythic",tint=Color3.fromRGB(255,80,180)},
    {key="vip",label="VIP",pats={"vip"},must="vip",tint=Color3.fromRGB(255,215,0)},
    {key="premium",label="PREMIUM",pats={"premium"},must="premium",tint=Color3.fromRGB(180,90,255)},
    {key="exclusive",label="EXCLUSIVE",pats={"exclusive"},must="exclusive",tint=Color3.fromRGB(100,200,255)},
    {key="elite",label="ELITE",pats={"elite"},must="elite",tint=Color3.fromRGB(60,180,200)},
    {key="master",label="MASTER",pats={"master"},must="master",tint=Color3.fromRGB(255,150,200)},
    {key="boost",label="BOOST",pats={"boost"},must="boost",tint=Color3.fromRGB(80,255,180)},
    {key="instant",label="INSTANT",pats={"instant"},must="instant",tint=Color3.fromRGB(255,220,80)},
}
for _,c in ipairs(PREM_CATS)do
    if S.categoryEnabled[c.key]==nil then S.categoryEnabled[c.key]=true end
end

local KW={"vip","premium","paid","god","godly","op","admin","dev","legendary","mythic",
    "exclusive","elite","ultra","super","mega","special","pro","secret","hidden",
    "royal","master","buff","boost","booster",
    "2x","3x","4x","5x","6x","7x","8x","9x","10x","15x","20x","25x","30x","40x","50x","75x","100x","x2","x3","x4","x5","x10","x20","x50","x100",
    "fast","faster","fastest","speed","quick","rapid","swift","instant","flash",
    "strong","stronger","strongest","power","powerful","mega","dmg","damage",
    "punch","hit","kick","smash","strike","swing","slash","attack","melee",
    "dumbell","dumbbell","weight","box","bag",
    "upgrade","upgraded","level","levelup"}

local function score(path,parentPath,parentName)
    local l=path:lower().."|"..parentPath:lower().."|"..parentName:lower()
    local s=0
    for _,k in ipairs(KW)do if l:find(k,1,true)then s=s+1 end end
    return s
end
local function classify(path,parentPath,parentName)
    local l=path:lower().."|"..parentPath:lower().."|"..parentName:lower()
    local hits={}
    for _,cat in ipairs(PREM_CATS)do
        local ok=true
        for _,p in ipairs(cat.pats)do
            if not l:find(p,1,true)then ok=false break end
        end
        if ok and l:find(cat.must,1,true)then table.insert(hits,cat.key)end
    end
    return hits
end
local function isDmgName(n)return DAMAGE_NAMES[n:lower()]==true end
local function isDmg(r)
    if isDmgName(r.Name)then return true end
    local p=r.Parent
    for _=1,4 do
        if not p then break end
        if isDmgName(p.Name)then return true end
        p=p.Parent
    end
    return false
end
local function enabled(r)local v=S.premToggles[r]if v==nil then return true end return v end
local function isBad(r)
    if not S.failTrk then return false end
    local f=S.failCount[r]
    return f and f>=5
end
local function catTint(key)
    for _,c in ipairs(PREM_CATS)do if c.key==key then return c.tint end end
    return T.PU
end

local function rebuild(silent)
    local t0=tick()
    S.remotes={}S.dmgR={}S.dmgW={}S.prem={}S.cnt=0 S.dmgCnt=0 S.premCnt=0 S.totW=0
    S.findStats={total=0,premium=0,damage=0,byParent={},lastScan=tick(),lastDuration=0}
    local all=scanAll()
    S.cnt=#all S.findStats.total=#all
    local premFound=0 local dmgFound=0

    for _,r in ipairs(all)do
        if not r or not r.Parent then continue end
        local path=r:GetFullName()
        local parent=r.Parent
        local parentPath=parent and parent:GetFullName()or""
        local parentName=parent and parent.Name or""
        prime(r)
        local cats=classify(path,parentPath,parentName)
        local catDisabled=false
        if #cats>0 then
            for _,catKey in ipairs(cats)do
                if S.categoryEnabled[catKey]==false then catDisabled=true end
            end
        end
        if #cats>0 and not catDisabled then
            for _,catKey in ipairs(cats)do
                S.prem[catKey]=S.prem[catKey]or{}
                table.insert(S.prem[catKey],{name=r.Name,r=r,cat=catKey,path=path,parent=parentName})
            end
            premFound=premFound+1 S.premCnt=S.premCnt+1
            if S.premToggles[r]==nil then S.premToggles[r]=true end
        end
        local sc=score(path,parentPath,parentName)
        local dmg=isDmg(r)
        if sc>0 or dmg then
            local w=1+sc+(dmg and 2 or 0)
            S.dmgCnt=S.dmgCnt+1 S.dmgR[S.dmgCnt]=r S.dmgW[S.dmgCnt]=w
            S.totW=S.totW+w
            S.pri[r]=sc>=8 and 1 or (sc>0 and 2 or 3)
            if dmg then dmgFound=dmgFound+1 end
        end
        if parentName~="" then
            S.findStats.byParent[parentName]=(S.findStats.byParent[parentName]or 0)+1
        end
    end
    S.findStats.premium=premFound S.findStats.damage=dmgFound
    S.findStats.lastDuration=math.floor((tick()-t0)*1000)
    table.insert(S.log,string.format("⚡FIND %d rem, %d dmg, %d prem (%dms)",
        S.cnt,dmgFound,premFound,S.findStats.lastDuration))
    while #S.log>8 do table.remove(S.log,1)end
    S.cursor=1 S.ultraCur=1
    if not silent then
        toast(string.format("%d rem • %d prem • %d dmg",S.cnt,premFound,dmgFound),
            premFound>0 and Color3.fromRGB(180,90,255)or Color3.fromRGB(80,220,120),"⚡ ")
    end
    if S.ui.refreshPrem then pcall(S.ui.refreshPrem)end
end
rebuild(true)

local function hookEquip(container)
    if not container then return end
    container.ChildAdded:Connect(function(c)
        if not S.autoRescanOnEquip then return end
        if c:IsA("Tool")then
            task.wait(0.3)
            rebuild(true)
            toast("Equipped: "..c.Name,T.PU,"🎒 ")
        end
    end)
end
hookEquip(lp:FindFirstChild("Backpack"))
hookEquip(lp.Character)
lp.CharacterAdded:Connect(function(c)
    task.wait(1)hookEquip(c)rebuild(true)
end)

task.spawn(function()while true do task.wait(5)
    if S.rescan then rebuild(true)end
end end)
task.spawn(function()while true do task.wait(30)
    if S.afk then pcall(function()VU:CaptureController()VU:ClickButton2(Vector2.new(0,0))end)end
end end)

local aR,aW,aCnt,aTot={},{},0,0
local function prefilter()
    aCnt=0 aTot=0
    local c,ws=0,0
    for tier=1,3 do
        for i=1,S.dmgCnt do
            local r=S.dmgR[i]
            if r and r.Parent and enabled(r) and prime(r) and not isBad(r) and (S.pri[r]or 3)==tier then
                if not S.premiumOnly or S.dmgW[i]>=3 then
                    c=c+1 aR[c]=r
                    local w=S.dmgW[i]or 1
                    aW[c]=w ws=ws+w
                end
            end
        end
    end
    aCnt=c aTot=ws
    for i=c+1,#aR do aR[i]=nil aW[i]=nil end
end

local function fireOne(r,n)
    local f=cFS[r]if not f then return 0 end
    if n==1 then
        local ok=pcall(f,r)
        if ok then S.failCount[r]=0 S.fireCount[r]=(S.fireCount[r]or 0)+1 return 1
        else S.failCount[r]=(S.failCount[r]or 0)+1 return 0 end
    end
    local ok=pcall(function()for _=1,n do f(r)end end)
    if ok then S.failCount[r]=0 S.fireCount[r]=(S.fireCount[r]or 0)+n return n
    else S.failCount[r]=(S.failCount[r]or 0)+n return 0 end
end

local function computeEff()
    local rt=S.rate
    local re="ok"
    if S.antiDelay then
        if S.turbo then rt=rt*(S.turboMult>1 and S.turboMult or 1) re="⚡OP TURBO"
        elseif S.pingComp and S.pingBase>0 and S.pingBase<120 then rt=math.min(rt*1.35,rt+5000) re="⚡OP+ PING"
        else re="⚡OP"end
        S.eff=math.floor(rt)S.reason=re return
    end
    if S.fps<15 then rt=math.min(rt,200)re="fps<15"
    elseif S.fps<25 then rt=math.min(rt,600)re="fps<25"
    elseif S.fps<40 then rt=math.min(rt,2000)re="fps<40"
    elseif S.fps<50 then rt=math.min(rt,5000)re="fps<50"end
    if S.throt and not S.turbo then
        local p=S.ping
        if p>300 then rt=math.min(rt,800)
        elseif p>200 then rt=math.min(rt,1500)
        elseif p>150 then rt=math.min(rt,3000)end
    elseif S.turbo then re="TURBO"
    elseif not S.throt then re="manual"end
    if S.pingComp and S.pingBase>0 and S.pingBase<120 then
        rt=math.min(rt*1.25,rt+3000)
        if re=="ok"then re="PING+"end
    end
    if S.antiFrz then
        local pk=S.packetKB
        if pk>=S.frzThr then rt=math.min(rt,500)
        elseif pk>=S.frzThr*0.75 then rt=math.min(rt,2000)
        elseif pk>=S.frzThr*0.5 then rt=math.min(rt,6000)end
    end
    if S.adaptive and S.running then
        local ratio=S.actual/math.max(1,S.eff)
        if ratio>=0.9 and S.turboMult<2 then S.turboMult=math.min(2,S.turboMult*1.05)
        elseif ratio<0.5 and S.turboMult>0.5 then S.turboMult=math.max(0.5,S.turboMult*0.9)end
    end
    S.eff=math.floor(rt)S.reason=re
end
task.spawn(function()while true do computeEff()task.wait(0.5)end end)

local function pickPattern()
    if S.autoPattern~="AUTO" then S.actualPattern=S.autoPattern return end
    if aCnt<=2 then S.actualPattern="RANDOM"
    elseif aCnt<=10 then S.actualPattern="ULTRA"
    else S.actualPattern="WEIGHTED" end
end
local function pickHot()
    local best,bestC=nil,0
    for r,c in pairs(S.fireCount)do if c>bestC then bestC=c best=r end end
    S.hotRemote=best
end
task.spawn(function()while true do task.wait(2)pcall(pickHot)end end)

local function opBoostActive()return S.antiDelay and tick()<S.opMode.boostUntil end
local function opWarmActive()return S.antiDelay and tick()<S.opMode.warmUntil end
local function opTriggerBoost(d)S.opMode.boostUntil=tick()+(d or 1.0)end
local function opRecordInterval(iv)
    if iv<=0 then return end
    table.insert(S.opMode.intervalSamples,iv)
    if #S.opMode.intervalSamples>30 then table.remove(S.opMode.intervalSamples,1)end
    local sum=0
    for _,v in ipairs(S.opMode.intervalSamples)do sum=sum+v end
    S.opMode.avgInterval=sum/#S.opMode.intervalSamples
end

local function updateMoveState(now)
    local char=lp.Character
    if not char then S.moveState.moving=false return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if not hrp then S.moveState.moving=false return end
    local pos=hrp.Position
    local prev=S.moveState.lastPos
    if prev and S.moveState.lastPosTick>0 then
        local dt=now-S.moveState.lastPosTick
        if dt>0 then
            local delta=pos-prev
            local speed=delta.Magnitude/dt
            S.moveState.velocity=delta/dt
            if speed>2 then
                S.moveState.moving=true S.moveState.walkFrames=S.moveState.walkFrames+1 S.moveState.stillFrames=0
            else
                S.moveState.moving=false S.moveState.stillFrames=S.moveState.stillFrames+1 S.moveState.walkFrames=0
            end
        end
    end
    S.moveState.lastPos=pos S.moveState.lastPosTick=now
end
local function applyAnchor(now)
    if not S.anchorMode or not S.running then S.anchorPos=nil return end
    local char=lp.Character if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")if not hrp then return end
    if not S.moveState.moving then S.anchorPos=nil return end
    if not S.anchorPos then S.anchorPos=hrp.CFrame end
    pcall(function()hrp.CFrame=S.anchorPos end)
end

local function update()
    local now=tick()
    local dt=now-(S.lastUpdateTick or now)
    if dt<=0 or dt>0.5 then dt=1/60 end
    S.lastUpdateTick=now
    updateMoveState(now)
    applyAnchor(now)

    if now-S.lastTick>=1 then
        local el=now-S.lastTick
        S.actual=math.floor(S.fired/el)S.fired=0 S.lastTick=now
        if S.actual>S.sessionBest then S.sessionBest=S.actual end
        table.insert(S.rateHistory,S.actual)
        if #S.rateHistory>40 then table.remove(S.rateHistory,1)end
        if S.antiDelay and S.running and S.eff>500 then
            local ratio=S.actual/S.eff
            if ratio>=1.1 then
                opTriggerBoost(1.5)
                if S.opMode.maxObserved<S.actual then S.opMode.maxObserved=S.actual end
            end
        end
    end
    if S.antiDelay and S.running and S.opMode.warmUntil==0 then
        S.opMode.warmUntil=now+1.5 S.opMode.boostUntil=now+1.5
    end
    if not S.running and S.antiDelay then
        S.opMode.warmUntil=0 S.opMode.boostUntil=0 S.opMode.intervalSamples={}
    end
    if S.ramp and S.running and not S.turbo and not S.antiDelay then
        local el=now-(S.rampStart or now)
        if el<2 then S.rMult=0.3+el/2*0.7 else S.rMult=1 end
    else
        S.rMult=1
        if S.antiDelay and opBoostActive() and not opWarmActive() then S.rMult=1.5 end
    end
    if S.burstWin and S.running then
        if now>=S.burstNext then
            if S.burstPhase=="on"then S.burstPhase="off"S.burstNext=now+S.burstOff
            else S.burstPhase="on"S.burstNext=now+S.burstOn end
        end
    else S.burstPhase="on"end
    if S.actualPattern=="ULTRA" and now-S.ultraRotTick>=1 then
        S.ultraRotTick=now
        if aCnt>1 then S.ultraCur=S.ultraCur+1 if S.ultraCur>aCnt then S.ultraCur=1 end end
    end
    if S.hitbox.en then
        S.hitbox.acc=S.hitbox.acc+dt
        if S.hitbox.acc>=0.15 then S.hitbox.acc=0 pcall(hbRefresh)end
    end
    if S.killSw and S.running and not S.turbo and S.eff>200 and not S.antiDelay then
        if S.actual<S.eff*0.3 then
            S.lowStreak=S.lowStreak+1
            if S.lowStreak>=5 then
                S.running=false S.lowStreak=0
                if S.ui.toggle then
                    S.ui.toggle.Text="▶   ENGAGE"S.ui.toggle.BackgroundColor3=Color3.fromRGB(255,40,40)
                    S.ui.toggle.TextColor3=Color3.fromRGB(0,0,0)
                end
            end
        else S.lowStreak=0 end
    end
    local spikeBlocked=S.spikeGuard and now<S.spikeUntil
    if S.running and S.dmgCnt>0 and (S.burstPhase=="on") and not spikeBlocked then
        local r=S.eff*S.rMult
        local movePenalty=1.0
        if S.moveSync and S.moveState.moving and not S.anchorMode then movePenalty=0.6 end
        r=r*movePenalty
        local pf=r*dt+S.carry
        local tf=math.floor(pf)
        S.carry=pf-tf
        if S.instantFire and S.needsInstantFire then
            tf=math.max(tf,math.min(S.maxFires,math.floor(S.eff*0.05)))S.needsInstantFire=false
        end
        if S.moveSync and S.moveState.moving and not S.anchorMode then
            local mcap=math.max(30,math.floor(S.eff*0.02))if tf>mcap then tf=mcap end
        end
        if tf>0 then
            local cap
            if S.antiDelay and opBoostActive()then cap=10000
            elseif S.antiDelay then cap=5000
            else cap=S.antiFrz and S.maxFires or (S.turbo and math.clamp(math.floor(S.fps*S.turboMult),300,10000) or (S.net and 5000 or 1000))end
            S.cap=cap
            if tf>cap then tf=cap end
            prefilter()
            pickPattern()
            local f=0 local t0=tick()
            if aCnt>0 then
                local pt=S.actualPattern
                if pt=="ULTRA" then
                    if S.ultraCur>aCnt then S.ultraCur=1 end
                    f=fireOne(aR[S.ultraCur],tf)
                    S.ultraCur=S.ultraCur+1
                elseif pt=="WEIGHTED" then
                    if aTot>0 then
                        for i=1,aCnt do
                            local c=math.floor(tf*aW[i]/aTot)if c<1 then c=1 end
                            f=f+fireOne(aR[i],c)
                        end
                    end
                else
                    for i=1,tf do f=f+fireOne(aR[math.random(1,aCnt)],1)end
                end
            end
            S.fired=S.fired+f S.total=S.total+f
            local elapsed=tick()-t0
            if elapsed>0 then opRecordInterval(elapsed)end
        end
    end

    S.acc=S.acc+dt
    if S.acc<0.4 or not S.ui.actual then return end
    S.acc=0
    local function sT(l,t)
        if l.Text~=t then
            l.Text=t
            l.TextTransparency=0.4
            TS:Create(l,TweenInfo.new(0.25),{TextTransparency=0}):Play()
        end
    end
    local function sC(l,c)if l.TextColor3~=c then l.TextColor3=c end end
    sT(S.ui.actual,tostring(S.actual))
    sT(S.ui.tot,tostring(S.total))
    sT(S.ui.eff,tostring(S.eff))
    sT(S.ui.dmg,S.onlyDmg and tostring(S.dmgCnt)or tostring(S.cnt))
    sT(S.ui.prem,tostring(S.findStats.premium))
    sT(S.ui.fps,string.format("%d FPS",math.floor(S.fps)))
    sC(S.ui.fps,S.fps>=45 and Color3.fromRGB(80,220,120)or S.fps>=25 and Color3.fromRGB(255,190,60)or Color3.fromRGB(255,60,60))
    if S.ui.ping then
        sT(S.ui.ping,string.format("%dms",math.floor(S.ping)))
        sC(S.ui.ping,S.ping<100 and Color3.fromRGB(80,220,120)or S.ping<200 and Color3.fromRGB(255,190,60)or Color3.fromRGB(255,60,60))
    end
    if S.ui.packet then sT(S.ui.packet,string.format("%.0fKB",S.packetKB))end
    if S.ui.session then
        local up=math.floor(now-S.startTime)
        sT(S.ui.session,string.format("%02d:%02d:%02d",math.floor(up/3600),math.floor(up%3600/60),up%60))
    end
    if S.ui.throttle then
        local parts={}
        if S.noLag then
            table.insert(parts,"🚀NO-LAG")
            if S.anchorMode and S.moveState.moving then table.insert(parts,"📌")
            elseif S.moveState.moving then table.insert(parts,"🚶")end
            if opBoostActive()then table.insert(parts,"BOOST")
            elseif opWarmActive()then table.insert(parts,"WARM")end
        else
            if S.anchorMode and S.moveState.moving then table.insert(parts,"📌ANCHOR")
            elseif S.moveSync and S.moveState.moving then table.insert(parts,"🚶SYNC")end
            if S.antiDelay then
                if opWarmActive()then table.insert(parts,"⚡OP WARM")
                elseif opBoostActive()then table.insert(parts,"⚡OP BOOST")
                else table.insert(parts,"⚡OP READY")end
            end
            if spikeBlocked then table.insert(parts,"🛡SPIKE")
            elseif not S.antiDelay then
                if S.frozen then table.insert(parts,"NET FREEZE")
                elseif S.turbo then table.insert(parts,string.format("TURBO %dx",S.turboMult))
                elseif S.reason=="ok"or S.reason=="PING+"then table.insert(parts,"OPTIMAL "..S.actualPattern)
                else table.insert(parts,"THROTTLED "..S.reason)end
            end
            if S.pingComp then table.insert(parts,"PING+")end
            if S.instantFire then table.insert(parts,"INST")end
            if S.premiumOnly then table.insert(parts,"💎PREM")end
            if S.burstWin and S.burstPhase=="on"then table.insert(parts,"●")end
            if S.profileActive then table.insert(parts,"P"..S.profileActive)end
        end
        sT(S.ui.throttle,table.concat(parts," "))
        local thCol=(S.noLag and(S.anchorMode and S.moveState.moving and Color3.fromRGB(255,180,60)or Color3.fromRGB(255,60,60)))
            or (S.anchorMode and S.moveState.moving)and Color3.fromRGB(255,180,60)
            or S.antiDelay and(opWarmActive()and Color3.fromRGB(255,200,60)or opBoostActive()and Color3.fromRGB(255,120,60)or Color3.fromRGB(255,60,60))
            or S.moveSync and S.moveState.moving and Color3.fromRGB(60,180,255)
            or spikeBlocked and Color3.fromRGB(60,180,255)
            or S.frozen and Color3.fromRGB(255,60,60)
            or (S.reason=="ok"or S.reason=="PING+")and Color3.fromRGB(80,220,120)
            or Color3.fromRGB(255,190,60)
        sC(S.ui.throttle,thCol)
    end
    if S.ui.hbSize then sT(S.ui.hbSize,tostring(S.hitbox.size))end
    if S.ui.hbStat then
        if S.hitbox.en then
            if S.hitbox.all then sT(S.ui.hbStat,"ALL "..S.hitbox.lastCount)sC(S.ui.hbStat,Color3.fromRGB(80,220,120))
            elseif S.hitbox.target then sT(S.ui.hbStat,S.hitbox.target.Name)sC(S.ui.hbStat,Color3.fromRGB(80,220,120))
            else sT(S.ui.hbStat,"SEARCH...")sC(S.ui.hbStat,Color3.fromRGB(255,190,60))end
        else sT(S.ui.hbStat,"DISABLED")sC(S.ui.hbStat,Color3.fromRGB(120,60,60))end
    end
    if S.ui.tInfo then
        if S.hitbox.en and S.hitbox.target then
            sT(S.ui.tInfo,string.format("%s %d/%d HP %dst",S.hitbox.target.Name,S.hitbox.hp,S.hitbox.maxHp,S.hitbox.dist))
        else sT(S.ui.tInfo,"NO TARGET")end
    end
    if S.ui.bestLbl then sT(S.ui.bestLbl,string.format("🏆 best %d/s",S.sessionBest))end
    if S.ui.pulseDot then
        if S.running then
            local p=(math.sin(S.pulsePhase*2)+1)/2
            local sz=6+p*4
            S.ui.pulseDot.Size=UDim2.new(0,sz,0,sz)
            S.ui.pulseDot.Position=UDim2.new(1,-64-sz/2,0.5,-sz/2)
            if S.frozen or spikeBlocked then S.ui.pulseDot.BackgroundColor3=Color3.fromRGB(255,60,60)
            elseif S.total~=S.lastFiredTotal then S.ui.pulseDot.BackgroundColor3=Color3.fromRGB(80,255,120)
            else S.ui.pulseDot.BackgroundColor3=Color3.fromRGB(255,190,60)end
        else
            S.ui.pulseDot.Size=UDim2.new(0,8,0,8)
            S.ui.pulseDot.Position=UDim2.new(1,-60,0.5,-4)
            S.ui.pulseDot.BackgroundColor3=Color3.fromRGB(120,60,60)
        end
        S.lastFiredTotal=S.total
    end
    -- ═══ SPARKLINE ═══
    if S.ui.spark and #S.rateHistory>1 then
        local bars=S.ui.spark:GetChildren()
        local maxRate=math.max(1,S.sessionBest,S.eff)
        local n=#S.rateHistory
        local show=math.min(30,n)
        for i=1,30 do
            local bar=S.ui.spark:FindFirstChild("s"..i)
            if bar then
                if i<=show then
                    local val=S.rateHistory[n-show+i]
                    local h=math.clamp(val/maxRate,0.02,1)
                    bar.Size=UDim2.new(0,3,h,0)
                    bar.Visible=true
                    if val>=S.eff*0.9 then bar.BackgroundColor3=Color3.fromRGB(80,220,120)
                    elseif val>=S.eff*0.5 then bar.BackgroundColor3=Color3.fromRGB(255,190,60)
                    else bar.BackgroundColor3=Color3.fromRGB(255,60,60)end
                else
                    bar.Visible=false
                end
            end
        end
    end
    if S.ui.log then
        local t=""
        if S.noLag then t="🚀 NO-LAG: ALL FIXES ON\n"end
        if S.premiumOnly then t="💎 PREMIUM-ONLY MODE\n"end
        t=t..string.format("📡 %d rem • %d prem • %d dmg\n",S.findStats.total,S.findStats.premium,S.findStats.damage)
        if S.hotRemote then
            local nm="?"
            pcall(function()nm=S.hotRemote.Name end)
            local ct=S.fireCount[S.hotRemote]or 0
            t=t.."🔥 HOT:"..nm.." ("..ct..")\n"
        end
        for i=#S.log,math.max(1,#S.log-2),-1 do t=t..">"..S.log[i].."\n"end
        sT(S.ui.log,t)
    end
end
RunService.Heartbeat:Connect(update)
RunService.RenderStepped:Connect(function()
    S.fpsFrames=S.fpsFrames+1
    local n=tick()
    if n-S.fpsTick>=1 then S.fps=S.fpsFrames/(n-S.fpsTick)S.fpsFrames=0 S.fpsTick=n end
end)

local function captureProfile()
    return{rate=S.rate,pattern=S.autoPattern,turbo=S.turbo,turboMult=S.turboMult,
        burstWin=S.burstWin,antiFrz=S.antiFrz,maxFires=S.maxFires,
        onlyDmg=S.onlyDmg,conc=S.conc,weight=S.weight,throt=S.throt,net=S.net,
        killSw=S.killSw,adaptive=S.adaptive,failTrk=S.failTrk,health=S.health,
        noLag=S.noLag,premiumOnly=S.premiumOnly,autoRescanOnEquip=S.autoRescanOnEquip,
        hbEn=S.hitbox.en,hbInvis=S.hitbox.invis,hbAll=S.hitbox.all,hbSize=S.hitbox.size}
end
local function applyProfile(p)
    if not p then return end
    for k,v in pairs(p)do
        if k=="hbEn"then S.hitbox.en=v
        elseif k=="hbInvis"then S.hitbox.invis=v
        elseif k=="hbAll"then S.hitbox.all=v
        elseif k=="hbSize"then S.hitbox.size=v
        elseif k=="pattern"then S.autoPattern=v
        else S[k]=v end
    end
    if p.noLag~=nil then S.noLag=p.noLag applyNoLag()end
    save()
    if S.ui.refreshAll then pcall(S.ui.refreshAll)end
end

local function buildReport()
    local lines={"═══ VERTEX CANNON REPORT ═══"}
    table.insert(lines,string.format("Total remotes: %d",S.findStats.total))
    table.insert(lines,string.format("Premium: %d",S.findStats.premium))
    table.insert(lines,string.format("Damage: %d",S.findStats.damage))
    table.insert(lines,string.format("Peak rate: %d/s",S.sessionBest))
    table.insert(lines,"")
    for _,cat in ipairs(PREM_CATS)do
        local l=S.prem[cat.key]
        if l and #l>0 then
            table.insert(lines,string.format("[%s]",cat.label))
            for _,e in ipairs(l)do
                table.insert(lines,"  • "..e.parent.." › "..e.path)
            end
        end
    end
    return table.concat(lines,"\n")
end

UIS.InputBegan:Connect(function(inp,gp)
    if gp or not S.keybd then return end
    if inp.KeyCode==Enum.KeyCode.RightShift then
        S.running=not S.running S.carry=0
        if S.running then
            S.rampStart=tick()S.needsInstantFire=true
            if S.antiDelay then
                S.opMode.warmUntil=tick()+1.5 S.opMode.boostUntil=tick()+1.5
                S.opMode.intervalSamples={}S.opMode.maxObserved=0
            end
        else
            S.opMode.warmUntil=0 S.opMode.boostUntil=0 S.anchorPos=nil
        end
        click(1.1)
        toast(S.running and "ENGAGED"or "DISENGAGED",S.running and Color3.fromRGB(80,220,120)or Color3.fromRGB(255,60,60),S.running and"▶ "or"■ ")
        if S.ui.toggle then
            if S.running then S.ui.toggle.Text="■ DISENGAGE"S.ui.toggle.BackgroundColor3=Color3.fromRGB(20,11,11)
            S.ui.toggle.TextColor3=Color3.fromRGB(255,40,40)
            else S.ui.toggle.Text="▶ ENGAGE"S.ui.toggle.BackgroundColor3=Color3.fromRGB(255,40,40)
            S.ui.toggle.TextColor3=Color3.fromRGB(0,0,0)end
        end
    end
    if inp.KeyCode==Enum.KeyCode.Tab then
        S.hitbox.en=not S.hitbox.en
        if not S.hitbox.en then hbClear()end
        S.hitbox.acc=999
        click(1.05)
        toast(S.hitbox.en and "Hitbox ON"or "Hitbox OFF",S.hitbox.en and Color3.fromRGB(80,220,120)or Color3.fromRGB(255,60,60),"🎯 ")
    end
    if inp.KeyCode==Enum.KeyCode.Zero then
        local seq={"AUTO","ULTRA","WEIGHTED","RANDOM"}
        local idx=1
        for i,v in ipairs(seq)do if v==S.autoPattern then idx=i break end end
        idx=(idx%#seq)+1
        S.autoPattern=seq[idx]save()
        click(1.1)
        toast("Pattern → "..S.autoPattern,Color3.fromRGB(180,90,255),"🔀 ")
        if S.ui.setPattern then pcall(S.ui.setPattern,S.autoPattern)end
    end
    if inp.KeyCode==Enum.KeyCode.G then
        S.noLag=not S.noLag applyNoLag()save()
        click(1.15)
        toast(S.noLag and"NO-LAG ON"or"NO-LAG OFF",S.noLag and Color3.fromRGB(255,60,60)or Color3.fromRGB(110,70,70),"🚀 ")
        if S.ui.refreshAll then pcall(S.ui.refreshAll)end
    end
    if inp.KeyCode==Enum.KeyCode.F then
        S.scanAnimUntil=tick()+0.5
        rebuild(false)
    end
    if inp.KeyCode==Enum.KeyCode.H then
        S.premiumOnly=not S.premiumOnly save()
        click(1.15)
        toast(S.premiumOnly and"PREM-ONLY ON"or"PREM-ONLY OFF",
            S.premiumOnly and Color3.fromRGB(180,90,255)or Color3.fromRGB(110,70,70),"💎 ")
        if S.ui.refreshAll then pcall(S.ui.refreshAll)end
    end
    if inp.KeyCode==Enum.KeyCode.C then
        local rep=buildReport()S.lastReport=rep
        if setclipboard then
            pcall(function()setclipboard(rep)end)
            toast("Report copied",Color3.fromRGB(80,220,120),"📋 ")
        else
            print(rep)toast("Report in console",Color3.fromRGB(255,190,60),"📋 ")
        end
    end
end)

local T={BG=Color3.fromRGB(10,6,6),P=Color3.fromRGB(20,11,11),C=Color3.fromRGB(28,14,14),
C2=Color3.fromRGB(38,18,18),SK=Color3.fromRGB(60,24,24),R=Color3.fromRGB(255,40,40),
RD=Color3.fromRGB(140,20,20),RG=Color3.fromRGB(255,80,80),G=Color3.fromRGB(80,220,120),
Y=Color3.fromRGB(255,190,60),PU=Color3.fromRGB(180,90,255),PD=Color3.fromRGB(80,40,120),
TX=Color3.fromRGB(245,235,235),D=Color3.fromRGB(160,120,120),M=Color3.fromRGB(110,70,70),B=Color3.fromRGB(0,0,0)}

local function mkBr(p,c,t)
    local s=Instance.new("UIStroke")s.Color=c or T.SK s.Thickness=t or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s
end

local function buildUI()
    local pg=lp:WaitForChild("PlayerGui",10)if not pg then return end
    if pg:FindFirstChild("CUI")then pg.CUI:Destroy()end
    local g=Instance.new("ScreenGui")g.Name="CUI"g.ResetOnSpawn=false g.IgnoreGuiInset=true g.Parent=pg
    local W,H=700,570
    local box=Instance.new("Frame")
    box.Size=UDim2.new(0,W,0,H)
    box.AnchorPoint=Vector2.new(0.5,0.5)
    box.Position=UDim2.fromScale(0.5,0.5)
    box.BackgroundColor3=T.BG box.BackgroundTransparency=1 box.BorderSizePixel=0 box.Parent=g

    -- ═══ RESPONSIVE UI SCALING ═══
    -- Automatically shrink/grow the entire interface so it fits phones,
    -- tablets and PC screens. The smaller screen dimension controls the scale.
    local uiScale=Instance.new("UIScale")
    uiScale.Name="ResponsiveScale"
    uiScale.Parent=box
    S.ui.scale=uiScale

    local function updateUIScale()
        local cam=workspace.CurrentCamera
        if not cam then return end
        local vp=cam.ViewportSize
        local margin=12
        local availableX=math.max(1,vp.X-margin*2)
        local availableY=math.max(1,vp.Y-margin*2)
        local scale=math.min(availableX/W,availableY/H)

        -- Keep the UI readable while still allowing very small screens to fit.
        scale=math.clamp(scale,0.35,1.15)
        uiScale.Scale=scale
        box.Position=UDim2.fromScale(0.5,0.5)
    end

    local function connectViewportWatcher()
        local cam=workspace.CurrentCamera
        if not cam then return end
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)
        updateUIScale()
    end

    connectViewportWatcher()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(connectViewportWatcher)
    end)

    Instance.new("UICorner",box).CornerRadius=UDim.new(0,14)
    mkBr(box,T.RD,1.5)
    TS:Create(box,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
    local hd=Instance.new("Frame")
    hd.Size=UDim2.new(1,0,0,42)hd.BackgroundColor3=T.P hd.BorderSizePixel=0 hd.Parent=box
    Instance.new("UICorner",hd).CornerRadius=UDim.new(0,14)
    local accent=Instance.new("Frame")
    accent.Size=UDim2.new(1,-30,0,2)accent.Position=UDim2.new(0,15,0,0)
    accent.BackgroundColor3=T.R accent.BorderSizePixel=0 accent.ZIndex=5
    accent.Parent=box
    Instance.new("UICorner",accent).CornerRadius=UDim.new(1,0)
    S.ui.accentBar=accent
    local lg=Instance.new("TextLabel")
    lg.Size=UDim2.new(0,26,1,0)lg.Position=UDim2.new(0,12,0,0)
    lg.BackgroundTransparency=1 lg.Text="▲"lg.TextColor3=T.R lg.TextSize=14
    lg.Font=Enum.Font.GothamBold lg.Parent=hd
    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(0,300,1,0)tl.Position=UDim2.new(0,44,0,0)
    tl.BackgroundTransparency=1 tl.Text="VERTEX CANNON • v32.0"tl.TextColor3=T.TX
    tl.TextSize=12 tl.Font=Enum.Font.GothamBold tl.TextXAlignment=Enum.TextXAlignment.Left tl.Parent=hd
    local fpsL=Instance.new("TextLabel")
    fpsL.Size=UDim2.new(0,60,0,22)fpsL.Position=UDim2.new(1,-296,0.5,-11)
    fpsL.BackgroundColor3=T.C fpsL.Text="60 FPS"fpsL.TextColor3=T.G fpsL.TextSize=9
    fpsL.Font=Enum.Font.GothamBold fpsL.Parent=hd
    Instance.new("UICorner",fpsL).CornerRadius=UDim.new(1,0)
    local pingL=Instance.new("TextLabel")
    pingL.Size=UDim2.new(0,70,0,22)pingL.Position=UDim2.new(1,-234,0.5,-11)
    pingL.BackgroundColor3=T.C pingL.Text="0ms"pingL.TextColor3=T.G pingL.TextSize=9
    pingL.Font=Enum.Font.GothamBold pingL.Parent=hd
    Instance.new("UICorner",pingL).CornerRadius=UDim.new(1,0)
    local pktL=Instance.new("TextLabel")
    pktL.Size=UDim2.new(0,60,0,22)pktL.Position=UDim2.new(1,-162,0.5,-11)
    pktL.BackgroundColor3=T.C pktL.Text="0KB"pktL.TextColor3=T.G pktL.TextSize=9
    pktL.Font=Enum.Font.GothamBold pktL.Parent=hd
    Instance.new("UICorner",pktL).CornerRadius=UDim.new(1,0)
    local sesL=Instance.new("TextLabel")
    sesL.Size=UDim2.new(0,60,0,22)sesL.Position=UDim2.new(1,-100,0.5,-11)
    sesL.BackgroundColor3=T.C sesL.Text="00:00"sesL.TextColor3=T.D sesL.TextSize=9
    sesL.Font=Enum.Font.GothamBold sesL.Parent=hd
    Instance.new("UICorner",sesL).CornerRadius=UDim.new(1,0)
    local pulseDot=Instance.new("Frame")
    pulseDot.Size=UDim2.new(0,8,0,8)pulseDot.Position=UDim2.new(1,-60,0.5,-4)
    pulseDot.BackgroundColor3=Color3.fromRGB(120,60,60)pulseDot.BorderSizePixel=0
    pulseDot.Parent=hd
    Instance.new("UICorner",pulseDot).CornerRadius=UDim.new(1,0)
    S.ui.pulseDot=pulseDot
    local minB=Instance.new("TextButton")
    minB.Size=UDim2.new(0,22,0,22)minB.Position=UDim2.new(1,-34,0.5,-11)
    minB.BackgroundColor3=T.C minB.Text="▢"minB.TextColor3=T.TX minB.TextSize=12
    minB.Font=Enum.Font.GothamBold minB.AutoButtonColor=false minB.Parent=hd
    Instance.new("UICorner",minB).CornerRadius=UDim.new(0,5)
    attachRipple(minB)
    local clB=Instance.new("TextButton")
    clB.Size=UDim2.new(0,22,0,22)clB.Position=UDim2.new(1,-8,0.5,-11)
    clB.BackgroundColor3=T.C clB.Text="✕"clB.TextColor3=T.R clB.TextSize=12
    clB.Font=Enum.Font.GothamBold clB.AutoButtonColor=false clB.Parent=hd
    Instance.new("UICorner",clB).CornerRadius=UDim.new(0,5)
    attachRipple(clB)
    clB.Activated:Connect(function()hbClear()g:Destroy()end)

    local ct=Instance.new("Frame")
    ct.Size=UDim2.new(1,0,1,-42)ct.Position=UDim2.new(0,0,0,42)
    ct.BackgroundTransparency=1 ct.Parent=box
    local minimized=false
    minB.Activated:Connect(function()
        minimized=not minimized
        ct.Visible=not minimized
        box.Size=minimized and UDim2.new(0,W,0,42)or UDim2.new(0,W,0,H)
        minB.Text=minimized and"▣"or"▢"
    end)

    local L=Instance.new("Frame")
    L.Size=UDim2.new(0,200,1,-20)L.Position=UDim2.new(0,10,0,10)
    L.BackgroundTransparency=1 L.Parent=ct
    local tp=Instance.new("Frame")
    tp.Size=UDim2.new(1,0,0,70)tp.BackgroundColor3=T.P tp.BorderSizePixel=0 tp.Parent=L
    Instance.new("UICorner",tp).CornerRadius=UDim.new(0,8)
    mkBr(tp,T.RD,1)
    local tT=Instance.new("TextLabel")
    tT.Size=UDim2.new(0.5,0,0,10)tT.Position=UDim2.new(0,0,0,8)
    tT.BackgroundTransparency=1 tT.Text="TARGET"tT.TextColor3=T.M tT.TextSize=8
    tT.Font=Enum.Font.GothamBold tT.Parent=tp
    local tL=Instance.new("TextLabel")
    tL.Size=UDim2.new(0.5,0,0,26)tL.Position=UDim2.new(0,0,0,20)
    tL.BackgroundTransparency=1 tL.Text="1500"tL.TextColor3=T.R tL.TextSize=22
    tL.Font=Enum.Font.GothamBold tL.Parent=tp
    local aT=Instance.new("TextLabel")
    aT.Size=UDim2.new(0.5,0,0,10)aT.Position=UDim2.new(0.5,0,0,8)
    aT.BackgroundTransparency=1 aT.Text="ACTUAL"aT.TextColor3=T.M aT.TextSize=8
    aT.Font=Enum.Font.GothamBold aT.Parent=tp
    local aL=Instance.new("TextLabel")
    aL.Size=UDim2.new(0.5,0,0,26)aL.Position=UDim2.new(0.5,0,0,20)
    aL.BackgroundTransparency=1 aL.Text="0"aL.TextColor3=T.RG aL.TextSize=22
    aL.Font=Enum.Font.GothamBold aL.Parent=tp

    -- ═══ SPARKLINE ═══
    local spark=Instance.new("Frame")
    spark.Size=UDim2.new(1,0,0,28)spark.Position=UDim2.new(0,0,0,78)
    spark.BackgroundColor3=T.P spark.BorderSizePixel=0 spark.Parent=L
    Instance.new("UICorner",spark).CornerRadius=UDim.new(0,6)
    mkBr(spark,T.SK,1)
    for i=1,30 do
        local bar=Instance.new("Frame")
        bar.Name="s"..i
        bar.Size=UDim2.new(0,3,0.02,0)bar.Position=UDim2.new(0,2+(i-1)*6.5,1,-2)
        bar.AnchorPoint=Vector2.new(0,1)
        bar.BackgroundColor3=T.G bar.BorderSizePixel=0 bar.Visible=false bar.Parent=spark
        Instance.new("UICorner",bar).CornerRadius=UDim.new(0,1)
    end
    S.ui.spark=spark

    local qr=Instance.new("Frame")
    qr.Size=UDim2.new(1,0,0,30)qr.Position=UDim2.new(0,0,0,112)
    qr.BackgroundColor3=T.P qr.BorderSizePixel=0 qr.Parent=L
    Instance.new("UICorner",qr).CornerRadius=UDim.new(0,6)
    mkBr(qr,T.SK,1)
    local function qc(x,lb)
        local f=Instance.new("Frame")f.Size=UDim2.new(0.25,0,1,0)f.Position=UDim2.new(x,0,0,0)
        f.BackgroundTransparency=1 f.Parent=qr
        local l=Instance.new("TextLabel")
        l.Size=UDim2.new(1,0,0,10)l.Position=UDim2.new(0,0,0,3)
        l.BackgroundTransparency=1 l.Text=lb l.TextColor3=T.M l.TextSize=7
        l.Font=Enum.Font.GothamBold l.Parent=f
        local v=Instance.new("TextLabel")
        v.Size=UDim2.new(1,0,0,14)v.Position=UDim2.new(0,0,0,13)
        v.BackgroundTransparency=1 v.Text="0"v.TextColor3=T.TX v.TextSize=11
        v.Font=Enum.Font.GothamBold v.Parent=f
        return v
    end
    local effL=qc(0,"EFF")local dmgL=qc(0.25,"DMG")local prL=qc(0.5,"PREM")local totL=qc(0.75,"TOT")
    effL.TextColor3=T.RG prL.TextColor3=T.PU totL.TextColor3=T.Y

    local thL=Instance.new("TextLabel")
    thL.Size=UDim2.new(1,0,0,12)thL.Position=UDim2.new(0,4,0,150)
    thL.BackgroundTransparency=1 thL.Text="OPTIMAL"thL.TextColor3=T.G thL.TextSize=9
    thL.Font=Enum.Font.GothamBold thL.TextXAlignment=Enum.TextXAlignment.Left thL.Parent=L

    local bestL=Instance.new("TextLabel")
    bestL.Size=UDim2.new(1,0,0,12)bestL.Position=UDim2.new(0,4,0,166)
    bestL.BackgroundTransparency=1 bestL.Text="🏆 best 0/s"bestL.TextColor3=T.Y bestL.TextSize=9
    bestL.Font=Enum.Font.GothamBold bestL.TextXAlignment=Enum.TextXAlignment.Left bestL.Parent=L

    local logBg=Instance.new("Frame")
    logBg.Size=UDim2.new(1,0,1,-196)logBg.Position=UDim2.new(0,0,0,188)
    logBg.BackgroundColor3=T.P logBg.BorderSizePixel=0 logBg.Parent=L
    Instance.new("UICorner",logBg).CornerRadius=UDim.new(0,6)
    mkBr(logBg,T.SK,1)
    local logL=Instance.new("TextLabel")
    logL.Size=UDim2.new(1,-12,1,-8)logL.Position=UDim2.new(0,6,0,4)
    logL.BackgroundTransparency=1 logL.Text=""logL.TextColor3=T.D logL.TextSize=8
    logL.Font=Enum.Font.GothamMedium logL.TextXAlignment=Enum.TextXAlignment.Left
    logL.TextYAlignment=Enum.TextYAlignment.Top logL.TextWrapped=true logL.Parent=logBg

    local M=Instance.new("Frame")
    M.Size=UDim2.new(0,240,1,-20)M.Position=UDim2.new(0,218,0,10)
    M.BackgroundColor3=T.P M.BorderSizePixel=0 M.Parent=ct
    Instance.new("UICorner",M).CornerRadius=UDim.new(0,8)
    mkBr(M,T.RD,1)
    local tabs=Instance.new("Frame")
    tabs.Size=UDim2.new(1,-12,0,20)tabs.Position=UDim2.new(0,6,0,6)
    tabs.BackgroundTransparency=1 tabs.Parent=M
    local tabGlow=Instance.new("Frame")
    tabGlow.Size=UDim2.new(0.5,-2,0,2)tabGlow.Position=UDim2.new(0,0,0,20)
    tabGlow.BackgroundColor3=T.R tabGlow.BorderSizePixel=0
    tabGlow.BackgroundTransparency=0.4
    tabGlow.ZIndex=3
    tabGlow.Parent=tabs
    S.ui.tabGlow=tabGlow
    local pages,bts={},{}
    local function sel(n)
        for k,p in pairs(pages)do p.Visible=(k==n)end
        for k,b in pairs(bts)do if k==n then b.BackgroundColor3=T.R b.TextColor3=T.B
        else b.BackgroundColor3=T.C b.TextColor3=T.D end end
        local idx=(n=="PREMIUM")and 0 or 1
        TS:Create(tabGlow,TweenInfo.new(0.25,Enum.EasingStyle.Quart),{
            Position=UDim2.new(idx*0.5,idx*1.5,0,20)}):Play()
    end
    S.ui.selTab=sel
    for i,n in ipairs({"PREMIUM","PLAYERS"})do
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1/2,-2,1,0)b.Position=UDim2.new((i-1)/2,(i-1)*1.5,0,0)
        b.BackgroundColor3=(i==1)and T.R or T.C
        b.Text=n b.TextColor3=(i==1)and T.B or T.D
        b.TextSize=9 b.Font=Enum.Font.GothamBold b.AutoButtonColor=false b.Parent=tabs
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        mkBr(b,T.SK,1)
        attachRipple(b)
        bts[n]=b
        b.Activated:Connect(function()click(1.05)sel(n)end)
    end
    local pPg=Instance.new("Frame")
    pPg.Size=UDim2.new(1,-12,1,-32)pPg.Position=UDim2.new(0,6,0,28)
    pPg.BackgroundTransparency=1 pPg.Parent=M
    pages.PREMIUM=pPg
    local pScr=Instance.new("ScrollingFrame")
    pScr.Size=UDim2.new(1,0,1,0)pScr.BackgroundTransparency=1
    pScr.BorderSizePixel=0 pScr.ScrollBarThickness=3 pScr.ScrollBarImageColor3=T.PU
    pScr.CanvasSize=UDim2.new(0,0,0,0)pScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
    pScr.Parent=pPg
    local pBtns={}
    local function refPrem()
        for _,b in ipairs(pBtns)do b:Destroy()end pBtns={}
        local y=0
        local tot=0
        for _,l in pairs(S.prem)do tot=tot+#l end
        local hStat=Instance.new("TextLabel")
        hStat.Size=UDim2.new(1,-10,0,26)hStat.Position=UDim2.new(0,5,0,0)
        hStat.BackgroundColor3=T.C2
        hStat.Text=string.format("📡 %d rem • %d prem • %d dmg",S.findStats.total,S.findStats.premium,S.findStats.damage)
        hStat.TextColor3=T.PU hStat.TextSize=8 hStat.Font=Enum.Font.GothamBold
        hStat.TextXAlignment=Enum.TextXAlignment.Left hStat.Parent=pScr
        Instance.new("UICorner",hStat).CornerRadius=UDim.new(0,4)
        pBtns[#pBtns+1]=hStat y=y+30
        if tot==0 then
            local e=Instance.new("TextLabel")
            e.Size=UDim2.new(1,-10,0,60)e.Position=UDim2.new(0,5,0,y)
            e.BackgroundTransparency=1
            e.Text="No premium remotes yet.\nEquip tool + press F to rescan."
            e.TextColor3=T.M e.TextSize=9 e.Font=Enum.Font.GothamMedium
            e.TextWrapped=true e.TextYAlignment=Enum.TextYAlignment.Top e.Parent=pScr
            pBtns[1]=e return
        end
        for _,cat in ipairs(PREM_CATS)do
            local l=S.prem[cat.key]
            if l and #l>0 then
                local catOn=S.categoryEnabled[cat.key]~=false
                local chdr=Instance.new("Frame")
                chdr.Size=UDim2.new(1,-10,0,16)chdr.Position=UDim2.new(0,5,0,y)
                chdr.BackgroundTransparency=1 chdr.Parent=pScr
                local cl=Instance.new("TextLabel")
                cl.Size=UDim2.new(1,-40,1,0)cl.Position=UDim2.new(0,0,0,0)
                cl.BackgroundTransparency=1 cl.Text="▸ "..cat.label.." ("..#l..")"
                cl.TextColor3=catOn and cat.tint or T.M cl.TextSize=9 cl.Font=Enum.Font.GothamBold
                cl.TextXAlignment=Enum.TextXAlignment.Left cl.Parent=chdr
                local cbtn=Instance.new("TextButton")
                cbtn.Size=UDim2.new(0,34,1,0)cbtn.Position=UDim2.new(1,-34,0,0)
                cbtn.BackgroundColor3=catOn and cat.tint or T.C
                cbtn.Text=catOn and"ON"or"OFF"
                cbtn.TextColor3=catOn and Color3.fromRGB(255,255,255)or T.D
                cbtn.TextSize=7 cbtn.Font=Enum.Font.GothamBold cbtn.AutoButtonColor=false cbtn.Parent=chdr
                Instance.new("UICorner",cbtn).CornerRadius=UDim.new(0,3)
                local capKey=cat.key
                cbtn.Activated:Connect(function()
                    S.categoryEnabled[capKey]=not(S.categoryEnabled[capKey]~=false)
                    save()click(1.05)refPrem()
                end)
                pBtns[#pBtns+1]=chdr y=y+16
                for _,e in ipairs(l)do
                    local en=enabled(e.r)and catOn
                    local rw=Instance.new("Frame")
                    rw.Size=UDim2.new(1,-10,0,32)rw.Position=UDim2.new(0,5,0,y)
                    rw.BackgroundColor3=en and T.C2 or T.C rw.BorderSizePixel=0 rw.Parent=pScr
                    Instance.new("UICorner",rw).CornerRadius=UDim.new(0,5)
                    local rb=mkBr(rw,en and cat.tint or T.SK,1)
                    local accent=Instance.new("Frame")
                    accent.Size=UDim2.new(0,2,1,-6)accent.Position=UDim2.new(0,2,0,3)
                    accent.BackgroundColor3=en and cat.tint or T.SK
                    accent.BorderSizePixel=0 accent.Parent=rw
                    Instance.new("UICorner",accent).CornerRadius=UDim.new(1,0)
                    local nl=Instance.new("TextLabel")
                    nl.Size=UDim2.new(1,-50,0,12)nl.Position=UDim2.new(0,10,0,3)
                    nl.BackgroundTransparency=1 nl.Text=e.name nl.TextColor3=en and T.TX or T.M
                    nl.TextSize=9 nl.Font=Enum.Font.GothamBold
                    nl.TextXAlignment=Enum.TextXAlignment.Left nl.TextTruncate=Enum.TextTruncate.AtEnd nl.Parent=rw
                    local pl=Instance.new("TextLabel")
                    pl.Size=UDim2.new(1,-50,0,10)pl.Position=UDim2.new(0,10,0,16)
                    pl.BackgroundTransparency=1 pl.Text=(e.parent or"?").." › "..e.path pl.TextColor3=T.M pl.TextSize=6
                    pl.Font=Enum.Font.GothamMedium pl.TextXAlignment=Enum.TextXAlignment.Left
                    pl.TextTruncate=Enum.TextTruncate.AtEnd pl.Parent=rw
                    local sb=Instance.new("TextButton")
                    sb.Size=UDim2.new(0,40,0,20)sb.Position=UDim2.new(1,-44,0.5,-10)
                    sb.BackgroundColor3=en and cat.tint or T.C
                    sb.Text=en and "ON"or "OFF"sb.TextColor3=en and Color3.fromRGB(255,255,255)or T.D
                    sb.TextSize=8 sb.Font=Enum.Font.GothamBold sb.AutoButtonColor=false sb.Parent=rw
                    Instance.new("UICorner",sb).CornerRadius=UDim.new(0,5)
                    attachRipple(sb)
                    local cap=e
                    sb.Activated:Connect(function()
                        local ne=not enabled(cap.r)
                        S.premToggles[cap.r]=ne
                        sb.BackgroundColor3=ne and cat.tint or T.C
                        sb.Text=ne and "ON"or "OFF"
                        sb.TextColor3=ne and Color3.fromRGB(255,255,255)or T.D
                        rb.Color=ne and cat.tint or T.SK
                        accent.BackgroundColor3=ne and cat.tint or T.SK
                        rw.BackgroundColor3=ne and T.C2 or T.C
                        nl.TextColor3=ne and T.TX or T.M
                        save()
                    end)
                    pBtns[#pBtns+1]=rw y=y+36
                end
                y=y+4
            end
        end
        local cpB=Instance.new("TextButton")
        cpB.Size=UDim2.new(1,-10,0,26)cpB.Position=UDim2.new(0,5,0,y+4)
        cpB.BackgroundColor3=T.C2 cpB.Text="📋 COPY REPORT"
        cpB.TextColor3=T.Y cpB.TextSize=9 cpB.Font=Enum.Font.GothamBold
        cpB.AutoButtonColor=false cpB.Parent=pScr
        Instance.new("UICorner",cpB).CornerRadius=UDim.new(0,5)
        mkBr(cpB,T.SK,1)
        attachRipple(cpB)
        cpB.Activated:Connect(function()
            local rep=buildReport()S.lastReport=rep
            if setclipboard then pcall(function()setclipboard(rep)end)toast("Copied!",T.G,"📋 ")
            else print(rep)toast("Report in console",T.Y,"📋 ")end
        end)
        pBtns[#pBtns+1]=cpB
    end
    S.ui.refreshPrem=refPrem
    refPrem()
    local pPg2=Instance.new("Frame")
    pPg2.Size=UDim2.new(1,-12,1,-32)pPg2.Position=UDim2.new(0,6,0,28)
    pPg2.BackgroundTransparency=1 pPg2.Visible=false pPg2.Parent=M
    pages.PLAYERS=pPg2
    local plScr=Instance.new("ScrollingFrame")
    plScr.Size=UDim2.new(1,0,1,0)plScr.BackgroundTransparency=1
    plScr.BorderSizePixel=0 plScr.ScrollBarThickness=3 plScr.ScrollBarImageColor3=T.R
    plScr.CanvasSize=UDim2.new(0,0,0,0)plScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
    plScr.Parent=pPg2
    task.spawn(function()
        while true do
            task.wait(2)
            for _,c in ipairs(plScr:GetChildren())do
                if c:IsA("Frame")then c:Destroy()end
            end
            local y=0
            for _,p in ipairs(P:GetPlayers())do if p~=lp then
                local hm=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                local alive=hm and hm.Health>0
                local hp=hm and math.floor(hm.Health)or 0
                local rw=Instance.new("Frame")
                rw.Size=UDim2.new(1,0,0,24)rw.Position=UDim2.new(0,0,0,y)
                rw.BackgroundColor3=T.C rw.BorderSizePixel=0 rw.Parent=plScr
                Instance.new("UICorner",rw).CornerRadius=UDim.new(0,4)
                local dt=Instance.new("Frame")
                dt.Size=UDim2.new(0,5,0,5)dt.Position=UDim2.new(0,4,0.5,-2.5)
                dt.BackgroundColor3=alive and T.G or T.M dt.BorderSizePixel=0 dt.Parent=rw
                Instance.new("UICorner",dt).CornerRadius=UDim.new(1,0)
                local nl=Instance.new("TextLabel")
                nl.Size=UDim2.new(1,-24,1,0)nl.Position=UDim2.new(0,14,0,0)
                nl.BackgroundTransparency=1 nl.Text=p.Name.." "..hp.."hp"
                nl.TextColor3=alive and T.TX or T.M nl.TextSize=9
                nl.Font=Enum.Font.GothamBold nl.TextXAlignment=Enum.TextXAlignment.Left nl.Parent=rw
                y=y+26
            end end
        end
    end)

    local R=Instance.new("Frame")
    R.Size=UDim2.new(1,-480,1,-20)R.Position=UDim2.new(0,470,0,10)
    R.BackgroundTransparency=1 R.Parent=ct
    local hs=Instance.new("Frame")
    hs.Size=UDim2.new(1,0,0,108)hs.BackgroundColor3=T.P hs.BorderSizePixel=0 hs.Parent=R
    Instance.new("UICorner",hs).CornerRadius=UDim.new(0,8)
    mkBr(hs,T.RD,1)
    local ht=Instance.new("TextLabel")
    ht.Size=UDim2.new(1,-16,0,14)ht.Position=UDim2.new(0,10,0,6)
    ht.BackgroundTransparency=1 ht.Text="▲ HITBOX [TAB]"ht.TextColor3=T.R ht.TextSize=10
    ht.Font=Enum.Font.GothamBold ht.TextXAlignment=Enum.TextXAlignment.Left ht.Parent=hs
    local r1=Instance.new("Frame")
    r1.Size=UDim2.new(1,-20,0,22)r1.Position=UDim2.new(0,10,0,24)
    r1.BackgroundTransparency=1 r1.Parent=hs
    local hbB=Instance.new("TextButton")
    hbB.Size=UDim2.new(0.32,0,1,0)hbB.BackgroundColor3=T.C hbB.Text="HITBOX"
    hbB.TextColor3=T.D hbB.TextSize=9 hbB.Font=Enum.Font.GothamBold hbB.AutoButtonColor=false hbB.Parent=r1
    Instance.new("UICorner",hbB).CornerRadius=UDim.new(0,5)
    mkBr(hbB,T.SK,1)
    attachRipple(hbB)
    local ivB=Instance.new("TextButton")
    ivB.Size=UDim2.new(0.32,0,1,0)ivB.Position=UDim2.new(0.34,0,0,0)
    ivB.BackgroundColor3=T.R ivB.Text="INVIS"ivB.TextColor3=T.B ivB.TextSize=9
    ivB.Font=Enum.Font.GothamBold ivB.AutoButtonColor=false ivB.Parent=r1
    Instance.new("UICorner",ivB).CornerRadius=UDim.new(0,5)
    attachRipple(ivB)
    local alB=Instance.new("TextButton")
    alB.Size=UDim2.new(0.32,0,1,0)alB.Position=UDim2.new(0.68,0,0,0)
    alB.BackgroundColor3=T.C alB.Text="TARGET"alB.TextColor3=T.D alB.TextSize=9
    alB.Font=Enum.Font.GothamBold alB.AutoButtonColor=false alB.Parent=r1
    Instance.new("UICorner",alB).CornerRadius=UDim.new(0,5)
    mkBr(alB,T.SK,1)
    attachRipple(alB)
    local r2=Instance.new("Frame")
    r2.Size=UDim2.new(1,-20,0,22)r2.Position=UDim2.new(0,10,0,50)
    r2.BackgroundTransparency=1 r2.Parent=hs
    local mB=Instance.new("TextButton")
    mB.Size=UDim2.new(0,24,1,0)mB.BackgroundColor3=T.C mB.Text="−"
    mB.TextColor3=T.R mB.TextSize=15 mB.Font=Enum.Font.GothamBold mB.AutoButtonColor=false mB.Parent=r2
    Instance.new("UICorner",mB).CornerRadius=UDim.new(0,5)
    mkBr(mB,T.SK,1)
    attachRipple(mB)
    local szL=Instance.new("TextLabel")
    szL.Size=UDim2.new(0,50,1,0)szL.Position=UDim2.new(0,28,0,0)
    szL.BackgroundColor3=T.C szL.Text="15"szL.TextColor3=T.RG szL.TextSize=11
    szL.Font=Enum.Font.GothamBold szL.Parent=r2
    Instance.new("UICorner",szL).CornerRadius=UDim.new(0,5)
    mkBr(szL,T.SK,1)
    local pB=Instance.new("TextButton")
    pB.Size=UDim2.new(0,24,1,0)pB.Position=UDim2.new(0,82,0,0)
    pB.BackgroundColor3=T.R pB.Text="+"pB.TextColor3=T.B pB.TextSize=15
    pB.Font=Enum.Font.GothamBold pB.AutoButtonColor=false pB.Parent=r2
    Instance.new("UICorner",pB).CornerRadius=UDim.new(0,5)
    attachRipple(pB)
    local stB=Instance.new("TextButton")
    stB.Size=UDim2.new(1,-110,1,0)stB.Position=UDim2.new(0,110,0,0)
    stB.BackgroundColor3=T.C stB.Text="STEP 5"stB.TextColor3=T.D stB.TextSize=9
    stB.Font=Enum.Font.GothamBold stB.AutoButtonColor=false stB.Parent=r2
    Instance.new("UICorner",stB).CornerRadius=UDim.new(0,5)
    mkBr(stB,T.SK,1)
    attachRipple(stB)
    local hstat=Instance.new("TextLabel")
    hstat.Size=UDim2.new(1,-20,0,12)hstat.Position=UDim2.new(0,10,0,76)
    hstat.BackgroundTransparency=1 hstat.Text="DISABLED"hstat.TextColor3=T.M hstat.TextSize=9
    hstat.Font=Enum.Font.GothamBold hstat.TextXAlignment=Enum.TextXAlignment.Left hstat.Parent=hs
    local tinfo=Instance.new("TextLabel")
    tinfo.Size=UDim2.new(1,-20,0,12)tinfo.Position=UDim2.new(0,10,0,90)
    tinfo.BackgroundTransparency=1 tinfo.Text="NO TARGET"tinfo.TextColor3=T.M tinfo.TextSize=9
    tinfo.Font=Enum.Font.GothamBold tinfo.TextXAlignment=Enum.TextXAlignment.Left tinfo.Parent=hs

    local es=Instance.new("Frame")
    es.Size=UDim2.new(1,0,0,258)es.Position=UDim2.new(0,0,0,114)
    es.BackgroundColor3=T.P es.BorderSizePixel=0 es.Parent=R
    Instance.new("UICorner",es).CornerRadius=UDim.new(0,8)
    mkBr(es,T.RD,1)
    local et=Instance.new("TextLabel")
    et.Size=UDim2.new(1,-16,0,14)et.Position=UDim2.new(0,10,0,6)
    et.BackgroundTransparency=1 et.Text="▲ ENGINE v32.0"et.TextColor3=T.R et.TextSize=10
    et.Font=Enum.Font.GothamBold et.TextXAlignment=Enum.TextXAlignment.Left et.Parent=es
    local nlb=Instance.new("TextButton")
    nlb.Size=UDim2.new(0.46,-8,0,28)nlb.Position=UDim2.new(0,8,0,24)
    nlb.BackgroundColor3=S.noLag and T.R or T.C2
    nlb.Text=S.noLag and"🚀 NO-LAG: ON"or"🚀 NO-LAG: OFF"
    nlb.TextColor3=S.noLag and Color3.fromRGB(255,255,255)or T.R
    nlb.TextSize=10 nlb.Font=Enum.Font.GothamBold nlb.AutoButtonColor=false nlb.Parent=es
    Instance.new("UICorner",nlb).CornerRadius=UDim.new(0,6)
    local nlbBr=mkBr(nlb,S.noLag and T.RG or T.SK,S.noLag and 2 or 1)
    attachRipple(nlb)
    nlb.Activated:Connect(function()
        S.noLag=not S.noLag applyNoLag()save()
        click(1.2)
        nlb.BackgroundColor3=S.noLag and T.R or T.C2
        nlb.Text=S.noLag and"🚀 NO-LAG: ON"or"🚀 NO-LAG: OFF"
        nlb.TextColor3=S.noLag and Color3.fromRGB(255,255,255)or T.R
        nlbBr.Color=S.noLag and T.RG or T.SK
        nlbBr.Thickness=S.noLag and 2 or 1
        toast(S.noLag and"ALL FIXES ON"or"NO-LAG OFF",S.noLag and T.RG or T.M,"🚀 ")
        if S.ui.refreshAll then pcall(S.ui.refreshAll)end
    end)
    S.ui.noLagBtn=nlb

    local fndB=Instance.new("TextButton")
    fndB.Size=UDim2.new(0.30,-8,0,28)fndB.Position=UDim2.new(0.46,0,0,24)
    fndB.BackgroundColor3=T.PU
    fndB.Text="⚡ FIND"
    fndB.TextColor3=Color3.fromRGB(255,255,255)
    fndB.TextSize=11 fndB.Font=Enum.Font.GothamBold fndB.AutoButtonColor=false fndB.Parent=es
    Instance.new("UICorner",fndB).CornerRadius=UDim.new(0,6)
    mkBr(fndB,T.PU,1.5)
    attachRipple(fndB)
    S.ui.findBtn=fndB
    fndB.Activated:Connect(function()
        click(1.15)
        S.scanAnimUntil=tick()+0.4
        task.wait(0.15)
        rebuild(false)
        S.scanAnimUntil=0
        fndB.Text="⚡ FIND"
    end)

    local pmB=Instance.new("TextButton")
    pmB.Size=UDim2.new(0.24,-8,0,28)pmB.Position=UDim2.new(0.76,0,0,24)
    pmB.BackgroundColor3=S.premiumOnly and T.PU or T.C2
    pmB.Text=S.premiumOnly and"💎 ON"or"💎 OFF"
    pmB.TextColor3=S.premiumOnly and Color3.fromRGB(255,255,255)or T.PU
    pmB.TextSize=10 pmB.Font=Enum.Font.GothamBold pmB.AutoButtonColor=false pmB.Parent=es
    Instance.new("UICorner",pmB).CornerRadius=UDim.new(0,6)
    local pmBr=mkBr(pmB,S.premiumOnly and T.PU or T.SK,S.premiumOnly and 2 or 1)
    attachRipple(pmB)
    pmB.Activated:Connect(function()
        S.premiumOnly=not S.premiumOnly save()
        click(1.15)
        pmB.BackgroundColor3=S.premiumOnly and T.PU or T.C2
        pmB.Text=S.premiumOnly and"💎 ON"or"💎 OFF"
        pmB.TextColor3=S.premiumOnly and Color3.fromRGB(255,255,255)or T.PU
        pmBr.Color=S.premiumOnly and T.PU or T.SK
        toast(S.premiumOnly and"PREMIUM-ONLY ON"or"PREM-ONLY OFF",S.premiumOnly and T.PU or T.M,"💎 ")
    end)
    S.ui.premBtn=pmB

    local pl2=Instance.new("TextLabel")
    pl2.Size=UDim2.new(0,50,0,10)pl2.Position=UDim2.new(0,10,0,58)
    pl2.BackgroundTransparency=1 pl2.Text="PATTERN"pl2.TextColor3=T.M pl2.TextSize=8
    pl2.Font=Enum.Font.GothamBold pl2.TextXAlignment=Enum.TextXAlignment.Left pl2.Parent=es
    local pats={}
    local patList={"AUTO","ULTRA","WEIGHTED","RANDOM"}
    for i,n in ipairs(patList)do
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0.25,-6,0,20)b.Position=UDim2.new((i-1)*0.25,4,0,70)
        b.BackgroundColor3=(S.autoPattern==n)and T.R or T.C
        b.Text=n b.TextColor3=(S.autoPattern==n)and T.B or T.D
        b.TextSize=8 b.Font=Enum.Font.GothamBold b.AutoButtonColor=false b.Parent=es
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        mkBr(b,T.SK,1)
        attachRipple(b)
        pats[n]=b
        b.Activated:Connect(function()
            click(1.05)S.autoPattern=n save()
            for k,bt in pairs(pats)do
                bt.BackgroundColor3=(k==n)and T.R or T.C
                bt.TextColor3=(k==n)and T.B or T.D
            end
        end)
    end
    S.ui.setPattern=function(n)
        for k,bt in pairs(pats)do
            bt.BackgroundColor3=(k==n)and T.R or T.C
            bt.TextColor3=(k==n)and T.B or T.D
        end
    end
    local tog={}
    local function mkTog(i,lb,init,setter)
        local col=(i-1)%3
        local row=math.floor((i-1)/3)
        local f=Instance.new("Frame")
        f.Size=UDim2.new(1/3,-4,0,20)f.Position=UDim2.new(col*(1/3),2,0,96+row*24)
        f.BackgroundColor3=T.C f.BorderSizePixel=0 f.Parent=es
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
        mkBr(f,T.SK,1)
        local l=Instance.new("TextLabel")
        l.Size=UDim2.new(1,-24,1,0)l.Position=UDim2.new(0,6,0,0)
        l.BackgroundTransparency=1 l.Text=lb l.TextColor3=T.TX l.TextSize=7
        l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left
        l.TextTruncate=Enum.TextTruncate.AtEnd l.Parent=f
        local pl=Instance.new("Frame")
        pl.Size=UDim2.new(0,22,0,10)pl.Position=UDim2.new(1,-26,0.5,-5)
        pl.BackgroundColor3=init and T.R or T.C2 pl.BorderSizePixel=0 pl.Parent=f
        Instance.new("UICorner",pl).CornerRadius=UDim.new(1,0)
        local kn=Instance.new("Frame")
        kn.Size=UDim2.new(0,6,0,6)
        kn.Position=init and UDim2.new(1,-8,0.5,-3)or UDim2.new(0,2,0.5,-3)
        kn.BackgroundColor3=Color3.fromRGB(255,255,255)kn.BorderSizePixel=0 kn.Parent=pl
        Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,0,1,0)b.BackgroundTransparency=1 b.Text=""b.Parent=f
        local function ap(st)
            pl.BackgroundColor3=st and T.R or T.C2
            TS:Create(kn,TweenInfo.new(0.15),{Position=st and UDim2.new(1,-8,0.5,-3)or UDim2.new(0,2,0.5,-3)}):Play()
        end
        b.Activated:Connect(function()click(1.05)ap(setter())end)
        tog[lb]={set=ap}
    end
    mkTog(1,"DAMAGE",S.onlyDmg,function()S.onlyDmg=not S.onlyDmg save()return S.onlyDmg end)
    mkTog(2,"CONC",S.conc,function()S.conc=not S.conc save()return S.conc end)
    mkTog(3,"WEIGHT",S.weight,function()S.weight=not S.weight save()return S.weight end)
    mkTog(4,"THROT",S.throt,function()S.throt=not S.throt save()return S.throt end)
    mkTog(5,"NET",S.net,function()S.net=not S.net save()return S.net end)
    mkTog(6,"RESCAN",S.rescan,function()S.rescan=not S.rescan save()return S.rescan end)
    mkTog(7,"AFK",S.afk,function()S.afk=not S.afk save()return S.afk end)
    mkTog(8,"SFX",S.sfx,function()S.sfx=not S.sfx save()return S.sfx end)
    mkTog(9,"KEYBD",S.keybd,function()S.keybd=not S.keybd save()return S.keybd end)
    mkTog(10,"ANTI-FRZ",S.antiFrz,function()S.antiFrz=not S.antiFrz save()return S.antiFrz end)
    mkTog(11,"AUTO-EQP",S.autoRescanOnEquip,function()S.autoRescanOnEquip=not S.autoRescanOnEquip save()return S.autoRescanOnEquip end)
    mkTog(12,"KILL-SW",S.killSw,function()S.killSw=not S.killSw save()return S.killSw end)

    local tmR=Instance.new("Frame")
    tmR.Size=UDim2.new(1,-16,0,18)tmR.Position=UDim2.new(0,8,0,208)
    tmR.BackgroundColor3=T.C tmR.BorderSizePixel=0 tmR.Parent=es
    Instance.new("UICorner",tmR).CornerRadius=UDim.new(0,5)
    mkBr(tmR,T.PU,1)
    local tmT=Instance.new("TextLabel")
    tmT.Size=UDim2.new(0.6,0,1,0)tmT.Position=UDim2.new(0,8,0,0)
    tmT.BackgroundTransparency=1 tmT.Text="TURBO MULT (tap)"tmT.TextColor3=T.M tmT.TextSize=8
    tmT.Font=Enum.Font.GothamBold tmT.TextXAlignment=Enum.TextXAlignment.Left tmT.Parent=tmR
    local tmV=Instance.new("TextLabel")
    tmV.Size=UDim2.new(0.4,-8,1,0)tmV.Position=UDim2.new(0.6,0,0,0)
    tmV.BackgroundTransparency=1 tmV.Text=S.turboMult.."x"tmV.TextColor3=T.PU tmV.TextSize=9
    tmV.Font=Enum.Font.GothamBold tmV.TextXAlignment=Enum.TextXAlignment.Right tmV.Parent=tmR
    local tmB=Instance.new("TextButton")
    tmB.Size=UDim2.new(1,0,1,0)tmB.BackgroundTransparency=1 tmB.Text=""tmB.Parent=tmR
    tmB.Activated:Connect(function()
        S.turboMultIdx=(S.turboMultIdx%#S.turboMultOpts)+1
        S.turboMult=S.turboMultOpts[S.turboMultIdx]
        tmV.Text=S.turboMult.."x"save()
    end)

    local cdR=Instance.new("Frame")
    cdR.Size=UDim2.new(1,-16,0,18)cdR.Position=UDim2.new(0,8,0,230)
    cdR.BackgroundColor3=T.C cdR.BorderSizePixel=0 cdR.Parent=es
    Instance.new("UICorner",cdR).CornerRadius=UDim.new(0,5)
    mkBr(cdR,T.SK,1)
    local cdT=Instance.new("TextLabel")
    cdT.Size=UDim2.new(0.6,0,1,0)cdT.Position=UDim2.new(0,8,0,0)
    cdT.BackgroundTransparency=1 cdT.Text="MAX FIRES/FRAME"cdT.TextColor3=T.M cdT.TextSize=8
    cdT.Font=Enum.Font.GothamBold cdT.TextXAlignment=Enum.TextXAlignment.Left cdT.Parent=cdR
    local cdV=Instance.new("TextLabel")
    cdV.Size=UDim2.new(0.4,-8,1,0)cdV.Position=UDim2.new(0.6,0,0,0)
    cdV.BackgroundTransparency=1 cdV.Text=S.maxFires.." f/f"cdV.TextColor3=T.RG cdV.TextSize=9
    cdV.Font=Enum.Font.GothamBold cdV.TextXAlignment=Enum.TextXAlignment.Right cdV.Parent=cdR
    local cdB=Instance.new("TextButton")
    cdB.Size=UDim2.new(1,0,1,0)cdB.BackgroundTransparency=1 cdB.Text=""cdB.Parent=cdR
    cdB.Activated:Connect(function()
        local o={100,200,500,1000,2000,5000,10000}
        local ix=1
        for i,v in ipairs(o)do if v==S.maxFires then ix=i break end end
        ix=(ix%#o)+1
        S.maxFires=o[ix]cdV.Text=S.maxFires.." f/f"save()
    end)

    local prR=Instance.new("Frame")
    prR.Size=UDim2.new(1,-16,0,20)prR.Position=UDim2.new(0,8,0,252)
    prR.BackgroundTransparency=1 prR.Parent=es
    local prLbl=Instance.new("TextLabel")
    prLbl.Size=UDim2.new(0,60,1,0)prLbl.Position=UDim2.new(0,0,0,0)
    prLbl.BackgroundTransparency=1 prLbl.Text="PROFILES"prLbl.TextColor3=T.M prLbl.TextSize=8
    prLbl.Font=Enum.Font.GothamBold prLbl.TextXAlignment=Enum.TextXAlignment.Left prLbl.Parent=prR
    for i=1,3 do
        local pb=Instance.new("TextButton")
        pb.Size=UDim2.new(0,48,1,0)pb.Position=UDim2.new(0,60+(i-1)*52,0,0)
        pb.BackgroundColor3=T.C pb.Text="P"..i pb.TextColor3=T.TX pb.TextSize=9
        pb.Font=Enum.Font.GothamBold pb.AutoButtonColor=false pb.Parent=prR
        Instance.new("UICorner",pb).CornerRadius=UDim.new(0,4)
        local pbr=mkBr(pb,T.SK,1)
        attachRipple(pb)
        pb.Activated:Connect(function()
            if S.profiles[i]then
                applyProfile(S.profiles[i])
                S.profileActive=i
                click(1.15)
                toast("Profile "..i.." loaded",T.G,"💾 ")
                pbr.Color=T.G
            else
                toast("Profile "..i.." empty (RMB to save)",T.Y,"💾 ")
            end
        end)
        pb.MouseButton2Click:Connect(function()
            S.profiles[i]=captureProfile()
            S.profileActive=i
            save()
            click(1.2)
            toast("Profile "..i.." saved",T.PU,"💾 ")
            pbr.Color=T.PU
        end)
    end
    S.ui.refreshAll=function()
        for label,t in pairs(tog)do
            local lookup={
                DAMAGE=S.onlyDmg,CONC=S.conc,WEIGHT=S.weight,THROT=S.throt,NET=S.net,
                RESCAN=S.rescan,AFK=S.afk,SFX=S.sfx,KEYBD=S.keybd,["ANTI-FRZ"]=S.antiFrz,
                ["AUTO-EQP"]=S.autoRescanOnEquip,["KILL-SW"]=S.killSw,
            }
            if lookup[label]~=nil then t.set(lookup[label])end
        end
        tmV.Text=S.turboMult.."x"
        cdV.Text=S.maxFires.." f/f"
        tL.Text=S.rate>=1000 and string.format("%.1fk",S.rate/1000)or tostring(S.rate)
        if S.ui.noLagBtn then
            S.ui.noLagBtn.BackgroundColor3=S.noLag and T.R or T.C2
            S.ui.noLagBtn.Text=S.noLag and"🚀 NO-LAG: ON"or"🚀 NO-LAG: OFF"
            S.ui.noLagBtn.TextColor3=S.noLag and Color3.fromRGB(255,255,255)or T.R
        end
        if S.ui.premBtn then
            S.ui.premBtn.BackgroundColor3=S.premiumOnly and T.PU or T.C2
            S.ui.premBtn.Text=S.premiumOnly and"💎 ON"or"💎 OFF"
            S.ui.premBtn.TextColor3=S.premiumOnly and Color3.fromRGB(255,255,255)or T.PU
        end
    end

    local rr=Instance.new("Frame")
    rr.Size=UDim2.new(1,0,0,26)rr.Position=UDim2.new(0,0,0,380)
    rr.BackgroundTransparency=1 rr.Parent=R
    local mn=Instance.new("TextButton")
    mn.Size=UDim2.new(0,30,1,0)mn.BackgroundColor3=T.C mn.Text="−"
    mn.TextColor3=T.R mn.TextSize=18 mn.Font=Enum.Font.GothamBold mn.AutoButtonColor=false mn.Parent=rr
    Instance.new("UICorner",mn).CornerRadius=UDim.new(0,6)
    mkBr(mn,T.SK,1)
    attachRipple(mn)
    local inp=Instance.new("TextBox")
    inp.Size=UDim2.new(1,-68,1,0)inp.Position=UDim2.new(0,34,0,0)
    inp.BackgroundColor3=T.C inp.Text=tostring(S.rate)inp.TextColor3=T.RG inp.TextSize=13
    inp.Font=Enum.Font.GothamBold inp.ClearTextOnFocus=false inp.Parent=rr
    Instance.new("UICorner",inp).CornerRadius=UDim.new(0,6)
    mkBr(inp,T.R,1.5)
    local pp=Instance.new("TextButton")
    pp.Size=UDim2.new(0,30,1,0)pp.Position=UDim2.new(1,-30,0,0)
    pp.BackgroundColor3=T.R pp.Text="+"pp.TextColor3=T.B pp.TextSize=18
    pp.Font=Enum.Font.GothamBold pp.AutoButtonColor=false pp.Parent=rr
    Instance.new("UICorner",pp).CornerRadius=UDim.new(0,6)
    attachRipple(pp)
    local ps={1000,5000,15000,25000,35000,50000,100000}
    local pr=Instance.new("Frame")
    pr.Size=UDim2.new(1,0,0,18)pr.Position=UDim2.new(0,0,0,410)
    pr.BackgroundTransparency=1 pr.Parent=R
    local psBtns={}
    local pw=1/#ps
    for i,v in ipairs(ps)do
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(pw,-3,1,0)b.Position=UDim2.new((i-1)*pw,1.5,0,0)
        b.BackgroundColor3=(v==S.rate)and T.R or T.C
        if v>=50000 then b.BackgroundColor3=(v==S.rate)and T.PU or T.C end
        b.Text=v>=1000 and(string.format("%dk",v/1000))or tostring(v)
        b.TextColor3=(v==S.rate)and T.B or T.D
        b.TextSize=8 b.Font=Enum.Font.GothamBold b.AutoButtonColor=false b.Parent=pr
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        mkBr(b,T.SK,1)
        attachRipple(b)
        psBtns[v]=b
    end
    local act=Instance.new("Frame")
    act.Size=UDim2.new(1,0,0,22)act.Position=UDim2.new(0,0,0,434)
    act.BackgroundTransparency=1 act.Parent=R
    local fdB=Instance.new("TextButton")
    fdB.Size=UDim2.new(0.33,-3,1,0)fdB.BackgroundColor3=T.PD
    fdB.Text="★ FIND [F]"fdB.TextColor3=Color3.fromRGB(255,255,255)fdB.TextSize=9
    fdB.Font=Enum.Font.GothamBold fdB.AutoButtonColor=false fdB.Parent=act
    Instance.new("UICorner",fdB).CornerRadius=UDim.new(0,5)
    mkBr(fdB,T.PU,1.5)
    attachRipple(fdB)
    fdB.Activated:Connect(function()click(1.15)S.scanAnimUntil=tick()+0.4 rebuild(false)S.scanAnimUntil=0 end)
    local tb2=Instance.new("TextButton")
    tb2.Size=UDim2.new(0.33,-3,1,0)tb2.Position=UDim2.new(0.33,3,0,0)
    tb2.BackgroundColor3=S.turbo and T.PU or T.C
    tb2.Text="🔥 TURBO"tb2.TextColor3=S.turbo and Color3.fromRGB(255,255,255)or T.PU
    tb2.TextSize=9 tb2.Font=Enum.Font.GothamBold tb2.AutoButtonColor=false tb2.Parent=act
    Instance.new("UICorner",tb2).CornerRadius=UDim.new(0,5)
    mkBr(tb2,S.turbo and T.PU or T.SK,1)
    attachRipple(tb2)
    local rsB=Instance.new("TextButton")
    rsB.Size=UDim2.new(0.33,-3,1,0)rsB.Position=UDim2.new(0.66,3,0,0)
    rsB.BackgroundColor3=T.C rsB.Text="↻ CLEAR"rsB.TextColor3=T.Y rsB.TextSize=9
    rsB.Font=Enum.Font.GothamBold rsB.AutoButtonColor=false rsB.Parent=act
    Instance.new("UICorner",rsB).CornerRadius=UDim.new(0,5)
    mkBr(rsB,T.SK,1)
    attachRipple(rsB)
    local tgB=Instance.new("TextButton")
    tgB.Size=UDim2.new(1,0,0,42)tgB.Position=UDim2.new(0,0,0,462)
    tgB.BackgroundColor3=T.R tgB.Text="▶   ENGAGE"tgB.TextColor3=T.B tgB.TextSize=15
    tgB.Font=Enum.Font.GothamBold tgB.AutoButtonColor=false tgB.Parent=R
    Instance.new("UICorner",tgB).CornerRadius=UDim.new(0,8)
    local tgB_stroke=mkBr(tgB,T.RG,2)
    attachRipple(tgB)

    S.ui.actual=aL S.ui.tot=totL S.ui.eff=effL S.ui.dmg=dmgL S.ui.prem=prL
    S.ui.fps=fpsL S.ui.ping=pingL S.ui.packet=pktL S.ui.session=sesL
    S.ui.throttle=thL S.ui.hbSize=szL S.ui.hbStat=hstat S.ui.tInfo=tinfo
    S.ui.log=logL S.ui.toggle=tgB S.ui.bestLbl=bestL S.ui.toggleStroke=tgB_stroke

    local function setRate(v)
        v=tonumber(v)if not v then return end
        v=math.clamp(math.floor(v),1,200000)
        S.rate=v S.carry=0 save()
        tL.Text=v>=1000 and string.format("%.1fk",v/1000)or tostring(v)
        inp.Text=tostring(v)
        for k,b in pairs(psBtns)do
            b.BackgroundColor3=(k==v)and T.R or T.C
            if k>=50000 and k==v then b.BackgroundColor3=T.PU end
            b.TextColor3=(k==v)and T.B or T.D
        end
    end
    setRate(S.rate)

    tgB.Activated:Connect(function()
        click(1.1)S.running=not S.running S.carry=0
        if S.running then
            S.rampStart=tick()S.needsInstantFire=true
            if S.antiDelay then
                S.opMode.warmUntil=tick()+1.5 S.opMode.boostUntil=tick()+1.5
                S.opMode.intervalSamples={}S.opMode.maxObserved=0
            end
        else
            S.opMode.warmUntil=0 S.opMode.boostUntil=0 S.anchorPos=nil
        end
        if S.running then
            tgB.Text="■   DISENGAGE"tgB.TextColor3=T.R
            tgB_stroke.Color=T.RG
        else
            tgB.Text="▶   ENGAGE"tgB.BackgroundColor3=T.R tgB.TextColor3=T.B
            tgB_stroke.Color=T.RG
        end
    end)
    pp.Activated:Connect(function()click(1.15)local st
        if S.rate<1000 then st=100 elseif S.rate<10000 then st=1000
        elseif S.rate<50000 then st=5000 else st=10000 end
        setRate(S.rate+st)
    end)
    mn.Activated:Connect(function()click(1.15)local st
        if S.rate<=1000 then st=100 elseif S.rate<=10000 then st=1000
        elseif S.rate<=50000 then st=5000 else st=10000 end
        setRate(S.rate-st)
    end)
    inp.FocusLost:Connect(function()setRate(inp.Text)end)
    for v,b in pairs(psBtns)do
        b.Activated:Connect(function()click(1.05)setRate(v)end)
    end
    tb2.Activated:Connect(function()click(1.2)S.turbo=not S.turbo save()
        tb2.BackgroundColor3=S.turbo and T.PU or T.C
        tb2.TextColor3=S.turbo and Color3.fromRGB(255,255,255)or T.PU
    end)
    rsB.Activated:Connect(function()click(1.05)S.health={}S.lastFire={}S.failCount={}S.fireCount={}save()
        toast("Cleared",T.G,"↻ ")
    end)
    hbB.Activated:Connect(function()click(1.05)S.hitbox.en=not S.hitbox.en
        if not S.hitbox.en then hbClear()end
        S.hitbox.acc=999
        hbB.BackgroundColor3=S.hitbox.en and T.R or T.C
        hbB.TextColor3=S.hitbox.en and T.B or T.D
    end)
    ivB.Activated:Connect(function()click(1.05)S.hitbox.invis=not S.hitbox.invis
        S.hitbox.acc=999
        ivB.BackgroundColor3=S.hitbox.invis and T.R or T.C
        ivB.TextColor3=S.hitbox.invis and T.B or T.D
    end)
    alB.Activated:Connect(function()click(1.05)S.hitbox.all=not S.hitbox.all
        hbClear()S.hitbox.acc=999
        alB.BackgroundColor3=S.hitbox.all and T.R or T.C
        alB.TextColor3=S.hitbox.all and T.B or T.D
        alB.Text=S.hitbox.all and "ALL"or "TARGET"
    end)
    pB.Activated:Connect(function()click(1.2)
        S.hitbox.size=math.min(200,S.hitbox.size+S.hitbox.step)
        S.hitbox.acc=999
    end)
    mB.Activated:Connect(function()click(1.2)
        S.hitbox.size=math.max(5,S.hitbox.size-S.hitbox.step)
        S.hitbox.acc=999
    end)
    stB.Activated:Connect(function()click(1.05)
        S.hitbox.stepIdx=(S.hitbox.stepIdx%#S.hitbox.steps)+1
        S.hitbox.step=S.hitbox.steps[S.hitbox.stepIdx]
        stB.Text="STEP "..S.hitbox.step
    end)

    local drag,ds,sp=false,nil,nil
    hd.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=i.Position sp=box.Position
            local c
            c=i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false c:Disconnect()end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then
            local d=i.Position-ds
            box.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    sel("PREMIUM")
end

local ok,err=pcall(buildUI)
if not ok then warn("[CANNON] UI error: "..tostring(err))end

task.spawn(function()
    task.wait(2)
    rebuild(true)
    local c=S.findStats.premium
    if c>0 then toast("Found "..c.." premium remotes!",Color3.fromRGB(180,90,255),"💎 ")
    else toast("Equip a tool then press F",Color3.fromRGB(255,190,60),"🎒 ")end
end)

print("═══════════════════════════════════")
print("  VERTEX CANNON v32.0 — SUPER POLISHED")
print("  Ripple / Sparkline / Tab glow")
print("═══════════════════════════════════")