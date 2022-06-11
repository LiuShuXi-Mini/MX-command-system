---@diagnostic disable: redundant-parameter, lowercase-global
--[[
    公共API
    本API的编写目的是防止重复造轮子，减少体积和函数重名风险。
]] --

PlayerNames = {}
--获取玩家名称
ScriptSupportEvent:registerEvent("Game.AnyPlayer.EnterGame", function(e)
    local ret, name = Player:getNickname(e.eventobjid)
    PlayerNames[name] = {}
    PlayerNames[name].uin = e.eventobjid --加入列表中
    --[[
        用法：
            1. PlayerNames["玩家名"].uin 为玩家uin
            2. 通过 PlayerNames["玩家名"] == nil 可以知道玩家是否加入了游戏
            3. 也可以赋值入私有变量
    ]]
    --
end)
ScriptSupportEvent:registerEvent("Game.AnyPlayer.EnterGame", function(e)
    PlayerNames[Player:getNickname(e.eventobjid)] = nil --从列表中删除
end)
---@diagnostic disable-next-line: lowercase-global
function getTableLength(t) --传入对象table，返回其成员数
    local tableLength = 0 --声明计时器
    --in pairs()递归
    for key, val in pairs(t) do
        tableLength = tableLength + 1 --计时器+1
    end
    return tableLength
end

function sysMsg(msg, target) --Chat:sendSystemMsg()的替代品
    local ret, nickname = Player:getNickname(target)
    Chat:sendSystemMsg(msg, target)
    print("[To " .. nickname .. "(" .. target .. ")] " .. msg)
end

function mprint(txt)
    --在聊天框输出对象(特殊对象不行，请使用print)
    if (type(txt) == "table") then
        tmprint(txt)
        return
    end
    sysMsg(txt, hostUin)
    print(txt)
end

function tmprint(table)
    --在聊天框输出数组
    print(table)
    mprint("----数组开始打印----")
    --递归
    for k, v in pairs(table) do
        --打印索引和值
        if (v == nil) then
            v = "nil"
        elseif (v == false) then
            v = "false"
        elseif (v == true) then
            v = "true"
        end
        if (type(v) == "table") then
            mprint("{索引：" .. k .. ",值：（数组）")
            tmprint(v)
            mprint("}")
        else
            mprint("{索引:" .. k .. ",值：" .. v .. "}")
        end
    end
    mprint("----数组打印完成----")
end

function split(str, reps)
    local resultStrList = {}
    ---@diagnostic disable-next-line: trailing-space, discard-returns
    string.gsub(str, '[^' .. reps .. ']+', function(w)
        table.insert(resultStrList, w)
    end)
    return resultStrList
end

function sleep(n, func) --延时.n为延时的时间(s),func是延时所干的事情（避免空耗资源）
    if (func == nil) then
        func = function()
            --do noting
        end
    end
    local s = os.time()
    while (n < os.time - s) do
        func()
    end
end

function findInTable(table, item)
    for index, value in pairs(table) do
        if (value == item) then
            return index
        end
    end
    return nil
end

--[[
    Op系统
]] --
op = {}
op.list = {} --管理员列表
op.num = 0 --管理数
op.err = {
    IsOp = 1,
    IsNotOp = 2,
}
op.setOp = function(uin)
    -- setOp(uin) 设置玩家为op
    -- uin:玩家Uin

    local ret, name = Player:getNickname(uin)
    --检测玩家是否为op
    ret = findInTable(op.list, uin)
    if (ret ~= nil) then
        return op.err.IsOp
    end
    op.num = op.num + 1

    print("玩家" .. name .. "(" .. uin .. ")被设置成管理员")
    op.list[op.num] = uin
end

op.isOp = function(uin)
    -- isOp(uin) 玩家是否为Op
    -- uin:玩家uin

    if (type(uin) == "table") then --不知道为什么有时候就是数组啊（直接用事件参数）
        uin = uin[1]
    end

    local ret = findInTable(op.list, uin)
    if (ret == nil) then
        return false
    end
    return true
end

op.delOp = function(uin)
    -- delOp(uin) 撤销玩家的op权限

    if (type(uin) == "table") then --不知道为什么有时候就是数组啊（直接用事件参数）
        uin = uin[1]
    end

    --检测玩家是否不为op
    local ret = findInTable(op.list, uin)
    if (ret == nil) then
        return op.err.IsNotOp
    end

    op.num = op.num - 1
    table.remove(op.list, ret)
end

op.showList = function()
    -- 打印管理员列表

    tmprint(op.list)
end
























--[[
    核心组件
    功能：处理消息和分发函数
]] --
cmds = {} --Op才可以执行
lcmds = {} --玩家就可以执行
Err = {} --错误码
Err.argsError = 1 --参数错误
Err.codeError = 2 --代码错误
Err.none = 0 --perfet!
ScriptSupportEvent:registerEvent("Game.Start", function(e)
    --获取房主uin
    err, hostUin = Player:getHostUin()
    print(err, hostUin)
    --将房主加入PlayerNames
    local ret, name = Player:getNickname(e.eventobjid)
    PlayerNames[name] = {}
    PlayerNames[name].uin = hostUin
    --模块初始化
    sysTime.load()
    --给予房主op
    op.setOp(hostUin)
    --打印房间信息
    sysMsg("房间信息\n-----------\n" .. "HostUin:" .. hostUin .. "\n", Player:getHostUin())
end)
ScriptSupportEvent:registerEvent("Player.NewInputContent", function(e)
    cmdsmain(e)
end)
function cmdsmain(e)
    -- 检测代码并将参数传到下级的函数
    -- 只要给出e.content 和 e.eventobjid 就好



    print(e)
    if (string.sub(e.content, 0, 1) == "/") then
        local args = split(string.sub(e.content, 2, string.len(e.content)), " ") --分割参数
        local ret, nickname = Player:getNickname(e.eventobjid)
        local isOp = op.isOp(e.eventobjid)
        if (isOp == false) then
            print("玩家：" .. nickname .. "(" .. e.eventobjid .. ")(非管理员)调用了命令：")
        else
            print("玩家：" .. nickname .. "(" .. e.eventobjid .. ")(管理员)调用了命令：")
        end
        print(args)
        if (cmds[args[1]] ~= nil) then --权限设置
            if (isOp == false) then
                sysMsg("没有权限", e.eventobjid)
                return
            else
                jumpfun = args[1] --后面会去掉，所以保存调用名称
                local event = {} --创建事件参数对象
                event.uin = e.eventobjid --触发玩家uin
                table.remove(args, 1) --去掉第一个（就是调用的主函数）
                event.args = args
                local ret = cmds[jumpfun].mainfun(event)
                if (ret == Err.argsError) then
                    sysMsg("参数错误。", e.eventobjid)
                elseif (ret == Err.codeError) then
                    sysMsg("代码运行出错，请检查参数设置或者重新调用。", e.eventobjid)
                elseif (ret == Err.none) then
                    sysMsg("执行成功！", e.eventobjid)
                elseif (ret == nil) then
                    sysMsg("执行成功,无返回值。", e.eventobjid)
                else
                    sysMsg("调用成功，返回值：" .. ret, e.eventobjid)
                end
            end
            return
        elseif (lcmds[args[1]] ~= nil) then
            jumpfun = args[1] --后面会去掉，所以保存调用名称
            local event = {} --创建事件参数对象
            event.uin = e.eventobjid --触发玩家uin
            table.remove(args, 1) --去掉第一个（就是调用的主函数）
            event.args = args
            local ret = lcmds[jumpfun].mainfun(event)
            if (ret == Err.argsError) then
                sysMsg("参数错误。", e.eventobjid)
            elseif (ret == Err.codeError) then
                sysMsg("代码运行出错，请检查参数设置或者重新调用。", e.eventobjid)
            elseif (ret == Err.none) then
                sysMsg("执行成功！", e.eventobjid)
            elseif (ret == nil) then
                sysMsg("执行成功,无返回值。", e.eventobjid)
            else
                sysMsg("调用成功，返回值：" .. ret, e.eventobjid)
            end
        else
            sysMsg("没有找到这个命令！", e.eventobjid)
        end
    end
    return 0
end

--[[
    功能增强：主控时钟
    ***模块暂时停止开发***
    使用时注意：
        1.时钟在游戏开始后才会启动
        2.时钟周期是默认的。
        3.特殊问题导致没有while...do，以后会解决
]] --
sysTime = {}
sysTime.load = function()
    if (1 == 1) then
        return
    end
    --初始化代码

    --注册计时器
    local ret = ErrorCode.FAILED
    sysTime.name = "sysTimer" --计时器名字
    while (ret == ErrorCode.FAILED) do --确保注册成功
        ret, sysTime.timer = MiniTimer:createTimer(sysTime.name) --计时器id
    end
    --ret, sysTime.timer = MiniTimer.createTimer(sysTime.name) --计时器id
    --运行计时器
    ret = ErrorCode.FAILED
    while (ret == ErrorCode.FAILED) do --确保正确运行
        ret = MiniTimer:startForwardTimer(sysTime.timer)
    end
    --ret = MiniTimer:startForwardTimer(sysTime.timer)
end
sysTime.getTime = function() --获取现在时间
    local ret = ErrorCode.FAILED
    local ret2 = 0
    while (ret == ErrorCode.FAILED) do
        ret, ret2 = MiniTimer.getTimerTime(sysTime.timer)
    end
    return ret2
end
sysTime.wait = function (time)
    local s = sysTime.getTime()
    while (time < sysTime.getTime() - s) do
        --do noting
    end
end















--[[
    chat命令
    版本号 0.0.1
    Copyright(C) liushuxi. All right reserved.
    帮助：
        chat <content> <Player_uin> <send_type>
        content: 发送的内容
        Player_uin：目标玩家名称。如果为0，则为所有玩家
        send_type：发送类型，有一下值：
            system：发送系统消息
            chat：发送玩家消息
]] --
cmds["chat"] = {}
cmds["chat"].mainfun = function(e) --e.avgs为参数数组,e.uin为输入玩家uin
    local targetUin = 0
    --判断参数个数
    if (getTableLength(e.args) > 3 or getTableLength(e.args) < 1) then
        sysMsg("参数个数不正确", e.uin)
        return Err.argsError
    else
        if (e.args[3] == nil) then --默认为system
            e.args[3] = "system"
        end
        if (e.args[2] == nil) then --全部玩家
            targetUin = 0
        elseif (e.args[2] == "0") then --同上
            targetUin = 0
        elseif (PlayerNames[e.args[2]] == nil) then --没有这个玩家
            sysMsg("没有这个玩家", e.uin)
            return Err.argsError
        else
            targetUin = PlayerNames[e.args[2]].uin
        end
        if (e.args[3] == "system") then --systemmsg
            sysMsg(e.args[1], targetUin) --uin
        elseif (e.args[3] == "chat") then --chat
            Chat:sendChat(e.args[1], targetUin) --uin
        else
            sysMsg("发送类型错误！", e.uin) --未知类型，报错
            return Err.argsError
        end
    end
end
cmds["chat"].start = function()
    --初始化代码
end























--[[
    attr命令
    版本号：v0.0.1
    Copyright(C)liushuxi.All right reserved.
    帮助：
        attr <type> [...]
        当 <type> 为 set
        attr set 属性名 属性值 目标玩家
        用途：更改给目标玩家的属性。属性名为API文档中游戏数据类型的PLAYERATTR.XXXXXXX 里的“.”后面的值
        当 <type> 为 get
        attr get 属性名 目标玩家
        用途：获取目标玩家的属性。属性名为API文档中游戏数据类型的PLAYERATTR.XXXXXXX 里的“.”后面的值
]] --




--PLAYERATTR 效果表
-- 使用方法：ATTRS[名字] = 输入值
ATTRS = {}
ATTRS["MAX_HP"] = 1
ATTRS["CUR_HP"] = 2
ATTRS["HP_RECOVER"] = 3
ATTRS["LIFE_NUM"] = 4
ATTRS["MAX_HUNGER"] = 5
ATTRS["CUR_HUNGER"] = 6
ATTRS["MAX_OXYGEN"] = 7
ATTRS["CUR_OXYGEN"] = 8
ATTRS["RECOVER_OXYGEN"] = 9
ATTRS["WALK_SPEED"] = 10
ATTRS["RUN_SPEED"] = 11
ATTRS["SNEAK_SPEED"] = 12
ATTRS["SWIN_SPEED"] = 13
ATTRS["JUMP_POWER"] = 14
ATTRS["DODGE"] = 15
ATTRS["ATK_MELEE"] = 16
ATTRS["ATK_REMOTE"] = 17
ATTRS["DEF_MELEE"] = 18
ATTRS["DEF_REMOTE"] = 19
ATTRS["DIMENSION"] = 20
ATTRS["SCORE"] = 21
ATTRS["LEVEL"] = 22
ATTRS["CUR_STRENGTH"] = 23
ATTRS["MAX_STRENGTH"] = 24
ATTRS["STRENGTH_RECOVER"] = 25
ATTRS["CUR_LEVELEXP"] = 26
ATTRS["CUR_LEVEL"] = 27

cmds["attr"] = {}
cmds["attr"].mainfun = function(e)
    --判断参数个数
    print(e)
    if (getTableLength(e.args) > 4 or getTableLength(e.args) < 2) then
        return Err.argsError
    end
    local targetuin = 0
    if (e.args[1] == "set") then --设置
        if not (getTableLength(e.args) == 4) then
            sysMsg("set 类型需要4个参数！", e.uin)
            return Err.argsError
        end
        if (e.args[4] == "host") then --房主
            targetuin = hostUin
        elseif (PlayerNames[e.args[4]] == nil) then --没有这个玩家
            sysMsg("没有这个玩家", e.uin)
            return Err.argsError
        else
            targetuin = PlayerNames[e.args[4]].uin
        end
        --没有这个属性
        if (ATTRS[e.args[2]] == nil) then
            sysMsg("没有这个属性", e.uin)
            return Err.argsError
        end
        mprint(targetuin)
        mprint(ATTRS[e.args[2]])
        mprint(e.args[3])
        local ret = Player:setAttr(targetuin, ATTRS[e.args[2]], e.args[3])
        mprint(targetuin)
        mprint(ATTRS[e.args[2]])
        mprint(e.args[3])
        if (ret == ErrorCode.FAILED) then
            return Err.codeError

        end
        --获取
    elseif (e.args[1] == "get") then
        if not (getTableLength(e.args) == 3) then
            sysMsg("get 类型需要3个参数！", e.uin)
            return Err.argsError
        end
        if (e.args[3] == "host") then --房主
            targetuin = hostUin
        elseif (PlayerNames[e.args[3]] == nil) then --没有这个玩家
            sysMsg("没有这个玩家", e.uin)
            return Err.argsError
        else
            targetuin = PlayerNames[e.args[3]].uin
        end
        --没有这个属性
        if (ATTRS[e.args[2]] == nil) then
            sysMsg("没有这个属性", e.uin)
            return Err.argsError
        end
        local ret, val = Player:getAttr(targetuin, ATTRS[e.args[2]])
        if (ret == ErrorCode.FAILED) then
            return Err.codeError
        end
        sysMsg("属性" .. e.args[2] .. "(" .. ATTRS[e.args[2]] .. ")的值为 " .. val)
    else
        sysMsg("类型有误！", e.uin)
        return Err.argsError
    end
end











--[[
    showPlayers命令
    版本号：v0.0.l
    用法：/showPlayers
    用途：获取在线玩家列表
]] --
cmds["showPlayers"] = {}
cmds["showPlayers"].mainfun = function(e)
    tmprint(PlayerNames)
end

















--[[give指令
    版本号：v0.0.2
    帮助：
        give <itemid> <itemnum> <playerName>
        用法：给予东西。
        itemid：物品id,hand为手持
        itemnum：物品数量
        playerName: 玩家名称，省略为自己,self也为自己。
]] --
cmds["give"] = {}
cmds["give"].mainfun = function(e) --e.avgs为参数数组,e.uin为输入玩家uin
    local targetUin = 0
    local ret = 0
    --判断参数个数
    if (getTableLength(e.args) < 2) then
        sysMsg("参数个数不正确", e.uin)
        return Err.argsError
    elseif (getTableLength(e.args) > 3) then
        sysMsg("参数个数不正确", e.uin)
        return Err.argsError
    elseif (e.args[3] == "self") then --自己
        targetUin = e.uin
    elseif (e.args[3] == nil) then --省略
        targetUin = e.uin
    elseif (PlayerNames[e.args[3]] == nil) then --没有这个玩家
        sysMsg("没有这个玩家", e.uin)
        return Err.argsError
    else
        targetUin = PlayerNames[e.args[3]].uin
    end
    if (e.args[1] == "hand") then
        ret, e.args[1] = Player:getCurToolID(e.uin)
    end
    ret = Backpack:enoughSpaceForItem(targetUin, e.args[1], e.args[2])
    if (ret == 0) then
        Backpack:addItem(targetUin, e.args[1], e.args[2])
        sysMsg("成功给予" .. e.args[2] .. "个id为" .. e.args[1] .. "的物品！", e.uin)
    else
        sysMsg("背包无法放下" .. e.args[2] .. "个id为" .. e.args[1] .. "的物品,但是将尽可能多的指定物品放入", e.uin)
        Backpack:addItem(hostUin, e.args[1], e.args[2])
        return Err.codeError
    end
end
cmds["give"].start = function()
    --初始化代码
end







--[[tphost指令
    版本号：v0.0.1
    用法：传送到房主那
        /tphost
]] --
lcmds["tphost"] = {}
lcmds["tphost"].mainfun = function(e) --e.avgs为参数数组,e.uin为输入玩家uin
    --判断参数个数
    print(e)
    if not (getTableLength(e.args) == 0) then
        sysMsg("参数个数不正确", e.uin)
        return Err.argsError
    else
        local ret, x, y, z = Actor:getPosition(hostUin)
        if (ret == ErrorCode.FAILED) then
            return Err.codeError
        end
        sysMsg("你将被传送到x:" .. x .. ",y:" .. y .. ",z:" .. z, e.uin)
        Player:setPosition(e.uin, x, y, z)
    end
end
lcmds["tphost"].start = function()
    --初始化代码
end











































--[[tp指令
    版本号：v0.0.1
    帮助：
        /tp <type>
        用途：传送
            当 type 为 pos 时
            /tp pos <x> <y> <z>
            传送到坐标(x,z)高度：y
            当 type 为 player 时
            /tp player <playerName>
            playerName：目标玩家的名字，当为host的时候，会传送到房主那里，也可以去掉空格形成缩写(/tphost)。如果是玩家使用，需要对方同意；如果是房主使用则不需要。self为自己
            传送到玩家
]] --
lcmds["tp"] = {}
lcmds["tp"].mainfun = function(e) --e.avgs为参数数组,e.uin为输入玩家uin
    local targetUin = 0
    print(e)
    --判断参数个数
    if (getTableLength(e.args) > 4 or getTableLength(e.args) < 1) then
        sysMsg("参数个数不正确", e.uin)
        return Err.argsError
    else
        if (e.args[1] == "player") then --player
            if not (getTableLength(e.args) == 2) then --判断参数个数
                sysMsg("参数个数不正确", e.uin)
                return Err.argsError
            end
            if (e.args[2] == "self") then --自己,用于卡入方块中
                targetUin = e.uin
            elseif (PlayerNames[e.args[2]] == nil) then --没有这个玩家
                sysMsg("没有这个玩家", e.uin)
                return Err.argsError
            else
                targetUin = PlayerNames[e.args[2]].uin
            end
            local ret, x, y, z = Actor:getPosition(targetUin) --获取坐标
            if (ret == ErrorCode.FAILED) then
                return Err.codeError
            end
            if (op.isOp(e.uin) == true) then --是op就不需要征集同意
                sysMsg("你将被传送到x:" .. x .. ",y:" .. y .. ",z:" .. z, e.uin)
                Player:setPosition(e.uin, x, y, z)
            else --不是op就需要征集同意
                local req = sendTPrequest(e.uin, targetUin) --发送请求
            end
        elseif (e.args[1] == "pos") then --pos
            if not (getTableLength(e.args) == 4) then --判断参数个数
                sysMsg("参数个数不正确", e.uin)
                return Err.argsError
            end
            --传送
            sysMsg("你将被传送到x:" .. e.args[2] .. ",y:" .. e.args[3] .. ",z:" .. e.args[4], e.uin)
            Player:setPosition(e.uin, e.args[2], e.args[3], e.args[4])
        elseif (e.args[1] == "host") then --host
            --判断参数个数
            if not (getTableLength(e.args) == 1) then
                sysMsg("参数个数不正确", e.uin)
                return Err.argsError
            else
                local req = sendTPrequest(e.uin, hostUin) --发送请求
            end
        elseif (e.args[1] == "accept") then --接受对方的传送
            local ret, str = Player:getNickname(e.uin)
            if (PlayerNames[str].tpRequest == nil) then --没有收到传送请求
                sysMsg("没有收到传送请求！", e.uin)
            else
                local ret2, x, y, z = Actor:getPosition(e.uin) --有就传送
                sysMsg("你将被传送到x:" .. x .. ",y:" .. y .. ",z:" .. z, PlayerNames[str].tpRequest)
                Player:setPosition(PlayerNames[str].tpRequest, x, y, z)
                PlayerNames[str].tpRequest = nil
            end
        elseif (e.args[1] == "refuse") then --接受对方的传送
            local ret, str = Player:getNickname(e.uin)
            if (PlayerNames[str].tpRequest == nil) then --没有收到传送请求
                sysMsg("没有收到传送请求！", e.uin)
            else --有就删掉
                sysMsg(str .. "拒绝了你的传送请求。", PlayerNames[str].tpRequest)
                PlayerNames[str].tpRequest = nil
            end
        else
            sysMsg("发送类型错误！", e.uin) --未知类型，报错
            return Err.argsError
        end
    end
end
lcmds["tp"].start = function()
    --初始化代码
end

function sendTPrequest(sendUin, targetUin) --向玩家发送传送请求,返回是否接受(返回值开发中)
    local ret, str = Player:getNickname(targetUin)
    local ret2, str2 = Player:getNickname(sendUin)
    if (PlayerNames[str].tpRequest ~= nil) then
        sysMsg("该玩家正在处理上一个请求，请稍后再试！", sendUin)
        return nil
    end
    PlayerNames[str].tpRequest = sendUin
    sysMsg("你收到来自" .. str2 .. "的传送请求，接受请输入/tp accept,拒绝输入/tp refuse,超时自动拒绝功能开发中......。", targetUin)
    --[[local s = os.Time()
    while (20 < os.Time() - s) do
        if (PlayerNames[str].tpRequest == nil) then
            return true
        end
    end
    PlayerNames[str].tpRequest = nil
    sysMsg(str .. "你拒绝了传送请求。", targetUin)
    sysMsg(str .. "拒绝了你的传送请求。", sendUin)
    return false]]--
end

--[[op指令
    版本号：v0.0.2
    帮助：
        op <type> [...]
        当 type 为 show
            op show
            显示管理员列表
        当 type 为 set
            op set <playername>
            playername: 玩家名
            给予玩家op权限
        当 type 为 del
            op del <playername>
            playername: 玩家名
            撤销玩家op权限
        当 type 为 get
            op get <playername>
            playername: 玩家名
            获取玩家是否为管理员

]] --
lcmds["op"] = {}
lcmds["op"].mainfun = function(e) --e.avgs为参数数组,e.uin为输入玩家uin
    local targetUin = 0
    local ret = 0
    --判断参数个数
    if (e.uin ~= hostUin) then
        sysMsg("没有权限！运行这个命令需要房主级别。", e.uin)
    end
    if (getTableLength(e.args) < 1) then
        sysMsg("参数个数不正确", e.uin)
        return Err.argsError
    end
    if (e.args[1] == "show") then
        if (getTableLength(e.args) ~= 1) then
            sysMsg("参数个数不正确", e.uin)
            return Err.argsError
        end
        op.showList()
    elseif (e.args[1] == "set") then
        if (getTableLength(e.args) ~= 2) then
            sysMsg("参数个数不正确", e.uin)
            return Err.argsError
        end
        if (PlayerNames[e.args[2]] == nil) then --没有这个玩家
            sysMsg("没有这个玩家", e.uin)
            return Err.argsError
        end
        ret = op.setOp(PlayerNames[e.args[2]].uin)
        if (ret == op.err.IsOp) then
            sysMsg("该玩家(" .. e.uin .. ")已经是管理员！", e.uin)
        end
    elseif (e.args[1] == "del") then
        if (getTableLength(e.args) ~= 2) then
            sysMsg("参数个数不正确", e.uin)
            return Err.argsError
        end
        if (PlayerNames[e.args[2]] == nil) then --没有这个玩家
            sysMsg("没有这个玩家", e.uin)
            return Err.argsError
        end
        ret = op.delOp(PlayerNames[e.args[2]].uin)
        if (ret == op.err.IsNotOp) then
            sysMsg("该玩家(" .. e.uin .. ")不是是管理员！", e.uin)
        end
    elseif (e.args[1] == "get") then
        if (getTableLength(e.args) ~= 2) then
            sysMsg("参数个数不正确", e.uin)
            return Err.argsError
        end
        if (PlayerNames[e.args[2]] == nil) then --没有这个玩家
            sysMsg("没有这个玩家", e.uin)
            return Err.argsError
        end
        ret = op.isOp(PlayerNames[e.args[2]].uin)
        if (ret == false) then
            sysMsg("该玩家(" .. e.uin .. ")不是管理员！", e.uin)
        else
            sysMsg("该玩家(" .. e.uin .. ")是管理员！", e.uin)
        end
    else
        sysMsg("没有" .. e.args[1] .. "这个选项", e.uin)
        return Err.argsError
    end
end
lcmds["op"].start = function()
    --初始化代码
end
